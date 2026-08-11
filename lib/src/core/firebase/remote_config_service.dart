import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wr_pmis_mobile/src/core/firebase/remote_config_keys.dart';
import 'package:wr_pmis_mobile/src/core/firebase/version_compare.dart';

final remoteConfigServiceProvider = Provider<RemoteConfigService>((Ref ref) {
  return RemoteConfigService(FirebaseRemoteConfig.instance);
});

enum AppUpdateKind { none, optional, force }

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.kind,
    required this.installedVersion,
    required this.minVersion,
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.message,
    required this.storeUrl,
  });

  final AppUpdateKind kind;
  final String installedVersion;
  final String minVersion;
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String message;
  final String storeUrl;

  bool get requiresUpdate => kind != AppUpdateKind.none;
  bool get isForce => kind == AppUpdateKind.force;
}

class RemoteConfigService {
  RemoteConfigService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  static const Map<String, dynamic> _defaults = <String, dynamic>{
    RemoteConfigKeys.minVersion: '1.0.0',
    RemoteConfigKeys.currentVersion: '1.0.0',
    RemoteConfigKeys.latestVersion: '1.0.0',
    RemoteConfigKeys.updateTitle: 'Update Available',
    RemoteConfigKeys.updateMessage:
        'A new version of WR PMIS is available. Please update to continue.',
    RemoteConfigKeys.forceUpdate: false,
    RemoteConfigKeys.optionalUpdate: false,
    RemoteConfigKeys.androidPackageName: 'com.synergiz.wr.pmis',
    RemoteConfigKeys.iosAppStoreId: '',
  };

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(hours: 12),
      ),
    );
    await _remoteConfig.setDefaults(_defaults);
    try {
      await _remoteConfig.activate();
      await _remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      debugPrint('Remote Config fetch failed: $error');
      debugPrint('$stackTrace');
    }
  }

  String get minVersion =>
      _remoteConfig.getString(RemoteConfigKeys.minVersion).trim();

  String get currentVersion =>
      _remoteConfig.getString(RemoteConfigKeys.currentVersion).trim();

  String get latestVersion =>
      _remoteConfig.getString(RemoteConfigKeys.latestVersion).trim();

  String get updateTitle {
    final String value =
        _remoteConfig.getString(RemoteConfigKeys.updateTitle).trim();
    return value.isEmpty ? 'Update Available' : value;
  }

  String get updateMessage {
    final String value =
        _remoteConfig.getString(RemoteConfigKeys.updateMessage).trim();
    return value.isEmpty
        ? 'A new version of WR PMIS is available. Please update to continue.'
        : value;
  }

  bool get forceUpdate =>
      _remoteConfig.getBool(RemoteConfigKeys.forceUpdate);

  bool get optionalUpdate =>
      _remoteConfig.getBool(RemoteConfigKeys.optionalUpdate);

  String get androidPackageName {
    final String value =
        _remoteConfig.getString(RemoteConfigKeys.androidPackageName).trim();
    return value.isEmpty ? 'com.synergiz.wr.pmis' : value;
  }

  String get iosAppStoreId =>
      _remoteConfig.getString(RemoteConfigKeys.iosAppStoreId).trim();

  /// Builds a launchable store URL from package name / App Store ID.
  String get storeUrl {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isIOS) {
      return _iosStoreUrl(iosAppStoreId);
    }
    return _androidStoreUrl(androidPackageName);
  }

  static String _androidStoreUrl(String packageName) {
    final String id = packageName.trim();
    if (id.isEmpty) {
      return '';
    }
    if (id.startsWith('http://') || id.startsWith('https://')) {
      return id;
    }
    return 'https://play.google.com/store/apps/details?id=$id';
  }

  static String _iosStoreUrl(String appStoreId) {
    final String raw = appStoreId.trim();
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final String id = raw.replaceFirst(RegExp(r'^id', caseSensitive: false), '');
    if (id.isEmpty || int.tryParse(id) == null) {
      return '';
    }
    return 'https://apps.apple.com/app/id$id';
  }

  Future<AppUpdateInfo> evaluateUpdate() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String installed = packageInfo.version.trim();
    final String min = minVersion.isEmpty ? '1.0.0' : minVersion;
    final String current = currentVersion.isEmpty ? installed : currentVersion;
    final String latest = latestVersion.isEmpty ? installed : latestVersion;

    final bool belowMin = VersionCompare.isLower(installed, min);
    final bool belowLatest = VersionCompare.isLower(installed, latest);

    AppUpdateKind kind = AppUpdateKind.none;
    if (belowMin || (forceUpdate && belowLatest)) {
      kind = AppUpdateKind.force;
    } else if (optionalUpdate && belowLatest) {
      kind = AppUpdateKind.optional;
    }

    return AppUpdateInfo(
      kind: kind,
      installedVersion: installed,
      minVersion: min,
      currentVersion: current,
      latestVersion: latest,
      title: updateTitle,
      message: updateMessage,
      storeUrl: storeUrl,
    );
  }

  String getString(String key) => _remoteConfig.getString(key);

  bool getBool(String key) => _remoteConfig.getBool(key);

  int getInt(String key) => _remoteConfig.getInt(key);

  double getDouble(String key) => _remoteConfig.getDouble(key);
}
