import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';

late final MotionAudioHandler audioHandler;

Future<void> initAudio() async {
  await Permission.notification.request(); // Android 13+: needed for the media notification
  audioHandler = await AudioService.init(
    builder: () => MotionAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.motionplayer.playback',
      androidNotificationChannelName: 'Motion Player playback',
      androidStopForegroundOnPause: false, // keep the foreground service alive while paused
    ),
  );
}

/// Owns the single Player. Runs inside a foreground service so playback
/// survives screen-off / app switch, and exposes lock-screen + notification controls.
class MotionAudioHandler extends BaseAudioHandler with SeekHandler {
  final player = Player(configuration: const PlayerConfiguration(title: 'Motion Player'));
  late final video = VideoController(player, configuration: const VideoControllerConfiguration(enableHardwareAcceleration: true));
  final backgroundPlay = ValueNotifier<bool>(true);

  MotionAudioHandler() {
    player.stream.playing.listen((_) => _broadcast());
    player.stream.buffering.listen((_) => _broadcast());
    player.stream.rate.listen((_) => _broadcast());
    player.stream.position.listen((_) => _broadcast());
    player.stream.duration.listen((d) {
      final m = mediaItem.value;
      if (m != null) mediaItem.add(m.copyWith(duration: d));
    });
  }

  void _broadcast() {
    final playing = player.state.playing;
    playbackState.add(PlaybackState(
      controls: [MediaControl.rewind, playing ? MediaControl.pause : MediaControl.play, MediaControl.fastForward, MediaControl.stop],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: player.state.buffering ? AudioProcessingState.buffering : AudioProcessingState.ready,
      playing: playing,
      updatePosition: player.state.position,
      speed: player.state.rate,
    ));
  }

  Future<void> openMedia(String path, String title) async {
    mediaItem.add(MediaItem(id: path, title: title));
    await player.open(Media(path));
  }

  /// Audio-only while backgrounded: drop the video track so no frames are decoded.
  void setVideoEnabled(bool on) =>
      (player.platform as dynamic).setProperty('vid', on ? 'auto' : 'no');

  @override Future<void> play() => player.play();
  @override Future<void> pause() => player.pause();
  @override Future<void> seek(Duration position) => player.seek(position);
  @override Future<void> rewind() => player.seek(player.state.position - const Duration(seconds: 10));
  @override Future<void> fastForward() => player.seek(player.state.position + const Duration(seconds: 10));

  @override
  Future<void> stop() async {
    await player.stop();
    playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.idle, playing: false));
    return super.stop();
  }
}
