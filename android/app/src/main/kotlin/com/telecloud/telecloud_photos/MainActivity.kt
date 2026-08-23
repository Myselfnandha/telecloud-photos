package com.telecloud.telecloud_photos

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val LAUNCHER_CHANNEL = "com.telecloud/launcher"
    private val ALIAS_NAME = "com.telecloud.telecloud_photos.FilesLauncherAlias"
    private var launchMode: String = "photos"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        detectLaunchMode(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isFilesLauncherEnabled" -> {
                    val componentName = ComponentName(context, ALIAS_NAME)
                    val state = packageManager.getComponentEnabledSetting(componentName)
                    result.success(state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
                }
                "setFilesLauncherEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val componentName = ComponentName(context, ALIAS_NAME)
                    val newState = if (enabled) {
                        PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                    } else {
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                    }
                    packageManager.setComponentEnabledSetting(
                        componentName,
                        newState,
                        PackageManager.DONT_KILL_APP
                    )
                    result.success(true)
                }
                "getLaunchMode" -> {
                    result.success(launchMode)
                }
                "clearLaunchMode" -> {
                    launchMode = "photos"
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        detectLaunchMode(intent)

        flutterEngine?.let { engine ->
            MethodChannel(engine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL)
                .invokeMethod("onNewLaunchMode", launchMode)
        }
    }

    private fun detectLaunchMode(intent: Intent?) {
        if (intent == null) return
        val component = intent.component
        if (component != null && component.className.contains("FilesLauncherAlias")) {
            launchMode = "files"
        } else if (intent.getStringExtra("app_mode") == "files" || intent.data?.host == "files") {
            launchMode = "files"
        } else {
            launchMode = "photos"
        }
    }
}
