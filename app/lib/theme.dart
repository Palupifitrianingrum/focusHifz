import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token warna HifzFlow. Semua pasangan teks/latar sudah dihitung kontrasnya (WCAG AA).
///
/// Palet inti: hijau tua (identitas), krem (kertas mushaf), emas (satu aksen).
/// Emas dipakai untuk penanda ayat, garis, dan satu tombol penting per layar,
/// tidak untuk teks kecil di atas krem (pakai [goldInk] bila perlu teks emas).
class Pal {
  final Color bg, card, card2, text, muted, line;
  final Color green, onGreen, green2, onHero;
  final Color gold, goldInk;
  final Color red, yellow, ok;
  final Color okBg, okFg, warnBg, warnFg, badBg, badFg;

  const Pal({
    required this.bg,
    required this.card,
    required this.card2,
    required this.text,
    required this.muted,
    required this.line,
    required this.green,
    required this.onGreen,
    required this.green2,
    required this.onHero,
    required this.gold,
    required this.goldInk,
    required this.red,
    required this.yellow,
    required this.ok,
    required this.okBg,
    required this.okFg,
    required this.warnBg,
    required this.warnFg,
    required this.badBg,
    required this.badFg,
  });

  static const Pal light = Pal(
    bg: Color(0xFFF6F0E2),
    card: Color(0xFFFFFDF7),
    card2: Color(0xFFEEE5CE),
    text: Color(0xFF1D2B26),
    muted: Color(0xFF56695F),
    line: Color(0xFFE3D8BD),
    green: Color(0xFF0F5C4A),
    onGreen: Color(0xFFFFFFFF),
    green2: Color(0xFF0A3D31),
    onHero: Color(0xFFEFE9D8),
    gold: Color(0xFFC9A24B),
    goldInk: Color(0xFF7A5A00),
    red: Color(0xFFB3301F),
    yellow: Color(0xFFB88A00),
    ok: Color(0xFF1E8E5A),
    okBg: Color(0xFFD5EFE1),
    okFg: Color(0xFF0B4A2D),
    warnBg: Color(0xFFFBEFC2),
    warnFg: Color(0xFF5E4600),
    badBg: Color(0xFFF6D6D2),
    badFg: Color(0xFF7A1D12),
  );

  static const Pal dark = Pal(
    bg: Color(0xFF0E1915),
    card: Color(0xFF16251F),
    card2: Color(0xFF1E3029),
    text: Color(0xFFEFE9D8),
    muted: Color(0xFFA8B9B0),
    line: Color(0xFF2A3D35),
    green: Color(0xFF3DB38F),
    onGreen: Color(0xFF06241B),
    green2: Color(0xFF0F3D31),
    onHero: Color(0xFFEFE9D8),
    gold: Color(0xFFD4B05A),
    goldInk: Color(0xFFD4B05A),
    red: Color(0xFFE0634F),
    yellow: Color(0xFFD9A400),
    ok: Color(0xFF3DB38F),
    okBg: Color(0xFF1B4A37),
    okFg: Color(0xFFBFEBD3),
    warnBg: Color(0xFF4A3B0A),
    warnFg: Color(0xFFF5E3A4),
    badBg: Color(0xFF5A211B),
    badFg: Color(0xFFF8C9C2),
  );

  static Pal of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Radius: hero 24, kartu 18, kontrol 12, penanda kecil 8. Hanya chip dan avatar
/// yang bundar penuh, supaya bentuk bundar tetap berarti.
class Rad {
  static const double hero = 24, card = 18, control = 12, tiny = 8;
}

/// Suara judul: Fraunces memberi kesan buku cetak yang hangat, cocok untuk teks
/// yang berdampingan dengan mushaf.
TextStyle serif(double size, {Color? color, FontWeight weight = FontWeight.w600}) =>
    GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color, height: 1.15);

/// Teks Arab: Amiri meniru kaligrafi naskh mushaf cetak dan mendukung harakat lengkap.
TextStyle arabic(double size, {Color? color, double height = 2.0, FontWeight? weight}) =>
    GoogleFonts.amiri(fontSize: size, height: height, color: color, fontWeight: weight);

/// Teks antarmuka: Plus Jakarta Sans punya bentuk huruf yang jelas untuk bahasa
/// Indonesia pada ukuran kecil.
TextStyle sans(double size,
        {Color? color, FontWeight weight = FontWeight.w500, double? height}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: weight, color: color, height: height);

ThemeData buildTheme(Brightness b) {
  final pl = b == Brightness.dark ? Pal.dark : Pal.light;
  final scheme = ColorScheme.fromSeed(seedColor: pl.green, brightness: b).copyWith(
    primary: pl.green,
    onPrimary: pl.onGreen,
    surface: pl.bg,
    onSurface: pl.text,
    error: pl.red,
  );
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    scaffoldBackgroundColor: pl.bg,
    colorScheme: scheme,
    focusColor: pl.green.withValues(alpha: .22),
  );
  final tt = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
      .apply(bodyColor: pl.text, displayColor: pl.text);
  return base.copyWith(
    textTheme: tt,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: pl.green2,
      contentTextStyle: sans(14, color: pl.onHero),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.control)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: pl.green,
      inactiveTrackColor: pl.line,
      thumbColor: pl.green,
      overlayColor: pl.green.withValues(alpha: .16),
      valueIndicatorColor: pl.green2,
      valueIndicatorTextStyle: sans(13, color: pl.onHero),
    ),
  );
}
