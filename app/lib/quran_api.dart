import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'store.dart';

// Sumber data online:
// - Daftar surah dan teks Utsmani bertajwid: API quran.com v4 (api.quran.com/api/v4)
// - Murottal per ayat dan daftar qari: everyayah.com (data/<folder>/SSSAAA.mp3)
// Semua respons disimpan di folder cache, jadi setelah dibuka sekali bisa dipakai offline.

const String _quranApi = 'https://api.quran.com/api/v4';
const String _everyAyah = 'https://everyayah.com/data';

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
  @override
  String toString() => message;
}

class Chapter {
  final int id;
  final String name; // Al-Baqarah
  final String arabic; // البقرة
  final String meaning; // Sapi Betina
  final String place; // makkah | madinah
  final int verses;
  final bool bismillah;

  const Chapter({
    required this.id,
    required this.name,
    required this.arabic,
    required this.meaning,
    required this.place,
    required this.verses,
    required this.bismillah,
  });

  factory Chapter.fromApi(Map<String, dynamic> j) => Chapter(
        id: (j['id'] as num).toInt(),
        name: (j['name_simple'] ?? '') as String,
        arabic: (j['name_arabic'] ?? '') as String,
        meaning: ((j['translated_name'] as Map?)?['name'] ?? '') as String,
        place: (j['revelation_place'] ?? '') as String,
        verses: (j['verses_count'] as num).toInt(),
        bismillah: j['bismillah_pre'] == true,
      );

  factory Chapter.fromCache(Map<String, dynamic> j) => Chapter(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        arabic: j['arabic'] as String,
        meaning: j['meaning'] as String,
        place: j['place'] as String,
        verses: (j['verses'] as num).toInt(),
        bismillah: j['bismillah'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'arabic': arabic,
        'meaning': meaning,
        'place': place,
        'verses': verses,
        'bismillah': bismillah,
      };

  String get placeLabel => place == 'madinah' ? 'Madaniyah' : 'Makkiyah';
}

/// Satu ayat dengan markup tajwid dari quran.com, mis.
/// `<tajweed class=ham_wasl>ٱ</tajweed>لْحَمْدُ ... <span class=end>٢</span>`
class QVerse {
  final int n;
  final String tajweed;
  const QVerse(this.n, this.tajweed);
}

class Reciter {
  final String folder; // subfolder di everyayah.com
  final String name;
  final String bitrate;
  const Reciter(this.folder, this.name, this.bitrate);

  String get label => '$name · $bitrate';

  /// Nama folder lokal yang aman (beberapa subfolder berisi "/", mis. warsh/...).
  String get localDir => folder.replaceAll('/', '__');
}

/// Dipakai bila daftar qari belum pernah terunduh dan perangkat sedang offline.
/// Diambil dari everyayah.com/data/recitations.js.
const List<Reciter> kFallbackReciters = [
  Reciter('Abdurrahmaan_As-Sudais_64kbps', 'Abdurrahmaan As-Sudais', '64kbps'),
  Reciter('Abdurrahmaan_As-Sudais_192kbps', 'Abdurrahmaan As-Sudais', '192kbps'),
  Reciter('Alafasy_64kbps', 'Alafasy', '64kbps'),
  Reciter('Alafasy_128kbps', 'Alafasy', '128kbps'),
  Reciter('Husary_64kbps', 'Husary', '64kbps'),
  Reciter('Husary_128kbps', 'Husary', '128kbps'),
  Reciter('Husary_Muallim_128kbps', 'Husary (Muallim)', '128kbps'),
  Reciter('Abdul_Basit_Murattal_64kbps', 'Abdul Basit Murattal', '64kbps'),
  Reciter('Abdul_Basit_Murattal_192kbps', 'Abdul Basit Murattal', '192kbps'),
  Reciter('Ghamadi_40kbps', 'Ghamadi', '40kbps'),
];

String pad3(int x) => x.toString().padLeft(3, '0');

String audioUrl(String folder, int surah, int ayah) =>
    '$_everyAyah/$folder/${pad3(surah)}${pad3(ayah)}.mp3';

class QuranApi {
  static List<Chapter>? _chapters;
  static final Map<int, List<QVerse>> _verses = {};
  static List<Reciter>? _reciters;

  static Future<File> _cache(String name) async =>
      File('${(await Store.sub('cache')).path}/$name');

  static Future<String> _get(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) {
        throw ApiError('Server membalas dengan kode ${res.statusCode}. Coba lagi nanti.');
      }
      // Paksa UTF-8: tanpa ini teks Arab bisa rusak bila server tidak menyebut charset.
      return utf8.decode(res.bodyBytes);
    } on SocketException {
      throw ApiError('Tidak ada koneksi internet. Sambungkan lalu coba lagi.');
    } on TimeoutException {
      throw ApiError('Koneksi terlalu lambat, server tidak menjawab. Coba lagi.');
    } on http.ClientException {
      throw ApiError('Gagal menghubungi server. Periksa koneksi lalu coba lagi.');
    }
  }

  /// Daftar 114 surah (nama Indonesia dari quran.com).
  static Future<List<Chapter>> chapters({bool refresh = false}) async {
    if (_chapters != null && !refresh) return _chapters!;
    final f = await _cache('chapters_id.json');
    if (!refresh) {
      final c = await Store.readJson(f);
      if (c is List && c.length == 114) {
        return _chapters =
            c.map((e) => Chapter.fromCache(Map<String, dynamic>.from(e as Map))).toList();
      }
    }
    final body = await _get('$_quranApi/chapters?language=id');
    final raw = (jsonDecode(body) as Map)['chapters'] as List;
    final list =
        raw.map((e) => Chapter.fromApi(Map<String, dynamic>.from(e as Map))).toList();
    if (list.length != 114) throw ApiError('Data surah dari server tidak lengkap.');
    await Store.writeJson(f, list.map((c) => c.toJson()).toList());
    return _chapters = list;
  }

  /// Muat daftar surah dari cache saja (tanpa internet), dipanggil saat aplikasi dibuka
  /// supaya beranda bisa langsung menampilkan nama surah terakhir dibaca.
  static Future<void> warmCache() async {
    if (_chapters != null) return;
    try {
      final c = await Store.readJson(await _cache('chapters_id.json'));
      if (c is List && c.length == 114) {
        _chapters =
            c.map((e) => Chapter.fromCache(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
  }

  static Chapter? chapterSync(int id) {
    final c = _chapters;
    if (c == null || id < 1 || id > c.length) return null;
    return c[id - 1];
  }

  /// Ayat sudah ada di memori (tanpa menunggu), untuk tampilan yang tidak boleh berkedip.
  static List<QVerse>? versesSync(int surah) => _verses[surah];

  /// Teks Utsmani bertajwid untuk satu surah.
  static Future<List<QVerse>> verses(int surah, {bool refresh = false}) async {
    if (_verses[surah] != null && !refresh) return _verses[surah]!;
    final f = await _cache('tajweed_${pad3(surah)}.json');
    if (!refresh) {
      final c = await Store.readJson(f);
      if (c is List && c.isNotEmpty) {
        return _verses[surah] = [
          for (final e in c) QVerse(((e as Map)['n'] as num).toInt(), e['t'] as String),
        ];
      }
    }
    final body = await _get('$_quranApi/quran/verses/uthmani_tajweed?chapter_number=$surah');
    final raw = (jsonDecode(body) as Map)['verses'] as List;
    final list = <QVerse>[];
    for (final e in raw) {
      final m = e as Map;
      final key = (m['verse_key'] as String).split(':');
      list.add(QVerse(int.parse(key[1]), (m['text_uthmani_tajweed'] ?? '') as String));
    }
    list.sort((a, b) => a.n.compareTo(b.n));
    if (list.isEmpty) throw ApiError('Teks surah ini belum tersedia dari server.');
    await Store.writeJson(f, [
      for (final v in list) {'n': v.n, 't': v.tajweed},
    ]);
    return _verses[surah] = list;
  }

  /// Semua qari yang tersedia di everyayah.com.
  static Future<List<Reciter>> reciters({bool refresh = false}) async {
    if (_reciters != null && !refresh) return _reciters!;
    final f = await _cache('reciters.json');
    if (!refresh) {
      final c = await Store.readJson(f);
      if (c is List && c.isNotEmpty) {
        return _reciters = [
          for (final e in c) Reciter((e as Map)['f'] as String, e['n'] as String, e['b'] as String),
        ];
      }
    }
    final body = await _get('$_everyAyah/recitations.js');
    // Isinya objek JSON; ambil dari "{" pertama sampai "}" terakhir supaya aman
    // kalau suatu saat dibungkus sebagai variabel JavaScript.
    final start = body.indexOf('{');
    final end = body.lastIndexOf('}');
    if (start < 0 || end <= start) throw ApiError('Format daftar qari tidak dikenali.');
    final m = jsonDecode(body.substring(start, end + 1)) as Map;
    final list = <Reciter>[];
    m.forEach((k, v) {
      if (v is Map && v['subfolder'] is String) {
        list.add(Reciter(
          v['subfolder'] as String,
          (v['name'] ?? v['subfolder']) as String,
          (v['bitrate'] ?? '') as String,
        ));
      }
    });
    if (list.isEmpty) throw ApiError('Daftar qari kosong dari server.');
    list.sort((a, b) {
      final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return c != 0 ? c : a.bitrate.compareTo(b.bitrate);
    });
    await Store.writeJson(f, [
      for (final r in list) {'f': r.folder, 'n': r.name, 'b': r.bitrate},
    ]);
    return _reciters = list;
  }
}
