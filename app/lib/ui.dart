import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'data.dart';
import 'murottal.dart';
import 'quran_api.dart';
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
    ..showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
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
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: border ?? pl.line),
    );
    final card = Material(
      color: color ?? pl.card,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    return Padding(
      padding: margin,
      child: onTap == null ? card : FocusRing(radius: 16, child: card),
    );
  }
}

class NavCard extends StatelessWidget {
  final String title;
  final String sub;
  final VoidCallback onTap;
  // final String? emoji; // emoji diganti ikon: tampil beda di tiap HP dan tidak punya label (antislop R-04)
  final IconData? icon;
  final Color? border;
  final String? trailing;
  const NavCard({
    super.key,
    required this.title,
    required this.sub,
    required this.onTap,
    this.icon,
    this.border,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return HCard(
      onTap: onTap,
      border: border,
      child: Row(children: [
        if (icon != null) ...[
          IconBadge(icon!),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: pl.muted, fontSize: 14)),
          ]),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Bdg(trailing!),
        ],
        ExcludeSemantics(child: Icon(Icons.chevron_right, color: pl.muted)),
      ]),
    );
  }
}

/// Ikon di dalam kotak hijau muda. Motif identitas: bentuk kotak bersudut 12
/// sama dengan tombol ikon dan nomor surah, supaya ikon tidak terlihat "lepas".
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  const IconBadge(this.icon, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: pl.green.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: pl.green, size: size * .55),
    );
  }
}

// ===== Tombol =====
enum BK { fill, outline, gold, red }

class HButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BK kind;
  const HButton({super.key, required this.label, this.onPressed, this.kind = BK.fill});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    Color bg;
    Color fg;
    switch (kind) {
      case BK.fill:
        bg = pl.green;
        fg = pl.onAccent; // tema gelap: teks gelap, putih hanya 3.48:1 di hijau terang
        break;
      case BK.gold:
        bg = pl.gold;
        fg = const Color(0xFF2A2108);
        break;
      case BK.red:
        bg = pl.red;
        fg = Colors.white;
        break;
      case BK.outline:
        bg = Colors.transparent;
        fg = pl.green;
        break;
    }
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const pad = EdgeInsets.symmetric(vertical: 14, horizontal: 16);
    const minSize = Size(0, 48);
    const ts = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
    final Widget btn;
    if (kind == BK.outline) {
      btn = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          disabledForegroundColor: fg.withValues(alpha: .4),
          side: BorderSide(color: onPressed == null ? fg.withValues(alpha: .4) : fg, width: 1.5),
          padding: pad,
          minimumSize: minSize,
          shape: shape,
          textStyle: ts,
        ).copyWith(
          side: focusSide(
              pl, BorderSide(color: onPressed == null ? fg.withValues(alpha: .4) : fg, width: 1.5)),
        ),
        child: Text(label, textAlign: TextAlign.center),
      );
    } else {
      btn = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: .4),
          disabledForegroundColor: fg.withValues(alpha: .8),
          padding: pad,
          minimumSize: minSize,
          shape: shape,
          textStyle: ts,
        ).copyWith(side: focusSide(pl)),
        child: Text(label, textAlign: TextAlign.center),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(width: double.infinity, child: btn),
    );
  }
}

class HChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const HChip({super.key, required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(99),
      side: BorderSide(color: on ? pl.green : pl.line, width: 1.5),
    );
    // Dulu GestureDetector tinggi ~34px tanpa peran tombol; sekarang tombol asli,
    // tinggi minimal 44px, bisa difokus keyboard, dan status terpilih dibacakan.
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: Semantics(
        button: true,
        selected: on,
        child: FocusRing(
          radius: 99,
          child: Material(
          color: on ? pl.green : pl.card,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kTap),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: on ? pl.onAccent : pl.text)),
                ]),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class Bdg extends StatelessWidget {
  final String text;
  final String kind; // g | y | r | ''
  const Bdg(this.text, {super.key, this.kind = ''});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    Color bg = pl.line, fg = pl.text;
    if (kind == 'g') {
      bg = kOkBg;
      fg = kOkFg;
    } else if (kind == 'y') {
      bg = kWarnBg;
      fg = kWarnFg;
    } else if (kind == 'r') {
      bg = kBadBg;
      fg = kBadFg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class HBar extends StatelessWidget {
  final double value;
  const HBar(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 8,
          color: pl.line,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clampD(value, 0, 1),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [pl.green, pl.gold]),
              ),
            ),
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
  const Ring({super.key, required this.progress, required this.label, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(clampD(progress, 0, 1), pl.line, pl.gold),
        child: Center(
          child: Text(label,
              style: TextStyle(fontSize: size > 120 ? 30 : 20, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double p;
  final Color track, color;
  _RingPainter(this.p, this.track, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
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
      old.p != p || old.track != track || old.color != color;
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
      thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
      trackColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? pl.green : pl.line),
      trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: pl.line, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == index,
              child: FocusRing(
                radius: 11,
                child: Material(
                color: i == index ? pl.card : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => onChanged(i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: kTap),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text(labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: i == index ? pl.green : pl.muted)),
                  ),
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
    Widget btn(IconData ic, String name, VoidCallback f) {
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: pl.line),
      );
      return Tooltip(
        message: name,
        child: FocusRing(
          radius: 12,
          child: Material(
            color: pl.card,
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: f,
              child: SizedBox(
                width: kTap,
                height: kTap,
                child: Icon(ic, size: 20, color: pl.text, semanticLabel: name),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(label)),
        btn(Icons.remove, 'Kurangi $label', onMinus),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        btn(Icons.add, 'Tambah $label', onPlus),
      ]),
    );
  }
}

class HIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// Nama tombol untuk pembaca layar dan tooltip (tombol ikon wajib punya nama).
  final String label;
  const HIconBtn({super.key, required this.icon, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: pl.line),
    );
    return Tooltip(
      message: label,
      child: FocusRing(
        radius: 12,
        child: Material(
          color: pl.card,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: SizedBox(
              width: kTap,
              height: kTap,
              child: Icon(icon, size: 22, color: pl.text, semanticLabel: label),
            ),
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  const PageHeader(this.title, {super.key, this.onBack, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        HIconBtn(
            icon: Icons.chevron_left,
            label: 'Kembali',
            onTap: onBack ?? () => Navigator.of(context).maybePop()),
        const SizedBox(width: 10),
        Expanded(child: Semantics(header: true, child: Text(title, style: serif(19)))),
        ...actions,
      ]),
    );
  }
}

class H4 extends StatelessWidget {
  final String text;
  const H4(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Semantics(
          header: true,
          child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
}

class Muted extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign? align;
  const Muted(this.text, {super.key, this.size = 14, this.align});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: align, style: TextStyle(color: Pal.of(context).muted, fontSize: size));
}

// ===== Mushaf & ayat =====
class Mushaf extends StatelessWidget {
  final Widget child;
  const Mushaf({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pl.bg,
        border: Border.all(color: pl.gold, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(color: pl.card, borderRadius: BorderRadius.circular(14)),
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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Animasi gelombang berhenti bila pengguna mematikan animasi di pengaturan HP.
    final still = MediaQuery.of(context).disableAnimations;
    if (still && _c.isAnimating) _c.stop();
    if (!still && !_c.isAnimating) _c.repeat();
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
          painter: _WavePainter(_c.value, lv?.value ?? 0.5, widget.active, pl.green),
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
    const bw = 5.0;
    const gap = 3.0;
    const total = n * bw + (n - 1) * gap;
    var x = (size.width - total) / 2;
    final paint = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final wave = 0.5 + 0.5 * math.sin(t * 2 * math.pi + i * 0.5);
      final double h = active ? 12 + 52 * wave * (0.25 + 0.75 * lvl) : 12.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + bw / 2, size.height / 2), width: bw, height: h),
          const Radius.circular(4),
        ),
        paint,
      );
      x += bw + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => true;
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
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Pal.of(context).card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: serif(19)),
            if (body != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(body)),
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

// ===== Status data: memuat, kosong, gagal (antislop R-27) =====
class LoadingState extends StatelessWidget {
  final String text;
  const LoadingState(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Semantics(
        liveRegion: true,
        child: Column(children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(height: 12),
          Muted(text, align: TextAlign.center),
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        child: Muted(text, align: TextAlign.center),
      );
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return HCard(
      color: kBadBg,
      border: pl.red,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.error_outline, color: kBadFg, size: 20),
          SizedBox(width: 8),
          Text('Gagal memuat', style: TextStyle(color: kBadFg, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Semantics(
          liveRegion: true,
          child: Text(message, style: const TextStyle(color: kBadFg)),
        ),
        if (onRetry != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kBadFg,
                  side: const BorderSide(color: kBadFg, width: 1.5),
                  minimumSize: const Size(0, kTap),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ).copyWith(side: focusSide(pl, const BorderSide(color: kBadFg, width: 1.5))),
                child: const Text('Coba lagi'),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Tombol kecil di dalam kartu (Ganti, Hapus). Tinggi tetap 44px.
class SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final IconData? icon;
  const SmallButton({super.key, required this.label, this.onPressed, this.danger = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final fg = danger ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFF8A80) : kBadFg) : pl.green;
    final style = OutlinedButton.styleFrom(
      foregroundColor: fg,
      side: BorderSide(color: fg, width: 1.5),
      minimumSize: const Size(0, kTap),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ).copyWith(side: focusSide(pl, BorderSide(color: fg, width: 1.5)));
    if (icon != null) {
      return OutlinedButton.icon(
          onPressed: onPressed, style: style, icon: Icon(icon, size: 18), label: Text(label));
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

class SearchField extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: 1.5),
        );
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: pl.muted),
        prefixIcon: Icon(Icons.search, color: pl.muted),
        filled: true,
        fillColor: pl.card,
        border: b(pl.line),
        enabledBorder: b(pl.line),
        focusedBorder: b(pl.green),
      ),
    );
  }
}

/// Nomor surah dalam bingkai belah ketupat emas: motif bingkai mushaf yang sama
/// dengan garis emas di kartu ayat. Dipakai di daftar surah.
class SurahNumber extends StatelessWidget {
  final int n;
  final double size;
  const SurahNumber(this.n, {super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size * .7,
            height: size * .7,
            decoration: BoxDecoration(
              border: Border.all(color: pl.gold, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Text('$n',
            style: TextStyle(fontSize: n > 99 ? 12 : 13, fontWeight: FontWeight.w700, color: pl.text)),
      ]),
    );
  }
}

// ===== Pemutar murottal mini (tampil di bawah layar selama audio berjalan) =====
class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        murottal.current,
        murottal.playing,
        murottal.loading,
        murottal.error,
        app,
      ]),
      builder: (context, _) {
        final cur = murottal.current.value;
        final err = murottal.error.value;
        if (cur == null && err == null) return const SizedBox.shrink();
        Widget body;
        if (cur == null) {
          body = Row(children: [
            const Icon(Icons.error_outline, color: kBadFg),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(err!, style: const TextStyle(color: kBadFg, fontSize: 13)),
              ),
            ),
            IconButton(
              tooltip: 'Tutup pesan',
              onPressed: () => murottal.error.value = null,
              icon: const Icon(Icons.close, color: kBadFg),
            ),
          ]);
          return Material(
            color: kBadBg,
            child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 6, 6, 6), child: body)),
          );
        }
        final name = QuranApi.chapterSync(cur.s)?.name ?? 'Surah ${cur.s}';
        final what = cur.isBasmalah ? 'Basmalah' : 'Ayat ${cur.a}';
        body = Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('$name · $what',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(murottal.loading.value ? 'Memuat audio…' : app.reciterName,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: pl.muted, fontSize: 13)),
            ]),
          ),
          IconButton(
            tooltip: 'Ayat sebelumnya',
            onPressed: () => murottal.skip(-1),
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton.filled(
            tooltip: murottal.playing.value ? 'Jeda' : 'Putar',
            style: IconButton.styleFrom(backgroundColor: pl.green, foregroundColor: pl.onAccent),
            onPressed: murottal.toggle,
            icon: Icon(murottal.playing.value ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Ayat berikutnya',
            onPressed: () => murottal.skip(1),
            icon: const Icon(Icons.skip_next),
          ),
          IconButton(
            tooltip: 'Hentikan murottal',
            onPressed: () => murottal.stop(),
            icon: const Icon(Icons.stop),
          ),
        ]);
        return Material(
          color: pl.card,
          child: Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: pl.gold, width: 2))),
            child: SafeArea(
              top: false,
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 4, 4), child: body),
            ),
          ),
        );
      },
    );
  }
}

/// Cincin fokus keyboard 3px untuk kontrol buatan sendiri (InkWell).
/// Hanya tampil saat navigasi pakai keyboard, tidak saat disentuh (antislop R-32).
class FocusRing extends StatefulWidget {
  final Widget child;
  final double radius;
  const FocusRing({super.key, required this.child, this.radius = 14});
  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) {
        final kb = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
        if (mounted) setState(() => _on = f && kb);
      },
      child: Container(
        foregroundDecoration: _on
            ? BoxDecoration(
                border: Border.all(color: pl.focus, width: 3),
                borderRadius: BorderRadius.circular(widget.radius),
              )
            : null,
        child: widget.child,
      ),
    );
  }
}
