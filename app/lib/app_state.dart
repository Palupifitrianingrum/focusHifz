import 'package:flutter/material.dart';

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

class AppState extends ChangeNotifier {
  String name = 'Ahmad Fauzi';
  int tot = 14, today = 2, tgt = 5, til = 35;
  int currentSurah = 0;
  int tab = 0;
  bool notif = true, rem = true;
  ThemeMode themeMode = ThemeMode.system;
  double arabicSize = 30;

  final List<MurajaItem> muraja = [
    MurajaItem(0, 2, 'ulang', 'Hari ini', 3),
    MurajaItem(0, 6, 'belajar', 'Besok', 1),
    MurajaItem(1, 3, 'lancar', '3 hari lagi', 0),
    MurajaItem(1, 1, 'belajar', 'Hari ini', 2),
    MurajaItem(0, 4, 'lancar', 'Minggu ini', 0),
  ];
  final List<LogItem> log = [
    LogItem("Muraja'ah Al-Fatihah : 2", 'Kemarin'),
    LogItem('Tilawah 15 menit', '2 hari lalu'),
  ];
  final List<CertItem> certs = [];
  final List<HistItem> hist = [];

  int get pending => muraja.where((x) => x.st != 'lancar').length;

  void update(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void addLog(String t) => update(() => log.insert(0, LogItem(t, 'Baru saja')));
}

final AppState app = AppState();
