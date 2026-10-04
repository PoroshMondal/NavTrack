package com.navtrack.nav_track

import com.navtrack.nav_track.location.LocationMethodHandler
import com.navtrack.nav_track.location.LocationStreamHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.navtrack/location_method"
    private val EVENT_CHANNEL = "com.navtrack/location_event"

    private var methodHandler: LocationMethodHandler? = null
    private var streamHandler: LocationStreamHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodHandler = LocationMethodHandler(applicationContext, this)
        streamHandler = LocationStreamHandler(applicationContext)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(methodHandler)

        val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(streamHandler)
    }

    override fun onResume() {
        super.onResume()
        methodHandler?.setActivity(this)
    }

    override fun onDestroy() {
        streamHandler?.stopLocationUpdates()
        super.onDestroy()
    }
}
