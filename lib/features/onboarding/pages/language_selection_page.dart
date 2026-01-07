import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/features/onboarding/pages/artist_selection_page.dart';

class LanguageSelectionPage extends ConsumerStatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  ConsumerState<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends ConsumerState<LanguageSelectionPage> {
  final Set<MusicLanguage> _selectedLanguages = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(20),
              
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Iconsax.music,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const Gap(24),
              
              Text(
                'What languages do you\nlisten to?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const Gap(8),
              
              Text(
                'Select your preferred music languages. We\'ll personalize your recommendations.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              
              const Gap(24),
              
              // Language Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: MusicLanguage.values.length,
                  itemBuilder: (context, index) {
                    final language = MusicLanguage.values[index];
                    final isSelected = _selectedLanguages.contains(language);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedLanguages.remove(language);
                          } else {
                            _selectedLanguages.add(language);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const Gap(8),
                              ],
                              Text(
                                language.displayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const Gap(16),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedLanguages.isEmpty
                      ? null
                      : () async {
                          // Save languages
                          await ref
                              .read(userPreferencesServiceProvider.notifier)
                              .setLanguages(_selectedLanguages.toList());
                          
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ArtistSelectionPage(
                                  selectedLanguages: _selectedLanguages.toList(),
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedLanguages.isEmpty
                            ? 'Select at least one language'
                            : 'Continue (${_selectedLanguages.length} selected)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedLanguages.isNotEmpty) ...[
                        const Gap(8),
                        const Icon(Iconsax.arrow_right_1, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
