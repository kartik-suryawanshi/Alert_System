package com.example.alert_system

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.alert_system/call"
    private val CALL_PERMISSION_REQUEST_CODE = 123

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "callPhone") {
                val number = call.argument<String>("number")
                if (number != null) {
                    makePhoneCall(number, result)
                } else {
                    result.error("UNAVAILABLE", "Phone number not provided", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun makePhoneCall(number: String, result: MethodChannel.Result) {
        // Check CALL_PHONE permission
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), CALL_PERMISSION_REQUEST_CODE)
            result.error("PERMISSION_DENIED", "Call permission not granted", null)
        } else {
            try {
                val callIntent = Intent(Intent.ACTION_CALL)
                callIntent.data = Uri.parse("tel:$number")
                startActivity(callIntent)
                result.success("Call initiated")
            } catch (e: Exception) {
                result.error("ERROR", "Failed to initiate call: ${e.message}", null)
            }
        }
    }
}