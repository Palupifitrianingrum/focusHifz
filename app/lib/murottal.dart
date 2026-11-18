import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'app_state.dart';
import 'quran_api.dart';
import 'store.dart';

/// Satu ayat. [a] == 0 berarti basmalah pembuka surah [s] (file 001001).
@immutable
class AyahRef {
  final int s;
  final int a;
  const AyahRef(this.s, this.a);

  bool get isBasmalah => a == 0;

  /// Nomor file di everyayah.com: basmalah memakai Al-Fatihah ayat 1.
  int get fileSurah => isBasmalah ? 1 : s;
  int get fileAyah => isBasmalah ? 1 : a;
  String get fileName => '${pad3(fileSurah)}${pad3(fileAyah)}.mp3';

  @override
  bool operator ==(Object o) => o is AyahRef && o.s == s && o.a == a;
  @override
  int get hashCode => s * 1000 + a;
}

/// Surah yang dibuka dengan basmalah terpisah (selain Al-Fatihah dan At-Taubah).
bool needsBasmalah(int surah) => surah != 1 && surah != 9;

Future<Directory> reciterDir(String folder) =>
    Store.sub('murottal/${folder.replaceAll('/', '__')}');

Future<File> ayahFile(String folder, AyahRef r) async =>
    File('${(await reciterDir(folder)).path}/${r.fileName}');

// =====================================================================
// Pemutar
// =====================================================================
class Murottal {
  final AudioPlayer _p = AudioPlayer();
  late final StreamSubscription<PlayerState> _sub;

  /// Ayat yang sedang diputar (null = berhenti).
  final ValueNotifier<AyahRef?> current = ValueNotifier<AyahRef?>(null);
  final ValueNotifier<bool> playing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  List<AyahRef> _queue = const [];
  int _i = 0;
  int _token = 0;
  int _handled = -1; // indeks antrean yang event "selesai"-nya sudah diproses

  Murottal() {
    _sub = _p.playerStateStream.listen(_onState, onError: (Object _) => _fail());
  }

  bool get active => current.value != null;

  void _onState(PlayerState st) {
    final ps = st.processingState;
    loading.value = ps == ProcessingState.loading || ps == ProcessingState.buffering;
    playing.value = st.playing && ps != ProcessingState.completed;
    if (ps == ProcessingState.completed && _handled != _token) {
      _handled = _token;
      _next();
    }
  }

  /// Putar satu ayat saja.
  Future<void> playAyah(int s, int a) => playQueue([AyahRef(s, a)]);

  /// Putar surah [s] dari ayat [from] sampai [to], dengan basmalah bila mulai dari ayat 1.
  Future<void> playRange(int s, int from, int to) {
    final q = <AyahRef>[
      if (from == 1 && needsBasmalah(s)) AyahRef(s, 0),
      for (var a = from; a <= to; a++) AyahRef(s, a),
    ];
    return playQueue(q);
  }

  Future<void> playQueue(List<AyahRef> q) async {
    if (q.isEmpty) return;
    _queue = List.unmodifiable(q);
    _i = 0;
    await _playAt(0);
  }

  Future<void> _playAt(int i) async {
    final tk = ++_token;
    final ref = _queue[i];
    current.value = ref;
    error.value = null;
    if (!ref.isBasmalah) app.setLastRead(ref.s, ref.a);
    final folder = app.reciter;
    try {
      final f = await ayahFile(folder, ref);
      if (tk != _token) return;
      if (await f.exists() && await f.length() > 0) {
        await _p.setFilePath(f.path);
      } else {
        await _p.setUrl(audioUrl(folder, ref.fileSurah, ref.fileAyah));
      }
      if (tk != _token) return;
      // play() baru selesai saat audio berhenti, jadi tidak ditunggu.
      unawaited(_p.play());
    } catch (_) {
      if (tk == _token) _fail();
    }
  }

  void _fail() {
    error.value =
        'Audio gagal diputar. Periksa koneksi internet, atau unduh murottal agar bisa diputar offline.';
    stop();
  }

  void _next() {
    if (_i + 1 < _queue.length) {
      _i++;
      _playAt(_i);
    } else {
      stop(keepError: true);
    }
  }

  Future<void> toggle() async {
    if (!active) return;
    if (_p.playing) {
      await _p.pause();
    } else {
      unawaited(_p.play());
    }
  }

  Future<void> skip(int delta) async {
    if (!active) return;
    final j = _i + delta;
    if (j < 0 || j >= _queue.length) return;
    _i = j;
    await _playAt(j);
  }

  Future<void> stop({bool keepError = false}) async {
    _token++;
    _queue = const [];
    current.value = null;
    playing.value = false;
    loading.value = false;
    if (!keepError) error.value = null;
    try {
      await _p.stop();
    } catch (_) {}
  }

  void dispose() {
    _sub.cancel();
    _p.dispose();
  }
}

final Murottal murottal = Murottal();

// =====================================================================
// Pengunduh
// =====================================================================
class DlProgress {
  final String reciterName;
  final String scope;
  final int total;
  final int done; // berhasil, termasuk yang sudah ada sebelumnya
  final int failed;
  final bool running;
  final bool cancelled;
  const DlProgress({
    required this.reciterName,
    required this.scope,
    required this.total,
    required this.done,
    required this.failed,
    required this.running,
    required this.cancelled,
  });

  double get ratio => total == 0 ? 0 : (done + failed) / total;
}

class ReciterStorage {
  final String folder; // nama folder lokal
  final int files;
  final int bytes;
  const ReciterStorage(this.folder, this.files, this.bytes);
}

String formatBytes(int b) {
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

class Downloader {
  final ValueNotifier<DlProgress?> progress = ValueNotifier<DlProgress?>(null);

  /// Naik setiap kali ada file baru tersimpan atau terhapus, supaya tampilan status ikut segar.
  final ValueNotifier<int> changed = ValueNotifier<int>(0);

  bool _cancel = false;
  List<AyahRef> _failedItems = const [];
  Reciter? _lastReciter;
  String _lastScope = '';

  bool get running => progress.value?.running ?? false;
  bool get canRetry => !running && _failedItems.isNotEmpty && _lastReciter != null;

  /// Tambahkan file basmalah bila ada surah yang diunduh dari ayat 1.
  static List<AyahRef> withBasmalah(List<AyahRef> items) {
    final needs = items.any((r) => r.a == 1 && needsBasmalah(r.s));
    final hasFatihah1 = items.any((r) => r.fileSurah == 1 && r.fileAyah == 1);
    if (needs && !hasFatihah1) return [const AyahRef(1, 1), ...items];
    return items;
  }

  Future<void> start(Reciter r, List<AyahRef> items, String scope) async {
    if (running) return;
    final list = withBasmalah(items);
    _cancel = false;
    _lastReciter = r;
    _lastScope = scope;
    var done = 0, failed = 0, next = 0;
    final failedItems = <AyahRef>[];
    void emit({bool running = true}) {
      progress.value = DlProgress(
        reciterName: r.label,
        scope: scope,
        total: list.length,
        done: done,
        failed: failed,
        running: running,
        cancelled: _cancel,
      );
    }

    emit();
    final dir = await reciterDir(r.folder);
    final client = http.Client();

    Future<void> worker() async {
      while (!_cancel) {
        final idx = next++;
        if (idx >= list.length) return;
        final ref = list[idx];
        final f = File('${dir.path}/${ref.fileName}');
        try {
          if (await f.exists() && await f.length() > 0) {
            done++;
          } else {
            final res = await client
                .get(Uri.parse(audioUrl(r.folder, ref.fileSurah, ref.fileAyah)))
                .timeout(const Duration(seconds: 40));
            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              final tmp = File('${f.path}.part');
              await tmp.writeAsBytes(res.bodyBytes, flush: true);
              await tmp.rename(f.path);
              done++;
            } else {
              failed++;
              failedItems.add(ref);
            }
          }
        } catch (_) {
          failed++;
          failedItems.add(ref);
        }
        emit();
      }
    }

    try {
      // Tiga unduhan berjalan bersamaan: cukup cepat tanpa membebani server everyayah.com.
      await Future.wait([worker(), worker(), worker()]);
    } finally {
      client.close();
      _failedItems = failedItems;
      emit(running: false);
      changed.value++;
    }
  }

  Future<void> retryFailed() async {
    final r = _lastReciter;
    if (r == null || _failedItems.isEmpty) return;
    await start(r, List.of(_failedItems), _lastScope);
  }

  void cancel() => _cancel = true;

  void clear() {
    if (!running) progress.value = null;
  }

  /// Nama file (SSSAAA.mp3) yang sudah tersimpan untuk satu qari.
  Future<Set<String>> savedFiles(String folder) async {
    final d = await reciterDir(folder);
    final out = <String>{};
    await for (final e in d.list()) {
      if (e is File && e.path.endsWith('.mp3')) out.add(e.uri.pathSegments.last);
    }
    return out;
  }

  /// Ukuran murottal tersimpan per qari (dihitung dari file yang benar-benar ada).
  Future<List<ReciterStorage>> storage() async {
    final root = await Store.sub('murottal');
    final out = <ReciterStorage>[];
    await for (final e in root.list()) {
      if (e is! Directory) continue;
      var n = 0, b = 0;
      await for (final f in e.list()) {
        if (f is File && f.path.endsWith('.mp3')) {
          n++;
          b += await f.length();
        }
      }
      if (n > 0) out.add(ReciterStorage(e.uri.pathSegments.where((x) => x.isNotEmpty).last, n, b));
    }
    out.sort((a, b) => b.bytes.compareTo(a.bytes));
    return out;
  }

  Future<void> deleteLocal(String localFolder) async {
    final root = await Store.sub('murottal');
    final d = Directory('${root.path}/$localFolder');
    if (await d.exists()) await d.delete(recursive: true);
    changed.value++;
  }
}

final Downloader downloader = Downloader();
