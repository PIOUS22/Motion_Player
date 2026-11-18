import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../update/update_banner.dart';
import '../update/update_service.dart';
import 'remote_config_service.dart';

/// Blocks the whole app when the kill switch is on or the version is below min_version.
class AppGate extends StatelessWidget {
  final Widget child;
  const AppGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: remoteConfig,
        builder: (_, __) {
          if (remoteConfig.killSwitch) return _Blocked(icon: Icons.block, title: 'App disabled', message: remoteConfig.killMessage);
          if (remoteConfig.forceUpdate) {
            return _Blocked(icon: Icons.system_update, title: 'Update required', message: 'Version ${remoteConfig.minVersion} or newer is needed to continue.');
          }
          return child;
        },
      );
}

class _Blocked extends StatefulWidget {
  final IconData icon;
  final String title, message;
  const _Blocked({required this.icon, required this.title, required this.message});
  @override
  State<_Blocked> createState() => _BlockedState();
}

class _BlockedState extends State<_Blocked> {
  @override
  void initState() { super.initState(); updateService.check(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, size: 72, color: AppColors.orange),
              const SizedBox(height: 16),
              Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(widget.message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const UpdateBanner(), // Download now -> Install now
              TextButton(onPressed: updateService.check, child: const Text('Check for update')),
            ]),
          ),
        ),
      );
}
