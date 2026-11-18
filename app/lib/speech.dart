import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Pembungkus speech_to_text untuk bahasa Arab.
/// Mendengarkan terus-menerus: kalau mesin Android berhenti sendiri karena jeda,
/// otomatis dimulai lagi dan teks sebelumnya digabung.
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  String? _locale;
  bool _want = false;
  int _token = 0;
  String _done = '';
  String _cur = '';

  /// Teks yang terdengar sejauh ini.
  final ValueNotifier<String> text = ValueNotifier<String>('');

  /// true selama sesi mendengarkan aktif (turun hanya saat dihentikan / error fatal).
  final ValueNotifier<bool> active = ValueNotifier<bool>(false);

  /// Level suara 0..1 untuk animasi gelombang.
  final ValueNotifier<double> level = ValueNotifier<double>(0);

  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  Future<bool> init() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(onError: _onError, onStatus: _onStatus);
    } catch (_) {
      _ready = false;
    }
    if (!_ready) {
      error.value =
          'Izin mikrofon ditolak atau layanan suara tidak tersedia. Aktifkan izin mikrofon untuk aplikasi ini dan pastikan layanan suara Google terpasang.';
      return false;
    }
    try {
      final locs = await _stt.locales();
      String? pick;
      for (final l in locs) {
        final id = l.localeId.replaceAll('-', '_').toLowerCase();
        if (id == 'ar_sa') {
          pick = l.localeId;
          break;
        }
      }
      if (pick == null) {
        for (final l in locs) {
          if (l.localeId.toLowerCase().startsWith('ar')) {
            pick = l.localeId;
            break;
          }
        }
      }
      _locale = pick ?? 'ar_SA';
    } catch (_) {
      _locale = 'ar_SA';
    }
    return true;
  }

  Future<bool> start() async {
    error.value = null;
    if (!await init()) return false;
    _done = '';
    _cur = '';
    text.value = '';
    _want = true;
    active.value = true;
    final ok = await _listen();
    if (!ok) {
      _want = false;
      active.value = false;
    }
    return ok;
  }

  Future<bool> _listen() async {
    try {
      await _stt.listen(
        onResult: _onResult,
        localeId: _locale,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 8),
        onSoundLevelChange: (double l) {
          final v = (l + 2) / 12;
          level.value = v < 0 ? 0.0 : (v > 1 ? 1.0 : v);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } catch (_) {
      error.value = 'Gagal memulai pengenalan suara.';
      return false;
    }
  }

  void _onResult(SpeechRecognitionResult r) {
    _cur = r.recognizedWords;
    _publish();
  }

  void _publish() {
    text.value = ('$_done $_cur').trim();
  }

  void _commit() {
    if (_cur.isNotEmpty) {
      _done = ('$_done $_cur').trim();
      _cur = '';
      _publish();
    }
  }

  void _scheduleRestart(int ms) {
    final tk = ++_token;
    Future.delayed(Duration(milliseconds: ms), () async {
      if (!_want || tk != _token) return;
      _commit();
      if (!_stt.isListening) await _listen();
    });
  }

  void _onStatus(String s) {
    if (!_want) return;
    if (s == 'listening') {
      _token++;
    } else if (s == 'done') {
      _scheduleRestart(300);
    } else if (s == 'notListening') {
      _scheduleRestart(1200);
    }
  }

  void _onError(SpeechRecognitionError e) {
    if (!_want) return;
    final msg = e.errorMsg;
    String? fatal;
    if (msg.contains('permission')) {
      fatal = 'Izin mikrofon ditolak. Aktifkan izin mikrofon lalu coba lagi.';
    } else if (msg.contains('network') || msg.contains('server')) {
      fatal = 'Pengenalan suara butuh koneksi internet. Periksa jaringan lalu coba lagi.';
    } else if (msg.contains('language')) {
      fatal = 'Bahasa Arab belum tersedia di layanan suara perangkat ini.';
    }
    if (fatal != null) {
      _want = false;
      _token++;
      error.value = fatal;
      active.value = false;
      return;
    }
    // no_match, speech_timeout, busy, client: coba lagi
    _scheduleRestart(500);
  }

  /// Hentikan dan kembalikan seluruh teks yang terdengar.
  Future<String> stopAndCollect() async {
    _want = false;
    _token++;
    try {
      await _stt.stop();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 900));
    _commit();
    active.value = false;
    level.value = 0;
    return text.value;
  }

  Future<void> cancel() async {
    _want = false;
    _token++;
    try {
      await _stt.cancel();
    } catch (_) {}
    active.value = false;
    level.value = 0;
  }

  void dispose() {
    _want = false;
    _token++;
    try {
      _stt.cancel();
    } catch (_) {}
    text.dispose();
    active.dispose();
    level.dispose();
    error.dispose();
  }
}
