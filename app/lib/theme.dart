import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Pal {
  final Color bg, card, text, muted, line, green, green2, gold, red, yellow, ok;
  const Pal({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.line,
    required this.green,
    required this.green2,
    required this.gold,
    required this.red,
    required this.yellow,
    required this.ok,
  });

  static const Pal light = Pal(
    bg: Color(0xFFF7F1E3),
    card: Color(0xFFFFFDF7),
    text: Color(0xFF1D2B26),
    muted: Color(0xFF667A71),
    line: Color(0xFFE6DCC3),
    green: Color(0xFF0F5C4A),
    green2: Color(0xFF0A3D31),
    gold: Color(0xFFC9A24B),
    red: Color(0xFFC0392B),
    yellow: Color(0xFFD9A400),
    ok: Color(0xFF1E8E5A),
  );

  static const Pal dark = Pal(
    bg: Color(0xFF0E1915),
    card: Color(0xFF16251F),
    text: Color(0xFFEFE9D8),
    muted: Color(0xFF9FB0A8),
    line: Color(0xFF2A3D35),
    green: Color(0xFF2F9A7C),
    green2: Color(0xFF0A3D31),
    gold: Color(0xFFC9A24B),
    red: Color(0xFFC0392B),
    yellow: Color(0xFFD9A400),
    ok: Color(0xFF1E8E5A),
  );

  static Pal of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

const Color kOkBg = Color(0xFFD5EFE1);
const Color kOkFg = Color(0xFF0F5A37);
const Color kWarnBg = Color(0xFFFBEFC2);
const Color kWarnFg = Color(0xFF7A5A00);
const Color kBadBg = Color(0xFFF6D6D2);
const Color kBadFg = Color(0xFF8E2418);

TextStyle serif(double size, {Color? color, FontWeight weight = FontWeight.w600}) =>
    GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color);

TextStyle arabic(double size, {Color? color, double height = 2.0, FontWeight? weight}) =>
    GoogleFonts.amiri(fontSize: size, height: height, color: color, fontWeight: weight);

ThemeData buildTheme(Brightness b) {
  final pl = b == Brightness.dark ? Pal.dark : Pal.light;
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    scaffoldBackgroundColor: pl.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: pl.green, brightness: b)
        .copyWith(primary: pl.green, surface: pl.bg),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: pl.text, displayColor: pl.text),
  );
}
