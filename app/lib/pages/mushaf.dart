import 'package:flutter/material.dart';
import '../app_state.dart';
import '../murottal.dart';
import '../quran_api.dart';
import '../tajweed.dart';
import '../theme.dart';
import '../ui.dart';
import 'murottal_page.dart';

const String kBasmalah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

// ================= MUSHAF (daftar 114 surah) =================
class MushafTab extends StatefulWidget {
  const MushafTab({super.key});
  @override
  State<MushafTab> createState() => _MushafTabState();
}

class _MushafTabState extends State<MushafTab> {
  late Future<List<Chapter>> _f = QuranApi.chapters();
  String q = '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Chapter>>(
      future: _f,
      builder: (context, snap) {
        final head = <Widget>[
          Semantics(header: true, child: Text('Mushaf', style: serif(24))),
          const SizedBox(height: 4),
          const Muted('Teks Utsmani bertajwid. Ketuk huruf berwarna untuk melihat hukum bacaannya.'),
          const SizedBox(height: 12),
        ];
        if (snap.connectionState != ConnectionState.done) {
          return ListView(padding: _pad, children: [...head, const LoadingState('Memuat daftar surah…')]);
        }
        if (snap.hasError || snap.data == null) {
          return ListView(padding: _pad, children: [
            ...head,
            ErrorState(
              message:
                  '${snap.error ?? 'Daftar surah gagal dimuat.'} Daftar surah perlu internet saat pertama kali dibuka, setelah itu tersimpan di HP.',
              onRetry: () => setState(() => _f = QuranApi.chapters(refresh: true)),
            ),
          ]);
        }
        final cs = snap.data!;
        final list = cs.where((c) => matchSurah(c, q)).toList();
        head.addAll([
          ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final last = app.lastSurah >= 1 && app.lastSurah <= 114 ? cs[app.lastSurah - 1] : null;
              if (last == null) return const SizedBox.shrink();
              return _ContinueCard(chapter: last, ayah: app.lastAyah);
            },
          ),
          Row(children: [
            Expanded(
              child: SmallButton(
                label: 'Murottal',
                icon: Icons.headphones,
                onPressed: () => pushPage(context, const MurottalPage()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SmallButton(
                label: 'Warna tajwid',
                icon: Icons.palette_outlined,
                onPressed: () => showLegendSheet(context),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SearchField(label: 'Cari surah (nama, arti, atau nomor)', onChanged: (v) => setState(() => q = v)),
          const SizedBox(height: 8),
          if (list.isEmpty) const EmptyState('Tidak ada surah dengan nama atau nomor itu.'),
        ]);
        return ListView.builder(
          padding: _pad,
          itemCount: head.length + list.length,
          itemBuilder: (context, i) {
            if (i < head.length) return head[i];
            return _SurahRow(chapter: list[i - head.length]);
          },
        );
      },
    );
  }
}

const EdgeInsets _pad = EdgeInsets.fromLTRB(16, 16, 16, 28);

class _ContinueCard extends StatelessWidget {
  final Chapter chapter;
  final int ayah;
  const _ContinueCard({required this.chapter, required this.ayah});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    // Satu-satunya kartu hijau di halaman ini: titik fokus "lanjutkan membaca".
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FocusRing(
        radius: 18,
        child: Material(
        color: pl.green2,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openSurah(context, chapter, ayah: ayah),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border(bottom: BorderSide(color: pl.gold, width: 3)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Lanjutkan membaca', style: TextStyle(color: Color(0xFFE9DFB8), fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('${chapter.name} · ayat ${ayah < 1 ? 1 : ayah}',
                      style: serif(19, color: Colors.white)),
                ]),
              ),
              Text(chapter.arabic, style: arabic(26, color: Colors.white, height: 1.4)),
              const SizedBox(width: 4),
              const ExcludeSemantics(child: Icon(Icons.chevron_right, color: Colors.white)),
            ]),
          ),
        ),
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  final Chapter chapter;
  const _SurahRow({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final c = chapter;
    return FocusRing(
      radius: 12,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openSurah(context, c),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: pl.line))),
          child: Row(children: [
            SurahNumber(c.id),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('${c.meaning} · ${c.verses} ayat · ${c.placeLabel}',
                    style: TextStyle(color: pl.muted, fontSize: 13)),
              ]),
            ),
            Text(c.arabic, style: arabic(22, color: pl.green, height: 1.5)),
          ]),
        ),
      ),
      ),
    );
  }
}

Future<void> openSurah(BuildContext context, Chapter c, {int ayah = 1}) =>
    pushPage(context, SurahPage(chapter: c, startAyah: ayah < 1 ? 1 : ayah));

// ================= BACA SURAH =================
class SurahPage extends StatefulWidget {
  final Chapter chapter;
  final int startAyah;
  const SurahPage({super.key, required this.chapter, this.startAyah = 1});
  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  late Future<List<QVerse>> _f = QuranApi.verses(widget.chapter.id);
  late int start = clampI(widget.startAyah, 1, widget.chapter.verses);
  final Map<int, GlobalKey> _keys = {};

  Chapter get c => widget.chapter;

  @override
  void initState() {
    super.initState();
    app.setLastRead(c.id, start);
    murottal.current.addListener(_follow);
  }

  @override
  void dispose() {
    murottal.current.removeListener(_follow);
    super.dispose();
  }

  /// Gulir mengikuti ayat yang sedang diputar.
  void _follow() {
    if (!mounted) return;
    final cur = murottal.current.value;
    if (cur == null || cur.s != c.id || cur.isBasmalah) return;
    final ctx = _keys[cur.a]?.currentContext;
    if (ctx == null) return;
    final still = MediaQuery.of(context).disableAnimations;
    Scrollable.ensureVisible(ctx,
        alignment: .12, duration: still ? Duration.zero : const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<QVerse>>(
          future: _f,
          builder: (context, snap) {
            final head = <Widget>[
              PageHeader(c.name, actions: [
                HIconBtn(
                  icon: Icons.palette_outlined,
                  label: 'Warna hukum tajwid',
                  onTap: () => showLegendSheet(context),
                ),
              ]),
              _SurahHeader(chapter: c, start: start),
            ];
            if (snap.connectionState != ConnectionState.done) {
              return ListView(padding: _pad, children: [...head, const LoadingState('Memuat ayat…')]);
            }
            if (snap.hasError || snap.data == null) {
              return ListView(padding: _pad, children: [
                ...head,
                ErrorState(
                  message:
                      '${snap.error ?? 'Ayat gagal dimuat.'} Teks surah perlu internet saat pertama kali dibuka.',
                  onRetry: () => setState(() => _f = QuranApi.verses(c.id, refresh: true)),
                ),
              ]);
            }
            final vs = snap.data!.where((v) => v.n >= start).toList();
            if (start > 1) {
              head.add(SmallButton(
                label: 'Tampilkan ayat 1–${start - 1}',
                icon: Icons.expand_less,
                onPressed: () => setState(() => start = 1),
              ));
              head.add(const SizedBox(height: 8));
            }
            if (start == 1 && c.bismillah) {
              head.add(Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(kBasmalah,
                      textAlign: TextAlign.center,
                      style: arabic(app.arabicSize * .9, color: Pal.of(context).text, height: 2)),
                ),
              ));
            }
            if (vs.isEmpty) head.add(const EmptyState('Tidak ada ayat untuk ditampilkan.'));
            return ListView.builder(
              padding: _pad,
              itemCount: head.length + vs.length,
              itemBuilder: (context, i) {
                if (i < head.length) return head[i];
                final v = vs[i - head.length];
                final key = _keys.putIfAbsent(v.n, () => GlobalKey());
                return _AyahCard(key: key, chapter: c, verse: v);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const PlayerBar(),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final Chapter chapter;
  final int start;
  const _SurahHeader({required this.chapter, required this.start});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final c = chapter;
    return Mushaf(
      child: Column(children: [
        Text(c.arabic, style: arabic(34, color: pl.text, height: 1.6)),
        Text('${c.meaning} · ${c.verses} ayat · ${c.placeLabel}',
            textAlign: TextAlign.center, style: TextStyle(color: pl.muted, fontSize: 13)),
        const SizedBox(height: 4),
        ListenableBuilder(
          listenable: app,
          builder: (context, _) => TextButton.icon(
            onPressed: () => pushPage(context, const ReciterPage()),
            style: TextButton.styleFrom(minimumSize: const Size(0, kTap), foregroundColor: pl.green),
            icon: const Icon(Icons.record_voice_over_outlined, size: 18),
            label: Text('Qari: ${app.reciterName}'),
          ),
        ),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => murottal.playRange(c.id, start, c.verses),
              style: FilledButton.styleFrom(
                backgroundColor: pl.green,
                foregroundColor: pl.onAccent,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text(start > 1 ? 'Putar dari ayat $start' : 'Putar surah'),
            ),
          ),
          const SizedBox(width: 8),
          SmallButton(
            label: 'Unduh',
            icon: Icons.download,
            onPressed: () => pushPage(context, MurottalPage(surah: c.id)),
          ),
        ]),
      ]),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final Chapter chapter;
  final QVerse verse;
  const _AyahCard({super.key, required this.chapter, required this.verse});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[murottal.current, murottal.playing]),
      builder: (context, _) {
        final cur = murottal.current.value;
        final isCur = cur != null && cur.s == chapter.id && cur.a == verse.n;
        final isPlaying = isCur && murottal.playing.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
          decoration: BoxDecoration(
            color: isCur ? pl.gold.withValues(alpha: .10) : pl.card,
            border: Border.all(color: isCur ? pl.gold : pl.line, width: isCur ? 2 : 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Bdg('${chapter.id}:${verse.n}'),
              const Spacer(),
              IconButton(
                tooltip: 'Hukum tajwid ayat ${verse.n}',
                onPressed: () =>
                    showAyahRulesSheet(context, verse.tajweed, 'Tajwid ${chapter.name} : ${verse.n}'),
                icon: Icon(Icons.palette_outlined, color: pl.muted),
              ),
              IconButton(
                tooltip: isPlaying ? 'Jeda' : 'Putar mulai ayat ${verse.n}',
                onPressed: () {
                  if (isCur) {
                    murottal.toggle();
                  } else {
                    murottal.playRange(chapter.id, verse.n, chapter.verses);
                  }
                },
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: pl.green, size: 30),
              ),
            ]),
            TajweedText(markup: verse.tajweed, ayah: verse.n),
          ]),
        );
      },
    );
  }
}
