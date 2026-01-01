import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/listening_stats_service.dart';

class ListeningStatsPage extends ConsumerStatefulWidget {
  const ListeningStatsPage({super.key});

  @override
  ConsumerState<ListeningStatsPage> createState() => _ListeningStatsPageState();
}

class _ListeningStatsPageState extends ConsumerState<ListeningStatsPage> {
  StatsPeriod _selectedPeriod = StatsPeriod.week;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await ListeningStatsService.instance.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsService = ListeningStatsService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Stats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  
                  const Gap(24),
                  
                  // Overview cards
                  _buildOverviewCards(statsService),
                  
                  const Gap(24),
                  
                  // Top Tracks
                  _buildSectionHeader('Top Tracks', Iconsax.music),
                  const Gap(12),
                  _buildTopTracks(statsService),
                  
                  const Gap(24),
                  
                  // Top Artists
                  _buildSectionHeader('Top Artists', Iconsax.microphone),
                  const Gap(12),
                  _buildTopArtists(statsService),
                  
                  const Gap(24),
                  
                  // Listening Activity
                  _buildSectionHeader('Daily Activity', Iconsax.chart_2),
                  const Gap(12),
                  _buildActivityChart(statsService),
                  
                  const Gap(32),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StatsPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getPeriodLabel(period)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPeriod = period);
                }
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.darkCard,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.today:
        return 'Today';
      case StatsPeriod.week:
        return 'This Week';
      case StatsPeriod.month:
        return 'This Month';
      case StatsPeriod.year:
        return 'This Year';
      case StatsPeriod.allTime:
        return 'All Time';
    }
  }

  Widget _buildOverviewCards(ListeningStatsService statsService) {
    final listeningTime = statsService.getListeningTimeForPeriod(_selectedPeriod);
    final trackCount = statsService.getTrackCountForPeriod(_selectedPeriod);
    final streak = statsService.getListeningStreak();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.clock,
            label: 'Listening Time',
            value: _formatDuration(listeningTime),
            color: Colors.blue,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.music,
            label: 'Tracks Played',
            value: trackCount.toString(),
            color: Colors.green,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.flash_1,
            label: 'Day Streak',
            value: '$streak days',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const Gap(8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const Gap(8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTopTracks(ListeningStatsService statsService) {
    final topTracks = statsService.getTopTracksByPlayCount(limit: 5);

    if (topTracks.isEmpty) {
      return _buildEmptyState('No tracks played yet');
    }

    return Column(
      children: topTracks.asMap().entries.map((entry) {
        final index = entry.key;
        final track = entry.value;
        return _buildTrackItem(index + 1, track);
      }).toList(),
    );
  }

  Widget _buildTrackItem(int rank, TrackStats track) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppTheme.primaryColor : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const Gap(12),
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: track.thumbnailUrl ?? '',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppTheme.darkSurface,
                child: const Icon(Iconsax.music, size: 20),
              ),
            ),
          ),
          const Gap(12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Gap(2),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          // Play count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${track.playCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'plays',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopArtists(ListeningStatsService statsService) {
    final topArtists = statsService.getTopArtistsByPlayCount(limit: 5);

    if (topArtists.isEmpty) {
      return _buildEmptyState('No artists played yet');
    }

    return Column(
      children: topArtists.asMap().entries.map((entry) {
        final index = entry.key;
        final artist = entry.value;
        return _buildArtistItem(index + 1, artist);
      }).toList(),
    );
  }

  Widget _buildArtistItem(int rank, ArtistStats artist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppTheme.primaryColor : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const Gap(12),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.darkSurface,
            child: Text(
              artist.artistName.isNotEmpty ? artist.artistName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const Gap(12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Gap(2),
                Text(
                  _formatDuration(Duration(milliseconds: artist.totalPlayTimeMs)),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          // Play count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${artist.playCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'plays',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(ListeningStatsService statsService) {
    final dailyStats = statsService.getDailyStatsForPastDays(7);
    
    if (dailyStats.every((s) => s.totalPlayTimeMs == 0)) {
      return _buildEmptyState('No activity data yet');
    }

    final maxTime = dailyStats.map((s) => s.totalPlayTimeMs).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((stats) {
                final height = maxTime > 0 
                    ? (stats.totalPlayTimeMs / maxTime * 100).clamp(4.0, 100.0)
                    : 4.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      _getDayLabel(stats.date),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } catch (e) {
      return '';
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Iconsax.chart, size: 48, color: Colors.grey.shade600),
            const Gap(12),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
