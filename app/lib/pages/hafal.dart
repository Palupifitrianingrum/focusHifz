import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../checker.dart';
import '../data.dart';
import '../lock.dart';
import '../murottal.dart';
import '../speech.dart';
import '../theme.dart';
import '../ui.dart';
import 'tilawah.dart';

/// Aturan baru: tiap pengulangan HARUS dibaca lewat mikrofon (ayat tetap tampil).
/// Tombol lanjut baru aktif setelah bacaan cocok minimal [kAkurasiUlang].
const double kAkurasiUlang = 0.6;

/// Ujian hafalan (ayat disembunyikan): minimal kecocokan agar lulus.
const double kAkurasiUji = 0.7;

/// Setelah gagal sebanyak ini berturut-turut pada satu pengulangan, muncul
/// tombol "Lewati tanpa penilaian" supaya tidak buntu kalau mesin suara bermasalah.
const int kMaxGagal = 3;

enum HStep { pick, set, rep, test, review, eval, done }

enum FocusKind { off, waktu, ayat }

enum MicState { idle, listening, checking, result }

class HafalPage extends StatefulWidget {
  const HafalPage({super.key});
  @override
  State<HafalPage> createState() => _HafalPageState();
}

class _HafalPageState extends State<HafalPage> {
  final SpeechService stt = SpeechService();

  HStep step = HStep.pick;
  int s = app.currentSurah;
  int from = 1;
  int to = 3;
  int rep = 5;
  bool custom = false;

  // Focus Mode
  FocusKind focus = FocusKind.off;
  int focusMin = 10;
  bool locked = false;
  bool timeUp = false;
  int left = 0;
  Timer? _tick;
  bool busy = false;
  bool aborted = false;

  // Sesi pengulangan
  int ai = 0; // indeks ayat dalam rentang
  int c = 0; // pengulangan yang sudah lolos untuk ayat ini
  int fails = 0;
  bool skipped = false;
  MicState mic = MicState.idle;
  CheckResult? repRes;
  bool repPass = false;

  // Uji & evaluasi
  CheckResult? res;
  Map<int, String> mk = {};

  int get count => to - from + 1;
  int get total => surahs[s].a.length;

  @override
  void initState() {
    super.initState();
    to = total < 3 ? total : 3;
    stt.active.addListener(_onActive);
  }

  @override
  void dispose() {
    _tick?.cancel();
    stt.active.removeListener(_onActive);
    stt.dispose();
    if (locked) native('stop');
    super.dispose();
  }

  // Mesin suara berhenti sendiri (error) saat sedang mendengarkan.
  void _onActive() {
    if (!mounted) return;
    if (!stt.active.value && mic == MicState.listening) {
      setState(() {
        mic = MicState.idle;
        fails++;
      });
    }
  }

  // ---------- Focus Mode ----------
  Future<void> _start() async {
    if (busy) return;
    setState(() => busy = true);
    await stt.init(); // minta izin mikrofon sebelum layar dikunci
    if (!mounted) return;
    if (focus != FocusKind.off) {
      await native('start');
      locked = true;
      if (focus == FocusKind.waktu) {
        left = focusMin * 60;
        _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
      }
    }
    if (!mounted) return;
    setState(() {
      busy = false;
      step = HStep.rep;
      ai = 0;
      c = 0;
      fails = 0;
      mic = MicState.idle;
      repRes = null;
      repPass = false;
      skipped = false;
      timeUp = false;
    });
  }

  void _onTick() {
    if (!mounted) return;
    if (left <= 1) {
      _tick?.cancel();
      setState(() => left = 0);
      _unlock(byTime: true);
    } else {
      setState(() => left--);
    }
  }

  Future<void> _unlock({bool byTime = false}) async {
    _tick?.cancel();
    final was = locked;
    if (mounted) {
      setState(() {
        locked = false;
        if (byTime) timeUp = true;
      });
    } else {
      locked = false;
    }
    if (was) await native('stop');
  }

  // ---------- Mikrofon: pengulangan ----------
  Future<void> _micStart() async {
    await murottal.stop(); // suara murottal jangan ikut terekam
    if (!mounted) return;
    setState(() {
      mic = MicState.listening;
      repRes = null;
      skipped = false;
      repPass = false;
    });
    final ok = await stt.start();
    if (!ok && mounted && mic == MicState.listening) {
      setState(() {
        mic = MicState.idle;
        fails++;
      });
    }
  }

  Future<void> _repStop() async {
    setState(() => mic = MicState.checking);
    final heard = await stt.stopAndCollect();
    if (!mounted) return;
    final n = from + ai;
    final r = checkRecitation(s, n, n, heard);
    final pass = r.total > 0 && r.heard.isNotEmpty && r.acc >= kAkurasiUlang;
    setState(() {
      repRes = r;
      repPass = pass;
      mic = MicState.result;
      if (pass) {
        c++;
        fails = 0;
      } else {
        fails++;
      }
    });
  }

  void _retry() => setState(() {
        mic = MicState.idle;
        repRes = null;
      });

  void _skip() => setState(() {
        skipped = true;
        repRes = null;
        repPass = true;
        c++;
        fails = 0;
        mic = MicState.result;
      });

  void _repNext() {
    if (!repPass) return;
    setState(() {
      mic = MicState.idle;
      repRes = null;
      skipped = false;
      repPass = false;
      fails = 0;
      if (c >= rep) {
        if (ai + 1 < count) {
          ai++;
          c = 0;
        } else {
          step = HStep.test;
          res = null;
        }
      }
    });
  }

  // ---------- Mikrofon: uji hafalan ----------
  Future<void> _testStart() async {
    await murottal.stop();
    if (!mounted) return;
    setState(() => mic = MicState.listening);
    final ok = await stt.start();
    if (!ok && mounted && mic == MicState.listening) {
      setState(() {
        mic = MicState.idle;
        fails++;
      });
    }
  }

  Future<void> _testStop() async {
    setState(() => mic = MicState.checking);
    final heard = await stt.stopAndCollect();
    if (!mounted) return;
    final r = checkRecitation(s, from, to, heard);
    final m = <int, String>{};
    if (r.heard.isNotEmpty && r.total > 0) {
      r.ays.forEach((k, v) => m[k] = v.v);
    }
    setState(() {
      res = r;
      mk = m;
      mic = MicState.idle;
      step = HStep.eval;
    });
  }

  bool get testPass {
    final r = res;
    return r != null && r.total > 0 && r.heard.isNotEmpty && r.acc >= kAkurasiUji;
  }

  // ---------- Simpan / akhiri ----------
  Future<void> _finish() async {
    app.update(() {
      for (var n = from; n <= to; n++) {
        final k = mk[n] ?? 'y';
        MurajaItem? e;
        for (final x in app.muraja) {
          if (x.s == s && x.n == n) {
            e = x;
            break;
          }
        }
        if (k == 'g') {
          app.tot++;
          app.today++;
          if (e != null) e.st = 'lancar';
        } else {
          final st = k == 'r' ? 'ulang' : 'belajar';
          if (e != null) {
            e.st = st;
            if (k == 'r') e.err++;
            e.due = 'Hari ini';
          } else {
            app.muraja.add(MurajaItem(s, n, st, 'Hari ini', k == 'r' ? 1 : 0));
          }
        }
      }
      app.currentSurah = s;
      app.log.insert(0, LogItem('Hafalan ${surahs[s].n} : $from–$to', 'Baru saja'));
    });
    await _unlock();
    if (mounted) setState(() => step = HStep.done);
  }

  Future<void> _abort() async {
    await stt.cancel();
    await _unlock();
    if (mounted) {
      setState(() {
        aborted = true;
        step = HStep.done;
        mic = MicState.idle;
      });
    }
  }

  void _ask() {
    showHSheet(
      context,
      title: 'Akhiri sesi hafalan?',
      body: 'Sesi dihentikan dan progres sesi ini tidak disimpan.'
          '${locked ? ' Focus Mode akan dimatikan.' : ''}',
      actions: [
        SheetAction('Lanjutkan sesi', () {}, BK.outline),
        SheetAction('Akhiri sesi', _abort, BK.red),
      ],
    );
  }

  void _onBack() {
    switch (step) {
      case HStep.pick:
      case HStep.done:
        Navigator.of(context).pop();
        break;
      case HStep.set:
        setState(() => step = HStep.pick);
        break;
      default:
        if (locked) {
          toast(context, 'Focus Mode aktif. Selesaikan sesi untuk membuka kunci.');
        } else {
          _ask();
        }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _banner(),
              _header(),
              _body(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    if (focus == FocusKind.off || step == HStep.pick || step == HStep.set || step == HStep.done) {
      return const SizedBox.shrink();
    }
    final pl = Pal.of(context);
    String text;
    if (!locked) {
      text = timeUp ? 'Waktu fokus selesai · kunci dibuka' : 'Focus Mode selesai';
    } else if (focus == FocusKind.waktu) {
      text = 'Focus Mode · ${mm(left)}';
    } else {
      text = 'Focus Mode · terbuka setelah lulus uji hafalan';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: pl.green2, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(locked ? Icons.lock : Icons.lock_open, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13))),
        if (locked && modeUji)
          TextButton(
            onPressed: _abort,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, kTap),
            ),
            child: const Text('Keluar (mode uji)', style: TextStyle(fontSize: 12)),
          ),
      ]),
    );
  }

  Widget _header() {
    if (step == HStep.pick || step == HStep.set || step == HStep.done) {
      return PageHeader('Hafalan', onBack: _onBack);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        if (!locked) ...[
          HIconBtn(icon: Icons.close, label: 'Akhiri sesi', onTap: _ask),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text('${surahs[s].n} : $from–$to', style: serif(19))),
      ]),
    );
  }

  Widget _body() {
    switch (step) {
      case HStep.pick:
        return _buildPick();
      case HStep.set:
        return _buildSet();
      case HStep.rep:
        return _buildRep();
      case HStep.test:
        return _buildTest();
      case HStep.review:
        return _buildReview();
      case HStep.eval:
        return _buildEval();
      case HStep.done:
        return _buildDone();
    }
  }

  Widget _dots(int ix) {
    final pl = Pal.of(context);
    const labels = ['Pilih', 'Ulangi', 'Uji', 'Evaluasi'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 4 : 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= ix ? pl.green : pl.line,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 3),
                Text(labels[i], style: TextStyle(fontSize: 11, color: pl.muted)),
              ]),
            ),
          ),
      ]),
    );
  }

  // ---------- Pilih ----------
  Widget _buildPick() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _dots(0),
      HCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pilih surah', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(children: [
            for (var i = 0; i < surahs.length; i++)
              HChip(
                label: surahs[i].n,
                on: s == i,
                onTap: () => setState(() {
                  s = i;
                  from = 1;
                  to = total < 3 ? total : 3;
                }),
              ),
          ]),
        ]),
      ),
      HCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SpinRow(
            label: 'Ayat awal',
            value: '$from',
            onMinus: () => setState(() {
              from = clampI(from - 1, 1, total);
              if (to < from) to = from;
            }),
            onPlus: () => setState(() {
              from = clampI(from + 1, 1, total);
              if (to < from) to = from;
            }),
          ),
          SpinRow(
            label: 'Ayat akhir',
            value: '$to',
            onMinus: () => setState(() => to = clampI(to - 1, from, total)),
            onPlus: () => setState(() => to = clampI(to + 1, from, total)),
          ),
          Muted('${surahs[s].n} · $total ayat · hafalan ayat $from–$to ($count ayat)'),
        ]),
      ),
      HButton(label: 'Lanjut: atur pengulangan', onPressed: () => setState(() => step = HStep.set)),
    ]);
  }

  // ---------- Atur ----------
  Widget _buildSet() {
    final pl = Pal.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _dots(0),
      HCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Jumlah pengulangan per ayat',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(children: [
            HChip(
                label: '5x',
                on: !custom && rep == 5,
                onTap: () => setState(() {
                      rep = 5;
                      custom = false;
                    })),
            HChip(
                label: '10x',
                on: !custom && rep == 10,
                onTap: () => setState(() {
                      rep = 10;
                      custom = false;
                    })),
            HChip(label: 'Khusus', on: custom, onTap: () => setState(() => custom = true)),
          ]),
          if (custom)
            SpinRow(
              label: 'Ulangi',
              value: '${rep}x',
              onMinus: () => setState(() => rep = clampI(rep - 1, 1, 100)),
              onPlus: () => setState(() => rep = clampI(rep + 1, 1, 100)),
            ),
          const SizedBox(height: 4),
          Muted(
              'Setiap pengulangan, bacakan ayat ke mikrofon (ayat tetap tampil). Tombol lanjut baru aktif setelah bacaanmu terdeteksi.',
              size: 13),
        ]),
      ),
      HCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Focus Mode', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Muted('Kunci layar dan blokir notifikasi selama sesi ini saja.', size: 13),
          const SizedBox(height: 10),
          Seg(
            labels: const ['Mati', 'Target waktu', 'Target ayat'],
            index: focus.index,
            onChanged: (i) => setState(() => focus = FocusKind.values[i]),
          ),
          if (focus == FocusKind.waktu) ...[
            Text('Durasi fokus: $focusMin menit', style: const TextStyle(fontSize: 16)),
            Slider(
              value: focusMin.toDouble(),
              min: 1,
              max: 120,
              divisions: 119,
              label: '$focusMin menit',
              activeColor: pl.green,
              onChanged: (v) => setState(() => focusMin = v.round()),
            ),
            const Muted('Kunci terbuka otomatis saat waktu habis.', size: 13),
          ],
          if (focus == FocusKind.ayat)
            const Muted(
                'Kunci baru terbuka setelah kamu lulus uji hafalan: ayat disembunyikan dan kamu melafalkannya dari ingatan.',
                size: 13),
          if (focus != FocusKind.off) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration:
                  BoxDecoration(color: pl.line, borderRadius: BorderRadius.circular(10)),
              child: const Text(
                  'Android akan menampilkan dialog "pin layar". Pilih Mulai / Got it. Izin Jangan Ganggu (opsional) dipakai untuk menahan notifikasi.',
                  style: TextStyle(fontSize: 13)),
            ),
            TextButton(
              onPressed: () => native('dndSettings'),
              child: const Text('Izinkan mode Jangan Ganggu (opsional)'),
            ),
          ],
        ]),
      ),
      HButton(label: busy ? 'Menyiapkan…' : 'Mulai sesi', onPressed: busy ? null : _start),
    ]);
  }

  // ---------- Panel mikrofon (dipakai ulangi & uji) ----------
  Widget _micPanel(String hint) {
    final pl = Pal.of(context);
    String title;
    switch (mic) {
      case MicState.idle:
        title = 'Siap merekam';
        break;
      case MicState.listening:
        title = 'Mendengarkan…';
        break;
      case MicState.checking:
        title = 'Memeriksa bacaan…';
        break;
      case MicState.result:
        title = 'Selesai';
        break;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HCard(
        child: Column(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Waveform(active: mic == MicState.listening, level: stt.level),
          Muted(hint, size: 13, align: TextAlign.center),
        ]),
      ),
      ValueListenableBuilder<String?>(
        valueListenable: stt.error,
        builder: (context, e, _) => e == null
            ? const SizedBox.shrink()
            : HCard(
                color: kBadBg,
                border: pl.red,
                child: Text(e,
                    style: const TextStyle(color: kBadFg, fontWeight: FontWeight.w600)),
              ),
      ),
      if (mic == MicState.listening || mic == MicState.checking)
        HCard(
          child: SizedBox(
            width: double.infinity,
            child: ValueListenableBuilder<String>(
              valueListenable: stt.text,
              builder: (context, txt, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Muted('Teks yang terdengar', size: 12),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        txt.isEmpty ? 'Belum ada suara terdeteksi…' : txt,
                        style: txt.isEmpty
                            ? TextStyle(fontSize: 13, color: pl.muted)
                            : arabic(22, color: pl.text, height: 1.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ]);
  }

  // ---------- Ulangi ----------
  Widget _buildRep() {
    final n = from + ai;
    final r = repRes;
    final result = mic == MicState.result;
    String nextLabel;
    if (c < rep) {
      nextLabel = 'Pengulangan berikutnya (${c + 1}/$rep)';
    } else if (ai + 1 < count) {
      nextLabel = 'Ayat berikutnya';
    } else {
      nextLabel = 'Lanjut uji hafalan';
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _dots(1),
      Muted('Ayat ${ai + 1} dari $count · ${surahs[s].n} : $n', size: 13, align: TextAlign.center),
      Mushaf(child: AyatText(s: s, from: n, to: n)),
      HCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '$c', style: serif(46)),
              TextSpan(text: ' / $rep', style: serif(20)),
            ])),
            const Muted('pengulangan', size: 13),
            HBar(c / rep),
          ]),
        ),
      ),
      _micPanel('Baca ayat di atas dengan suara jelas, lalu tekan "Selesai membaca".'),
      if (result) _repFeedback(r),
      if (mic == MicState.idle) _listenButton(n),
      if (mic == MicState.idle)
        HButton(label: 'Mulai baca ke mikrofon', onPressed: _micStart),
      if (mic == MicState.listening)
        HButton(label: 'Selesai membaca', kind: BK.gold, onPressed: _repStop),
      if (mic == MicState.checking) const HButton(label: 'Memeriksa…'),
      if (result && !repPass) ...[
        HButton(label: 'Coba baca lagi', onPressed: _retry),
        if (fails >= kMaxGagal)
          HButton(label: 'Lewati tanpa penilaian', kind: BK.outline, onPressed: _skip),
      ],
      HButton(
        label: result && repPass ? nextLabel : 'Lanjut (baca dulu lewat mikrofon)',
        kind: BK.outline,
        onPressed: result && repPass ? _repNext : null,
      ),
    ]);
  }

  /// Dengarkan murottal ayat yang sedang dihafal (qari pilihan di Profil).
  Widget _listenButton(int n) {
    final ref = AyahRef(surahs[s].no, n);
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[murottal.current, murottal.playing]),
      builder: (context, _) {
        final on = murottal.current.value == ref;
        return HButton(
          label: on ? 'Hentikan murottal' : 'Dengarkan murottal ayat ini',
          kind: BK.outline,
          onPressed: on ? () => murottal.stop() : () => murottal.playAyah(ref.s, ref.a),
        );
      },
    );
  }

  Widget _repFeedback(CheckResult? r) {
    if (skipped || r == null) {
      return const HCard(
        color: kWarnBg,
        child: Text('Dilewati tanpa penilaian.',
            style: TextStyle(color: kWarnFg, fontWeight: FontWeight.w600)),
      );
    }
    final n = from + ai;
    final a = r.ays[n];
    final ws = a?.ws ?? <WordRes>[];
    return HCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Ring(progress: r.acc, label: '${(r.acc * 100).round()}%', size: 84),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(repPass ? 'Bacaan diterima ✓' : 'Belum tepat',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Muted(
                  repPass
                      ? 'Kecocokan dari ${r.total} kata'
                      : (r.heard.isEmpty
                          ? 'Belum ada suara terdeteksi. Coba lagi.'
                          : 'Minimal ${(kAkurasiUlang * 100).round()}% agar bisa lanjut.'),
                  size: 13),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                Bdg('${r.cnt['ok']} benar', kind: 'g'),
                Bdg('${r.cnt['bad']} salah', kind: 'r'),
                Bdg('${(r.cnt['near'] ?? 0) + (r.cnt['miss'] ?? 0)} ragu / terlewat', kind: 'y'),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        _WordChips(ws),
        _ErrLines(ws),
      ]),
    );
  }

  // ---------- Uji ----------
  Widget _buildTest() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _dots(2),
      Mushaf(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: AyatText(s: s, from: from, to: to),
        ),
      ),
      Muted('Teks disembunyikan. Lafalkan ayat $from–$to dari ingatan.',
          align: TextAlign.center),
      const SizedBox(height: 8),
      _micPanel('Lafalkan seluruh ayat tanpa melihat teks, lalu tekan "Selesai & cek bacaan".'),
      if (mic == MicState.idle) HButton(label: 'Mulai uji (rekam)', onPressed: _testStart),
      if (mic == MicState.listening)
        HButton(label: 'Selesai & cek bacaan', kind: BK.gold, onPressed: _testStop),
      if (mic == MicState.checking) const HButton(label: 'Memeriksa…'),
      if (mic == MicState.idle)
        HButton(
          label: 'Kembali ke bacaan',
          kind: BK.outline,
          onPressed: () => setState(() => step = HStep.review),
        ),
    ]);
  }

  Widget _buildReview() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _dots(2),
      Mushaf(child: AyatText(s: s, from: from, to: to)),
      const Muted('Baca dan hafalkan lagi, lalu uji kembali.', align: TextAlign.center),
      HButton(
        label: 'Uji hafalan lagi',
        onPressed: () => setState(() {
          step = HStep.test;
          mic = MicState.idle;
          fails = 0;
        }),
      ),
    ]);
  }

  // ---------- Evaluasi ----------
  Widget _buildEval() {
    final pl = Pal.of(context);
    final r = res;
    final strict = focus == FocusKind.ayat && locked;
    final kids = <Widget>[_dots(3)];

    if (r == null || r.heard.isEmpty || r.total == 0) {
      kids.add(const HCard(
        color: kWarnBg,
        border: Color(0xFFD9A400),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tidak ada bacaan yang terdeteksi',
              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4A3800))),
          SizedBox(height: 4),
          Text('Coba rekam ulang dengan suara lebih jelas.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A3800))),
        ]),
      ));
      if (!strict) {
        for (var n = from; n <= to; n++) {
          kids.add(HCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: double.infinity,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(surahs[s].a[n - 1],
                      textAlign: TextAlign.center, style: arabic(22, color: pl.text, height: 1.8)),
                ),
              ),
              Muted('Ayat $n', size: 13),
              _MarkRow(mk[n], (v) => setState(() => mk[n] = v)),
            ]),
          ));
        }
      }
    } else {
      final cnt = r.cnt;
      kids.add(HCard(
        child: Row(children: [
          Ring(progress: r.acc, label: '${(r.acc * 100).round()}%', size: 96),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hasil pengecekan', style: TextStyle(fontWeight: FontWeight.w700)),
              Muted('Kecocokan dari ${r.total} kata', size: 13),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                Bdg('${cnt['ok']} benar', kind: 'g'),
                Bdg('${cnt['bad']} salah', kind: 'r'),
                Bdg('${(cnt['near'] ?? 0) + (cnt['miss'] ?? 0)} ragu / terlewat', kind: 'y'),
              ]),
            ]),
          ),
        ]),
      ));
      kids.add(HCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Muted('Yang terdengar', size: 12),
            Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: double.infinity,
                child: Text(r.heard, style: arabic(20, color: pl.text, height: 1.9)),
              ),
            ),
          ]),
        ),
      ));
      kids.add(const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          Bdg('Hijau: benar', kind: 'g'),
          Bdg('Merah: salah', kind: 'r'),
          Bdg('Kuning: mirip / terlewat', kind: 'y'),
        ]),
      ));
      for (var n = from; n <= to; n++) {
        final a = r.ays[n]!;
        kids.add(HCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _WordChips(a.ws, big: true),
            Row(children: [
              Expanded(child: Muted('Ayat $n', size: 13)),
              Bdg(a.v == 'g' ? 'Lancar' : (a.v == 'y' ? 'Ragu' : 'Salah'), kind: a.v),
            ]),
            _ErrLines(a.ws),
            _MarkRow(mk[n], (v) => setState(() => mk[n] = v)),
          ]),
        ));
      }
      kids.add(const Muted(
          'Pengecekan otomatis mencocokkan kata hasil pengenalan suara dengan teks ayat. Ini belum menilai tajwid, makhraj, atau panjang pendek bacaan. Verifikasi dengan guru.',
          size: 12));
    }

    if (strict && !testPass) {
      final pct = r == null ? 0 : (r.acc * 100).round();
      kids.add(HCard(
        color: kBadBg,
        border: pl.red,
        child: Text(
            'Belum lulus (kecocokan $pct%, minimal ${(kAkurasiUji * 100).round()}%). Kunci tetap aktif sampai kamu lulus uji hafalan.',
            style: const TextStyle(color: kBadFg, fontWeight: FontWeight.w600)),
      ));
      kids.add(HButton(
        label: 'Baca ulang ayat',
        onPressed: () => setState(() => step = HStep.review),
      ));
    } else {
      kids.add(HButton(
        label: strict ? 'Lulus! Simpan & buka kunci' : "Simpan & lanjut muraja'ah",
        onPressed: _finish,
      ));
      kids.add(HButton(
        label: 'Rekam ulang',
        kind: BK.outline,
        onPressed: () => setState(() {
          step = HStep.test;
          mic = MicState.idle;
        }),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kids);
  }

  // ---------- Selesai ----------
  Widget _buildDone() {
    final pl = Pal.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 14),
      HCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(children: [
            Icon(aborted ? Icons.stop_circle_outlined : Icons.check_circle_outline,
                size: 56, color: aborted ? pl.muted : pl.green),
            Text(aborted ? 'Sesi diakhiri' : 'Sesi selesai', style: serif(19)),
            const SizedBox(height: 4),
            Muted(
                aborted
                    ? 'Progres sesi ini tidak disimpan.'
                    : '$count ayat ${surahs[s].n} sudah diproses. Progres hari ini ${app.today}/${app.tgt}.',
                align: TextAlign.center),
            if (focus != FocusKind.off) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(color: pl.line, borderRadius: BorderRadius.circular(10)),
                child: const Text('Focus Mode dimatikan dan pengaturan fokus dipulihkan.',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ]),
        ),
      ),
      if (!aborted)
        HButton(
          label: "Buka muraja'ah",
          onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const MurajaPage())),
        ),
      HButton(
        label: 'Kembali ke beranda',
        kind: BK.outline,
        onPressed: () {
          app.update(() => app.tab = 0); // tab Beranda
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    ]);
  }
}

// ================= Widget bantu =================
class _WordChips extends StatelessWidget {
  final List<WordRes> ws;
  final bool big;
  const _WordChips(this.ws, {this.big = false});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final w in ws)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: w.st == 'ok' ? kOkBg : (w.st == 'bad' ? kBadBg : kWarnBg),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                w.orig,
                style: arabic(big ? 24 : 22,
                    height: 1.9,
                    color: w.st == 'ok' ? kOkFg : (w.st == 'bad' ? kBadFg : kWarnFg)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrLines extends StatelessWidget {
  final List<WordRes> ws;
  const _ErrLines(this.ws);

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final base = TextStyle(fontSize: 13, color: pl.muted);
    final bold = arabic(18, color: pl.text, height: 1.5, weight: FontWeight.w700);
    final lines = <Widget>[];
    for (final w in ws) {
      if (w.st == 'bad') {
        lines.add(Text.rich(TextSpan(style: base, children: [
          const TextSpan(text: 'Terdengar '),
          TextSpan(text: w.heard, style: bold),
          const TextSpan(text: ' → seharusnya '),
          TextSpan(text: w.orig, style: bold),
        ])));
      } else if (w.st == 'near') {
        lines.add(Text.rich(TextSpan(style: base, children: [
          const TextSpan(text: 'Kurang jelas: '),
          TextSpan(text: w.orig, style: bold),
          const TextSpan(text: ' (terdengar '),
          TextSpan(text: w.heard, style: bold),
          const TextSpan(text: ')'),
        ])));
      } else if (w.st == 'miss') {
        lines.add(Text.rich(TextSpan(style: base, children: [
          const TextSpan(text: 'Terlewat: '),
          TextSpan(text: w.orig, style: bold),
        ])));
      }
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
    );
  }
}

class _MarkRow extends StatelessWidget {
  final String? sel;
  final ValueChanged<String> onPick;
  const _MarkRow(this.sel, this.onPick);

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    Widget b(String label, String k, Color bg, Color bc) {
      final on = sel == k;
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: on ? bc : pl.line, width: 1.5),
      );
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 6, top: 6),
          child: Semantics(
            button: true,
            selected: on,
            child: FocusRing(
              radius: 10,
              child: Material(
              color: on ? bg : pl.card,
              shape: shape,
              child: InkWell(
                customBorder: shape,
                onTap: () => onPick(k),
                child: Container(
                  constraints: const BoxConstraints(minHeight: kTap),
                  alignment: Alignment.center,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: on ? Colors.black87 : pl.text)),
                ),
              ),
            ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      b('Lancar', 'g', kOkBg, pl.ok),
      b('Ragu', 'y', kWarnBg, pl.yellow),
      b('Salah', 'r', kBadBg, pl.red),
    ]);
  }
}
