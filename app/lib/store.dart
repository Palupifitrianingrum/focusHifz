import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Penyimpanan lokal sederhana berbasis file JSON di folder dokumen aplikasi.
/// Dipakai untuk pengaturan, cache teks Al-Qur'an, dan file murottal.
class Store {
  static Directory? _root;

  static Future<Directory> root() async {
    return _root ??= await getApplicationDocumentsDirectory();
  }

  /// Folder di dalam folder dokumen aplikasi, dibuat bila belum ada.
  static Future<Directory> sub(String name) async {
    final d = Directory('${(await root()).path}/$name');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<dynamic> readJson(File f) async {
    try {
      if (!await f.exists()) return null;
      return jsonDecode(await f.readAsString());
    } catch (_) {
      return null; // file rusak dianggap tidak ada, akan diunduh ulang
    }
  }

  /// Tulis ke file sementara lalu ganti nama, supaya file tidak setengah jadi
  /// kalau aplikasi tertutup di tengah penulisan.
  static Future<void> writeJson(File f, Object data) async {
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(data), flush: true);
    await tmp.rename(f.path);
  }
}
