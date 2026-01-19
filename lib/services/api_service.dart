import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl =
      'https://gokeihub.github.io/bookify_api/new.json';
  static const String authorsBoxName = 'authors';
  static const String cacheKey = 'cached_authors_data';

  // Get the Hive box for authors
  Box<String> get _cacheBox => Hive.box<String>('cache');

  // Fetch authors from API or cache
  Future<List<Author>> fetchAuthors({bool forceRefresh = false}) async {
    try {
      // If forceRefresh is true or we don't have cached data, fetch from API
      if (forceRefresh || !(await _hasCachedData())) {
        return await _fetchFromApi();
      }

      // Otherwise, try to load from cache first
      try {
        return await _loadAuthorsFromCache();
      } catch (cacheError) {
        // If cache fails, fall back to API
        print('Cache error: $cacheError');
        return await _fetchFromApi();
      }
    } catch (e) {
      print('Exception details: $e');
      // If there's an exception with API, try to load from cache
      try {
        return await _loadAuthorsFromCache();
      } catch (cacheError) {
        print('Cache error: $cacheError');
        throw Exception('Failed to load authors: $e');
      }
    }
  }

  // Helper method to check if we have cached data
  Future<bool> _hasCachedData() async {
    final jsonString = _cacheBox.get(cacheKey);
    return jsonString != null && jsonString.isNotEmpty;
  }

  // Helper method to fetch from API
  Future<List<Author>> _fetchFromApi() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      // Print the raw response for debugging
      print('Raw API response: ${response.body}');

      final List<dynamic> decodedData =
          jsonDecode(response.body) as List<dynamic>;

      // Save the fresh data to Hive
      await _saveAuthorsToCache(response.body);

      // Process each item carefully with proper type checking
      return decodedData.map((item) {
        // Ensure each item is properly cast to Map<String, dynamic>
        if (item is Map) {
          return Author.fromJson(Map<String, dynamic>.from(item));
        } else {
          throw Exception('Invalid author data format: $item');
        }
      }).toList();
    } else {
      throw Exception('Failed to load authors: ${response.statusCode}');
    }
  }

  // Save authors data to Hive
  Future<void> _saveAuthorsToCache(String jsonData) async {
    try {
      await _cacheBox.put(cacheKey, jsonData);
      print('Authors data saved to Hive cache');
    } catch (e) {
      print('Failed to save authors to cache: $e');
    }
  }

  // Load authors data from Hive
  Future<List<Author>> _loadAuthorsFromCache() async {
    final jsonString = _cacheBox.get(cacheKey);

    if (jsonString == null || jsonString.isEmpty) {
      throw Exception('No cached data available');
    }

    print('Loading authors from Hive cache');
    final List<dynamic> decodedData = jsonDecode(jsonString) as List<dynamic>;

    return decodedData.map((item) {
      if (item is Map) {
        return Author.fromJson(Map<String, dynamic>.from(item));
      } else {
        throw Exception('Invalid cached author data format');
      }
    }).toList();
  }

  // Check if there is newer data available
  Future<bool> hasNewData() async {
    try {
      final cachedData = _cacheBox.get(cacheKey);

      if (cachedData == null) return true;

      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        return response.body != cachedData;
      }
      return false;
    } catch (e) {
      print('Error checking for new data: $e');
      return false;
    }
  }
}
