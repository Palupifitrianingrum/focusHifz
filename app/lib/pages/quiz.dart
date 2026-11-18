import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../ui.dart';
import 'tilawah.dart';

const Map<String, String> quizNames = {
  'sambung': 'Sambung Ayat',
  'tebak': 'Tebak Ayat',
  'susun': 'Susun Ayat',
  'hukum': 'Tebak Hukum Bacaan',
  'tantang': 'Tantangan Waktu',
  'ujian': 'Ujian Sambung Ayat',
};

class Question {
  final bool susun;
  final String q;
  final String? ar;
  final List<String> o;
  final int a;
  final String top;
  final List<String> ws;
  final String ans;
  const Question({
    required this.susun,
    required this.q,
    this.ar,
    this.o = const [],
    this.a = 0,
    required this.top,
    this.ws = const [],
    this.ans = '',
  });
}

Question _hukumQ(Hukum h) {
  final op = shuf<String>([h.r, ...shuf<String>(hukumPilihan.where((x) => x != h.r)).take(3)]);
  return Question(susun: false, q: h.q, ar: h.t, o: op, a: op.indexOf(h.r), top: h.r);
}

Question genQuestion(String k) {
  if (k == 'sambung') {
    final cand = verses.where((x) => words(x.t).length >= 3).toList();
    final v = rnd(cand);
    final w = words(v.t);
    final others = cand.where((x) => x != v).toList();
    if (rng.nextDouble() < .5 && w.length >= 4) {
      final j = 1 + rng.nextInt(w.length - 2);
      final pool = shuf<String>(
          others.expand((x) => words(x.t)).where((z) => z != w[j]).toSet());
      final op = shuf<String>([w[j], ...pool.take(3)]);
      return Question(
        susun: false,
        q: 'Lengkapi kata yang hilang',
        ar: [for (var i = 0; i < w.length; i++) i == j ? '_____' : w[i]].join(' '),
        o: op,
        a: op.indexOf(w[j]),
        top: surahs[v.s].n,
      );
    }
    final c = (w.length / 2).ceil();
    final rest = w.sublist(c).join(' ');
    final ds = others
        .map((x) {
          final y = words(x.t);
          return y.sublist((y.length / 2).ceil()).join(' ');
        })
        .where((r) => r != rest)
        .toSet();
    final op = shuf<String>([rest, ...shuf<String>(ds).take(3)]);
    return Question(
      susun: false,
      q: 'Pilih kelanjutan ayat',
      ar: '${w.sublist(0, c).join(' ')} …',
      o: op,
      a: op.indexOf(rest),
      top: surahs[v.s].n,
    );
  }
  if (k == 'tebak') {
    final v = rnd(verses);
    String lb(Verse x) => '${surahs[x.s].n} : ${x.n}';
    final others = shuf<Verse>(verses.where((x) => x != v)).take(3);
    final op = shuf<Verse>([v, ...others]).map(lb).toList();
    return Question(
        susun: false,
        q: 'Ayat ini berasal dari…',
        ar: v.t,
        o: op,
        a: op.indexOf(lb(v)),
        top: surahs[v.s].n);
  }
  if (k == 'susun') {
    final cand = verses.where((x) {
      final l = words(x.t).length;
      return l >= 3 && l <= 6;
    }).toList();
    final v = rnd(cand);
    return Question(
        susun: true,
        q: 'Susun potongan menjadi ayat yang benar',
        ws: shuf<String>(words(v.t)),
        ans: v.t,
        top: surahs[v.s].n);
  }
  return _hukumQ(rnd(hukumList));
}

List<Question> buildQuiz(String k) {
  if (k == 'hukum') return shuf<Hukum>(hukumList).map(_hukumQ).toList();
  final n = k == 'tantang' ? 12 : (k == 'susun' ? 4 : 5);
  const kinds = ['sambung', 'tebak', 'susun', 'hukum'];
  return [
    for (var i = 0; i < n; i++)
      genQuestion(k == 'tantang' ? rnd(kinds) : (k == 'ujian' ? 'sambung' : k)),
  ];
}

class QuizResult {
  final String kind;
  final int total, ok, no, best, dur;
  final List<Question> bad;
  const QuizResult(this.kind, this.total, this.ok, this.no, this.best, this.dur, this.bad);
}

// ================= KUIS =================
class QuizPage extends StatefulWidget {
  final String kind;
  const QuizPage({super.key, required this.kind});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final List<Question> l = buildQuiz(widget.kind);
  int i = 0, ok = 0, no = 0, st = 0, best = 0, left = 60;
  int? sel;
  List<int> seq = [];
  final List<Question> bad = [];
  final DateTime t0 = DateTime.now();
  bool done = false;
  Timer? _tm;

  @override
  void initState() {
    super.initState();
    if (widget.kind == 'tantang') {
      _tm = Timer.periodic(const Duration(seconds: 1), (_) {
        if (done || !mounted) return;
        setState(() => left--);
        if (left <= 0) _fin();
      });
    }
  }

  @override
  void dispose() {
    _tm?.cancel();
    super.dispose();
  }

  void _score(bool right, Question q) {
    if (right) {
      ok++;
      st++;
      best = math.max(best, st);
    } else {
      no++;
      st = 0;
      bad.add(q);
    }
  }

  void _fin() {
    if (done) return;
    done = true;
    _tm?.cancel();
    final dur = DateTime.now().difference(t0).inSeconds;
    final ex = widget.kind == 'ujian';
    final pc = ok / l.length;
    if (ex) {
      app.update(() {
        app.hist.insert(
            0,
            HistItem('Ujian Sambung Ayat · Level 1',
                '${(pc * 100).round()}% · ${pc >= .6 ? 'Lulus' : 'Belum lulus'}', tanggalHariIni()));
        if (pc >= .6 && app.certs.isEmpty) {
          app.certs.add(CertItem(0, tanggalHariIni(),
              'HF-${DateTime.now().year}-${1000 + math.Random().nextInt(9000)}'));
        }
      });
    }
    app.addLog('${quizNames[widget.kind]}: $ok/${l.length} benar');
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) =>
            QuizResultPage(QuizResult(widget.kind, l.length, ok, no, best, dur, List.of(bad)))));
  }

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final q = l[i];
    final tm = widget.kind == 'tantang';
    final answered = sel != null;
    Widget body;
    if (!q.susun) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var x = 0; x < q.o.length; x++) _opt(pl, q, x, answered),
      ]);
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Mushaf(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: seq.isEmpty
                  ? const Center(child: Muted('Ketuk potongan di bawah'))
                  : Wrap(alignment: WrapAlignment.center, children: [
                      for (final x in seq)
                        _wordChip(q.ws[x], answered ? null : () => setState(() => seq.remove(x)), pl),
                    ]),
            ),
          ),
        ),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(alignment: WrapAlignment.center, children: [
            for (var x = 0; x < q.ws.length; x++)
              if (!seq.contains(x))
                _wordChip(q.ws[x], answered ? null : () => setState(() => seq.add(x)), pl),
          ]),
        ),
        if (answered)
          HCard(
            color: sel == 1 ? kOkBg : kBadBg,
            child: Column(children: [
              Text(sel == 1 ? 'Benar' : 'Kurang tepat',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222222))),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(q.ans,
                    textAlign: TextAlign.center,
                    style: arabic(24, color: const Color(0xFF222222))),
              ),
            ]),
          )
        else
          HButton(
            label: 'Periksa',
            onPressed: seq.length == q.ws.length
                ? () => setState(() {
                      final right = seq.map((x) => q.ws[x]).join(' ') == q.ans;
                      sel = right ? 1 : 0;
                      _score(right, q);
                    })
                : null,
          ),
      ]);
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            PageHeader(quizNames[widget.kind] ?? 'Kuis'),
            Row(children: [
              Muted('Soal ${i + 1}/${l.length}', size: 13),
              const Spacer(),
              if (tm) ...[
                Bdg('⏱ ${left}d', kind: 'y'),
                const SizedBox(width: 6),
                Bdg('Streak $st', kind: 'g'),
                const SizedBox(width: 6),
                Bdg('Benar $ok'),
              ],
            ]),
            HBar((i + 1) / l.length),
            Text(q.q, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (q.ar != null)
              Mushaf(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(q.ar!,
                      textAlign: TextAlign.center, style: arabic(app.arabicSize, color: pl.text)),
                ),
              ),
            body,
            if (answered)
              HButton(
                label: i + 1 >= l.length ? 'Lihat hasil' : 'Lanjut',
                onPressed: () {
                  if (i + 1 >= l.length) {
                    _fin();
                  } else {
                    setState(() {
                      i++;
                      sel = null;
                      seq = [];
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _wordChip(String w, VoidCallback? onTap, Pal pl) => Padding(
        padding: const EdgeInsets.all(3),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: pl.card,
              border: Border.all(color: pl.line, width: 1.5),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(w, style: arabic(24, color: pl.text, height: 1.6)),
          ),
        ),
      );

  Widget _opt(Pal pl, Question q, int x, bool answered) {
    Color bg = pl.card, bc = pl.line, fg = pl.text;
    if (answered && x == q.a) {
      bg = kOkBg;
      bc = pl.ok;
      fg = kOkFg;
    } else if (answered && x == sel) {
      bg = kBadBg;
      bc = pl.red;
      fg = kBadFg;
    }
    final isAr = q.o[x].runes.any((r) => r >= 0x0600 && r <= 0x06FF);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: answered
            ? null
            : () => setState(() {
                  sel = x;
                  _score(x == q.a, q);
                }),
        child: Container(
          padding: const EdgeInsets.all(13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: bc, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Text(q.o[x],
                textAlign: TextAlign.center,
                style: isAr
                    ? arabic(24, color: fg, height: 1.8)
                    : TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
          ),
        ),
      ),
    );
  }
}

// ================= HASIL =================
class QuizResultPage extends StatelessWidget {
  final QuizResult r;
  const QuizResultPage(this.r, {super.key});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final pc = (r.ok / r.total * 100).round();
    final ex = r.kind == 'ujian';
    final pass = ex && pc >= 60;
    final topics = r.bad.map((x) => x.top).toSet().toList();
    final tm = r.kind == 'tantang';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            HCard(
              child: SizedBox(
                width: double.infinity,
                child: Column(children: [
                  Muted(quizNames[r.kind] ?? '', size: 13),
                  Text(tm ? '${r.ok * 10 + r.best * 2} poin' : '$pc%', style: serif(46)),
                  Text(
                      '${r.ok} benar · ${r.no} salah${tm ? ' · ${r.total - r.ok - r.no} tidak sempat' : ''} · ${mm(r.dur)}${tm ? ' · streak terbaik ${r.best}' : ''}',
                      textAlign: TextAlign.center),
                  if (ex) ...[
                    const SizedBox(height: 6),
                    Bdg(pass ? 'Lulus' : 'Belum lulus', kind: pass ? 'g' : 'r'),
                  ],
                ]),
              ),
            ),
            const H4('Materi yang perlu dipelajari'),
            HCard(
              child: topics.isEmpty
                  ? const Muted('Tidak ada. Bagus!')
                  : Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final x in topics) Bdg(x, kind: 'y'),
                    ]),
            ),
            if (r.bad.isNotEmpty) ...[
              const H4('Pelajari kesalahan'),
              for (final x in r.bad)
                HCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if ((x.ar ?? '').isNotEmpty || x.ans.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(x.ar ?? x.ans,
                              textAlign: TextAlign.center,
                              style: arabic(22, color: pl.text, height: 1.8)),
                        ),
                      ),
                    Muted(x.q, size: 13),
                    const SizedBox(height: 4),
                    Text('Jawaban benar:', style: TextStyle(color: pl.muted)),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(x.susun ? x.ans : x.o[x.a],
                          style: arabic(20, color: pl.text, height: 1.6, weight: FontWeight.w700)),
                    ),
                  ]),
                ),
            ],
            if (pass)
              HButton(
                  label: 'Lihat sertifikat',
                  kind: BK.gold,
                  onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => const CertPage(index: 0)))),
            HButton(
                label: 'Coba lagi',
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => QuizPage(kind: r.kind)))),
            HButton(
              label: ex ? 'Kembali ke Sertifikasi' : 'Kembali ke LCC',
              kind: BK.outline,
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                if (ex) nav.pop();
              },
            ),
            if (r.bad.any((x) => hukumPilihan.contains(x.top)))
              HButton(
                  label: 'Pelajari tajwid',
                  kind: BK.outline,
                  onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => const TajwidPage()))),
          ],
        ),
      ),
    );
  }
}

// ================= SERTIFIKASI =================
class _Level {
  final String n, d;
  final bool lock;
  const _Level(this.n, this.d, {this.lock = false});
}

const List<_Level> _levels = [
  _Level('Level 1 · Hafalan surah pilihan', 'Menghafal satu surah pilihan dengan lancar.'),
  _Level('Level 2 · Hafalan beberapa surah', 'Rincian persyaratan menyusul sesuai kurikulum.',
      lock: true),
  _Level('Level 3 · Hafalan juz', 'Rincian persyaratan menyusul sesuai kurikulum.', lock: true),
];

class SertifikasiPage extends StatefulWidget {
  const SertifikasiPage({super.key});
  @override
  State<SertifikasiPage> createState() => _SertifikasiPageState();
}

class _SertifikasiPageState extends State<SertifikasiPage> {
  int sl = 0;

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final lv = _levels[sl];
            final reqs = <List<Object>>[
              ['Menghafal minimal satu surah pilihan', app.tot >= 4],
              ['Lulus ujian sambung ayat (minimal 60%)', app.certs.isNotEmpty],
              ["Muraja'ah rutin 7 hari berturut-turut", false],
            ];
            final dn = reqs.where((x) => x[1] == true).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const PageHeader('Sertifikasi'),
                HCard(
                  border: pl.gold,
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Sertifikasi kompetensi internal',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Muted(
                        "Program penilaian kemampuan hafalan di focusHifz. Bukan ijazah dan bukan sanad Al-Qur'an. Jenjang dapat berubah sesuai kurikulum."),
                  ]),
                ),
                const H4('Jenjang'),
                for (var i = 0; i < _levels.length; i++)
                  HCard(
                    border: sl == i ? pl.green : null,
                    onTap: () => setState(() => sl = i),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                            child: Text(_levels[i].n,
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                        if (_levels[i].lock)
                          const Bdg('Segera')
                        else if (app.certs.any((c) => c.lv == i))
                          const Bdg('Diraih', kind: 'g')
                        else
                          const Bdg('Terbuka', kind: 'y'),
                      ]),
                      Muted(_levels[i].d),
                    ]),
                  ),
                if (!lv.lock) ...[
                  const H4('Persyaratan & progres'),
                  HCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      HBar(dn / reqs.length),
                      for (final x in reqs)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text('${x[1] == true ? '✅' : '⬜'} ${x[0]}'),
                        ),
                    ]),
                  ),
                  HButton(
                      label: 'Ikut ujian',
                      onPressed: () => pushPage(context, const UjianPage())),
                ],
                const H4('Riwayat ujian'),
                if (app.hist.isEmpty)
                  const HCard(child: Muted('Belum ada ujian. Mulai dari Level 1.', align: TextAlign.center))
                else
                  for (final x in app.hist)
                    HCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(x.t, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Muted('${x.r} · ${x.d}'),
                      ]),
                    ),
                const H4('Sertifikat saya'),
                if (app.certs.isEmpty)
                  const HCard(child: Muted('Belum ada sertifikat.', align: TextAlign.center))
                else
                  for (var i = 0; i < app.certs.length; i++)
                    NavCard(
                      emoji: '🎓',
                      title: _levels[app.certs[i].lv].n,
                      sub: '${app.certs[i].no} · ${app.certs[i].d}',
                      onTap: () => pushPage(context, CertPage(index: i)),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class UjianPage extends StatelessWidget {
  const UjianPage({super.key});

  @override
  Widget build(BuildContext context) {
    void pv() => toast(context, 'Preview: belum terhubung ke backend');
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const PageHeader('Ujian Level 1'),
            const Muted('Pilih jenis ujian. Lulus ujian sambung ayat (≥60%) menerbitkan sertifikat contoh.'),
            const SizedBox(height: 10),
            NavCard(
                title: 'Ujian sambung ayat',
                sub: '5 soal sambung ayat. Sudah berfungsi.',
                onTap: () => pushPage(context, const QuizPage(kind: 'ujian'))),
            NavCard(title: 'Ujian hafalan', sub: 'Setor hafalan ke penguji. Preview.', onTap: pv),
            NavCard(
                title: 'Ujian kelancaran', sub: 'Penilaian kelancaran bacaan. Preview.', onTap: pv),
            NavCard(
                title: 'Penilaian penguji manusia',
                sub: 'Penguji menilai rekaman Anda. Preview.',
                onTap: pv),
          ],
        ),
      ),
    );
  }
}

class CertPage extends StatelessWidget {
  final int index;
  const CertPage({super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final c = app.certs[clampI(index, 0, app.certs.length - 1)];
    const ink = Color(0xFF2B2410);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const PageHeader('Sertifikat'),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF3),
                border: Border.all(color: Pal.light.gold, width: 3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: ink, fontSize: 15),
                textAlign: TextAlign.center,
                child: Column(children: [
                  const Text('focusHifz · Sertifikat kompetensi internal',
                      style: TextStyle(fontSize: 12, color: Color(0xFF667A71))),
                  const SizedBox(height: 10),
                  Text('Sertifikat Kompetensi', style: serif(24, color: Pal.light.green2)),
                  const SizedBox(height: 10),
                  const Text('diberikan kepada'),
                  Text(app.name, style: serif(24, color: ink)),
                  const SizedBox(height: 6),
                  Text('atas capaian ${_levels[c.lv].n}'),
                  Text('Tanggal terbit: ${c.d}'),
                  Text('Nomor: ${c.no} (contoh)'),
                  const SizedBox(height: 10),
                  SizedBox(width: 96, height: 96, child: CustomPaint(painter: _QrPainter(c.no))),
                  const SizedBox(height: 6),
                  const Text('QR contoh, belum terhubung ke layanan verifikasi',
                      style: TextStyle(fontSize: 12, color: Color(0xFF667A71))),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            const Muted(
                "Sertifikat ini adalah sertifikasi kompetensi internal focusHifz. Bukan ijazah dan bukan sanad Al-Qur'an.",
                size: 13),
            HButton(
                label: 'Bagikan (preview)',
                kind: BK.outline,
                onPressed: () => toast(context, 'Preview: belum terhubung ke backend')),
          ],
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String seed;
  _QrPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0xFFFFFFFF;
    }
    final u = size.width / 21;
    final paint = Paint()..color = const Color(0xFF0A3D31);
    for (var y = 0; y < 21; y++) {
      for (var x = 0; x < 21; x++) {
        bool on;
        if ((x < 7 || x > 13) && (y < 7 || y > 13) && !(x > 13 && y > 13)) {
          final a = x < 7 ? x : x - 14;
          final b = y < 7 ? y : y - 14;
          on = a == 0 || a == 6 || b == 0 || b == 6 || (a > 1 && a < 5 && b > 1 && b < 5);
        } else {
          h = (h * 1103515245 + 12345) & 0xFFFFFFFF;
          on = ((h >> 16) & 1) == 1;
        }
        if (on) canvas.drawRect(Rect.fromLTWH(x * u, y * u, u, u), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}
