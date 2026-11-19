import 'package:file_picker/file_picker.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import '../../core/playback_handler.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme.dart';
import '../remote/firebase_boot.dart';
import '../equalizer/equalizer_screen.dart';
import 'player_controller.dart';

class PlayerScreen extends StatefulWidget {
  final String path, title;
  const PlayerScreen({super.key, required this.path, required this.title});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  final c = PlayerController();
  final floating = Floating();
  double brightness = .5, volume = .5, speed = 1, zoom = 1, baseZoom = 1;
  bool showUi = true;
  String? hud;
  Offset tap = Offset.zero;
  bool inPip = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    floating.pipStatusStream.listen((s) => inPip = s == PiPStatus.enabled);
    WakelockPlus.enable();
    c.open(widget.path, widget.title);
    track('play_media', {'ext': widget.path.split('.').last.toLowerCase()});
    c.player.stream.position.listen(c.enforceLoop);
    ScreenBrightness().current.then((v) => brightness = v);
    VolumeController.instance.showSystemUI = false;
    VolumeController.instance.getVolume().then((v) => volume = v);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    audioHandler.setVideoEnabled(true);
    c.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (inPip) return;
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      if (audioHandler.backgroundPlay.value) {
        audioHandler.setVideoEnabled(false); // audio only: stop decoding video while screen is off
      } else {
        c.player.pause();
      }
    } else if (s == AppLifecycleState.resumed) {
      audioHandler.setVideoEnabled(true);
    }
  }

  void _flash(String t) {
    setState(() => hud = t);
    Future.delayed(const Duration(milliseconds: 700), () { if (mounted) setState(() => hud = null); });
  }

  void _vertical(DragUpdateDetails d, double width) {
    final delta = -d.delta.dy / 300;
    if (d.localPosition.dx < width / 2) {
      brightness = (brightness + delta).clamp(0.0, 1.0);
      ScreenBrightness().setScreenBrightness(brightness);
      _flash('Brightness ${(brightness * 100).round()}%');
    } else {
      volume = (volume + delta).clamp(0.0, 1.0);
      VolumeController.instance.setVolume(volume);
      _flash('Volume ${(volume * 100).round()}%');
    }
  }

  void _seekBy(Duration d) {
    final t = c.player.state.position + d;
    c.player.seek(t < Duration.zero ? Duration.zero : t);
    _flash('${d.isNegative ? '-' : '+'}${d.inSeconds.abs()}s  →  ${_f(t)}');
  }

  String _f(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => showUi = !showUi),
        onDoubleTapDown: (d) => tap = d.localPosition,
        onDoubleTap: () {
          if (tap.dx < w * .33) { _seekBy(const Duration(seconds: -10)); }
          else if (tap.dx > w * .66) { _seekBy(const Duration(seconds: 10)); }
          else { c.player.playOrPause(); }
        },
        onVerticalDragUpdate: (d) => _vertical(d, w),
        onHorizontalDragUpdate: (d) => _seekBy(Duration(seconds: (d.delta.dx / 3).round())),
        onScaleStart: (_) => baseZoom = zoom,
        onScaleUpdate: (s) { if (s.pointerCount == 2) setState(() => zoom = (baseZoom * s.scale).clamp(1.0, 4.0)); },
        child: Stack(children: [
          Center(child: Transform.scale(scale: zoom, child: Video(controller: c.video, controls: NoVideoControls))),
          if (hud != null)
            Center(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Text(hud!, style: const TextStyle(color: AppColors.cyan, fontSize: 18)))),
          if (showUi) _overlay(),
        ]),
      ),
    );
  }

  Widget _overlay() => SafeArea(
        child: Column(children: [
          Container(
            color: Colors.black38,
            child: Row(children: [
              const BackButton(),
              Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ActionChip(label: Text('${speed}x'), onPressed: _speedSheet),
              IconButton(icon: const Icon(Icons.subtitles), onPressed: () async {
                final r = await FilePicker.platform.pickFiles();
                if (r?.files.single.path != null) c.loadSubtitle(r!.files.single.path!);
              }),
              ValueListenableBuilder<bool>(
                valueListenable: audioHandler.backgroundPlay,
                builder: (_, on, __) => IconButton(
                  tooltip: 'Background play',
                  icon: Icon(Icons.headphones, color: on ? AppColors.cyan : null),
                  onPressed: () => audioHandler.backgroundPlay.value = !on,
                ),
              ),
              IconButton(icon: const Icon(Icons.picture_in_picture_alt), onPressed: () => floating.enable(const ImmediatePiP())),
              IconButton(icon: const Icon(Icons.equalizer), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EqualizerScreen(player: c.player)))),
            ]),
          ),
          const Spacer(),
          Container(
            color: Colors.black38,
            child: Column(children: [
              StreamBuilder<Duration>(
                stream: c.player.stream.position,
                builder: (_, s) {
                  final dur = c.player.state.duration.inMilliseconds.toDouble();
                  final pos = (s.data ?? Duration.zero).inMilliseconds.toDouble();
                  return Slider(value: pos.clamp(0, dur < 1 ? 1 : dur), max: dur < 1 ? 1 : dur, onChanged: (v) => c.player.seek(Duration(milliseconds: v.toInt())));
                },
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(icon: const Icon(Icons.repeat_one), color: c.a != null ? AppColors.orange : null, onPressed: () { setState(c.toggleAB); _flash(c.a == null ? 'A-B off' : c.b == null ? 'A set' : 'B set'); }),
                IconButton(icon: const Icon(Icons.replay_10), onPressed: () => _seekBy(const Duration(seconds: -10))),
                StreamBuilder<bool>(stream: c.player.stream.playing, builder: (_, s) => IconButton(iconSize: 44, icon: Icon(s.data == true ? Icons.pause_circle : Icons.play_circle), onPressed: c.player.playOrPause)),
                IconButton(icon: const Icon(Icons.forward_10), onPressed: () => _seekBy(const Duration(seconds: 10))),
                IconButton(icon: Icon(c.rotationLocked ? Icons.screen_lock_rotation : Icons.screen_rotation), onPressed: () async { await c.toggleRotationLock(MediaQuery.of(context).orientation == Orientation.landscape); setState(() {}); }),
              ]),
            ]),
          ),
        ]),
      );

  void _speedSheet() => showModalBottomSheet(
        context: context,
        builder: (_) => Wrap(children: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) => ListTile(title: Text('${s}x'), onTap: () { c.setSpeed(s); setState(() => speed = s); Navigator.pop(context); })).toList()),
      );
}
