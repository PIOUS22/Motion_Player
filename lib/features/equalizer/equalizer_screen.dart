import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../core/playback_handler.dart';
import '../../core/theme.dart';

/// 5-band EQ + bass boost via mpv's ffmpeg audio filters (works for audio and video).
class EqService {
  static const freqs = [60, 230, 910, 3600, 14000];
  static const presets = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Rock': [4.0, 2.0, -1.0, 3.0, 4.0],
    'Pop': [-1.0, 2.0, 4.0, 2.0, -1.0],
    'Bass': [6.0, 4.0, 0.0, 0.0, 0.0],
    'Vocal': [-2.0, 0.0, 4.0, 3.0, 0.0],
  };
  static void apply(Player p, List<double> gains, double bass) {
    final f = [for (var i = 0; i < 5; i++) 'equalizer=f=${freqs[i]}:width_type=o:w=1:g=${gains[i]}'];
    if (bass > 0) f.add('bass=g=${bass.toStringAsFixed(1)}');
    (p.platform as dynamic).setProperty('af', 'lavfi=[${f.join(',')}]');
  }
}

class EqualizerScreen extends StatefulWidget {
  final Player player;
  const EqualizerScreen({super.key, required this.player});
  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  List<double> gains = List.filled(5, 0);
  double bass = 0;

  void _update() { setState(() {}); EqService.apply(widget.player, gains, bass); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Equalizer')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Wrap(spacing: 8, children: EqService.presets.entries.map((e) => ActionChip(label: Text(e.key), onPressed: () { gains = [...e.value]; _update(); })).toList()),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                for (var i = 0; i < 5; i++)
                  Column(children: [
                    Expanded(child: RotatedBox(quarterTurns: 3, child: Slider(min: -12, max: 12, value: gains[i], onChanged: (v) { gains[i] = v; _update(); }))),
                    Text(EqService.freqs[i] >= 1000 ? '${EqService.freqs[i] ~/ 1000}k' : '${EqService.freqs[i]}', style: const TextStyle(fontSize: 12)),
                  ]),
              ]),
            ),
            const Divider(),
            ListTile(title: const Text('Bass boost'), subtitle: Slider(activeColor: AppColors.orange, min: 0, max: 15, value: bass, onChanged: (v) { bass = v; _update(); })),
            ValueListenableBuilder<bool>(valueListenable: audioHandler.backgroundPlay, builder: (_, on, __) => SwitchListTile(title: const Text('Background play'), subtitle: const Text('Keep audio playing with screen off'), value: on, onChanged: (v) => audioHandler.backgroundPlay.value = v)),
          ]),
        ),
      );
}
