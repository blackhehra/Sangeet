import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing search history with persistence
class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 20;
  
  static final SearchHistoryService _instance = SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();
  
  static SearchHistoryService get instance => _instance;
  
  final List<String> _searchHistory = [];
  bool _isLoaded = false;
  
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  
  /// Initialize and load search history from storage
  Future<void> init() async {
    if (_isLoaded) return;
    await _loadSearchHistory();
    _isLoaded = true;
  }
  
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_searchHistoryKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _searchHistory.clear();
        _searchHistory.addAll(jsonList.cast<String>());
      }
      print('SearchHistoryService: Loaded ${_searchHistory.length} search history items');
    } catch (e) {
      print('SearchHistoryService: Error loading search history: $e');
    }
  }
  
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_searchHistory);
      await prefs.setString(_searchHistoryKey, jsonString);
    } catch (e) {
      print('SearchHistoryService: Error saving search history: $e');
    }
  }
  
  /// Add a search query to history
  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final trimmedQuery = query.trim();
    
    // Remove if already exists (to move to top)
    _searchHistory.remove(trimmedQuery);
    
    // Add to beginning
    _searchHistory.insert(0, trimmedQuery);
    
    // Limit history size
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeRange(_maxHistoryItems, _searchHistory.length);
    }
    
    await _saveSearchHistory();
  }
  
  /// Remove a search query from history
  Future<void> removeSearch(String query) async {
    _searchHistory.remove(query);
    await _saveSearchHistory();
  }
  
  /// Clear all search history
  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _saveSearchHistory();
  }
  
  /// Get recent searches (limited)
  List<String> getRecentSearches({int limit = 10}) {
    return _searchHistory.take(limit).toList();
  }
}
