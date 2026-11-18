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
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? pl.card,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class NavCard extends StatelessWidget {
  final String title;
  final String sub;
  final VoidCallback onTap;
  final String? emoji;
  final Color? border;
  const NavCard({
    super.key,
    required this.title,
    required this.sub,
    required this.onTap,
    this.emoji,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return HCard(
      onTap: onTap,
      border: border,
      child: Row(children: [
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: pl.muted, fontSize: 14)),
          ]),
        ),
        Text('›', style: TextStyle(fontSize: 22, color: pl.muted)),
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
  const HButton({super.key, required this.label, this.onPressed, this.kind = BK.fill});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    Color bg;
    Color fg;
    switch (kind) {
      case BK.fill:
        bg = pl.green;
        fg = Colors.white;
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
          shape: shape,
          textStyle: ts,
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
          shape: shape,
          textStyle: ts,
        ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? pl.green : pl.card,
            border: Border.all(color: on ? pl.green : pl.line, width: 1.5),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: on ? Colors.white : pl.text)),
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
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: i == index ? pl.card : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: i == index ? pl.green : pl.muted)),
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
    Widget btn(String t, VoidCallback f) => GestureDetector(
          onTap: f,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pl.card,
              border: Border.all(color: pl.line),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(t, style: const TextStyle(fontSize: 18)),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(label)),
        btn('−', onMinus),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        btn('+', onPlus),
      ]),
    );
  }
}

class HIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const HIconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: pl.card,
          border: Border.all(color: pl.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: pl.text),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const PageHeader(this.title, {super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        HIconBtn(
            icon: Icons.chevron_left,
            onTap: onBack ?? () => Navigator.of(context).maybePop()),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: serif(19))),
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
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
              style: TextStyle(fontSize: sz * .6, color: pl.gold)));
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
