import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/wrapped_service.dart';
import 'package:sangeet/services/listening_stats_service.dart';

/// Wrapped Page - Spotify Wrapped-like year-end summary
class WrappedPage extends ConsumerStatefulWidget {
  const WrappedPage({super.key});

  @override
  ConsumerState<WrappedPage> createState() => _WrappedPageState();
}

class _WrappedPageState extends ConsumerState<WrappedPage> {
  final WrappedService _wrappedService = WrappedService.instance;
  WrappedData? _wrappedData;
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadWrappedData();
  }

  Future<void> _loadWrappedData() async {
    setState(() => _isLoading = true);
    
    await _wrappedService.init();
    final data = await _wrappedService.generateYearWrapped(_selectedYear);
    
    if (mounted) {
      setState(() {
        _wrappedData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _wrappedData == null
              ? _buildEmptyState()
              : _buildWrappedContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.chart, size: 64, color: Colors.grey.shade600),
          const Gap(16),
          Text(
            'No listening data yet',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
          const Gap(8),
          Text(
            'Start listening to see your stats!',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWrappedContent() {
    final data = _wrappedData!;
    
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('$_selectedYear Wrapped'),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1DB954),
                    Color(0xFF191414),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  '🎵',
                  style: TextStyle(fontSize: 80),
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Iconsax.calendar),
              onSelected: (year) {
                setState(() => _selectedYear = year);
                _loadWrappedData();
              },
              itemBuilder: (context) {
                final currentYear = DateTime.now().year;
                return List.generate(5, (index) {
                  final year = currentYear - index;
                  return PopupMenuItem(
                    value: year,
                    child: Text('$year'),
                  );
                });
              },
            ),
          ],
        ),
        
        // Listening personality
        SliverToBoxAdapter(
          child: _PersonalityCard(personality: data.listeningPersonality),
        ),
        
        // Total stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.timer_1,
                    value: '${data.totalHours}',
                    label: 'Hours Listened',
                    color: const Color(0xFF1DB954),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.music,
                    value: '${data.totalTracksPlayed}',
                    label: 'Tracks Played',
                    color: const Color(0xFF1ED760),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Top tracks section
        if (data.topTracks.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Your Top Songs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = data.topTracks[index];
                return _TopTrackTile(
                  rank: index + 1,
                  track: track,
                );
              },
              childCount: data.topTracks.length.clamp(0, 5),
            ),
          ),
        ],
        
        // Top artists section
        if (data.topArtists.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Your Top Artists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.topArtists.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final artist = data.topArtists[index];
                  return _TopArtistCard(
                    rank: index + 1,
                    artist: artist,
                  );
                },
              ),
            ),
          ),
        ],
        
        // Top genres
        if (data.topGenres.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Your Top Genres',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.topGenres.map((genre) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      genre.name,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        
        // Peak month
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _PeakMonthCard(
              monthName: data.peakMonthName,
              minutes: data.peakMonthMinutes,
            ),
          ),
        ),
        
        // Fun facts
        if (data.funFacts.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Fun Facts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data.funFacts[index],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
              childCount: data.funFacts.length,
            ),
          ),
        ],
        
        const SliverGap(100),
      ],
    );
  }
}

class _PersonalityCard extends StatelessWidget {
  final String personality;

  const _PersonalityCard({required this.personality});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Listening Personality',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const Gap(8),
          Text(
            personality,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const Gap(8),
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

class _TopTrackTile extends StatelessWidget {
  final int rank;
  final WrappedTrack track;

  const _TopTrackTile({
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
            '${track.minutesListened} min',
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

class _TopArtistCard extends StatelessWidget {
  final int rank;
  final WrappedArtist artist;

  const _TopArtistCard({
    required this.rank,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.darkCard,
                  border: rank == 1
                      ? Border.all(color: AppTheme.primaryColor, width: 3)
                      : null,
                ),
                child: const Center(
                  child: Icon(Iconsax.user, size: 32, color: Colors.grey),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? AppTheme.primaryColor : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${artist.minutesListened} min',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeakMonthCard extends StatelessWidget {
  final String monthName;
  final int minutes;

  const _PeakMonthCard({
    required this.monthName,
    required this.minutes,
  });

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.chart_215,
              color: AppTheme.primaryColor,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peak Month',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  monthName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${minutes ~/ 60}h ${minutes % 60}m',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
