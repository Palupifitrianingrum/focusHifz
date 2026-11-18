import 'package:flutter/services.dart';

/// true = ada tombol "Keluar (mode uji)" saat Focus Mode aktif, untuk demo/testing.
/// Ubah ke false untuk versi asli.
const bool modeUji = true;

const MethodChannel _ch = MethodChannel('fokus/lock');

/// Panggil kode native (MainActivity.kt): start, stop, status, dndSettings.
Future<dynamic> native(String m) async {
  try {
    return await _ch.invokeMethod(m);
  } catch (_) {
    return null; // di web/DartPad tidak ada kode native
  }
}
