import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/bluetooth_provider.dart';

class DevicePickerSheet extends ConsumerStatefulWidget {
  const DevicePickerSheet({super.key});

  @override
  ConsumerState<DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends ConsumerState<DevicePickerSheet> {
  bool _isLoading = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final service = ref.read(bluetoothAudioServiceProvider);
    final hasPermission = await service.hasBluetoothPermission();
    if (mounted) {
      setState(() => _hasPermission = hasPermission);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    
    final service = ref.read(bluetoothAudioServiceProvider);
    final granted = await service.requestBluetoothPermission();
    
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isLoading = false;
      });
      
      if (granted) {
        await service.refresh();
      }
    }
  }

  Future<void> _openBluetoothSettings() async {
    final service = ref.read(bluetoothAudioServiceProvider);
    await service.openBluetoothSettings();
  }

  @override
  Widget build(BuildContext context) {
    final connectedDeviceAsync = ref.watch(connectedAudioDeviceProvider);
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF282828),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const Gap(16),
            
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Iconsax.bluetooth, size: 24),
                  Gap(12),
                  Text(
                    'Connect to a device',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const Gap(20),
            
            // Current device section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current device',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(12),
                  
                  // This phone
                  _buildDeviceTile(
                    icon: Iconsax.mobile,
                    name: 'This phone',
                    subtitle: 'Phone speaker',
                    isSelected: connectedDeviceAsync.valueOrNull == null,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            const Gap(16),
            
            // Bluetooth devices section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bluetooth devices',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_hasPermission)
                        TextButton(
                          onPressed: _openBluetoothSettings,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Settings',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Gap(12),
                  
                  if (!_hasPermission)
                    _buildPermissionRequest()
                  else
                    connectedDeviceAsync.when(
                      data: (device) {
                        if (device != null) {
                          return _buildDeviceTile(
                            icon: Iconsax.headphone,
                            name: device.name,
                            subtitle: 'Connected',
                            isSelected: true,
                            isConnected: true,
                            onTap: () {},
                          );
                        }
                        return _buildNoDevicesMessage();
                      },
                      loading: () => _buildNoDevicesMessage(), // Show no devices instead of loading
                      error: (_, __) => _buildNoDevicesMessage(),
                    ),
                ],
              ),
            ),
            
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile({
    required IconData icon,
    required String name,
    required String subtitle,
    required bool isSelected,
    bool isConnected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primaryColor : Colors.white,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isConnected 
                          ? AppTheme.primaryColor 
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Iconsax.tick_circle5,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Iconsax.bluetooth,
            size: 40,
            color: Colors.grey,
          ),
          const Gap(12),
          const Text(
            'Allow Bluetooth access',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Gap(8),
          Text(
            'To connect to speakers and headphones, allow Sangeet to access Bluetooth.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Allow Bluetooth',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDevicesMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.headphone,
            size: 32,
            color: Colors.grey.shade500,
          ),
          const Gap(8),
          Text(
            'No Bluetooth devices connected',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
          const Gap(8),
          TextButton(
            onPressed: _openBluetoothSettings,
            child: const Text(
              'Open Bluetooth settings',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
