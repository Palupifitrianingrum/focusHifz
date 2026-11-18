import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Arah desain: prototype Figma milik repo (HifzFlow_Semua_Halaman_Figma.html).
// Hijau tua = warna mushaf dan identitas utama, emas = aksen bingkai mushaf,
// krem = kertas mushaf. Fraunces untuk judul, Inter untuk teks UI, Amiri untuk ayat.
//
// Kontras sudah dihitung dengan rumus WCAG 2.x:
// - muted terang #4F6258: 5.79 di bg, 6.41 di kartu, 4.78 di latar segmen
// - goldInk terang #7D5F17 (nomor ayat): 5.30 di bg, 5.86 di kartu
// - tombol gelap: teks #0E1915 di hijau #2F9A7C = 5.16 (putih hanya 3.48, gagal)
class Pal {
  final Color bg, card, text, muted, line, green, green2, gold, goldInk, onAccent, focus, red, yellow, ok;
  const Pal({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.line,
    required this.green,
    required this.green2,
    required this.gold,
    required this.goldInk,
    required this.onAccent,
    required this.focus,
    required this.red,
    required this.yellow,
    required this.ok,
  });

  static const Pal light = Pal(
    bg: Color(0xFFF7F1E3),
    card: Color(0xFFFFFDF7),
    text: Color(0xFF1D2B26),
    // muted: Color(0xFF667A71), // lama: 4.06 di bg, gagal WCAG AA
    muted: Color(0xFF4F6258),
    line: Color(0xFFE6DCC3),
    green: Color(0xFF0F5C4A),
    green2: Color(0xFF0A3D31),
    gold: Color(0xFFC9A24B),
    goldInk: Color(0xFF7D5F17),
    onAccent: Colors.white,
    focus: Color(0xFF0A3D31), // cincin fokus: 11.97 di kartu, 10.81 di bg
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
    goldInk: Color(0xFFC9A24B),
    onAccent: Color(0xFF0E1915),
    focus: Color(0xFFE9C46A), // cincin fokus: 9.53 di kartu, 10.76 di bg
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

/// Tinggi minimum area sentuh (antislop R-03).
const double kTap = 44;

TextStyle serif(double size, {Color? color, FontWeight weight = FontWeight.w600}) =>
    GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color);

TextStyle arabic(double size, {Color? color, double height = 2.0, FontWeight? weight}) =>
    GoogleFonts.amiri(fontSize: size, height: height, color: color, fontWeight: weight);

/// Garis tepi tombol: tebal 3px saat difokus keyboard (antislop R-32, kontras >= 3:1).
WidgetStateProperty<BorderSide?> focusSide(Pal pl, [BorderSide? normal]) =>
    WidgetStateProperty.resolveWith<BorderSide?>(
        (s) => s.contains(WidgetState.focused) ? BorderSide(color: pl.focus, width: 3) : normal);

/// Inter untuk semua gaya teks Material.
///
/// Sengaja tidak memakai GoogleFonts.interTextTheme(): sejak Flutter 3.50 google_fonts 9
/// memakai TextTheme dari paket material_ui, beda tipe dengan TextTheme Flutter, sehingga
/// build gagal. GoogleFonts.inter(textStyle:) hanya menukar TextStyle, jadi aman di
/// google_fonts versi lama maupun baru.
TextTheme interTextTheme(TextTheme t) {
  TextStyle? f(TextStyle? s) => s == null ? null : GoogleFonts.inter(textStyle: s);
  return t.copyWith(
    displayLarge: f(t.displayLarge),
    displayMedium: f(t.displayMedium),
    displaySmall: f(t.displaySmall),
    headlineLarge: f(t.headlineLarge),
    headlineMedium: f(t.headlineMedium),
    headlineSmall: f(t.headlineSmall),
    titleLarge: f(t.titleLarge),
    titleMedium: f(t.titleMedium),
    titleSmall: f(t.titleSmall),
    bodyLarge: f(t.bodyLarge),
    bodyMedium: f(t.bodyMedium),
    bodySmall: f(t.bodySmall),
    labelLarge: f(t.labelLarge),
    labelMedium: f(t.labelMedium),
    labelSmall: f(t.labelSmall),
  );
}

ThemeData buildTheme(Brightness b) {
  final pl = b == Brightness.dark ? Pal.dark : Pal.light;
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    scaffoldBackgroundColor: pl.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: pl.green, brightness: b).copyWith(
      primary: pl.green,
      onPrimary: pl.onAccent,
      surface: pl.bg,
      secondary: pl.gold,
    ),
    // Isian lembut saat fokus. Kontras 3:1 dipenuhi oleh cincin fokus (FocusRing / focusSide),
    // isian ini hanya penanda tambahan.
    focusColor: pl.gold.withValues(alpha: .25),
  );
  return base.copyWith(
    // Teks UI pakai Inter, mengikuti prototype Figma.
    // textTheme: GoogleFonts.interTextTheme(base.textTheme)
    //     .apply(bodyColor: pl.text, displayColor: pl.text), // gagal build di Flutter 3.50
    textTheme: interTextTheme(base.textTheme).apply(bodyColor: pl.text, displayColor: pl.text),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    filledButtonTheme: FilledButtonThemeData(style: ButtonStyle(side: focusSide(pl))),
    textButtonTheme: TextButtonThemeData(style: ButtonStyle(side: focusSide(pl))),
    iconButtonTheme: IconButtonThemeData(style: ButtonStyle(side: focusSide(pl))),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: pl.green),
    // Warna label tab bawah ditetapkan sendiri supaya kontrasnya terukur:
    // terpilih hijau (7.79 terang / 4.58 gelap), lainnya muted (6.41 / 7.02).
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((s) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected) ? pl.green : pl.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? pl.green : pl.muted,
          )),
    ),
  );
}
