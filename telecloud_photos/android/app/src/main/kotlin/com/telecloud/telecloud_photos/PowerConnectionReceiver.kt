package com.telecloud.telecloud_photos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

class PowerConnectionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs: SharedPreferences = context.getSharedPreferences("TeleCloudPrefs", Context.MODE_PRIVATE)
        when (intent.action) {
            Intent.ACTION_POWER_CONNECTED -> {
                prefs.edit().putBoolean("is_charging", true).putLong("charging_changed_at", System.currentTimeMillis()).apply()
            }
            Intent.ACTION_POWER_DISCONNECTED -> {
                prefs.edit().putBoolean("is_charging", false).putLong("charging_changed_at", System.currentTimeMillis()).apply()
            }
        }
    }
}
