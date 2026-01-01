package com.example.flutter_app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.flutter_app/native"
    private val BLUETOOTH_CHANNEL = "com.sangeet.audio/bluetooth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Original channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val deviceInfo = getDeviceInfo()
                    result.success(deviceInfo)
                }
                "greetFromKotlin" -> {
                    val name = call.argument<String>("name") ?: "User"
                    result.success(greetFromKotlin(name))
                }
                else -> result.notImplemented()
            }
        }
        
        // Bluetooth audio channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLUETOOTH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getConnectedAudioDevice" -> {
                    val device = getConnectedAudioDevice()
                    result.success(device)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Kotlin native function - get device info
    private fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "brand" to android.os.Build.BRAND,
            "model" to android.os.Build.MODEL,
            "androidVersion" to android.os.Build.VERSION.RELEASE,
            "sdkVersion" to android.os.Build.VERSION.SDK_INT.toString()
        )
    }

    // Kotlin native function - greeting
    private fun greetFromKotlin(name: String): String {
        return "Hello $name! This message comes from Kotlin 🎉"
    }
    
    // Get connected Bluetooth audio device
    private fun getConnectedAudioDevice(): Map<String, String>? {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            // Check if audio is routed to Bluetooth
            if (audioManager.isBluetoothA2dpOn || audioManager.isBluetoothScoOn) {
                val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
                    // Get connected Bluetooth devices
                    val connectedDevices = bluetoothAdapter.bondedDevices
                    
                    // Find connected audio device
                    for (device in connectedDevices) {
                        // Check if device is connected (bonded and likely connected)
                        if (device.bondState == BluetoothDevice.BOND_BONDED) {
                            // Check device class for audio devices
                            val deviceClass = device.bluetoothClass?.majorDeviceClass
                            if (deviceClass == 1024 || // AUDIO_VIDEO
                                device.name?.contains("buds", ignoreCase = true) == true ||
                                device.name?.contains("headphone", ignoreCase = true) == true ||
                                device.name?.contains("speaker", ignoreCase = true) == true) {
                                
                                return mapOf(
                                    "name" to (device.name ?: "Bluetooth Device"),
                                    "id" to device.address,
                                    "type" to "bluetooth"
                                )
                            }
                        }
                    }
                    
                    // If audio is routed to BT but we can't find specific device,
                    // return first bonded device
                    if (connectedDevices.isNotEmpty()) {
                        val device = connectedDevices.first()
                        return mapOf(
                            "name" to (device.name ?: "Bluetooth Device"),
                            "id" to device.address,
                            "type" to "bluetooth"
                        )
                    }
                }
            }
        } catch (e: Exception) {
            // Permission denied or other error
            return null
        }
        return null
    }
}
