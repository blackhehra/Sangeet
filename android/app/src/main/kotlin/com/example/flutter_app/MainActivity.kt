package com.example.flutter_app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.flutter_app/native"
    private val BLUETOOTH_CHANNEL = "com.sangeet.audio/bluetooth"
    
    private var a2dpProfile: BluetoothProfile? = null
    private var headsetProfile: BluetoothProfile? = null
    private var pendingResult: MethodChannel.Result? = null

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
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val success = installApk(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_PATH", "File path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Bluetooth audio channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLUETOOTH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getConnectedAudioDevice" -> {
                    getConnectedAudioDeviceAsync(result)
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
    
    // Install APK using FileProvider for Android 7+ (API 24+)
    private fun installApk(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                android.util.Log.e("AppUpdate", "APK file not found: $filePath")
                return false
            }
            
            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file
                )
            } else {
                Uri.fromFile(file)
            }
            
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            startActivity(intent)
            android.util.Log.d("AppUpdate", "Install intent launched for: $filePath")
            true
        } catch (e: Exception) {
            android.util.Log.e("AppUpdate", "Failed to install APK: ${e.message}", e)
            false
        }
    }
    
    // Get connected Bluetooth audio device asynchronously using BluetoothProfile
    private fun getConnectedAudioDeviceAsync(result: MethodChannel.Result) {
        try {
            android.util.Log.d("BluetoothNative", "getConnectedAudioDeviceAsync called")
            
            // First, try using AudioManager to check for connected Bluetooth audio devices (API 23+)
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val audioDevices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            
            for (device in audioDevices) {
                android.util.Log.d("BluetoothNative", "Audio device: ${device.productName}, type: ${device.type}")
                if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP || 
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && device.type == AudioDeviceInfo.TYPE_BLE_HEADSET)) {
                    
                    val deviceName = device.productName?.toString() ?: "Bluetooth Device"
                    android.util.Log.d("BluetoothNative", "Found connected Bluetooth audio via AudioManager: $deviceName")
                    result.success(mapOf(
                        "name" to deviceName,
                        "id" to device.id.toString(),
                        "type" to "bluetooth"
                    ))
                    return
                }
            }
            
            // Fallback: Use BluetoothProfile to get connected A2DP devices
            val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val bluetoothAdapter = bluetoothManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
            
            if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
                android.util.Log.d("BluetoothNative", "Bluetooth not available or disabled")
                result.success(null)
                return
            }
            
            // Store the result to use in the callback
            pendingResult = result
            
            // Get A2DP profile proxy to find connected audio devices
            val profileListener = object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    android.util.Log.d("BluetoothNative", "Profile $profile connected")
                    
                    val connectedDevices = proxy.connectedDevices
                    android.util.Log.d("BluetoothNative", "Found ${connectedDevices.size} connected devices for profile $profile")
                    
                    if (connectedDevices.isNotEmpty()) {
                        val device = connectedDevices[0]
                        val deviceName = device.name ?: "Bluetooth Device"
                        android.util.Log.d("BluetoothNative", "Connected device: $deviceName")
                        
                        pendingResult?.success(mapOf(
                            "name" to deviceName,
                            "id" to device.address,
                            "type" to "bluetooth"
                        ))
                        pendingResult = null
                    } else if (profile == BluetoothProfile.A2DP) {
                        // A2DP checked, now try HEADSET profile
                        bluetoothAdapter.getProfileProxy(this@MainActivity, this, BluetoothProfile.HEADSET)
                    } else {
                        // Both profiles checked, no devices found
                        pendingResult?.success(null)
                        pendingResult = null
                    }
                    
                    // Close the proxy
                    bluetoothAdapter.closeProfileProxy(profile, proxy)
                }
                
                override fun onServiceDisconnected(profile: Int) {
                    android.util.Log.d("BluetoothNative", "Profile $profile disconnected")
                }
            }
            
            // Start with A2DP profile (for music/media audio)
            val success = bluetoothAdapter.getProfileProxy(this, profileListener, BluetoothProfile.A2DP)
            if (!success) {
                android.util.Log.d("BluetoothNative", "Failed to get A2DP profile proxy")
                result.success(null)
                pendingResult = null
            }
            
        } catch (e: SecurityException) {
            android.util.Log.e("BluetoothNative", "Security exception - missing permission: ${e.message}")
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("BluetoothNative", "Error: ${e.message}", e)
            result.success(null)
        }
    }
}
