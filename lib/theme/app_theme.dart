import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // biru lebih cerah untuk kesan fresh
  static const _seed = Color(0xFF1565C0);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    // background lembut (bukan putih polos)
    scaffoldBackgroundColor: const Color(0xFFF3F8FF),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
        .apply(bodyColor: _lightScheme.onBackground),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightScheme.primary,
      foregroundColor: _lightScheme.onPrimary,
      elevation: 0,
      centerTitle: true,
    ),

    // ICON
    iconTheme: IconThemeData(color: _lightScheme.primary),

    // CARD sebagai "bubble"
    cardTheme: CardThemeData(
      elevation: 8,
      shadowColor: _lightScheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: _lightScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
    ),

    // INPUT seperti bubble
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightScheme.primary.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),

    // BUTTONS bulat
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightScheme.primary,
        foregroundColor: _lightScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(_lightScheme.primary),
        foregroundColor: MaterialStateProperty.all(_lightScheme.onPrimary),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _lightScheme.primary),
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _lightScheme.primary,
      foregroundColor: _lightScheme.onPrimary,
      elevation: 6,
    ),

    // SNACKBAR
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightScheme.primary,
      contentTextStyle: TextStyle(color: _lightScheme.onPrimary),
      behavior: SnackBarBehavior.floating,
    ),

    // List tile ringan
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightScheme.surface,
      selectedItemColor: _lightScheme.primary,
      unselectedItemColor: _lightScheme.onSurface.withOpacity(0.6),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: const Color(0xFF071428),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: _darkScheme.onBackground),
    appBarTheme: AppBarTheme(
      backgroundColor: _dark_scheme_primary(_darkScheme),
      foregroundColor: _darkScheme.onPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    iconTheme: IconThemeData(color: _darkScheme.primary),
    cardTheme: CardThemeData(
      elevation: 6,
      shadowColor: _darkScheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: _darkScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkScheme.surfaceVariant.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkScheme.primary,
        foregroundColor: _darkScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(_darkScheme.primary),
        foregroundColor: MaterialStateProperty.all(_darkScheme.onPrimary),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _darkScheme.primary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _darkScheme.primary,
      foregroundColor: _darkScheme.onPrimary,
      elevation: 4,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkScheme.surfaceVariant,
      contentTextStyle: TextStyle(color: _darkScheme.onSurface),
      behavior: SnackBarBehavior.floating,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkScheme.surface,
      selectedItemColor: _darkScheme.primary,
      unselectedItemColor: _darkScheme.onSurface.withOpacity(0.6),
    ),
  );
}

// helper fallback untuk beberapa versi SDK yang mungkin butuh Color
Color _dark_scheme_primary(ColorScheme s) => s.primary;
