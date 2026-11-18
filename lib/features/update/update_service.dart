import 'dart:convert';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// TODO: set to your public GitHub repo, e.g. 'piash/motion-player'
const kGithubRepo = 'YOUR_USERNAME/motion-player';

enum UpdateStage { none, available, downloading, ready, failed }

class UpdateInfo {
  final String version, notes, apkUrl;
  UpdateInfo(this.version, this.notes, this.apkUrl);
}

/// Checks GitHub Releases, downloads the APK in the background
/// (continues with the app closed, with a system notification),
/// then offers "Install now".
class UpdateService extends ChangeNotifier {
  UpdateStage stage = UpdateStage.none;
  UpdateInfo? info;
  double progress = 0;
  String? _apkPath;
  DownloadTask? _task;

  Future<void> init() async {
    FileDownloader().configureNotification(
      running: const TaskNotification('Downloading update', '{filename} • {progress}'),
      complete: const TaskNotification('Update downloaded', 'Tap to install'),
      error: const TaskNotification('Update failed', 'Tap to retry in the app'),
      progressBar: true,
    );
    FileDownloader().registerCallbacks(taskNotificationTapCallback: (task, type) {
      if (task.taskId == _task?.taskId && stage == UpdateStage.ready) install();
    });
    FileDownloader().updates.listen((u) async {
      if (u.task.taskId != _task?.taskId) return;
      if (u is TaskProgressUpdate && u.progress >= 0) {
        progress = u.progress;
        notifyListeners();
      } else if (u is TaskStatusUpdate) {
        if (u.status == TaskStatus.complete) {
          _apkPath = await u.task.filePath();
          stage = UpdateStage.ready;
        } else if (u.status == TaskStatus.failed || u.status == TaskStatus.notFound) {
          stage = UpdateStage.failed;
        }
        notifyListeners();
      }
    });
  }

  Future<void> check() async {
    if (stage == UpdateStage.downloading || stage == UpdateStage.ready) return;
    try {
      final r = await http.get(Uri.parse('https://api.github.com/repos/$kGithubRepo/releases/latest'),
          headers: {'Accept': 'application/vnd.github+json'}).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final latest = (j['tag_name'] as String).replaceFirst(RegExp(r'^v'), '');
      final current = (await PackageInfo.fromPlatform()).version;
      if (!_isNewer(latest, current)) return;
      final assets = (j['assets'] as List).cast<Map<String, dynamic>>().where((a) => (a['name'] as String).endsWith('.apk')).toList();
      if (assets.isEmpty) return;
      final a = assets.firstWhere((a) => (a['name'] as String).contains('arm64'), orElse: () => assets.first);
      info = UpdateInfo(latest, (j['body'] ?? '') as String, a['browser_download_url'] as String);
      stage = UpdateStage.available;
      notifyListeners();
    } catch (_) {/* offline or rate-limited: stay silent */}
  }

  Future<void> download() async {
    final i = info;
    if (i == null) return;
    _task = DownloadTask(
      url: i.apkUrl,
      filename: 'motion_player_${i.version}.apk',
      baseDirectory: BaseDirectory.applicationSupport,
      updates: Updates.statusAndProgress,
      allowPause: true,
    );
    progress = 0;
    stage = UpdateStage.downloading;
    notifyListeners();
    await FileDownloader().enqueue(_task!);
  }

  Future<void> install() async {
    if (_apkPath == null) return;
    await OpenFilex.open(_apkPath!, type: 'application/vnd.android.package-archive');
  }

  void dismiss() { stage = UpdateStage.none; notifyListeners(); }

  bool _isNewer(String a, String b) {
    final x = a.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final y = b.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final p = i < x.length ? x[i] : 0, q = i < y.length ? y[i] : 0;
      if (p != q) return p > q;
    }
    return false;
  }
}

final updateService = UpdateService();

/// true if version [a] is newer than [b] (e.g. 1.2.0 vs 1.1.9)
bool versionIsNewer(String a, String b) => updateService._isNewer(a, b);
