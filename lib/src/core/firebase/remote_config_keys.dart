class RemoteConfigKeys {
  const RemoteConfigKeys._();

  static const String minVersion = 'min_version';
  static const String currentVersion = 'current_version';
  static const String latestVersion = 'latest_version';
  static const String updateTitle = 'update_title';
  static const String updateMessage = 'update_message';
  static const String forceUpdate = 'force_update';
  static const String optionalUpdate = 'optional_update';

  /// Play Store package name, e.g. com.synergiz.wr.pmis
  static const String androidPackageName = 'android_package_name';

  /// Numeric App Store ID only, e.g. 6505123456
  static const String iosAppStoreId = 'ios_app_store_id';
}
