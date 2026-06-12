// UNVERIFIED: requires on-device build/test (Plan 3 Task D1)
package com.friendslocalizer.friends_localizer

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BleMeshPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, BleMeshListener {

    private lateinit var context: Context
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var events: EventChannel.EventSink? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "fl/ble").also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, "fl/ble/events").also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        BleMeshService.listener = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                BleMeshService.listener = this
                context.startForegroundService(Intent(context, BleMeshService::class.java))
                result.success(null)
            }
            "stop" -> {
                context.stopService(Intent(context, BleMeshService::class.java))
                result.success(null)
            }
            "broadcast" -> {
                // Selon la version du moteur Flutter, un Uint8List arrive en
                // ByteArray brut ou enveloppé ; on couvre les deux cas.
                val frame: ByteArray? = when (val a = call.arguments) {
                    is ByteArray -> a
                    else -> null
                }
                if (frame != null) BleMeshService.instance?.broadcast(frame)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) { events = sink }
    override fun onCancel(arguments: Any?) { events = null }

    override fun onFrame(frame: ByteArray) {
        main.post { events?.success(mapOf("type" to "frame", "data" to frame)) }
    }

    override fun onNeighbor() {
        main.post { events?.success(mapOf("type" to "neighbor")) }
    }
}
