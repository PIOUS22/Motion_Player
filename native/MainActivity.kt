package com.motionplayer.motion_player

import android.content.Context
import android.app.PictureInPictureParams
import android.media.AudioManager
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "motion/system")
            .setMethodCallHandler { call, res ->
                val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                when (call.method) {
                    "getBrightness" -> {
                        val b = window.attributes.screenBrightness
                        res.success(if (b < 0) 0.5 else b.toDouble())
                    }
                    "setBrightness" -> {
                        val a = window.attributes
                        a.screenBrightness = (call.arguments as Double).toFloat()
                        window.attributes = a
                        res.success(null)
                    }
                    "getVolume" -> res.success(am.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max)
                    "setVolume" -> {
                        am.setStreamVolume(AudioManager.STREAM_MUSIC, ((call.arguments as Double) * max).toInt(), 0)
                        res.success(null)
                    }
                    "enterPip" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            enterPictureInPictureMode(
                                PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9)).build())
                        }
                        res.success(null)
                    }
                    else -> res.notImplemented()
                }
            }
    }
}
