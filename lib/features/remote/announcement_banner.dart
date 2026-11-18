import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import 'remote_config_service.dart';

class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key});
  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  String? dismissedId;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) => setState(() => dismissedId = p.getString('dismissed_announcement') ?? ''));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: remoteConfig,
        builder: (_, __) {
          final text = remoteConfig.announcement, id = remoteConfig.announcementId;
          if (text.isEmpty || dismissedId == null || dismissedId == id) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.orange.withOpacity(.5))),
            child: Row(children: [
              const Icon(Icons.campaign, color: AppColors.orange),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              IconButton(icon: const Icon(Icons.close), onPressed: () async {
                (await SharedPreferences.getInstance()).setString('dismissed_announcement', id);
                setState(() => dismissedId = id);
              }),
            ]),
          );
        },
      );
}
