import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'data.dart';
import 'theme.dart';

double clampD(double x, double a, double b) => x < a ? a : (x > b ? b : x);
int clampI(int x, int a, int b) => x < a ? a : (x > b ? b : x);

String mm(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

Future<T?> pushPage<T>(BuildContext c, Widget w) =>
    Navigator.of(c).push<T>(MaterialPageRoute<T>(builder: (_) => w));

void toast(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

/// Lebar baca maksimum. Di tablet atau layar lebar, konten tetap satu kolom yang nyaman
/// dibaca, bukan melebar sampai tepi.
const double kMaxContentWidth = 600;

const EdgeInsets kPagePad = EdgeInsets.fromLTRB(20, 16, 20, 32);

/// Daftar gulir satu kolom dengan lebar terbatas dan padding halaman standar.
class PageList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const PageList({super.key, required this.children, this.padding = kPagePad});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
        child: ListView(padding: padding, children: children),
      ),
    );
  }
}

/// Scaffold + SafeArea + [PageList] untuk halaman sekunder.
class PageScaffold extends StatelessWidget {
  final List<Widget> children;
  final Widget? bottom;
  const PageScaffold({super.key, required this.children, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: PageList(children: children)),
      bottomNavigationBar: bottom,
    );
  }
}

// ===== Penanda identitas: bintang delapan sudut (penanda hizb di mushaf cetak) =====
class _RubPainter extends CustomPainter {
  final Color fill;
  final Color? edge;
  _RubPainter(this.fill, this.edge);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final big = size.width / 2, small = big * .80;
    final p = Path();
    for (var i = 0; i < 16; i++) {
      final a = -math.pi / 2 + i * math.pi / 8;
      final r = i.isEven ? big : small;
      final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    canvas.drawPath(p, Paint()..color = fill);
    if (edge != null) {
      canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = edge!);
    }
  }

  @override
  bool shouldRepaint(covariant _RubPainter old) => old.fill != fill || old.edge != edge;
}

/// Wadah ikon atau angka berbentuk bintang delapan sudut. Dipakai berulang di seluruh
/// aplikasi sebagai ciri HifzFlow: nomor ayat, ikon menu, tanda status.
class RubBadge extends StatelessWidget {
  final Widget child;
  final double size;
  final Color? fill;
  final Color? edge;
  const RubBadge({super.key, required this.child, this.size = 44, this.fill, this.edge});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RubPainter(fill ?? pl.card2, edge),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Ikon dalam [RubBadge] dengan warna yang menjaga kontras di kedua tema.
class RubIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? fill;
  final Color? color;
  const RubIcon(this.icon, {super.key, this.size = 44, this.fill, this.color});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return RubBadge(
      size: size,
      fill: fill,
      child: Icon(icon, size: size * .46, color: color ?? pl.green),
    );
  }
}

// ===== Kartu =====
class HCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? border;
  final Color? color;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const HCard({
    super.key,
    required this.child,
    this.onTap,
    this.border,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Rad.card),
      side: BorderSide(color: border ?? pl.line),
    );
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? pl.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Baris navigasi: ikon, judul, keterangan, chevron.
class NavCard extends StatelessWidget {
  final String title;
  final String sub;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? border;
  const NavCard({
    super.key,
    required this.title,
    required this.sub,
    required this.onTap,
    this.icon,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return HCard(
      onTap: onTap,
      border: border,
      child: Row(children: [
        if (icon != null) ...[
          RubIcon(icon!, size: 48),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: sans(15, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(sub, style: sans(13, color: pl.muted, height: 1.35)),
          ]),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 24, color: pl.muted),
      ]),
    );
  }
}

// ===== Tombol =====
enum BK { fill, outline, gold, red }

class HButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BK kind;
  final IconData? icon;
  const HButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = BK.fill,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    switch (kind) {
      case BK.fill:
        bg = pl.green;
        fg = pl.onGreen;
        break;
      case BK.gold:
        bg = pl.gold;
        fg = const Color(0xFF2A2108);
        break;
      case BK.red:
        bg = pl.red;
        fg = dark ? const Color(0xFF1A0A07) : Colors.white;
        break;
      case BK.outline:
        bg = Colors.transparent;
        fg = pl.green;
        break;
    }
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const pad = EdgeInsets.symmetric(vertical: 15, horizontal: 18);
    final ts = sans(15, weight: FontWeight.w700);
    final child = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
      Flexible(child: Text(label, textAlign: TextAlign.center)),
    ]);
    final Widget btn;
    if (kind == BK.outline) {
      btn = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          disabledForegroundColor: pl.muted.withValues(alpha: .7),
          side: BorderSide(
              color: onPressed == null ? pl.line : pl.green.withValues(alpha: .7), width: 1.5),
          padding: pad,
          minimumSize: const Size(0, 52),
          shape: shape,
          textStyle: ts,
        ),
        child: child,
      );
    } else {
      btn = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: pl.card2,
          disabledForegroundColor: pl.muted.withValues(alpha: .8),
          padding: pad,
          minimumSize: const Size(0, 52),
          shape: shape,
          textStyle: ts,
        ),
        child: child,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(width: double.infinity, child: btn),
    );
  }
}

/// Pilihan tunggal. Pilihan aktif memakai isi hijau DAN tanda centang, jadi status
/// tidak bergantung pada warna saja.
class HChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const HChip({super.key, required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final shape = StadiumBorder(side: BorderSide(color: on ? pl.green : pl.line, width: 1.5));
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? pl.green : pl.card,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (on) ...[
                    Icon(Icons.check_rounded, size: 18, color: pl.onGreen),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(label,
                        style: sans(14,
                            weight: FontWeight.w600, color: on ? pl.onGreen : pl.text)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Penanda status nyata (benar, ragu, salah, jadwal). Bentuk persegi bersudut kecil,
/// bukan kapsul, dan selalu membawa teks.
class Bdg extends StatelessWidget {
  final String text;
  final String kind; // g | y | r | ''
  final IconData? icon;
  const Bdg(this.text, {super.key, this.kind = '', this.icon});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    Color bg = pl.card2, fg = pl.text;
    if (kind == 'g') {
      bg = pl.okBg;
      fg = pl.okFg;
    } else if (kind == 'y') {
      bg = pl.warnBg;
      fg = pl.warnFg;
    } else if (kind == 'r') {
      bg = pl.badBg;
      fg = pl.badFg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Rad.tiny)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
        Flexible(child: Text(text, style: sans(12, weight: FontWeight.w700, color: fg))),
      ]),
    );
  }
}

enum SK { ok, warn, bad, info }

/// Kotak pesan status (hasil, galat, peringatan) dengan ikon dan teks.
class StatusNote extends StatelessWidget {
  final SK kind;
  final String title;
  final String? body;
  final EdgeInsets margin;
  const StatusNote({
    super.key,
    required this.kind,
    required this.title,
    this.body,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    Color bg, fg;
    IconData ic;
    switch (kind) {
      case SK.ok:
        bg = pl.okBg;
        fg = pl.okFg;
        ic = Icons.check_circle_outline_rounded;
        break;
      case SK.warn:
        bg = pl.warnBg;
        fg = pl.warnFg;
        ic = Icons.info_outline_rounded;
        break;
      case SK.bad:
        bg = pl.badBg;
        fg = pl.badFg;
        ic = Icons.error_outline_rounded;
        break;
      case SK.info:
        bg = pl.card2;
        fg = pl.text;
        ic = Icons.info_outline_rounded;
        break;
    }
    return Padding(
      padding: margin,
      child: Semantics(
        liveRegion: kind == SK.bad,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Rad.control + 2)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(ic, size: 20, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: sans(14, weight: FontWeight.w700, color: fg, height: 1.35)),
                if (body != null) ...[
                  const SizedBox(height: 3),
                  Text(body!, style: sans(13, color: fg, height: 1.4)),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Keadaan kosong: ikon, satu kalimat penjelas, dan (opsional) satu tindakan nyata.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(children: [
        RubIcon(icon, size: 64),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: serif(19)),
        if (body != null) ...[
          const SizedBox(height: 6),
          Text(body!,
              textAlign: TextAlign.center, style: sans(14, color: pl.muted, height: 1.45)),
        ],
        if (actionLabel != null && onAction != null)
          HButton(label: actionLabel!, kind: BK.outline, onPressed: onAction),
      ]),
    );
  }
}

class HBar extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? track;
  const HBar(this.value, {super.key, this.color, this.track});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 8,
          color: track ?? pl.line,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clampD(value.isNaN ? 0 : value, 0, 1),
            child: Container(color: color ?? pl.green),
          ),
        ),
      ),
    );
  }
}

class Ring extends StatelessWidget {
  final double progress;
  final String label;
  final double size;
  final Color? color;
  final Color? track;
  final Color? textColor;
  const Ring({
    super.key,
    required this.progress,
    required this.label,
    this.size = 110,
    this.color,
    this.track,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
            clampD(progress.isNaN ? 0 : progress, 0, 1), track ?? pl.line, color ?? pl.green,
            size > 120 ? 12 : 9),
        child: Center(
          child: Text(label,
              style: serif(size > 120 ? 32 : (size > 90 ? 22 : 18), color: textColor ?? pl.text)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double p;
  final Color track, color;
  final double stroke;
  _RingPainter(this.p, this.track, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - stroke;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        2 * math.pi * p,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.p != p || old.track != track || old.color != color || old.stroke != stroke;
}

class HSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const HSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? pl.onGreen : pl.muted),
      trackColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? pl.green : pl.card2),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? pl.green : pl.muted),
    );
  }
}

/// Baris pengaturan: label dan keterangan di kiri, sakelar di kanan.
class SwitchRow extends StatelessWidget {
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const SwitchRow(
      {super.key, required this.label, this.sub, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Semantics(
      label: label,
      toggled: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.control),
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: sans(15, weight: FontWeight.w600)),
                if (sub != null) Text(sub!, style: sans(12.5, color: pl.muted)),
              ]),
            ),
            ExcludeSemantics(child: HSwitch(value: value, onChanged: onChanged)),
          ]),
        ),
      ),
    );
  }
}

class Seg extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const Seg({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: pl.card2, borderRadius: BorderRadius.circular(Rad.control + 2)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == index,
              child: Material(
                color: i == index ? pl.card : Colors.transparent,
                borderRadius: BorderRadius.circular(Rad.control),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(labels[i],
                        textAlign: TextAlign.center,
                        style: sans(13,
                            weight: i == index ? FontWeight.w700 : FontWeight.w600,
                            color: i == index ? pl.green : pl.muted)),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class SpinRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const SpinRow({
    super.key,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    Widget btn(IconData ic, String tip, VoidCallback f) => Tooltip(
          message: tip,
          child: Semantics(
            button: true,
            label: tip,
            excludeSemantics: true,
            child: Material(
              color: pl.card2,
              borderRadius: BorderRadius.circular(Rad.control),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: f,
                child: SizedBox(width: 44, height: 44, child: Icon(ic, size: 22, color: pl.text)),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: sans(15))),
        btn(Icons.remove_rounded, 'Kurangi $label', onMinus),
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          alignment: Alignment.center,
          child: Text(value, style: sans(16, weight: FontWeight.w700)),
        ),
        btn(Icons.add_rounded, 'Tambah $label', onPlus),
      ]),
    );
  }
}

class HIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color? fill;
  final Color? color;
  const HIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.label = 'Tombol',
    this.fill,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: fill ?? pl.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rad.control + 2),
            side: BorderSide(color: pl.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
                width: 44, height: 44, child: Icon(icon, size: 22, color: color ?? pl.text)),
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final String? sub;
  const PageHeader(this.title, {super.key, this.onBack, this.sub});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        HIconBtn(
            icon: Icons.arrow_back_rounded,
            label: 'Kembali',
            onTap: onBack ?? () => Navigator.of(context).maybePop()),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            header: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: serif(22), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (sub != null) Text(sub!, style: sans(12.5, color: pl.muted)),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Judul bagian. [action] adalah tautan nyata ke halaman lain, bukan hiasan.
class H4 extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const H4(this.text, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(children: [
        Expanded(
          child: Semantics(
              header: true, child: Text(text, style: serif(18))),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: pl.green,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: sans(13, weight: FontWeight.w700),
            ),
            child: Text(action!),
          ),
      ]),
    );
  }
}

class Muted extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign? align;
  const Muted(this.text, {super.key, this.size = 14, this.align});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: align, style: sans(size, color: Pal.of(context).muted, height: 1.45));
}

// ===== Mushaf & ayat =====
/// Bingkai ganda emas, meniru garis tepi halaman mushaf cetak.
class Mushaf extends StatelessWidget {
  final Widget child;
  const Mushaf({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: pl.card,
        border: Border.all(color: pl.gold, width: 1.5),
        borderRadius: BorderRadius.circular(Rad.hero - 2),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: pl.line),
          borderRadius: BorderRadius.circular(Rad.hero - 7),
        ),
        child: child,
      ),
    );
  }
}

class AyatText extends StatelessWidget {
  final int s;
  final int from;
  final int to;
  final double? size;
  const AyatText({super.key, required this.s, required this.from, required this.to, this.size});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final sz = size ?? app.arabicSize;
        final spans = <InlineSpan>[];
        for (var n = from; n <= to; n++) {
          spans.add(TextSpan(text: '${surahs[s].a[n - 1]} '));
          spans.add(TextSpan(
              text: '\uFD3F$n\uFD3E ',
              style: TextStyle(fontSize: sz * .6, color: pl.goldInk)));
        }
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(children: spans, style: arabic(sz, color: pl.text, height: 2.1)),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

// ===== Gelombang suara =====
class Waveform extends StatefulWidget {
  final bool active;
  final ValueListenable<double>? level;
  const Waveform({super.key, required this.active, this.level});
  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant Waveform old) {
    super.didUpdateWidget(old);
    _sync();
  }

  // Gerak hanya berjalan saat merekam dan berhenti bila pengguna meminta kurangi animasi.
  void _sync() {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (widget.active && !reduce) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final lv = widget.level;
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_c, if (lv != null) lv]),
        builder: (context, _) => CustomPaint(
          painter: _WavePainter(_c.value, lv?.value ?? 0.5, widget.active,
              widget.active ? pl.green : pl.muted.withValues(alpha: .5)),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  final double lvl;
  final bool active;
  final Color color;
  _WavePainter(this.t, this.lvl, this.active, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 26;
    const gap = 3.0;
    final bw = math.min(5.0, (size.width - (n - 1) * gap) / n);
    final total = n * bw + (n - 1) * gap;
    var x = (size.width - total) / 2;
    final paint = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final wave = 0.5 + 0.5 * math.sin(t * 2 * math.pi + i * 0.5);
      final double h = active ? 12 + 52 * wave * (0.25 + 0.75 * lvl) : 12.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + bw / 2, size.height / 2), width: bw, height: h),
          const Radius.circular(3),
        ),
        paint,
      );
      x += bw + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.t != t || old.lvl != lvl || old.active != active || old.color != color;
}

// ===== Bottom sheet =====
class SheetAction {
  final String label;
  final VoidCallback onTap;
  final BK kind;
  const SheetAction(this.label, this.onTap, [this.kind = BK.fill]);
}

Future<void> showHSheet(
  BuildContext context, {
  required String title,
  String? body,
  Widget? extra,
  List<SheetAction> actions = const [],
}) {
  final pl = Pal.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: pl.card,
    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.hero))),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: serif(21)),
            if (body != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(body, style: sans(14.5, color: pl.muted, height: 1.5))),
            if (extra != null) extra,
            for (final a in actions)
              HButton(
                label: a.label,
                kind: a.kind,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  a.onTap();
                },
              ),
            if (actions.isEmpty)
              HButton(label: 'Tutup', onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
    ),
  );
}
