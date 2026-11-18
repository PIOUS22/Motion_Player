import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../update/update_service.dart';

/// Values you control from Firebase Console > Remote Config (no new release needed):
///   min_version (e.g. "1.2.0")  -> older versions are forced to update
///   kill_switch (true/false)    -> blocks the app, shows kill_message
///   kill_message, announcement, announcement_id, ads_enabled, feature_vault, feature_equalizer
class RemoteConfigService extends ChangeNotifier {
  String currentVersion = '0.0.0';
  bool ready = false;

  static const _defaults = {
    'min_version': '0.0.0',
    'kill_switch': false,
    'kill_message': 'This version is disabled. Please update.',
    'announcement': '',
    'announcement_id': '0',
    'ads_enabled': true,
    'feature_vault': true,
    'feature_equalizer': true,
  };

  Future<void> init() async {
    currentVersion = (await PackageInfo.fromPlatform()).version;
    final rc = FirebaseRemoteConfig.instance;
    await rc.setDefaults(_defaults);
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
    ));
    try { await rc.fetchAndActivate(); } catch (_) {}
    ready = true;
    notifyListeners();
    // Live updates: changes published in the console apply while the app is open
    rc.onConfigUpdated.listen((_) async { await rc.activate(); notifyListeners(); });
  }

  FirebaseRemoteConfig? get _rc { try { return ready ? FirebaseRemoteConfig.instance : null; } catch (_) { return null; } }
  bool _b(String k) => _rc?.getBool(k) ?? (_defaults[k] as bool);
  String _s(String k) => _rc?.getString(k) ?? '${_defaults[k]}';

  bool get killSwitch => _b('kill_switch');
  String get killMessage => _s('kill_message');
  String get minVersion => _s('min_version');
  bool get forceUpdate => versionIsNewer(minVersion, currentVersion);
  String get announcement => _s('announcement');
  String get announcementId => _s('announcement_id');
  bool get adsEnabled => _b('ads_enabled');
  bool get vaultEnabled => _b('feature_vault');
  bool get equalizerEnabled => _b('feature_equalizer');
}

final remoteConfig = RemoteConfigService();
