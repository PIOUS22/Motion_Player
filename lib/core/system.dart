import 'package:flutter/services.dart';

class Sys {
  static const _c = MethodChannel('motion/system');
  static Future<double> brightness() async => (await _c.invokeMethod<double>('getBrightness')) ?? .5;
  static Future<void> setBrightness(double v) => _c.invokeMethod('setBrightness', v);
  static Future<double> volume() async => (await _c.invokeMethod<double>('getVolume')) ?? .5;
  static Future<void> setVolume(double v) => _c.invokeMethod('setVolume', v);
}
