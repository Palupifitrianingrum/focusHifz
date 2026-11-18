import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../ui.dart';
import 'quiz.dart';

// ================= TILAWAH =================
class TilawahPage extends StatefulWidget {
  final String mode;
  const TilawahPage({super.key, this.mode = 'bebas'});
  @override
  State<TilawahPage> createState() => _TilawahPageState();
}

class _TilawahPageState extends State<TilawahPage> {
  late String m = widget.mode;
  int s = 0, f = 1, t = 7, pos = 1;
  int minutes = 15, left = 900, el = 0;
  bool run = false;
  String u = 'Ayat';
  int n = 5, d = 0;
  Timer? _tm;

  @override
  void initState() {
    super.initState();
    _tm = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!run || !mounted) return;
      setState(() {
        left--;
        el++;
      });
      if (left <= 0) _end();
    });
  }

  @override
  void dispose() {
    _tm?.cancel();
    super.dispose();
  }

  int get total => surahs[s].a.length;

  void _end() {
    final durasi = mm(el);
    setState(() => run = false);
    app.addLog('Tilawah $durasi');
    showHSheet(context,
        title: 'Ringkasan tilawah',
        body: 'Durasi terbaca $durasi dari target $minutes menit.');
    setState(() {
      el = 0;
      left = minutes * 60;
    });
  }

  void _pickSurah(int i) => setState(() {
        s = i;
        f = 1;
        t = total < 7 ? total : 7;
        pos = 1;
      });

  void _range(bool isFrom, int dlt) => setState(() {
        if (isFrom) {
          f = clampI(f + dlt, 1, total);
          if (t < f) t = f;
        } else {
          t = clampI(t + dlt, f, total);
        }
        pos = clampI(pos, f, t);
      });

  Widget _bebas(Pal pl) {
    final span = t - f + 1;
    final prog = (pos - f + 1) / span;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Surah', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(children: [
            for (var i = 0; i < surahs.length; i++)
              HChip(label: surahs[i].n, on: s == i, onTap: () => _pickSurah(i)),
          ]),
          SpinRow(
              label: 'Ayat awal',
              value: '$f',
              onMinus: () => _range(true, -1),
              onPlus: () => _range(true, 1)),
          SpinRow(
              label: 'Ayat akhir',
              value: '$t',
              onMinus: () => _range(false, -1),
              onPlus: () => _range(false, 1)),
        ]),
      ),
      Mushaf(child: AyatText(s: s, from: pos, to: pos)),
      Row(children: [
        HChip(
            label: '‹ Sebelumnya',
            on: false,
            onTap: () => setState(() => pos = clampI(pos - 1, f, t))),
        Expanded(child: Muted('Ayat $pos · $f–$t', align: TextAlign.center, size: 13)),
        HChip(
            label: 'Berikutnya ›',
            on: false,
            onTap: () => setState(() => pos = clampI(pos + 1, f, t))),
      ]),
      HBar(prog),
      Muted('Progres bacaan ${(prog * 100).round()}%', size: 13),
    ]);
  }

  Widget _waktu() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(alignment: WrapAlignment.center, children: [
        for (final x in [10, 15, 30, 60])
          HChip(
            label: '$x menit',
            on: minutes == x,
            onTap: () {
              if (!run && el == 0) {
                setState(() {
                  minutes = x;
                  left = x * 60;
                });
              }
            },
          ),
      ]),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Ring(progress: left / (minutes * 60), label: mm(left), size: 190),
        ),
      ),
      Muted(
          '${run ? 'Sedang berjalan' : (el > 0 ? 'Dijeda' : 'Siap dimulai')} · terbaca ${mm(el)}',
          align: TextAlign.center),
      HButton(
          label: run ? 'Jeda' : (el > 0 ? 'Lanjutkan' : 'Mulai'),
          onPressed: () => setState(() => run = !run)),
      HButton(label: 'Akhiri sesi', kind: BK.outline, onPressed: _end),
    ]);
  }

  Widget _target() {
    final unit = u.toLowerCase();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Jenis target', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(children: [
            for (final x in ['Ayat', 'Halaman', 'Surah'])
              HChip(
                  label: x,
                  on: u == x,
                  onTap: () => setState(() {
                        u = x;
                        d = 0;
                      })),
          ]),
          SpinRow(
              label: 'Jumlah $unit',
              value: '$n',
              onMinus: () => setState(() => n = n > 1 ? n - 1 : 1),
              onPlus: () => setState(() => n++)),
        ]),
      ),
      HCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('Progres target', style: TextStyle(fontWeight: FontWeight.w700))),
            Text('$d/$n $unit'),
          ]),
          HBar(d / n),
        ]),
      ),
      HButton(
          label: 'Tandai 1 $unit selesai',
          onPressed: () {
            setState(() => d++);
            if (d >= n) {
              app.addLog('Tilawah target $n $unit');
              showHSheet(context,
                  title: 'Target tercapai', body: '$n $unit selesai dibaca.');
              setState(() => d = 0);
            }
          }),
      HButton(label: 'Atur ulang', kind: BK.outline, onPressed: () => setState(() => d = 0)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    const names = ['bebas', 'waktu', 'target'];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const PageHeader('Tilawah'),
            Seg(
              labels: const ['Bebas', 'Waktu', 'Target'],
              index: names.indexOf(m),
              onChanged: (i) => setState(() => m = names[i]),
            ),
            if (m == 'bebas') _bebas(pl) else if (m == 'waktu') _waktu() else _target(),
          ],
        ),
      ),
    );
  }
}

// ================= MURAJA'AH =================
class MurajaPage extends StatefulWidget {
  const MurajaPage({super.key});
  @override
  State<MurajaPage> createState() => _MurajaPageState();
}

class _MurajaPageState extends State<MurajaPage> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final list = app.muraja.where((x) => filter == 'all' || x.st == filter).toList();
            const nm = {
              'ulang': ['Perlu diulang', 'r'],
              'belajar': ['Sedang dipelajari', 'y'],
              'lancar': ['Sudah lancar', 'g'],
            };
            const filters = [
              ['all', 'Semua'],
              ['ulang', 'Perlu diulang'],
              ['belajar', 'Sedang dipelajari'],
              ['lancar', 'Sudah lancar'],
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const PageHeader("Muraja'ah"),
                Wrap(children: [
                  for (final x in filters)
                    HChip(label: x[1], on: filter == x[0], onTap: () => setState(() => filter = x[0])),
                ]),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Muted('Tidak ada ayat di kategori ini.', align: TextAlign.center),
                  ),
                for (final x in list)
                  HCard(
                    onTap: () => _open(context, x),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                            child: Text('${surahs[x.s].n} : ${x.n}',
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                        Bdg(nm[x.st]![0], kind: nm[x.st]![1]),
                      ]),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(surahs[x.s].a[x.n - 1],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: arabic(22, color: pl.text, height: 1.7)),
                      ),
                      Muted('Jadwal: ${x.due} · salah ${x.err}x', size: 13),
                    ]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, MurajaItem x) {
    final pl = Pal.of(context);
    showHSheet(
      context,
      title: '${surahs[x.s].n} : ${x.n}',
      extra: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(surahs[x.s].a[x.n - 1],
              textAlign: TextAlign.center, style: arabic(app.arabicSize, color: pl.text)),
        ),
      ),
      actions: [
        SheetAction('Tandai lancar', () {
          app.update(() {
            x.st = 'lancar';
            x.due = 'Minggu ini';
            app.log.insert(0, LogItem("Muraja'ah ${surahs[x.s].n} : ${x.n}", 'Baru saja'));
          });
        }),
        SheetAction('Perlu diulang', () => app.update(() => x.st = 'ulang'), BK.outline),
        SheetAction('Tutup', () {}, BK.outline),
      ],
    );
  }
}

// ================= TAJWID =================
class TajwidPage extends StatefulWidget {
  const TajwidPage({super.key});
  @override
  State<TajwidPage> createState() => _TajwidPageState();
}

class _TajwidPageState extends State<TajwidPage> {
  int open = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const PageHeader('Belajar tajwid'),
            const Muted('Ringkasan dasar. Verifikasi dengan guru sebelum dijadikan rujukan.'),
            const SizedBox(height: 10),
            for (var i = 0; i < tajwid.length; i++)
              HCard(
                onTap: () => setState(() => open = open == i ? -1 : i),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                        child: Text(tajwid[i][0],
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text(open == i ? '−' : '+', style: const TextStyle(fontSize: 18)),
                  ]),
                  if (open == i)
                    Padding(padding: const EdgeInsets.only(top: 6), child: Text(tajwid[i][1])),
                ]),
              ),
            HButton(
                label: 'Latihan tebak hukum bacaan',
                onPressed: () => pushPage(context, const QuizPage(kind: 'hukum'))),
          ],
        ),
      ),
    );
  }
}
