import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/services/settings_service.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/features/settings/pages/about_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final settingsService = ref.read(settingsServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Audio Quality Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Audio Quality',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Quality Options
          ...AudioQuality.values.map((quality) => _QualityTile(
            quality: quality,
            isSelected: settings.audioQuality == quality,
            onTap: () => settingsService.setAudioQuality(quality),
          )),
          
          const Divider(height: 32),
          
          // Music Source Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Music Source',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Source Options
          ...MusicSource.values.map((source) => _SourceTile(
            source: source,
            isSelected: settings.musicSource == source,
            onTap: () => settingsService.setMusicSource(source),
          )),
          
          const Divider(height: 32),
          
          // About Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Iconsax.info_circle),
            title: const Text('About Sangeet'),
            subtitle: const Text('Version, developer info & more'),
            trailing: const Icon(Iconsax.arrow_right_3, size: 18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          
          const Divider(height: 32),
          
          // Preferences Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Iconsax.refresh),
            title: const Text('Reset Preferences'),
            subtitle: const Text('Redo language and artist selection'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Preferences?'),
                  content: const Text(
                    'This will reset your language and artist preferences. '
                    'You will need to select them again.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await ref
                    .read(userPreferencesServiceProvider.notifier)
                    .resetOnboarding();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QualityTile extends StatelessWidget {
  final AudioQuality quality;
  final bool isSelected;
  final VoidCallback onTap;

  const _QualityTile({
    required this.quality,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSelected ? Iconsax.tick_circle5 : Iconsax.music_circle,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        quality.label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(quality.description),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _SourceTile extends StatelessWidget {
  final MusicSource source;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceTile({
    required this.source,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSelected ? Iconsax.tick_circle5 : Iconsax.video_circle,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        source.label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(source.description),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
