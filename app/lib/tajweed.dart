import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'theme.dart';
import 'ui.dart';

/// Satu hukum tajwid dari markup quran.com (atribut class pada tag <tajweed>).
///
/// Warna mengikuti kelompok yang umum di mushaf tajwid (mad = biru, ikhfa = ungu,
/// idgham = hijau, ghunnah = oranye, qalqalah = merah, tidak dibaca = abu-abu),
/// lalu disesuaikan agar kontrasnya >= 3:1 untuk teks Arab besar di kartu terang
/// (#FFFDF7) dan gelap (#16251F). Nilai terendah: 3.39 (abu-abu, tema terang).
class TajweedRule {
  final String key;
  final String name;
  final String desc;
  final Color light;
  final Color dark;
  const TajweedRule(this.key, this.name, this.desc, this.light, this.dark);

  Color color(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

const List<TajweedRule> kTajweedRules = [
  TajweedRule('madda_normal', "Mad Thabi'i", 'Mad asli. Huruf mad dipanjangkan 2 harakat.',
      Color(0xFF3A6BE0), Color(0xFF7FA3FF)),
  TajweedRule(
      'madda_permissible',
      'Mad Jaiz',
      "Mad yang panjangnya boleh dipilih, mis. Mad Jaiz Munfashil dan Mad 'Aridh Lissukun. "
          'Pilih satu panjang sesuai yang diajarkan gurumu, lalu konsisten.',
      Color(0xFF2C3FD8),
      Color(0xFF8E99FF)),
  TajweedRule('madda_obligatory', 'Mad Wajib Muttashil',
      'Huruf mad bertemu hamzah dalam satu kata. Dipanjangkan 4 atau 5 harakat.',
      Color(0xFF1E3BAA), Color(0xFF6F8CFF)),
  TajweedRule('madda_necessary', 'Mad Lazim',
      'Huruf mad bertemu sukun asli atau tasydid. Dipanjangkan 6 harakat.',
      Color(0xFF0A1590), Color(0xFFA9B4FF)),
  TajweedRule('ghunnah', 'Ghunnah',
      'Nun atau mim bertasydid. Dibaca berdengung sekitar 2 harakat.',
      Color(0xFFC25400), Color(0xFFFF9B4D)),
  TajweedRule('ikhafa', 'Ikhfa Haqiqi',
      'Nun sukun atau tanwin bertemu salah satu dari 15 huruf ikhfa. Dibaca samar disertai dengung.',
      Color(0xFF8A009C), Color(0xFFD58BFF)),
  TajweedRule('ikhafa_shafawi', 'Ikhfa Syafawi',
      'Mim sukun bertemu huruf ب. Dibaca samar di bibir disertai dengung.',
      Color(0xFFB5009B), Color(0xFFF06AE0)),
  TajweedRule('iqlab', 'Iqlab',
      'Nun sukun atau tanwin bertemu huruf ب. Bunyi nun berubah menjadi mim disertai dengung.',
      Color(0xFF0079A8), Color(0xFF4CC9FF)),
  TajweedRule('idgham_ghunnah', 'Idgham Bighunnah',
      'Nun sukun atau tanwin bertemu ي ن م و. Dilebur ke huruf sesudahnya disertai dengung.',
      Color(0xFF137A62), Color(0xFF3FD1AE)),
  TajweedRule('idgham_wo_ghunnah', 'Idgham Bilaghunnah',
      'Nun sukun atau tanwin bertemu ل atau ر. Dilebur tanpa dengung.',
      Color(0xFF2E7A00), Color(0xFF7FCF4A)),
  TajweedRule('idgham_shafawi', 'Idgham Mimi',
      'Mim sukun bertemu mim. Dilebur dan didengungkan.',
      Color(0xFF3E8500), Color(0xFF8BDB4A)),
  TajweedRule('idgham_mutajanisayn', 'Idgham Mutajanisain',
      'Dua huruf yang makhrajnya sama tetapi sifatnya berbeda bertemu. Huruf pertama dilebur ke huruf kedua.',
      Color(0xFF7A7A7A), Color(0xFFB5BDB9)),
  TajweedRule('idgham_mutaqaribayn', 'Idgham Mutaqaribain',
      'Dua huruf yang makhraj dan sifatnya berdekatan bertemu. Huruf pertama dilebur ke huruf kedua.',
      Color(0xFF7A7A7A), Color(0xFFB5BDB9)),
  TajweedRule('qalaqah', 'Qalqalah', 'Huruf ق ط ب ج د yang sukun dibaca memantul.',
      Color(0xFFC8000A), Color(0xFFFF6B6B)),
  TajweedRule('laam_shamsiyah', 'Alif Lam Syamsiyah',
      'Lam pada "ال" tidak dibaca dan melebur ke huruf sesudahnya, yang dibaca bertasydid.',
      Color(0xFF8A8A8A), Color(0xFF9AA39F)),
  TajweedRule('ham_wasl', 'Hamzah Wasal',
      'Hamzah ini hanya dibaca bila memulai bacaan dari kata ini. Bila disambung dengan kata sebelumnya, tidak dibaca.',
      Color(0xFF8A8A8A), Color(0xFF9AA39F)),
  TajweedRule('slnt', 'Tidak dibaca', 'Huruf ini tertulis di mushaf tetapi tidak dilafalkan.',
      Color(0xFF8A8A8A), Color(0xFF9AA39F)),
];

final Map<String, TajweedRule> kRuleByKey = {for (final r in kTajweedRules) r.key: r};

/// Potongan teks ayat. [rule] null = huruf tanpa hukum khusus (warna teks biasa).
class TSeg {
  final String text;
  final TajweedRule? rule;
  const TSeg(this.text, this.rule);
}

final RegExp _tag = RegExp(r'<(/?)([a-zA-Z]+)([^>]*)>');
final RegExp _cls = RegExp(r'class\s*=\s*"?([\w-]+)"?');

/// Ubah markup quran.com menjadi potongan berwarna.
/// Isi <span class=end> (nomor ayat bawaan) dibuang; nomor ayat digambar sendiri.
List<TSeg> parseTajweed(String markup) {
  final out = <TSeg>[];
  final stack = <String>[]; // class tiap tag yang sedang terbuka
  var pos = 0;

  void addText(String t) {
    if (t.isEmpty) return;
    if (stack.contains('end')) return;
    TajweedRule? rule;
    for (var i = stack.length - 1; i >= 0; i--) {
      final r = kRuleByKey[stack[i]];
      if (r != null) {
        rule = r;
        break;
      }
    }
    // Gabungkan dengan potongan sebelumnya bila hukumnya sama (lebih sedikit span).
    if (out.isNotEmpty && out.last.rule == rule) {
      out[out.length - 1] = TSeg(out.last.text + t, rule);
    } else {
      out.add(TSeg(t, rule));
    }
  }

  for (final m in _tag.allMatches(markup)) {
    addText(markup.substring(pos, m.start));
    pos = m.end;
    final closing = m.group(1) == '/';
    if (closing) {
      if (stack.isNotEmpty) stack.removeLast();
    } else {
      final attrs = m.group(3) ?? '';
      if (attrs.trim().endsWith('/')) continue; // tag tunggal, mis. <br/>
      stack.add(_cls.firstMatch(attrs)?.group(1) ?? '');
    }
  }
  addText(markup.substring(pos));

  // Rapikan spasi ganda di ujung (sisa dari span nomor ayat).
  if (out.isNotEmpty) {
    final last = out.last;
    out[out.length - 1] = TSeg(last.text.trimRight(), last.rule);
  }
  return out;
}

/// Hukum tajwid yang muncul di satu ayat, urut sesuai kemunculan, beserta potongan hurufnya.
List<MapEntry<TajweedRule, List<String>>> rulesIn(List<TSeg> segs) {
  final map = <TajweedRule, List<String>>{};
  for (final s in segs) {
    final r = s.rule;
    if (r == null) continue;
    map.putIfAbsent(r, () => <String>[]).add(s.text);
  }
  return map.entries.toList();
}

String arabicDigits(int n) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

/// Ayat bertajwid berwarna. Mengetuk huruf berwarna membuka penjelasan hukumnya,
/// seperti di aplikasi Tarteel.
class TajweedText extends StatefulWidget {
  final String markup;
  final int ayah;
  final double? size;
  final TextAlign align;
  const TajweedText({
    super.key,
    required this.markup,
    required this.ayah,
    this.size,
    this.align = TextAlign.right,
  });

  @override
  State<TajweedText> createState() => _TajweedTextState();
}

class _TajweedTextState extends State<TajweedText> {
  late List<TSeg> _segs;
  final List<TapGestureRecognizer> _rec = [];

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(covariant TajweedText old) {
    super.didUpdateWidget(old);
    if (old.markup != widget.markup) _parse();
  }

  void _parse() {
    for (final r in _rec) {
      r.dispose();
    }
    _rec.clear();
    _segs = parseTajweed(widget.markup);
    for (final s in _segs) {
      final rule = s.rule;
      if (rule == null) continue;
      _rec.add(TapGestureRecognizer()..onTap = () => showRuleSheet(context, rule, s.text));
    }
  }

  @override
  void dispose() {
    for (final r in _rec) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final sz = widget.size ?? app.arabicSize;
        final spans = <InlineSpan>[];
        var ri = 0;
        for (final s in _segs) {
          final rule = s.rule;
          if (rule == null) {
            spans.add(TextSpan(text: s.text));
          } else {
            spans.add(TextSpan(
              text: s.text,
              style: TextStyle(color: rule.color(context)),
              recognizer: _rec[ri++],
              semanticsLabel: '${s.text}, ${rule.name}',
            ));
          }
        }
        spans.add(TextSpan(
          text: ' ﴿${arabicDigits(widget.ayah)}﴾',
          style: TextStyle(fontSize: sz * .62, color: pl.goldInk),
          semanticsLabel: 'ayat ${widget.ayah}',
        ));
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: double.infinity,
            child: Text.rich(
              TextSpan(children: spans, style: arabic(sz, color: pl.text, height: 2.1)),
              textAlign: widget.align,
            ),
          ),
        );
      },
    );
  }
}

/// Penjelasan satu hukum tajwid (muncul saat huruf berwarna diketuk).
Future<void> showRuleSheet(BuildContext context, TajweedRule rule, String text) {
  final pl = Pal.of(context);
  return showHSheet(
    context,
    title: rule.name,
    extra: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: pl.bg, borderRadius: BorderRadius.circular(12)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(text,
              textAlign: TextAlign.center,
              style: arabic(44, color: rule.color(context), height: 1.8)),
        ),
      ),
      const SizedBox(height: 10),
      Text(rule.desc),
      const SizedBox(height: 8),
      const Muted('Ringkasan dasar. Pastikan bacaanmu dengan guru.', size: 13),
    ]),
    actions: [
      SheetAction('Lihat semua warna hukum', () => showLegendSheet(context), BK.outline),
      SheetAction('Tutup', () {}),
    ],
  );
}

/// Daftar hukum yang ada di satu ayat. Jalan alternatif yang bisa dijangkau
/// keyboard dan pembaca layar, karena huruf di dalam teks tidak bisa difokus.
Future<void> showAyahRulesSheet(BuildContext context, String markup, String title) {
  final entries = rulesIn(parseTajweed(markup));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Pal.of(context).card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .8),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            children: [
              Text(title, style: serif(19)),
              const SizedBox(height: 4),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Muted('Tidak ada hukum bertanda warna di ayat ini.'),
                ),
              for (final e in entries)
                HCard(
                  margin: const EdgeInsets.only(top: 10),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showRuleSheet(context, e.key, e.value.first);
                  },
                  child: Row(children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: e.key.color(ctx), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.key.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(e.value.take(3).join('  '),
                          style: arabic(24, color: e.key.color(ctx), height: 1.5)),
                    ),
                  ]),
                ),
              const SizedBox(height: 6),
              HButton(label: 'Tutup', kind: BK.outline, onPressed: () => Navigator.of(ctx).pop()),
              const Muted('Ketuk satu hukum untuk penjelasannya.', size: 12, align: TextAlign.center),
            ],
          ),
        ),
      );
    },
  );
}

/// Legenda semua warna hukum tajwid.
Future<void> showLegendSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Pal.of(context).card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          children: [
            Text('Warna hukum tajwid', style: serif(19)),
            const SizedBox(height: 4),
            const Muted('Huruf tanpa warna dibaca biasa, termasuk izhar.', size: 13),
            const SizedBox(height: 8),
            for (final r in kTajweedRules)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: r.color(ctx), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Nama memakai warna teks biasa: abu-abu tajwid hanya 3.39:1,
                      // cukup untuk huruf Arab besar tapi tidak untuk teks 15px.
                      Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(r.desc, style: const TextStyle(fontSize: 14)),
                    ]),
                  ),
                ]),
              ),
            HButton(label: 'Tutup', kind: BK.outline, onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
    ),
  );
}
