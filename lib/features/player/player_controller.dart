import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import '../../core/playback_handler.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Wraps media_kit Player: speed, A-B loop, tracks, subtitles, rotation lock.
class PlayerController {
  Player get player => audioHandler.player;
  // Hardware decoding (MediaCodec) incl. 4K/UHD on Android.
  VideoController get video => audioHandler.video;
  Duration? a, b;
  bool rotationLocked = false;

  Future<void> open(String path, String title) => audioHandler.openMedia(path, title);
  Future<void> setSpeed(double s) => player.setRate(s.clamp(0.25, 2.0));

  void toggleAB() {
    if (a == null) { a = player.state.position; }
    else if (b == null) { b = player.state.position; }
    else { a = b = null; }
  }

  void enforceLoop(Duration pos) {
    if (a != null && b != null && pos >= b!) player.seek(a!);
  }

  Future<void> loadSubtitle(String path) => player.setSubtitleTrack(SubtitleTrack.uri(path)); // .srt/.ass
  void setSubtitleDelay(int ms) => (player.platform as dynamic).setProperty('sub-delay', (ms / 1000).toString());
  void setSubtitleSize(double scale) => (player.platform as dynamic).setProperty('sub-scale', scale.toString());
  Future<void> setAudioTrack(AudioTrack t) => player.setAudioTrack(t); // embedded tracks: player.state.tracks.audio

  Future<void> toggleRotationLock(bool landscape) async {
    rotationLocked = !rotationLocked;
    await SystemChrome.setPreferredOrientations(rotationLocked
        ? (landscape ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight] : [DeviceOrientation.portraitUp])
        : DeviceOrientation.values);
  }

  /// Leaving the screen: keep playing (notification stays) only if background play is on.
  void dispose() {
    if (!audioHandler.backgroundPlay.value) audioHandler.stop();
  }
}
