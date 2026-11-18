import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'store.dart';

class MurajaItem {
  int s;
  int n;
  String st; // ulang | belajar | lancar
  String due;
  int err;
  MurajaItem(this.s, this.n, this.st, this.due, this.err);
}

class LogItem {
  final String t;
  final String d;
  LogItem(this.t, this.d);
}

class CertItem {
  final int lv;
  final String d;
  final String no;
  CertItem(this.lv, this.d, this.no);
}

class HistItem {
  final String t, r, d;
  HistItem(this.t, this.r, this.d);
}

const List<String> _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const List<String> _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String tanggalHariIni() {
  final n = DateTime.now();
  return '${_hari[n.weekday - 1]}, ${n.day} ${_bulan[n.month - 1]} ${n.year}';
}

/// Qari bawaan: Abdurrahman As-Sudais (64 kbps, ukuran file kecil untuk HP).
const String kDefaultReciter = 'Abdurrahmaan_As-Sudais_64kbps';
const String kDefaultReciterName = 'Abdurrahmaan As-Sudais';

class AppState extends ChangeNotifier {
  // String name = 'Ahmad Fauzi'; // nama contoh, diganti nama yang diisi pengguna (antislop R-23)
  String name = '';
  // int tot = 14, today = 2, tgt = 5, til = 35; // angka contoh tanpa sumber (antislop R-17)
  int tot = 0, today = 0, tgt = 5;
  int currentSurah = 0;
  int tab = 0;
  bool notif = true, rem = true;
  ThemeMode themeMode = ThemeMode.system;
  double arabicSize = 30;

  // Murottal
  String reciter = kDefaultReciter;
  String reciterName = kDefaultReciterName;

  // Posisi terakhir membaca di Mushaf (nomor surah 1-114, nomor ayat). 0 = belum pernah.
  int lastSurah = 0, lastAyah = 0;

  final List<MurajaItem> muraja = [
    // Data contoh lama, dimatikan supaya beranda tidak menampilkan angka palsu.
    // MurajaItem(0, 2, 'ulang', 'Hari ini', 3),
    // MurajaItem(0, 6, 'belajar', 'Besok', 1),
    // MurajaItem(1, 3, 'lancar', '3 hari lagi', 0),
    // MurajaItem(1, 1, 'belajar', 'Hari ini', 2),
    // MurajaItem(0, 4, 'lancar', 'Minggu ini', 0),
  ];
  final List<LogItem> log = [
    // LogItem("Muraja'ah Al-Fatihah : 2", 'Kemarin'),
    // LogItem('Tilawah 15 menit', '2 hari lalu'),
  ];
  final List<CertItem> certs = [];
  final List<HistItem> hist = [];

  int get pending => muraja.where((x) => x.st != 'lancar').length;

  void update(VoidCallback fn) {
    fn();
    notifyListeners();
    _saveSoon();
  }

  void addLog(String t) => update(() => log.insert(0, LogItem(t, 'Baru saja')));

  void setLastRead(int surah, int ayah) {
    if (lastSurah == surah && lastAyah == ayah) return;
    update(() {
      lastSurah = surah;
      lastAyah = ayah;
    });
  }

  // ---------- Simpan pengaturan ke file ----------
  Timer? _saveTimer;

  void _saveSoon() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<File> _file() async => File('${(await Store.root()).path}/pengaturan.json');

  Future<void> _save() async {
    try {
      await Store.writeJson(await _file(), {
        'name': name,
        'tgt': tgt,
        'theme': themeMode.index,
        'arabicSize': arabicSize,
        'reciter': reciter,
        'reciterName': reciterName,
        'lastSurah': lastSurah,
        'lastAyah': lastAyah,
      });
    } catch (_) {
      // Gagal simpan tidak menghentikan aplikasi; pengaturan berlaku sampai aplikasi ditutup.
    }
  }

  Future<void> load() async {
    try {
      final j = await Store.readJson(await _file());
      if (j is! Map) return;
      name = (j['name'] as String?) ?? name;
      tgt = (j['tgt'] as num?)?.toInt() ?? tgt;
      final th = (j['theme'] as num?)?.toInt();
      if (th != null && th >= 0 && th < ThemeMode.values.length) themeMode = ThemeMode.values[th];
      arabicSize = (j['arabicSize'] as num?)?.toDouble() ?? arabicSize;
      reciter = (j['reciter'] as String?) ?? reciter;
      reciterName = (j['reciterName'] as String?) ?? reciterName;
      lastSurah = (j['lastSurah'] as num?)?.toInt() ?? 0;
      lastAyah = (j['lastAyah'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }
}

final AppState app = AppState();
