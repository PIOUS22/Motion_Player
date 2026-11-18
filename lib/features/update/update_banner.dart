import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'update_service.dart';

class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: updateService,
        builder: (_, __) {
          final s = updateService.stage;
          if (s == UpdateStage.none) return const SizedBox.shrink();
          final v = updateService.info?.version ?? '';
          late final IconData icon;
          late final String text;
          late final List<Widget> actions;
          switch (s) {
            case UpdateStage.available:
              icon = Icons.system_update; text = 'New version $v available';
              actions = [TextButton(onPressed: updateService.dismiss, child: const Text('Later')), FilledButton(onPressed: updateService.download, child: const Text('Download now'))];
            case UpdateStage.downloading:
              icon = Icons.downloading; text = 'Downloading update… ${(updateService.progress * 100).round()}%';
              actions = [];
            case UpdateStage.ready:
              icon = Icons.check_circle; text = 'Update $v downloaded';
              actions = [FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.black), onPressed: updateService.install, child: const Text('Install now'))];
            case UpdateStage.failed:
              icon = Icons.error_outline; text = 'Update download failed';
              actions = [FilledButton(onPressed: updateService.download, child: const Text('Retry'))];
            case UpdateStage.none:
              return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cyan.withOpacity(.4))),
            child: Column(children: [
              Row(children: [
                Icon(icon, color: AppColors.cyan),
                const SizedBox(width: 10),
                Expanded(child: Text(text)),
                ...actions,
              ]),
              if (s == UpdateStage.downloading) Padding(padding: const EdgeInsets.only(top: 8), child: LinearProgressIndicator(value: updateService.progress)),
            ]),
          );
        },
      );
}
