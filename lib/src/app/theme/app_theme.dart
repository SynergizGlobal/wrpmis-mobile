import 'package:flutter/material.dart';

/// Western Railways brand palette — warm ochre/tan (distinct from WCR purple).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.loginBackground,
    required this.loginTitle,
    required this.loginSecondaryText,
    required this.actionLink,
    required this.loginButton,
    required this.avatarFill,
    required this.avatarText,
    required this.summaryCard,
  });

  final Color loginBackground;
  final Color loginTitle;
  final Color loginSecondaryText;
  final Color actionLink;
  final Color loginButton;
  final Color avatarFill;
  final Color avatarText;
  final Color summaryCard;

  static const AppPalette light = AppPalette(
    loginBackground: Color(0xFFD58D54),
    loginTitle: Color(0xFFFFFFFF),
    loginSecondaryText: Color(0xFFF5E6D8),
    actionLink: Color(0xFFFFFFFF),
    loginButton: Color(0xFFB87242),
    avatarFill: Color(0xFFF0DCC8),
    avatarText: Color(0xFF5C3317),
    summaryCard: Color(0xFFF3E0D0),
  );

  static const AppPalette dark = AppPalette(
    loginBackground: Color(0xFFD58D54),
    loginTitle: Color(0xFFF8EDE3),
    loginSecondaryText: Color(0xFFD4B8A0),
    actionLink: Color(0xFFE8B88A),
    loginButton: Color(0xFFD58D54),
    avatarFill: Color(0xFF3D2A1E),
    avatarText: Color(0xFFF8EDE3),
    summaryCard: Color(0xFF3D2A1E),
  );

  @override
  AppPalette copyWith({
    Color? loginBackground,
    Color? loginTitle,
    Color? loginSecondaryText,
    Color? actionLink,
    Color? loginButton,
    Color? avatarFill,
    Color? avatarText,
    Color? summaryCard,
  }) {
    return AppPalette(
      loginBackground: loginBackground ?? this.loginBackground,
      loginTitle: loginTitle ?? this.loginTitle,
      loginSecondaryText: loginSecondaryText ?? this.loginSecondaryText,
      actionLink: actionLink ?? this.actionLink,
      loginButton: loginButton ?? this.loginButton,
      avatarFill: avatarFill ?? this.avatarFill,
      avatarText: avatarText ?? this.avatarText,
      summaryCard: summaryCard ?? this.summaryCard,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      loginBackground: Color.lerp(loginBackground, other.loginBackground, t)!,
      loginTitle: Color.lerp(loginTitle, other.loginTitle, t)!,
      loginSecondaryText:
          Color.lerp(loginSecondaryText, other.loginSecondaryText, t)!,
      actionLink: Color.lerp(actionLink, other.actionLink, t)!,
      loginButton: Color.lerp(loginButton, other.loginButton, t)!,
      avatarFill: Color.lerp(avatarFill, other.avatarFill, t)!,
      avatarText: Color.lerp(avatarText, other.avatarText, t)!,
      summaryCard: Color.lerp(summaryCard, other.summaryCard, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  /// Primary brand — #D58D54 (rgb 213, 141, 84).
  static const Color brandPrimary = Color(0xFFD58D54);
  static const Color brandAccent = Color(0xFFD71920);
  static const Color scaffoldLight = Color(0xFFFFEFE2);

  static ThemeData get light {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
    ).copyWith(
      primary: brandPrimary,
      onPrimary: Colors.white,
      secondary: brandAccent,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldLight,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F5FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        toolbarHeight: 60,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: Colors.white,
      ),
      extensions: const <ThemeExtension<dynamic>>[AppPalette.light],
    );
  }

  static ThemeData get dark {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFE0A06A),
      onPrimary: Colors.black,
      secondary: const Color(0xFFFF6B6B),
      surface: const Color(0xFF1C1612),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF14100D),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF241C16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 60,
        elevation: 4,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const <ThemeExtension<dynamic>>[AppPalette.dark],
    );
  }
}
