import 'dart:math' as math;
import 'data.dart';

/// Normalisasi teks Arab: buang harakat, samakan bentuk huruf.
final RegExp _diac = RegExp(r'[\u0640\u064B-\u065F\u0670\u06D6-\u06ED]');
final RegExp _nonAr = RegExp(r'[^\u0621-\u064A\s]');
final RegExp _spaces = RegExp(r'\s+');

String an(String s) {
  var t = s.replaceAll(_diac, '');
  t = t
      .replaceAll('\u0623', '\u0627')
      .replaceAll('\u0625', '\u0627')
      .replaceAll('\u0622', '\u0627')
      .replaceAll('\u0671', '\u0627')
      .replaceAll('\u0649', '\u064A')
      .replaceAll('\u0626', '\u064A')
      .replaceAll('\u0624', '\u0648')
      .replaceAll('\u0629', '\u0647');
  t = t.replaceAll(_nonAr, ' ').replaceAll(_spaces, ' ').trim();
  return t;
}

int lev(String a, String b) {
  final m = a.length, n = b.length;
  var p = List<int>.generate(n + 1, (j) => j);
  for (var i = 1; i <= m; i++) {
    final c = List<int>.filled(n + 1, 0);
    c[0] = i;
    for (var j = 1; j <= n; j++) {
      c[j] = math.min(
        math.min(p[j] + 1, c[j - 1] + 1),
        p[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      );
    }
    p = c;
  }
  return p[n];
}

double sim(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1;
  return 1 - lev(a, b) / math.max(a.length, b.length);
}

class WordRes {
  final String orig;
  final String k;
  final int ay;
  String st = 'miss'; // ok | near | bad | miss
  String heard = '';
  WordRes(this.orig, this.k, this.ay);
}

class AyatRes {
  final List<WordRes> ws;
  final String v; // g | y | r
  AyatRes(this.ws, this.v);
}

class CheckResult {
  final String heard;
  final int total;
  final double acc;
  final Map<String, int> cnt;
  final int extra;
  final Map<int, AyatRes> ays;
  CheckResult(this.heard, this.total, this.acc, this.cnt, this.extra, this.ays);
}

/// Cocokkan hasil speech-to-text dengan teks ayat [f]..[t] surah indeks [s].
CheckResult checkRecitation(int s, int f, int t, String heardRaw) {
  final words = <WordRes>[];
  for (var ay = f; ay <= t; ay++) {
    for (final w in surahs[s].a[ay - 1].split(' ')) {
      final k = an(w);
      if (k.isNotEmpty) words.add(WordRes(w, k, ay));
    }
  }
  final raw = an(heardRaw);
  final hh = raw.isEmpty ? <String>[] : raw.split(' ');
  final n = words.length, m = hh.length;
  final d = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0));
  final pt = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  double sc(int x, int y) {
    final q = sim(words[x].k, hh[y]);
    return q >= .5 ? 1 - q : 1.2;
  }

  for (var i = 1; i <= n; i++) {
    d[i][0] = i.toDouble();
    pt[i][0] = 1;
  }
  for (var j = 1; j <= m; j++) {
    d[0][j] = j.toDouble();
    pt[0][j] = 2;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final a = d[i - 1][j - 1] + sc(i - 1, j - 1);
      final b = d[i - 1][j] + 1;
      final c = d[i][j - 1] + 1;
      final mn = math.min(a, math.min(b, c));
      d[i][j] = mn;
      pt[i][j] = mn == a ? 0 : (mn == b ? 1 : 2);
    }
  }
  var i = n, j = m, extra = 0;
  while (i > 0 || j > 0) {
    final p = (i > 0 && j > 0) ? pt[i][j] : (i > 0 ? 1 : 2);
    if (p == 0) {
      final q = sim(words[i - 1].k, hh[j - 1]);
      words[i - 1].heard = hh[j - 1];
      words[i - 1].st = q >= .85 ? 'ok' : (q >= .6 ? 'near' : 'bad');
      i--;
      j--;
    } else if (p == 1) {
      words[i - 1].st = 'miss';
      i--;
    } else {
      extra++;
      j--;
    }
  }
  final cnt = <String, int>{'ok': 0, 'near': 0, 'bad': 0, 'miss': 0};
  for (final w in words) {
    cnt[w.st] = (cnt[w.st] ?? 0) + 1;
  }
  final ays = <int, AyatRes>{};
  for (var a = f; a <= t; a++) {
    final ws = words.where((w) => w.ay == a).toList();
    final bad = ws.any((w) => w.st == 'bad');
    final soft = ws.any((w) => w.st == 'near' || w.st == 'miss');
    ays[a] = AyatRes(ws, bad ? 'r' : (soft ? 'y' : 'g'));
  }
  final acc = n == 0 ? 0.0 : ((cnt['ok'] ?? 0) + .5 * (cnt['near'] ?? 0)) / n;
  return CheckResult(heardRaw.trim(), n, acc, cnt, extra, ays);
}
