import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../player/player_screen.dart';
import '../ads/ad_banner.dart';
import '../remote/announcement_banner.dart';
import '../update/update_banner.dart';
import '../update/update_service.dart';
import '../vault/vault_screen.dart';
import 'library_repository.dart';

String fmt(Duration d) {
  String t(int n) => n.toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:${t(d.inMinutes % 60)}:${t(d.inSeconds % 60)}' : '${t(d.inMinutes)}:${t(d.inSeconds % 60)}';
}

void _play(BuildContext c, MediaItem i) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => PlayerScreen(path: i.path, title: i.title)));

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    updateService.check();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [const _VideosTab(), const _MusicTab(), const _FoldersTab(), const VaultScreen()];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: TextField(
          onChanged: (v) => ref.read(queryProvider.notifier).state = v,
          decoration: const InputDecoration(hintText: 'Search', border: InputBorder.none, prefixIcon: Icon(Icons.search)),
        ),
        actions: [
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (s) => ref.read(sortProvider.notifier).state = s,
            itemBuilder: (_) => SortBy.values.map((s) => PopupMenuItem(value: s, child: Text(s.name))).toList(),
          ),
        ],
      ),
      body: Column(children: [const AnnouncementBanner(), const UpdateBanner(), Expanded(child: pages[tab])]),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [const AdBanner(), NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'Videos'),
          NavigationDestination(icon: Icon(Icons.music_note_outlined), label: 'Music'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Folders'),
          NavigationDestination(icon: Icon(Icons.lock_outline), label: 'Private'),
        ],
      )]),
    );
  }
}

class _Thumb extends StatelessWidget {
  final MediaItem item;
  const _Thumb(this.item);
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => _play(context, item),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<Uint8List?>(
                  future: item.asset.thumbnailDataWithSize(ThumbnailSize(400, 300)),
                  builder: (_, s) => s.data == null ? Container(color: AppColors.surface) : Image.memory(s.data!, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 6, bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                  child: Text(fmt(item.duration), style: const TextStyle(fontSize: 11, color: AppColors.cyan)),
                ),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );
}

Widget _grid(List<MediaItem> l) => GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3),
      itemCount: l.length,
      itemBuilder: (_, i) => _Thumb(l[i]),
    );

Widget _async<T>(AsyncValue<T> v, Widget Function(T) b) => v.when(
      data: b, loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('$e')));

class _VideosTab extends ConsumerWidget {
  const _VideosTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(libraryRepoProvider);
    return _async(ref.watch(videosProvider), (l) => _grid(repo.sort(l, ref.watch(sortProvider), query: ref.watch(queryProvider))));
  }
}

class _FoldersTab extends ConsumerWidget {
  const _FoldersTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(libraryRepoProvider);
    return _async(ref.watch(videosProvider), (l) {
      final f = repo.byFolder(l).entries.toList();
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12),
        itemCount: f.length,
        itemBuilder: (_, i) => InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text(f[i].key)), body: _grid(f[i].value)))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.folder, size: 56, color: AppColors.orange),
            Text(f[i].key, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${f[i].value.length} videos', style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ]),
        ),
      );
    });
  }
}

class _MusicTab extends ConsumerWidget {
  const _MusicTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(libraryRepoProvider);
    return _async(ref.watch(audioProvider), (l) {
      final s = repo.sort(l, ref.watch(sortProvider), query: ref.watch(queryProvider));
      return ListView.builder(
        itemCount: s.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.music_note, color: AppColors.cyan),
          title: Text(s[i].title, maxLines: 1),
          subtitle: Text(fmt(s[i].duration)),
          onTap: () => _play(context, s[i]),
        ),
      );
    });
  }
}
