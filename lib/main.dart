import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'core/playback_handler.dart';
import 'core/theme.dart';
import 'features/library/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await initAudio();
  runApp(const ProviderScope(child: MotionPlayerApp()));
}

class MotionPlayerApp extends StatelessWidget {
  const MotionPlayerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Motion Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeShell(),
      );
}
