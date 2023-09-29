package com.example.webview_camera_maps_playback_flutter

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import com.yandex.mapkit.MapKitFactory

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        MapKitFactory.setApiKey("50b92bdd-e996-4792-a547-876a7b6c9667") // Your generated API key
        super.configureFlutterEngine(flutterEngine)
    }
}
