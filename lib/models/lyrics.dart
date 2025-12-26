import 'package:lrc/lrc.dart';

/// Represents a single line of lyrics with its timestamp
class LyricSlice {
  final Duration time;
  final String text;

  const LyricSlice({
    required this.time,
    required this.text,
  });

  factory LyricSlice.fromLrcLine(LrcLine line) {
    return LyricSlice(
      time: line.timestamp,
      text: line.lyrics.trim(),
    );
  }

  factory LyricSlice.fromJson(Map<String, dynamic> json) {
    return LyricSlice(
      time: Duration(milliseconds: json['time'] as int),
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.inMilliseconds,
      'text': text,
    };
  }

  @override
  String toString() => 'LyricSlice(time: $time, text: $text)';
}

/// Container for lyrics data including metadata
class SubtitleSimple {
  final String name;
  final List<LyricSlice> lyrics;
  final int rating;
  final String provider;

  const SubtitleSimple({
    required this.name,
    required this.lyrics,
    required this.rating,
    required this.provider,
  });

  /// Check if lyrics are synced (have timestamps) or plain text
  bool get isSynced => lyrics.any((l) => l.time != Duration.zero);

  factory SubtitleSimple.fromJson(Map<String, dynamic> json) {
    return SubtitleSimple(
      name: json['name'] as String,
      lyrics: (json['lyrics'] as List<dynamic>)
          .map((e) => LyricSlice.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: json['rating'] as int,
      provider: json['provider'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lyrics': lyrics.map((e) => e.toJson()).toList(),
      'rating': rating,
      'provider': provider,
    };
  }

  /// Create an empty/error state
  factory SubtitleSimple.empty(String trackName) {
    return SubtitleSimple(
      name: trackName,
      lyrics: [],
      rating: 0,
      provider: 'none',
    );
  }
}
