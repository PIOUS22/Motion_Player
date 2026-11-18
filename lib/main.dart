import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'core/playback_handler.dart';
import 'core/theme.dart';
import 'features/ads/ad_banner.dart';
import 'features/remote/app_gate.dart';
import 'features/remote/firebase_boot.dart';
import 'features/update/update_service.dart';
import 'features/library/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await bootFirebase();   // crash reports, analytics, push, remote config (safe if not configured)
  await initAds();
  await initAudio();
  await updateService.init();
  runApp(const ProviderScope(child: MotionPlayerApp()));
}

class MotionPlayerApp extends StatelessWidget {
  const MotionPlayerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Motion Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AppGate(child: HomeShell()),
      );
}
