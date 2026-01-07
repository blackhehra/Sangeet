import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';

class LicensePage extends StatefulWidget {
  const LicensePage({super.key});

  @override
  State<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  String? _licenseText;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    try {
      final license = await rootBundle.loadString('LICENSE');
      setState(() {
        _licenseText = license;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load license: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('License'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.warning_2, size: 48, color: Colors.grey.shade600),
                      const Gap(16),
                      Text(_error!, style: TextStyle(color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const Gap(24),
                      
                      // License Header
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Iconsax.document_text,
                                size: 28,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const Gap(16),
                            const Text(
                              'Proprietary Software License',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Gap(8),
                            Text(
                              'Sangeet is proprietary software. All rights reserved.',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const Gap(24),
                      
                      // What this means section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What this means:',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Gap(12),
                            _buildPermissionItem(
                              icon: Iconsax.tick_circle,
                              color: Colors.green,
                              text: 'You can use this app for personal use',
                            ),
                            _buildPermissionItem(
                              icon: Iconsax.tick_circle,
                              color: Colors.green,
                              text: 'You can install it on your personal devices',
                            ),
                            _buildPermissionItem(
                              icon: Iconsax.close_circle,
                              color: Colors.red,
                              text: 'You cannot copy or distribute the software',
                            ),
                            _buildPermissionItem(
                              icon: Iconsax.close_circle,
                              color: Colors.red,
                              text: 'You cannot reverse engineer or modify it',
                            ),
                            _buildPermissionItem(
                              icon: Iconsax.close_circle,
                              color: Colors.red,
                              text: 'You cannot use it for commercial purposes',
                            ),
                          ],
                        ),
                      ),
                      
                      const Gap(24),
                      
                      // Full License Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full License Text:',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Gap(12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade800),
                              ),
                              child: SelectableText(
                                _licenseText ?? '',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Colors.grey.shade300,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Gap(32),
                      
                      // Copyright notice
                      Text(
                        '© 2024-2025 Simran Khehra',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      
                      const Gap(32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const Gap(12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
