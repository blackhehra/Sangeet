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
            android.util.Log.d("BluetoothNative", "getConnectedAudioDevice called")
            
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            
            if (bluetoothAdapter == null) {
                android.util.Log.d("BluetoothNative", "BluetoothAdapter is null")
                return null
            }
            
            if (!bluetoothAdapter.isEnabled) {
                android.util.Log.d("BluetoothNative", "Bluetooth is disabled")
                return null
            }
            
            // Get all bonded (paired) devices
            val bondedDevices = bluetoothAdapter.bondedDevices
            android.util.Log.d("BluetoothNative", "Found ${bondedDevices.size} bonded devices")
            
            // Check if audio is currently routed to Bluetooth
            val isBluetoothA2dp = audioManager.isBluetoothA2dpOn
            val isBluetoothSco = audioManager.isBluetoothScoOn
            android.util.Log.d("BluetoothNative", "Audio routing - A2DP: $isBluetoothA2dp, SCO: $isBluetoothSco")
            
            val isBluetoothAudio = isBluetoothA2dp || isBluetoothSco
            
            if (bondedDevices.isEmpty()) {
                android.util.Log.d("BluetoothNative", "No bonded devices found")
                return null
            }
            
            // Log all bonded devices
            for (device in bondedDevices) {
                val deviceClass = device.bluetoothClass?.majorDeviceClass
                android.util.Log.d("BluetoothNative", "Device: ${device.name}, Class: $deviceClass, Address: ${device.address}")
            }
            
            if (isBluetoothAudio) {
                android.util.Log.d("BluetoothNative", "Audio is routed to Bluetooth, searching for audio device...")
                // Audio is playing through Bluetooth, find the likely device
                for (device in bondedDevices) {
                    val deviceClass = device.bluetoothClass?.majorDeviceClass
                    val deviceName = device.name ?: "Bluetooth Device"
                    
                    // Check if it's an audio device by class or name
                    val isAudioDevice = deviceClass == 1024 || // AUDIO_VIDEO class
                        deviceName.contains("buds", ignoreCase = true) ||
                        deviceName.contains("headphone", ignoreCase = true) ||
                        deviceName.contains("headset", ignoreCase = true) ||
                        deviceName.contains("speaker", ignoreCase = true) ||
                        deviceName.contains("airpods", ignoreCase = true) ||
                        deviceName.contains("earphone", ignoreCase = true)
                    
                    if (isAudioDevice) {
                        android.util.Log.d("BluetoothNative", "Found audio device: $deviceName")
                        return mapOf(
                            "name" to deviceName,
                            "id" to device.address,
                            "type" to "bluetooth"
                        )
                    }
                }
                
                // If we can't identify specific audio device but audio is on BT,
                // return the first bonded device
                val firstDevice = bondedDevices.firstOrNull()
                if (firstDevice != null) {
                    android.util.Log.d("BluetoothNative", "Returning first bonded device: ${firstDevice.name}")
                    return mapOf(
                        "name" to (firstDevice.name ?: "Bluetooth Device"),
                        "id" to firstDevice.address,
                        "type" to "bluetooth"
                    )
                }
            } else {
                android.util.Log.d("BluetoothNative", "Audio not on Bluetooth, checking for paired audio devices...")
                // Audio not currently on Bluetooth, but check for bonded audio devices
                for (device in bondedDevices) {
                    val deviceClass = device.bluetoothClass?.majorDeviceClass
                    val deviceName = device.name ?: "Bluetooth Device"
                    
                    // Only return if it's clearly an audio device
                    val isAudioDevice = deviceClass == 1024 ||
                        deviceName.contains("buds", ignoreCase = true) ||
                        deviceName.contains("headphone", ignoreCase = true) ||
                        deviceName.contains("headset", ignoreCase = true) ||
                        deviceName.contains("airpods", ignoreCase = true)
                    
                    if (isAudioDevice) {
                        android.util.Log.d("BluetoothNative", "Found paired audio device: $deviceName")
                        return mapOf(
                            "name" to deviceName,
                            "id" to device.address,
                            "type" to "bluetooth"
                        )
                    }
                }
            }
            
            android.util.Log.d("BluetoothNative", "No audio device found")
        } catch (e: Exception) {
            android.util.Log.e("BluetoothNative", "Error: ${e.message}", e)
            return null
        }
        return null
    }
}
