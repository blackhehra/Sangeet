import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';

/// Voice Command Service
/// Handles voice commands for playback control
/// Note: Requires speech_to_text package for actual voice recognition
class VoiceCommandService extends ChangeNotifier {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final YtMusicService _ytMusicService = YtMusicService();
  
  bool _isListening = false;
  String _lastCommand = '';
  String _status = 'Ready';
  
  bool get isListening => _isListening;
  String get lastCommand => _lastCommand;
  String get status => _status;

  /// Process a voice command text
  Future<VoiceCommandResult> processCommand(String command, AudioPlayerService audioService) async {
    _lastCommand = command;
    final normalizedCommand = command.toLowerCase().trim();
    
    print('VoiceCommandService: Processing command: "$normalizedCommand"');
    
    // Play command
    if (normalizedCommand.startsWith('play ')) {
      final query = normalizedCommand.substring(5).trim();
      if (query.isNotEmpty) {
        _status = 'Searching for "$query"...';
        notifyListeners();
        
        final tracks = await _ytMusicService.searchSongs(query, limit: 1);
        if (tracks.isNotEmpty) {
          await audioService.play(tracks.first);
          _status = 'Playing "${tracks.first.title}"';
          notifyListeners();
          return VoiceCommandResult.success('Playing "${tracks.first.title}"');
        } else {
          _status = 'No results found';
          notifyListeners();
          return VoiceCommandResult.error('No results found for "$query"');
        }
      }
    }
    
    // Pause command
    if (_matchesCommand(normalizedCommand, ['pause', 'stop', 'halt'])) {
      await audioService.pause();
      _status = 'Paused';
      notifyListeners();
      return VoiceCommandResult.success('Playback paused');
    }
    
    // Resume/Play command (without query)
    if (_matchesCommand(normalizedCommand, ['resume', 'continue', 'unpause']) ||
        normalizedCommand == 'play') {
      await audioService.resume();
      _status = 'Playing';
      notifyListeners();
      return VoiceCommandResult.success('Playback resumed');
    }
    
    // Skip/Next command
    if (_matchesCommand(normalizedCommand, ['skip', 'next', 'next song', 'skip song', 'next track'])) {
      await audioService.skipToNext();
      _status = 'Skipped to next';
      notifyListeners();
      return VoiceCommandResult.success('Skipped to next track');
    }
    
    // Previous command
    if (_matchesCommand(normalizedCommand, ['previous', 'back', 'go back', 'previous song', 'previous track'])) {
      await audioService.skipToPrevious();
      _status = 'Previous track';
      notifyListeners();
      return VoiceCommandResult.success('Playing previous track');
    }
    
    // Volume commands
    if (_matchesCommand(normalizedCommand, ['volume up', 'louder', 'increase volume', 'turn up'])) {
      await audioService.setVolume(1.0); // Max volume
      _status = 'Volume increased';
      notifyListeners();
      return VoiceCommandResult.success('Volume increased');
    }
    
    if (_matchesCommand(normalizedCommand, ['volume down', 'quieter', 'decrease volume', 'turn down'])) {
      await audioService.setVolume(0.5);
      _status = 'Volume decreased';
      notifyListeners();
      return VoiceCommandResult.success('Volume decreased');
    }
    
    if (_matchesCommand(normalizedCommand, ['mute', 'silence'])) {
      await audioService.setVolume(0.0);
      _status = 'Muted';
      notifyListeners();
      return VoiceCommandResult.success('Muted');
    }
    
    // Shuffle command
    if (_matchesCommand(normalizedCommand, ['shuffle', 'shuffle on', 'enable shuffle', 'mix it up'])) {
      if (!audioService.isShuffled) {
        audioService.toggleShuffle();
      }
      _status = 'Shuffle enabled';
      notifyListeners();
      return VoiceCommandResult.success('Shuffle enabled');
    }
    
    if (_matchesCommand(normalizedCommand, ['shuffle off', 'disable shuffle', 'no shuffle'])) {
      if (audioService.isShuffled) {
        audioService.toggleShuffle();
      }
      _status = 'Shuffle disabled';
      notifyListeners();
      return VoiceCommandResult.success('Shuffle disabled');
    }
    
    // Repeat command
    if (_matchesCommand(normalizedCommand, ['repeat', 'repeat on', 'loop'])) {
      audioService.cycleRepeatMode();
      _status = 'Repeat mode changed';
      notifyListeners();
      return VoiceCommandResult.success('Repeat mode: ${audioService.repeatMode.name}');
    }
    
    // What's playing command
    if (_matchesCommand(normalizedCommand, ['what\'s playing', 'what is playing', 'current song', 'what song'])) {
      final track = audioService.currentTrack;
      if (track != null) {
        _status = 'Now playing: ${track.title}';
        notifyListeners();
        return VoiceCommandResult.success('Now playing: "${track.title}" by ${track.artist}');
      } else {
        _status = 'Nothing playing';
        notifyListeners();
        return VoiceCommandResult.error('Nothing is currently playing');
      }
    }
    
    _status = 'Command not recognized';
    notifyListeners();
    return VoiceCommandResult.error('Command not recognized: "$command"');
  }

  bool _matchesCommand(String input, List<String> commands) {
    for (final cmd in commands) {
      if (input == cmd || input.contains(cmd)) {
        return true;
      }
    }
    return false;
  }

  /// Start listening for voice commands
  /// Note: Actual implementation requires speech_to_text package
  void startListening() {
    _isListening = true;
    _status = 'Listening...';
    notifyListeners();
    
    // In actual implementation, this would start the speech recognizer
    // speech.listen(onResult: (result) => processCommand(result.recognizedWords));
  }

  /// Stop listening
  void stopListening() {
    _isListening = false;
    _status = 'Ready';
    notifyListeners();
  }

  /// Get available voice commands
  static List<VoiceCommandInfo> get availableCommands => [
    VoiceCommandInfo('Play [song name]', 'Search and play a song'),
    VoiceCommandInfo('Pause / Stop', 'Pause playback'),
    VoiceCommandInfo('Resume / Play', 'Resume playback'),
    VoiceCommandInfo('Skip / Next', 'Skip to next track'),
    VoiceCommandInfo('Previous / Back', 'Go to previous track'),
    VoiceCommandInfo('Volume up / Louder', 'Increase volume'),
    VoiceCommandInfo('Volume down / Quieter', 'Decrease volume'),
    VoiceCommandInfo('Mute', 'Mute audio'),
    VoiceCommandInfo('Shuffle', 'Enable shuffle'),
    VoiceCommandInfo('Repeat / Loop', 'Toggle repeat mode'),
    VoiceCommandInfo('What\'s playing', 'Get current track info'),
  ];
}

class VoiceCommandResult {
  final bool success;
  final String message;
  
  const VoiceCommandResult._(this.success, this.message);
  
  factory VoiceCommandResult.success(String message) => VoiceCommandResult._(true, message);
  factory VoiceCommandResult.error(String message) => VoiceCommandResult._(false, message);
}

class VoiceCommandInfo {
  final String command;
  final String description;
  
  const VoiceCommandInfo(this.command, this.description);
}
