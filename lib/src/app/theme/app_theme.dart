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
    required this.cardSurface,
    required this.tableRowEven,
    required this.tableRowOdd,
    required this.stickyBar,
    required this.borderSubtle,
    required this.mutedText,
  });

  final Color loginBackground;
  final Color loginTitle;
  final Color loginSecondaryText;
  final Color actionLink;
  final Color loginButton;
  final Color avatarFill;
  final Color avatarText;
  final Color summaryCard;
  final Color cardSurface;
  final Color tableRowEven;
  final Color tableRowOdd;
  final Color stickyBar;
  final Color borderSubtle;
  final Color mutedText;

  static const AppPalette light = AppPalette(
    loginBackground: Color(0xFFD58D54),
    loginTitle: Color(0xFFFFFFFF),
    loginSecondaryText: Color(0xFFF5E6D8),
    actionLink: Color(0xFFFFFFFF),
    loginButton: Color(0xFFB87242),
    avatarFill: Color(0xFFF0DCC8),
    avatarText: Color(0xFF5C3317),
    summaryCard: Color(0xFFF3E0D0),
    cardSurface: Color(0xFFFFFFFF),
    tableRowEven: Color(0xFFF8E4D6),
    tableRowOdd: Color(0xFFFFFFFF),
    stickyBar: Color(0xFFFFFFFF),
    borderSubtle: Color(0x1A000000),
    mutedText: Color(0x99000000),
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
    cardSurface: Color(0xFF241C16),
    tableRowEven: Color(0xFF2E241C),
    tableRowOdd: Color(0xFF1C1612),
    stickyBar: Color(0xFF1C1612),
    borderSubtle: Color(0x33FFFFFF),
    mutedText: Color(0x99FFFFFF),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

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
    Color? cardSurface,
    Color? tableRowEven,
    Color? tableRowOdd,
    Color? stickyBar,
    Color? borderSubtle,
    Color? mutedText,
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
      cardSurface: cardSurface ?? this.cardSurface,
      tableRowEven: tableRowEven ?? this.tableRowEven,
      tableRowOdd: tableRowOdd ?? this.tableRowOdd,
      stickyBar: stickyBar ?? this.stickyBar,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      mutedText: mutedText ?? this.mutedText,
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
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      tableRowEven: Color.lerp(tableRowEven, other.tableRowEven, t)!,
      tableRowOdd: Color.lerp(tableRowOdd, other.tableRowOdd, t)!,
      stickyBar: Color.lerp(stickyBar, other.stickyBar, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  /// Primary brand — #D58D54 (rgb 213, 141, 84).
  static const Color brandPrimary = Color(0xFFD58D54);

  /// Slightly deeper ochre for app bars so the orange logo reads clearly on top.
  static const Color brandAppBar = Color(0xFFC47A48);
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
      onSurface: const Color(0xFF1C1410),
      surfaceContainerHighest: const Color(0xFFF3E0D0),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldLight,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F1EA),
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
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brandPrimary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandAppBar,
          side: const BorderSide(color: brandAppBar),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: brandAppBar,
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
      onPrimary: const Color(0xFF1C1410),
      secondary: const Color(0xFFFF8A80),
      surface: const Color(0xFF1C1612),
      onSurface: const Color(0xFFF5EBE3),
      surfaceContainerHighest: const Color(0xFF2E241C),
      outlineVariant: const Color(0xFF4A3A2E),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF14100D),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF241C16),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.85),
        ),
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
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.35),
          disabledForegroundColor:
              colorScheme.onPrimary.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.7)),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: brandAppBar,
        foregroundColor: Colors.white,
        toolbarHeight: 60,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: const Color(0xFF241C16),
      ),
      extensions: const <ThemeExtension<dynamic>>[AppPalette.dark],
    );
  }
}
