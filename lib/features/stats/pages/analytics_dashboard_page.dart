import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/listening_stats_service.dart';
import 'package:sangeet/services/wrapped_service.dart';
import 'package:sangeet/features/stats/pages/wrapped_page.dart';

/// Analytics Dashboard Page
/// Shows detailed listening statistics, patterns, and insights
class AnalyticsDashboardPage extends ConsumerStatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  ConsumerState<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends ConsumerState<AnalyticsDashboardPage> {
  final ListeningStatsService _statsService = ListeningStatsService.instance;
  final WrappedService _wrappedService = WrappedService.instance;
  
  StatsPeriod _selectedPeriod = StatsPeriod.week;
  bool _isLoading = true;
  
  Duration _totalTime = Duration.zero;
  int _trackCount = 0;
  List<TrackStats> _topTracks = [];
  List<ArtistStats> _topArtists = [];
  List<DailyStats> _dailyStats = [];
  ListeningStreakInfo? _streakInfo;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    await _statsService.init();
    await _wrappedService.init();
    
    final totalTime = _statsService.getListeningTimeForPeriod(_selectedPeriod);
    final trackCount = _statsService.getTrackCountForPeriod(_selectedPeriod);
    final topTracks = _statsService.getTopTracksByPlayCount(limit: 10);
    final topArtists = _statsService.getTopArtistsByPlayCount(limit: 10);
    final dailyStats = _statsService.getDailyStatsForPastDays(
      _selectedPeriod == StatsPeriod.week ? 7 : 30
    );
    final streakInfo = _wrappedService.getStreakInfo();
    
    if (mounted) {
      setState(() {
        _totalTime = totalTime;
        _trackCount = trackCount;
        _topTracks = topTracks;
        _topArtists = topArtists;
        _dailyStats = dailyStats;
        _streakInfo = streakInfo;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text(
              'Listening Stats',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WrappedPage()),
                  );
                },
                icon: const Icon(Iconsax.gift),
                tooltip: 'Year Wrapped',
              ),
              IconButton(
                onPressed: _loadStats,
                icon: const Icon(Iconsax.refresh),
              ),
            ],
          ),
          
          // Period selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _PeriodChip(
                    label: 'Today',
                    isSelected: _selectedPeriod == StatsPeriod.today,
                    onTap: () {
                      setState(() => _selectedPeriod = StatsPeriod.today);
                      _loadStats();
                    },
                  ),
                  const Gap(8),
                  _PeriodChip(
                    label: 'Week',
                    isSelected: _selectedPeriod == StatsPeriod.week,
                    onTap: () {
                      setState(() => _selectedPeriod = StatsPeriod.week);
                      _loadStats();
                    },
                  ),
                  const Gap(8),
                  _PeriodChip(
                    label: 'Month',
                    isSelected: _selectedPeriod == StatsPeriod.month,
                    onTap: () {
                      setState(() => _selectedPeriod = StatsPeriod.month);
                      _loadStats();
                    },
                  ),
                  const Gap(8),
                  _PeriodChip(
                    label: 'All Time',
                    isSelected: _selectedPeriod == StatsPeriod.allTime,
                    onTap: () {
                      setState(() => _selectedPeriod = StatsPeriod.allTime);
                      _loadStats();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            )
          else ...[
            // Overview cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _OverviewCard(
                        icon: Iconsax.timer_1,
                        value: _formatDuration(_totalTime),
                        label: 'Listening Time',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _OverviewCard(
                        icon: Iconsax.music,
                        value: '$_trackCount',
                        label: 'Tracks Played',
                        color: const Color(0xFF667EEA),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Streak card
            if (_streakInfo != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _StreakCard(streakInfo: _streakInfo!),
                ),
              ),
            
            // Daily activity chart
            if (_dailyStats.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DailyActivityChart(dailyStats: _dailyStats),
                ),
              ),
            
            // Top tracks
            if (_topTracks.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Top Tracks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = _topTracks[index];
                    return _TrackStatTile(
                      rank: index + 1,
                      track: track,
                    );
                  },
                  childCount: _topTracks.length.clamp(0, 5),
                ),
              ),
            ],
            
            // Top artists
            if (_topArtists.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Top Artists',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final artist = _topArtists[index];
                    return _ArtistStatTile(
                      rank: index + 1,
                      artist: artist,
                    );
                  },
                  childCount: _topArtists.length.clamp(0, 5),
                ),
              ),
            ],
            
            // Empty state
            if (_topTracks.isEmpty && _topArtists.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Iconsax.chart, size: 64, color: Colors.grey.shade600),
                        const Gap(16),
                        Text(
                          'No listening data for this period',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const Gap(8),
                        Text(
                          'Start listening to see your stats!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          
          const SliverGap(100),
        ],
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

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
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
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _OverviewCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Gap(12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final ListeningStreakInfo streakInfo;

  const _StreakCard({required this.streakInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            streakInfo.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streakInfo.currentStreak} Day Streak',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  streakInfo.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyActivityChart extends StatelessWidget {
  final List<DailyStats> dailyStats;

  const _DailyActivityChart({required this.dailyStats});

  @override
  Widget build(BuildContext context) {
    // Find max value for scaling
    int maxMinutes = 1;
    for (final stat in dailyStats) {
      final minutes = stat.totalPlayTimeMs ~/ 60000;
      if (minutes > maxMinutes) maxMinutes = minutes;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((stat) {
                final minutes = stat.totalPlayTimeMs ~/ 60000;
                final height = maxMinutes > 0 
                    ? (minutes / maxMinutes * 80).clamp(4.0, 80.0) 
                    : 4.0;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message: '${stat.date}: ${minutes}m',
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: minutes > 0 
                              ? AppTheme.primaryColor 
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dailyStats.isNotEmpty ? _formatDate(dailyStats.first.date) : '',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              Text(
                dailyStats.isNotEmpty ? _formatDate(dailyStats.last.date) : '',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return '${parts[1]}/${parts[2]}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _TrackStatTile extends StatelessWidget {
  final int rank;
  final TrackStats track;

  const _TrackStatTile({
    required this.rank,
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
          ),
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: track.thumbnailUrl ?? '',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppTheme.darkCard,
                child: const Icon(Iconsax.music, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade400),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${track.playCount} plays',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Text(
            '${track.totalPlayTimeMs ~/ 60000}m',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistStatTile extends StatelessWidget {
  final int rank;
  final ArtistStats artist;

  const _ArtistStatTile({
    required this.rank,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
          ),
          const Gap(8),
          ClipOval(
            child: artist.thumbnailUrl != null && artist.thumbnailUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: artist.thumbnailUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppTheme.darkCard,
                      child: const Icon(Iconsax.user, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: AppTheme.darkCard,
                    child: const Icon(Iconsax.user, color: Colors.grey),
                  ),
          ),
        ],
      ),
      title: Text(
        artist.artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${artist.playCount} plays',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Text(
            '${artist.totalPlayTimeMs ~/ 60000}m',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
