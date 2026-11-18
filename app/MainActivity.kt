package com.fokus.fokus_hafalan

import android.app.ActivityManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var locked = false
    private var wasPinned = false
    private var oldFilter = NotificationManager.INTERRUPTION_FILTER_ALL

    private fun pinned(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
    }

    private fun nm() = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fokus/lock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val n = nm()
                        if (!locked && n.isNotificationPolicyAccessGranted) {
                            oldFilter = n.currentInterruptionFilter
                            n.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                        }
                        locked = true
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        startLockTask()
                        result.success(null)
                    }
                    "stop" -> {
                        locked = false
                        wasPinned = false
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        val n = nm()
                        if (n.isNotificationPolicyAccessGranted) n.setInterruptionFilter(oldFilter)
                        if (pinned()) stopLockTask()
                        result.success(null)
                    }
                    "status" -> {
                        if (pinned()) wasPinned = true
                        result.success(pinned())
                    }
                    "dndSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        // Kalau pin terlepas saat sesi masih berjalan, pasang lagi.
        if (locked && wasPinned && !pinned()) startLockTask()
    }
}
