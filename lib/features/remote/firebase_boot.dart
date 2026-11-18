import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'remote_config_service.dart';

bool firebaseReady = false;

@pragma('vm:entry-point')
Future<void> _bgMessage(RemoteMessage m) async {} // notification messages are shown by Android itself

/// Starts Firebase. If google-services.json is missing the app still runs (all features no-op).
Future<void> bootFirebase() async {
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase not configured: $e');
    return;
  }
  // Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (e, s) { FirebaseCrashlytics.instance.recordError(e, s, fatal: true); return true; };
  // Push (FCM): everyone gets the "all" topic, so you can message all users from the console
  FirebaseMessaging.onBackgroundMessage(_bgMessage);
  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.subscribeToTopic('all');
  // Remote config
  await remoteConfig.init();
}

/// Analytics helper: track('play_media', {'ext': 'mp4'})
void track(String name, [Map<String, Object>? params]) {
  if (firebaseReady) FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
}
