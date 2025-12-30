import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sangeet/features/settings/pages/license_page.dart' as custom;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  void _openLicensePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const custom.LicensePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = _packageInfo?.version ?? '1.0.0-beta.1';
    final buildNumber = _packageInfo?.buildNumber ?? '1';

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Gap(32),
            
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/ic_launcher.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const Gap(24),
            
            // App Name
            const Text(
              'Sangeet',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            
            const Gap(8),
            
            // Version Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'v$version (Beta)',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            
            const Gap(8),
            
            // Build Number
            Text(
              'Build $buildNumber',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            
            const Gap(16),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'A modern music streaming app, i\'m sure it will enhance your music experience.\nDISCLAIMER: This app is using open source libraries and plugins.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            
            const Gap(32),
            
            // Developer Section
            _buildSectionHeader('Developer'),
            _buildListTile(
              icon: Iconsax.user,
              title: 'Simran Khehra',
              subtitle: 'Creator & Developer',  
            ),
            _buildListTile(
              icon: Iconsax.instagram,
              title: 'Instagram',
              subtitle: '@blackhehra',
              onTap: () => _launchUrl('https://www.instagram.com/blackhehra'),
            ),
            
            const Gap(16),
            
            // Community Section
            _buildSectionHeader('Community'),
            _buildListTile(
              icon: Iconsax.message,
              title: 'Telegram',
              subtitle: 'Join our community',
              onTap: () => _launchUrl('https://t.me/sangeet_official'),
            ),
            
            const Gap(16),
            
            // Source Code Section
            _buildSectionHeader('Source Code'),
            _buildListTile(
              icon: Iconsax.code,
              title: 'GitHub Repository',
              subtitle: 'View source code',
              onTap: () => _launchUrl('https://github.com/blackhehra/sangeet'),
            ),
            _buildListTile(
              icon: Iconsax.warning_2,
              title: 'Report Bug',
              subtitle: 'Found an issue? Let us know',
              onTap: () => _launchUrl('https://github.com/blackhehra/sangeet/issues/new?labels=bug'),
            ),
            _buildListTile(
              icon: Iconsax.lamp_charge,
              title: 'Request Feature',
              subtitle: 'Suggest new features',
              onTap: () => _launchUrl('https://t.me/sangeet_chat'),
            ),
            
            const Gap(16),
            
            // Legal Section
            _buildSectionHeader('Legal'),
            _buildListTile(
              icon: Iconsax.document_text,
              title: 'License',
              subtitle: 'Proprietary License',
              onTap: _openLicensePage,
            ),
            _buildListTile(
              icon: Iconsax.shield_tick,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () => _launchUrl('https://github.com/blackhehra/sangeet/blob/main/PRIVACY.md'),
            ),
            
            const Gap(32),
            
            // Powered By
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _launchUrl('https://github.com/sonic-liberation/spotube-plugin-spotify'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.music, size: 20, color: Colors.grey),
                          const Gap(8),
                          Text(
                            'Streams music from various sources',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        'Big thanks to sonic-liberation ↗',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const Gap(24),
            
            // Made with love
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Made with ',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const Icon(
                  Iconsax.heart5,
                  size: 16,
                  color: Colors.red,
                ),
                ],
            ),
            
            const Gap(16),
            
            // Copyright
            Text(
              '© 2025-2026 Simran Khehra',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            
            const Gap(8),
            
            Text(
              'All rights reserved',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
              ),
            ),
            
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white70),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: Colors.grey.shade600,
            )
          : null,
      onTap: onTap,
    );
  }
}
