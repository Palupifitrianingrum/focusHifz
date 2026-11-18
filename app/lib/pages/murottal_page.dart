import 'package:flutter/material.dart';
import '../app_state.dart';
import '../murottal.dart';
import '../quran_api.dart';
import '../theme.dart';
import '../ui.dart';

// ================= MUROTTAL & UNDUHAN =================
class MurottalPage extends StatefulWidget {
  /// Surah yang langsung dipilih (dari halaman surah), 0 = tidak ada.
  final int surah;
  const MurottalPage({super.key, this.surah = 0});
  @override
  State<MurottalPage> createState() => _MurottalPageState();
}

class _MurottalPageState extends State<MurottalPage> {
  late Future<List<Chapter>> _chapters = QuranApi.chapters();
  late int scope = widget.surah > 0 ? 1 : 0; // 0 semua, 1 per surah, 2 rentang ayat
  late int surah = widget.surah > 0 ? widget.surah : 1;
  int from = 1, to = 7;
  Set<String> saved = {};
  bool savedLoading = true;
  late Future<List<ReciterStorage>> _storage = downloader.storage();

  @override
  void initState() {
    super.initState();
    _refreshSaved();
    downloader.changed.addListener(_onChanged);
    app.addListener(_onApp);
    _lastReciter = app.reciter;
  }

  String _lastReciter = '';

  void _onApp() {
    if (app.reciter != _lastReciter) {
      _lastReciter = app.reciter;
      _refreshSaved();
    }
  }

  void _onChanged() {
    _refreshSaved();
    setState(() => _storage = downloader.storage());
  }

  @override
  void dispose() {
    downloader.changed.removeListener(_onChanged);
    app.removeListener(_onApp);
    super.dispose();
  }

  Future<void> _refreshSaved() async {
    setState(() => savedLoading = true);
    Set<String> s;
    try {
      s = await downloader.savedFiles(app.reciter);
    } catch (_) {
      s = {};
    }
    if (!mounted) return;
    setState(() {
      saved = s;
      savedLoading = false;
    });
  }

  List<AyahRef> _items(List<Chapter> cs) {
    switch (scope) {
      case 0:
        return [
          for (final c in cs)
            for (var a = 1; a <= c.verses; a++) AyahRef(c.id, a),
        ];
      case 1:
        return [for (var a = 1; a <= cs[surah - 1].verses; a++) AyahRef(surah, a)];
      default:
        return [for (var a = from; a <= to; a++) AyahRef(surah, a)];
    }
  }

  String _scopeLabel(List<Chapter> cs) {
    switch (scope) {
      case 0:
        return "Seluruh Al-Qur'an";
      case 1:
        return 'Surah ${cs[surah - 1].name}';
      default:
        return '${cs[surah - 1].name} ayat $from–$to';
    }
  }

  void _setSurah(List<Chapter> cs, int s) => setState(() {
        surah = s;
        from = 1;
        to = cs[s - 1].verses;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Chapter>>(
          future: _chapters,
          builder: (context, snap) {
            final kids = <Widget>[const PageHeader('Murottal')];
            if (snap.connectionState != ConnectionState.done) {
              kids.add(const LoadingState('Memuat daftar surah…'));
            } else if (snap.hasError || snap.data == null) {
              kids.add(ErrorState(
                message: '${snap.error ?? 'Daftar surah gagal dimuat.'}',
                onRetry: () => setState(() => _chapters = QuranApi.chapters(refresh: true)),
              ));
            } else {
              kids.addAll(_content(snap.data!));
            }
            return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: kids);
          },
        ),
      ),
      bottomNavigationBar: const PlayerBar(),
    );
  }

  List<Widget> _content(List<Chapter> cs) {
    if (to > cs[surah - 1].verses || to < from) to = cs[surah - 1].verses;
    final items = Downloader.withBasmalah(_items(cs));
    final have = savedLoading ? 0 : items.where((r) => saved.contains(r.fileName)).length;
    final need = items.length - have;
    final ch = cs[surah - 1];
    return [
      // ----- Qari -----
      HCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Muted('Qari', size: 13),
              Text(app.reciterName, style: serif(19)),
              Muted(app.reciter == kDefaultReciter ? 'Bawaan aplikasi' : app.reciter, size: 12),
            ]),
          ),
          SmallButton(
            label: 'Ganti qari',
            onPressed: () => pushPage(context, const ReciterPage()),
          ),
        ]),
      ),

      // ----- Pilih yang diunduh -----
      const H4('Unduh untuk didengar offline'),
      Seg(
        labels: const ['Semua', 'Per surah', 'Rentang ayat'],
        index: scope,
        onChanged: (i) => setState(() => scope = i),
      ),
      if (scope > 0)
        HCard(
          onTap: () async {
            final s = await pickSurah(context, cs, surah);
            if (s != null) _setSurah(cs, s);
          },
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Muted('Surah', size: 13),
                Text('${ch.id}. ${ch.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Muted('${ch.verses} ayat · ${ch.meaning}', size: 13),
              ]),
            ),
            Icon(Icons.unfold_more, color: Pal.of(context).muted, semanticLabel: 'Pilih surah'),
          ]),
        ),
      if (scope == 2)
        HCard(
          child: Column(children: [
            SpinRow(
              label: 'Dari ayat',
              value: '$from',
              onMinus: () => setState(() => from = clampI(from - 1, 1, to)),
              onPlus: () => setState(() => from = clampI(from + 1, 1, to)),
            ),
            SpinRow(
              label: 'Sampai ayat',
              value: '$to',
              onMinus: () => setState(() => to = clampI(to - 1, from, ch.verses)),
              onPlus: () => setState(() => to = clampI(to + 1, from, ch.verses)),
            ),
            if (ch.verses > 1)
              RangeSlider(
                values: RangeValues(from.toDouble(), to.toDouble()),
                min: 1,
                max: ch.verses.toDouble(),
                divisions: ch.verses - 1,
                labels: RangeLabels('$from', '$to'),
                onChanged: (v) => setState(() {
                  from = v.start.round();
                  to = v.end.round();
                }),
              ),
          ]),
        ),
      HCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_scopeLabel(cs), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Muted(
            savedLoading
                ? 'Memeriksa file yang sudah tersimpan…'
                : '${items.length} file ayat · $have sudah tersimpan',
            size: 13,
          ),
          if (scope == 0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Muted(
                  'Unduhan seluruh Al-Qur\'an berukuran besar. Sebaiknya pakai Wi-Fi dan biarkan aplikasi tetap terbuka.',
                  size: 13),
            ),
          _ProgressBlock(scope: _scopeLabel(cs)),
          ValueListenableBuilder<DlProgress?>(
            valueListenable: downloader.progress,
            builder: (context, p, _) {
              final busy = p?.running ?? false;
              return HButton(
                label: busy
                    ? 'Sedang mengunduh…'
                    : (need == 0 && !savedLoading ? 'Semua sudah tersimpan' : 'Unduh $need ayat'),
                onPressed: busy || savedLoading || need == 0
                    ? null
                    : () => downloader.start(
                          Reciter(app.reciter, app.reciterName, ''),
                          _items(cs),
                          _scopeLabel(cs),
                        ),
              );
            },
          ),
        ]),
      ),

      // ----- Penyimpanan -----
      const H4('Tersimpan di HP'),
      FutureBuilder<List<ReciterStorage>>(
        future: _storage,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingState('Menghitung file tersimpan…');
          }
          if (snap.hasError) {
            return ErrorState(
              message: 'Gagal membaca penyimpanan.',
              onRetry: () => setState(() => _storage = downloader.storage()),
            );
          }
          final list = snap.data ?? const <ReciterStorage>[];
          if (list.isEmpty) {
            return const EmptyState('Belum ada murottal yang diunduh.');
          }
          return Column(children: [
            for (final x in list)
              HCard(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(x.folder.replaceAll('__', '/').replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Muted('${x.files} ayat · ${formatBytes(x.bytes)}', size: 13),
                    ]),
                  ),
                  SmallButton(
                    label: 'Hapus',
                    danger: true,
                    onPressed: () => showHSheet(
                      context,
                      title: 'Hapus murottal ini?',
                      body:
                          '${x.files} file (${formatBytes(x.bytes)}) akan dihapus dari HP. Bisa diunduh lagi kapan saja.',
                      actions: [
                        SheetAction('Batal', () {}, BK.outline),
                        SheetAction('Hapus file', () => downloader.deleteLocal(x.folder), BK.red),
                      ],
                    ),
                  ),
                ]),
              ),
          ]);
        },
      ),
      const SizedBox(height: 6),
      const Muted('Sumber audio: everyayah.com. Teks dan daftar surah: quran.com.', size: 12),
    ];
  }
}

class _ProgressBlock extends StatelessWidget {
  final String scope;
  const _ProgressBlock({required this.scope});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DlProgress?>(
      valueListenable: downloader.progress,
      builder: (context, p, _) {
        if (p == null) return const SizedBox.shrink();
        final pl = Pal.of(context);
        String status;
        if (p.running) {
          status = 'Mengunduh ${p.done + p.failed} dari ${p.total}';
        } else if (p.cancelled) {
          status = 'Dihentikan. ${p.done} dari ${p.total} tersimpan.';
        } else if (p.failed > 0) {
          status = 'Selesai, ${p.failed} file gagal diunduh.';
        } else {
          status = 'Selesai. ${p.done} file tersimpan.';
        }
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: pl.bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.scope} · ${p.reciterName}', style: const TextStyle(fontSize: 13)),
            HBar(p.ratio),
            Semantics(
              liveRegion: true,
              child: Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (p.running)
              HButton(label: 'Hentikan unduhan', kind: BK.outline, onPressed: downloader.cancel),
            if (!p.running && downloader.canRetry)
              HButton(
                  label: 'Coba lagi yang gagal',
                  kind: BK.outline,
                  onPressed: downloader.retryFailed),
          ]),
        );
      },
    );
  }
}

/// Pilih surah dari daftar 114 dengan pencarian.
Future<int?> pickSurah(BuildContext context, List<Chapter> cs, int current) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Pal.of(context).card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => _SurahPicker(cs: cs, current: current),
  );
}

class _SurahPicker extends StatefulWidget {
  final List<Chapter> cs;
  final int current;
  const _SurahPicker({required this.cs, required this.current});
  @override
  State<_SurahPicker> createState() => _SurahPickerState();
}

class _SurahPickerState extends State<_SurahPicker> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final list = widget.cs.where((c) => matchSurah(c, q)).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .8,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: SearchField(label: 'Cari surah', onChanged: (v) => setState(() => q = v)),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState('Tidak ada surah dengan nama atau nomor itu.')
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final c = list[i];
                        final on = c.id == widget.current;
                        return ListTile(
                          selected: on,
                          selectedColor: pl.green,
                          leading: SurahNumber(c.id),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${c.verses} ayat · ${c.meaning}',
                              style: TextStyle(color: pl.muted)),
                          trailing: Text(c.arabic, style: arabic(20, color: pl.text, height: 1.4)),
                          onTap: () => Navigator.of(context).pop(c.id),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

bool matchSurah(Chapter c, String q) {
  final t = q.trim().toLowerCase();
  if (t.isEmpty) return true;
  if ('${c.id}' == t) return true;
  String norm(String x) => x.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]"), '');
  final n = norm(t);
  return norm(c.name).contains(n) || norm(c.meaning).contains(n) || c.arabic.contains(q.trim());
}

// ================= PILIH QARI =================
class ReciterPage extends StatefulWidget {
  const ReciterPage({super.key});
  @override
  State<ReciterPage> createState() => _ReciterPageState();
}

class _ReciterPageState extends State<ReciterPage> {
  late Future<List<Reciter>> _f = QuranApi.reciters();
  String q = '';

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Reciter>>(
          future: _f,
          builder: (context, snap) {
            final kids = <Widget>[
              const PageHeader('Pilih qari'),
              const Muted(
                  'Daftar qari dari everyayah.com. Bitrate kecil berarti file lebih ringan, bitrate besar suaranya lebih jernih.',
                  size: 13),
              const SizedBox(height: 10),
            ];
            List<Reciter> all;
            if (snap.connectionState != ConnectionState.done) {
              kids.add(const LoadingState('Memuat daftar qari…'));
              return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: kids);
            } else if (snap.hasError || snap.data == null) {
              kids.add(ErrorState(
                message: '${snap.error ?? 'Daftar qari gagal dimuat.'} Sementara ditampilkan daftar bawaan.',
                onRetry: () => setState(() => _f = QuranApi.reciters(refresh: true)),
              ));
              all = kFallbackReciters;
            } else {
              all = snap.data!;
            }
            final t = q.trim().toLowerCase();
            final list = all
                .where((r) => t.isEmpty || r.name.toLowerCase().contains(t) || r.folder.toLowerCase().contains(t))
                .toList();
            kids.add(SearchField(label: 'Cari nama qari', onChanged: (v) => setState(() => q = v)));
            kids.add(const SizedBox(height: 8));
            if (list.isEmpty) kids.add(const EmptyState('Tidak ada qari dengan nama itu.'));
            for (final r in list) {
              final on = r.folder == app.reciter;
              kids.add(HCard(
                border: on ? pl.green : null,
                onTap: () {
                  app.update(() {
                    app.reciter = r.folder;
                    app.reciterName = r.name;
                  });
                  Navigator.of(context).pop();
                },
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Muted(r.bitrate.isEmpty ? r.folder : r.bitrate, size: 13),
                    ]),
                  ),
                  if (r.folder == kDefaultReciter) const Bdg('Bawaan'),
                  if (on) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: pl.green, semanticLabel: 'Dipilih'),
                  ],
                ]),
              ));
            }
            return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: kids);
          },
        ),
      ),
    );
  }
}
