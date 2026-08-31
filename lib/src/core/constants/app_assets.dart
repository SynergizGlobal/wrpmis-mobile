/// Asset paths for WR-PMIS.
///
/// UI must only use [uiProductIcon]. Client logos under [internalDocumentClientLogo]
/// are reserved for generated documents / uploads — never show in screens, app bars,
/// login, splash, or store screenshots.
class AppAssets {
  const AppAssets._();

  /// Synergiz product mark shown in login, home app bar, and profile.
  static const String uiProductIcon = 'assets/app_icon_mark.png';

  /// Client logo for document generation only — do not use in UI.
  static const String internalDocumentClientLogo =
      'assets/internal/indian_railways_logo.png';
}
