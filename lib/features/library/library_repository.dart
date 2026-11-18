import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

enum SortBy { date, size, name }

class MediaItem {
  final AssetEntity asset;
  final String path, title, folder;
  final Duration duration;
  final int size;
  final DateTime added;
  MediaItem(this.asset, this.path, this.size)
      : title = asset.title ?? '',
        duration = asset.videoDuration,
        added = asset.createDateTime,
        folder = path.contains('/') ? path.substring(0, path.lastIndexOf('/')).split('/').last : '';
}

class LibraryRepository {
  Future<bool> requestPermission() async => (await PhotoManager.requestPermissionExtend()).hasAccess;

  Future<List<MediaItem>> scan(RequestType type) async {
    final paths = await PhotoManager.getAssetPathList(type: type, onlyAll: true);
    if (paths.isEmpty) return [];
    final assets = await paths.first.getAssetListRange(start: 0, end: 5000);
    final items = <MediaItem>[];
    for (final a in assets) {
      final f = await a.originFile;
      if (f == null) continue;
      items.add(MediaItem(a, f.path, await f.length()));
    }
    return items;
  }

  List<MediaItem> sort(List<MediaItem> l, SortBy s, {String query = ''}) {
    final r = l.where((e) => e.title.toLowerCase().contains(query.toLowerCase())).toList();
    switch (s) {
      case SortBy.date: r.sort((a, b) => b.added.compareTo(a.added));
      case SortBy.size: r.sort((a, b) => b.size.compareTo(a.size));
      case SortBy.name: r.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return r;
  }

  Map<String, List<MediaItem>> byFolder(List<MediaItem> l) {
    final m = <String, List<MediaItem>>{};
    for (final i in l) { (m[i.folder] ??= []).add(i); }
    return m;
  }
}

final libraryRepoProvider = Provider((_) => LibraryRepository());
final sortProvider = StateProvider((_) => SortBy.date);
final queryProvider = StateProvider((_) => '');
final videosProvider = FutureProvider((ref) async {
  final repo = ref.read(libraryRepoProvider);
  if (!await repo.requestPermission()) return <MediaItem>[];
  return repo.scan(RequestType.video);
});
final audioProvider = FutureProvider((ref) async {
  final repo = ref.read(libraryRepoProvider);
  if (!await repo.requestPermission()) return <MediaItem>[];
  return repo.scan(RequestType.audio);
});
