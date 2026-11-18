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
            constraints: const BoxConstraints(minHeight: 56),
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
        const SizedBox(height: 8),
        if (answered)
          StatusNote(
            kind: sel == 1 ? SK.ok : SK.bad,
            title: sel == 1 ? 'Benar' : 'Kurang tepat',
            body: sel == 1 ? null : 'Susunan yang benar ada di bawah.',
          ),
        if (answered)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(q.ans,
                textAlign: TextAlign.center, style: arabic(24, color: pl.text, height: 1.9)),
          )
        else
          HButton(
            label: 'Periksa',
            icon: Icons.check_rounded,
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
    return PageScaffold(
      children: [
        PageHeader(quizNames[widget.kind] ?? 'Kuis'),
        Row(children: [
          Expanded(child: Muted('Soal ${i + 1} dari ${l.length}', size: 13)),
          if (tm) ...[
            Bdg('${left}d', kind: 'y', icon: Icons.timer_outlined),
            const SizedBox(width: 6),
            Bdg('Streak $st', kind: 'g'),
            const SizedBox(width: 6),
            Bdg('Benar $ok'),
          ],
        ]),
        HBar((i + 1) / l.length),
        const SizedBox(height: 6),
        Text(q.q, style: sans(16.5, weight: FontWeight.w700, height: 1.35)),
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
            label: i + 1 >= l.length ? 'Lihat hasil' : 'Soal berikutnya',
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
    );
  }

  Widget _wordChip(String w, VoidCallback? onTap, Pal pl) => Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: pl.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rad.control),
            side: BorderSide(color: pl.line, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Text(w, style: arabic(24, color: pl.text, height: 1.6)),
            ),
          ),
        ),
      );

  Widget _opt(Pal pl, Question q, int x, bool answered) {
    Color bg = pl.card, bc = pl.line, fg = pl.text;
    IconData? mark;
    if (answered && x == q.a) {
      bg = pl.okBg;
      bc = pl.ok;
      fg = pl.okFg;
      mark = Icons.check_circle_rounded;
    } else if (answered && x == sel) {
      bg = pl.badBg;
      bc = pl.red;
      fg = pl.badFg;
      mark = Icons.cancel_rounded;
    }
    final isAr = q.o[x].runes.any((r) => r >= 0x0600 && r <= 0x06FF);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Semantics(
        button: true,
        enabled: !answered,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: bc, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: answered
                ? null
                : () => setState(() {
                      sel = x;
                      _score(x == q.a, q);
                    }),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  if (mark != null) const SizedBox(width: 26),
                  Expanded(
                    child: Directionality(
                      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(q.o[x],
                          textAlign: TextAlign.center,
                          style: isAr
                              ? arabic(24, color: fg, height: 1.8)
                              : sans(15, weight: FontWeight.w600, color: fg)),
                    ),
                  ),
                  if (mark != null) Icon(mark, size: 26, color: fg),
                ]),
              ),
            ),
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
    return PageScaffold(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration:
              BoxDecoration(color: pl.green2, borderRadius: BorderRadius.circular(Rad.hero)),
          child: Column(children: [
            Text(quizNames[r.kind] ?? '',
                style: sans(13, weight: FontWeight.w600, color: pl.onHero.withValues(alpha: .85))),
            const SizedBox(height: 6),
            Text(tm ? '${r.ok * 10 + r.best * 2} poin' : '$pc%',
                style: serif(54, color: pl.onHero)),
            const SizedBox(height: 8),
            Text(
                '${r.ok} benar · ${r.no} salah${tm ? ' · ${r.total - r.ok - r.no} tidak sempat' : ''} · ${mm(r.dur)}${tm ? ' · streak terbaik ${r.best}' : ''}',
                textAlign: TextAlign.center,
                style: sans(13.5, color: pl.onHero, height: 1.45)),
            if (ex) ...[
              const SizedBox(height: 12),
              Bdg(pass ? 'Lulus' : 'Belum lulus',
                  kind: pass ? 'g' : 'r',
                  icon: pass ? Icons.check_rounded : Icons.close_rounded),
            ],
          ]),
        ),
        const H4('Materi yang perlu dipelajari'),
        HCard(
          child: topics.isEmpty
              ? const Muted('Tidak ada. Bagus!')
              : Wrap(spacing: 8, runSpacing: 8, children: [
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
                const SizedBox(height: 6),
                Text('Jawaban benar', style: sans(12.5, weight: FontWeight.w700, color: pl.muted)),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(x.susun ? x.ans : x.o[x.a],
                        style: arabic(20, color: pl.text, height: 1.6, weight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
        ],
        if (pass)
          HButton(
              label: 'Lihat sertifikat',
              kind: BK.gold,
              icon: Icons.workspace_premium_outlined,
              onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const CertPage(index: 0)))),
        HButton(
            label: 'Coba lagi',
            icon: Icons.replay_rounded,
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
            return PageList(
              children: [
                const PageHeader('Sertifikasi'),
                const StatusNote(
                  kind: SK.info,
                  title: 'Sertifikasi kompetensi internal',
                  body:
                      "Program penilaian kemampuan hafalan di HifzFlow. Bukan ijazah dan bukan sanad Al-Qur'an. Jenjang dapat berubah sesuai kurikulum.",
                ),
                const H4('Jenjang'),
                for (var i = 0; i < _levels.length; i++)
                  Semantics(
                    selected: sl == i,
                    child: HCard(
                      border: sl == i ? pl.green : null,
                      onTap: () => setState(() => sl = i),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                              child: Text(_levels[i].n, style: sans(15, weight: FontWeight.w700))),
                          const SizedBox(width: 8),
                          if (_levels[i].lock)
                            const Bdg('Segera', icon: Icons.lock_outline_rounded)
                          else if (app.certs.any((c) => c.lv == i))
                            const Bdg('Diraih', kind: 'g', icon: Icons.check_rounded)
                          else
                            const Bdg('Terbuka', kind: 'y'),
                        ]),
                        const SizedBox(height: 4),
                        Muted(_levels[i].d),
                      ]),
                    ),
                  ),
                if (!lv.lock) ...[
                  const H4('Persyaratan dan progres'),
                  HCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Muted('$dn dari ${reqs.length} terpenuhi', size: 13)),
                      ]),
                      HBar(dn / reqs.length),
                      const SizedBox(height: 4),
                      for (final x in reqs)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(
                                x[1] == true
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 22,
                                color: x[1] == true ? pl.ok : pl.muted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('${x[0]}', style: sans(14, height: 1.4)),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                  HButton(
                      label: 'Ikut ujian',
                      onPressed: () => pushPage(context, const UjianPage())),
                ],
                const H4('Riwayat ujian'),
                if (app.hist.isEmpty)
                  const HCard(
                    child: EmptyState(
                      icon: Icons.history_edu_outlined,
                      title: 'Belum ada ujian',
                      body: 'Mulai dari Level 1.',
                    ),
                  )
                else
                  for (final x in app.hist)
                    HCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(x.t, style: sans(15, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Muted('${x.r} · ${x.d}'),
                      ]),
                    ),
                const H4('Sertifikat saya'),
                if (app.certs.isEmpty)
                  const HCard(
                    child: EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Belum ada sertifikat',
                      body: 'Lulus ujian sambung ayat untuk menerbitkan sertifikat contoh.',
                    ),
                  )
                else
                  for (var i = 0; i < app.certs.length; i++)
                    NavCard(
                      icon: Icons.workspace_premium_outlined,
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
    return PageScaffold(
      children: [
        const PageHeader('Ujian Level 1'),
        const Muted('Pilih jenis ujian. Lulus ujian sambung ayat (≥60%) menerbitkan sertifikat contoh.'),
        const SizedBox(height: 14),
        NavCard(
            icon: Icons.link_rounded,
            title: 'Ujian sambung ayat',
            sub: '5 soal sambung ayat. Sudah berfungsi.',
            onTap: () => pushPage(context, const QuizPage(kind: 'ujian'))),
        NavCard(
            icon: Icons.record_voice_over_outlined,
            title: 'Ujian hafalan',
            sub: 'Setor hafalan ke penguji. Preview.',
            onTap: pv),
        NavCard(
            icon: Icons.speed_rounded,
            title: 'Ujian kelancaran',
            sub: 'Penilaian kelancaran bacaan. Preview.',
            onTap: pv),
        NavCard(
            icon: Icons.person_search_outlined,
            title: 'Penilaian penguji manusia',
            sub: 'Penguji menilai rekaman Anda. Preview.',
            onTap: pv),
      ],
    );
  }
}

class CertPage extends StatelessWidget {
  final int index;
  const CertPage({super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    if (app.certs.isEmpty) {
      return const PageScaffold(children: [
        PageHeader('Sertifikat'),
        EmptyState(
          icon: Icons.workspace_premium_outlined,
          title: 'Belum ada sertifikat',
          body: 'Lulus ujian sambung ayat untuk menerbitkan sertifikat contoh.',
        ),
      ]);
    }
    final c = app.certs[clampI(index, 0, app.certs.length - 1)];
    // Sertifikat adalah dokumen kertas: warnanya tetap krem dengan tinta gelap di kedua tema.
    const ink = Color(0xFF2B2410);
    const inkSoft = Color(0xFF56695F);
    return PageScaffold(
      children: [
        const PageHeader('Sertifikat'),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF3),
            border: Border.all(color: Pal.light.gold, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Pal.light.line),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DefaultTextStyle(
              style: sans(15, color: ink, height: 1.45),
              textAlign: TextAlign.center,
              child: Column(children: [
                RubBadge(
                  size: 60,
                  fill: Pal.light.green2,
                  child: Icon(Icons.workspace_premium_outlined,
                      size: 28, color: Pal.light.gold),
                ),
                const SizedBox(height: 10),
                Text('HifzFlow · Sertifikat kompetensi internal',
                    style: sans(12, color: inkSoft)),
                const SizedBox(height: 12),
                Text('Sertifikat Kompetensi', style: serif(26, color: Pal.light.green2)),
                const SizedBox(height: 12),
                const Text('diberikan kepada'),
                const SizedBox(height: 2),
                Text(app.name, style: serif(26, color: ink)),
                const SizedBox(height: 8),
                Text('atas capaian ${_levels[c.lv].n}'),
                Text('Tanggal terbit: ${c.d}'),
                Text('Nomor: ${c.no} (contoh)'),
                const SizedBox(height: 14),
                SizedBox(width: 96, height: 96, child: CustomPaint(painter: _QrPainter(c.no))),
                const SizedBox(height: 8),
                Text('QR contoh, belum terhubung ke layanan verifikasi',
                    style: sans(12, color: inkSoft)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Muted(
            "Sertifikat ini adalah sertifikasi kompetensi internal HifzFlow. Bukan ijazah dan bukan sanad Al-Qur'an.",
            size: 13),
        HButton(
            label: 'Bagikan (preview)',
            kind: BK.outline,
            icon: Icons.ios_share_rounded,
            onPressed: () => toast(context, 'Preview: belum terhubung ke backend')),
      ],
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
