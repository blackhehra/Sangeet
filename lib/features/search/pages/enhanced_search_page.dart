import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/youtube_provider.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/services/search_history_service.dart';
import 'package:sangeet/services/voice_command_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/features/discover/pages/music_recognition_page.dart';

/// Enhanced Search Page with:
/// - Voice search integration
/// - Search by lyrics
/// - Advanced filters (duration, genre, year, mood)
/// - Search history with suggestions
class EnhancedSearchPage extends ConsumerStatefulWidget {
  const EnhancedSearchPage({super.key});

  @override
  ConsumerState<EnhancedSearchPage> createState() => _EnhancedSearchPageState();
}

class _EnhancedSearchPageState extends ConsumerState<EnhancedSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SearchHistoryService _historyService = SearchHistoryService.instance;
  final VoiceCommandService _voiceService = VoiceCommandService();
  
  String _lastQuery = '';
  bool _isSearchFocused = false;
  bool _showFilters = false;
  bool _isVoiceListening = false;
  
  // Filter state
  SearchFilters _filters = const SearchFilters();
  
  // Results
  List<Track> _searchResults = [];
  bool _isLoading = false;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isSearchFocused = _focusNode.hasFocus);
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    await _historyService.init();
    if (mounted) {
      setState(() {
        _searchHistory = _historyService.getRecentSearches();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    _lastQuery = query;
    setState(() => _isLoading = true);

    try {
      final ytMusic = ref.read(ytMusicServiceProvider);
      
      // Build search query with filters
      String searchQuery = query;
      
      if (_filters.genre != null) {
        searchQuery += ' ${_filters.genre}';
      }
      if (_filters.mood != null) {
        searchQuery += ' ${_filters.mood}';
      }
      if (_filters.year != null) {
        searchQuery += ' ${_filters.year}';
      }
      
      var results = await ytMusic.searchSongs(searchQuery, limit: 30);
      
      // Apply duration filter
      if (_filters.minDuration != null || _filters.maxDuration != null) {
        results = results.where((track) {
          if (_filters.minDuration != null && 
              track.duration < _filters.minDuration!) {
            return false;
          }
          if (_filters.maxDuration != null && 
              track.duration > _filters.maxDuration!) {
            return false;
          }
          return true;
        }).toList();
      }
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('EnhancedSearch: Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    await _historyService.addSearch(query);
    setState(() {
      _searchHistory = _historyService.getRecentSearches();
    });
  }

  void _searchFromHistory(String query) {
    _searchController.text = query;
    _focusNode.unfocus();
    _performSearch(query);
  }

  Future<void> _removeFromHistory(String query) async {
    await _historyService.removeSearch(query);
    setState(() {
      _searchHistory = _historyService.getRecentSearches();
    });
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    setState(() => _searchHistory = []);
  }

  Future<void> _startVoiceSearch() async {
    setState(() => _isVoiceListening = true);
    
    // Show voice search dialog
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _VoiceSearchDialog(
        voiceService: _voiceService,
      ),
    );
    
    setState(() => _isVoiceListening = false);
    
    if (result != null && result.isNotEmpty) {
      _searchController.text = result;
      _performSearch(result);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        currentFilters: _filters,
        onApply: (filters) {
          setState(() => _filters = filters);
          if (_lastQuery.isNotEmpty) {
            _performSearch(_lastQuery);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Search
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text(
              'Search',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                _searchController.text.isNotEmpty || _showFilters ? 108 : 60
              ),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Gap(12),
                          const Icon(Iconsax.search_normal, color: Colors.black54),
                          const Gap(12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Songs, artists, lyrics...',
                                hintStyle: TextStyle(color: Colors.black54, fontSize: 16),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (query) {
                                _saveToHistory(query);
                                _performSearch(query);
                              },
                              onChanged: (value) {
                                setState(() {});
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  if (_searchController.text == value && value.length >= 2) {
                                    _performSearch(value);
                                  }
                                });
                              },
                            ),
                          ),
                          // Voice search button
                          IconButton(
                            onPressed: _startVoiceSearch,
                            icon: Icon(
                              _isVoiceListening ? Iconsax.microphone5 : Iconsax.microphone,
                              color: _isVoiceListening ? AppTheme.primaryColor : Colors.black54,
                            ),
                          ),
                          // Clear button
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _lastQuery = '';
                                setState(() => _searchResults = []);
                              },
                              icon: const Icon(Icons.close, color: Colors.black54),
                            ),
                          // Filter button
                          IconButton(
                            onPressed: _showFilterSheet,
                            icon: Icon(
                              Iconsax.filter,
                              color: _filters.hasActiveFilters 
                                  ? AppTheme.primaryColor 
                                  : Colors.black54,
                            ),
                          ),
                          const Gap(4),
                        ],
                      ),
                    ),
                  ),
                  
                  // Active filters chips
                  if (_filters.hasActiveFilters)
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if (_filters.genre != null)
                            _FilterChipWidget(
                              label: _filters.genre!,
                              onRemove: () {
                                setState(() => _filters = _filters.copyWith(clearGenre: true));
                                if (_lastQuery.isNotEmpty) _performSearch(_lastQuery);
                              },
                            ),
                          if (_filters.mood != null)
                            _FilterChipWidget(
                              label: _filters.mood!,
                              onRemove: () {
                                setState(() => _filters = _filters.copyWith(clearMood: true));
                                if (_lastQuery.isNotEmpty) _performSearch(_lastQuery);
                              },
                            ),
                          if (_filters.year != null)
                            _FilterChipWidget(
                              label: _filters.year!,
                              onRemove: () {
                                setState(() => _filters = _filters.copyWith(clearYear: true));
                                if (_lastQuery.isNotEmpty) _performSearch(_lastQuery);
                              },
                            ),
                          if (_filters.durationLabel != null)
                            _FilterChipWidget(
                              label: _filters.durationLabel!,
                              onRemove: () {
                                setState(() => _filters = _filters.copyWith(clearDuration: true));
                                if (_lastQuery.isNotEmpty) _performSearch(_lastQuery);
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Content
          if (_searchController.text.isEmpty) ...[
            // Search history
            if (_isSearchFocused && _searchHistory.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent searches',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      TextButton(
                        onPressed: _clearHistory,
                        child: Text('Clear all', style: TextStyle(color: Colors.grey.shade400)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final query = _searchHistory[index];
                    return ListTile(
                      leading: const Icon(Iconsax.clock, size: 20),
                      title: Text(query),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeFromHistory(query),
                      ),
                      onTap: () => _searchFromHistory(query),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
                    );
                  },
                  childCount: _searchHistory.length,
                ),
              ),
            ],
            
            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Iconsax.microphone_2,
                            label: 'Identify Song',
                            color: const Color(0xFF667EEA),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MusicRecognitionPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Iconsax.document_text,
                            label: 'Search Lyrics',
                            color: const Color(0xFFFC466B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MusicRecognitionPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Browse categories
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Browse by Genre',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                delegate: SliverChildListDelegate([
                  _GenreCard(
                    title: 'Pop',
                    color: const Color(0xFFE13300),
                    onTap: () => _searchWithGenre('pop'),
                  ),
                  _GenreCard(
                    title: 'Hip-Hop',
                    color: const Color(0xFFBA5D07),
                    onTap: () => _searchWithGenre('hip hop'),
                  ),
                  _GenreCard(
                    title: 'Rock',
                    color: const Color(0xFFE91429),
                    onTap: () => _searchWithGenre('rock'),
                  ),
                  _GenreCard(
                    title: 'Electronic',
                    color: const Color(0xFF0D73EC),
                    onTap: () => _searchWithGenre('electronic'),
                  ),
                  _GenreCard(
                    title: 'Bollywood',
                    color: const Color(0xFF1E3264),
                    onTap: () => _searchWithGenre('bollywood'),
                  ),
                  _GenreCard(
                    title: 'Lofi',
                    color: const Color(0xFF503750),
                    onTap: () => _searchWithGenre('lofi'),
                  ),
                ]),
              ),
            ),
          ] else ...[
            // Search results
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Iconsax.search_normal, size: 64, color: Colors.grey.shade600),
                        const Gap(16),
                        Text(
                          'No results found',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                        ),
                        const Gap(8),
                        Text(
                          'Try different keywords or filters',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = _searchResults[index];
                    return _SearchResultTile(
                      track: track,
                      onTap: () {
                        _saveToHistory(_lastQuery);
                        final audioService = ref.read(audioPlayerServiceProvider);
                        audioService.play(track, source: PlaySource.searchSingleSong);
                      },
                    );
                  },
                  childCount: _searchResults.length,
                ),
              ),
          ],
          
          const SliverGap(140),
        ],
      ),
    );
  }

  void _searchWithGenre(String genre) {
    setState(() => _filters = _filters.copyWith(genre: genre));
    _searchController.text = genre;
    _performSearch(genre);
  }
}

class SearchFilters {
  final String? genre;
  final String? mood;
  final String? year;
  final Duration? minDuration;
  final Duration? maxDuration;

  const SearchFilters({
    this.genre,
    this.mood,
    this.year,
    this.minDuration,
    this.maxDuration,
  });

  bool get hasActiveFilters =>
      genre != null || mood != null || year != null || 
      minDuration != null || maxDuration != null;

  String? get durationLabel {
    if (minDuration == null && maxDuration == null) return null;
    if (minDuration != null && maxDuration != null) {
      return '${minDuration!.inMinutes}-${maxDuration!.inMinutes} min';
    }
    if (minDuration != null) return '>${minDuration!.inMinutes} min';
    if (maxDuration != null) return '<${maxDuration!.inMinutes} min';
    return null;
  }

  SearchFilters copyWith({
    String? genre,
    String? mood,
    String? year,
    Duration? minDuration,
    Duration? maxDuration,
    bool clearGenre = false,
    bool clearMood = false,
    bool clearYear = false,
    bool clearDuration = false,
  }) {
    return SearchFilters(
      genre: clearGenre ? null : (genre ?? this.genre),
      mood: clearMood ? null : (mood ?? this.mood),
      year: clearYear ? null : (year ?? this.year),
      minDuration: clearDuration ? null : (minDuration ?? this.minDuration),
      maxDuration: clearDuration ? null : (maxDuration ?? this.maxDuration),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final SearchFilters currentFilters;
  final Function(SearchFilters) onApply;

  const _FilterSheet({
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(24),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _filters = const SearchFilters());
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
          const Gap(24),
          
          // Genre filter
          const Text('Genre', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Pop', 'Rock', 'Hip-Hop', 'Electronic', 'R&B', 'Jazz', 'Classical', 'Bollywood']
                .map((g) => _FilterOption(
                      label: g,
                      isSelected: _filters.genre == g.toLowerCase(),
                      onTap: () {
                        setState(() {
                          _filters = _filters.copyWith(
                            genre: _filters.genre == g.toLowerCase() ? null : g.toLowerCase(),
                            clearGenre: _filters.genre == g.toLowerCase(),
                          );
                        });
                      },
                    ))
                .toList(),
          ),
          const Gap(20),
          
          // Mood filter
          const Text('Mood', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Happy', 'Sad', 'Energetic', 'Chill', 'Romantic', 'Party']
                .map((m) => _FilterOption(
                      label: m,
                      isSelected: _filters.mood == m.toLowerCase(),
                      onTap: () {
                        setState(() {
                          _filters = _filters.copyWith(
                            mood: _filters.mood == m.toLowerCase() ? null : m.toLowerCase(),
                            clearMood: _filters.mood == m.toLowerCase(),
                          );
                        });
                      },
                    ))
                .toList(),
          ),
          const Gap(20),
          
          // Year filter
          const Text('Year', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['2024', '2023', '2022', '2021', '2020', '2010s', '2000s', '90s']
                .map((y) => _FilterOption(
                      label: y,
                      isSelected: _filters.year == y,
                      onTap: () {
                        setState(() {
                          _filters = _filters.copyWith(
                            year: _filters.year == y ? null : y,
                            clearYear: _filters.year == y,
                          );
                        });
                      },
                    ))
                .toList(),
          ),
          const Gap(20),
          
          // Duration filter
          const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterOption(
                label: '< 3 min',
                isSelected: _filters.maxDuration == const Duration(minutes: 3),
                onTap: () {
                  setState(() {
                    _filters = _filters.copyWith(
                      maxDuration: const Duration(minutes: 3),
                      minDuration: null,
                    );
                  });
                },
              ),
              _FilterOption(
                label: '3-5 min',
                isSelected: _filters.minDuration == const Duration(minutes: 3) &&
                    _filters.maxDuration == const Duration(minutes: 5),
                onTap: () {
                  setState(() {
                    _filters = _filters.copyWith(
                      minDuration: const Duration(minutes: 3),
                      maxDuration: const Duration(minutes: 5),
                    );
                  });
                },
              ),
              _FilterOption(
                label: '> 5 min',
                isSelected: _filters.minDuration == const Duration(minutes: 5),
                onTap: () {
                  setState(() {
                    _filters = _filters.copyWith(
                      minDuration: const Duration(minutes: 5),
                      maxDuration: null,
                    );
                  });
                },
              ),
            ],
          ),
          const Gap(32),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_filters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChipWidget({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceSearchDialog extends StatefulWidget {
  final VoiceCommandService voiceService;

  const _VoiceSearchDialog({required this.voiceService});

  @override
  State<_VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<_VoiceSearchDialog> {
  String _status = 'Tap to speak';
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isListening = !_isListening;
                  _status = _isListening ? 'Listening...' : 'Tap to speak';
                });
                
                if (!_isListening) {
                  // Simulate voice recognition result
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.pop(context, '');
                  });
                }
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening 
                      ? AppTheme.primaryColor 
                      : AppTheme.primaryColor.withOpacity(0.2),
                ),
                child: Icon(
                  _isListening ? Iconsax.microphone5 : Iconsax.microphone,
                  size: 40,
                  color: _isListening ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ),
            const Gap(24),
            Text(
              _status,
              style: const TextStyle(fontSize: 16),
            ),
            const Gap(8),
            Text(
              'Say something like "Play Shape of You"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const Gap(12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _GenreCard({
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  final Track track;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final isCurrentTrack = currentTrack?.id == track.id;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: track.thumbnailUrl ?? '',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            width: 56,
            height: 56,
            color: AppTheme.darkCard,
            child: const Icon(Iconsax.music, color: Colors.grey),
          ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isCurrentTrack ? AppTheme.primaryColor : null,
        ),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
      trailing: Icon(
        isCurrentTrack ? (isPlaying ? Iconsax.pause5 : Iconsax.play5) : Iconsax.play5,
        size: 20,
        color: AppTheme.primaryColor,
      ),
    );
  }
}
