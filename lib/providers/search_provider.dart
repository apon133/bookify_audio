import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/author.dart';

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final SearchResultType type;
  final dynamic data; // Can be Author, Book, or Episode
  final Author? author; // For books and episodes

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.type,
    required this.data,
    this.author,
  });
}

enum SearchResultType {
  author,
  book,
  episode,
}

class SearchNotifier extends ChangeNotifier {
  String _query = '';
  List<SearchResult> _results = [];
  bool _isSearching = false;
  List<String> _recentSearches = [];

  String get query => _query;
  List<SearchResult> get results => _results;
  bool get isSearching => _isSearching;
  List<String> get recentSearches => _recentSearches;

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;

    // Remove if already exists
    _recentSearches.remove(query);

    // Add to beginning
    _recentSearches.insert(0, query);

    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }

    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    notifyListeners();
  }

  void search(String query, List<Author> authors) {
    _query = query;
    _isSearching = true;
    notifyListeners();

    if (query.trim().isEmpty) {
      _results = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    final List<SearchResult> searchResults = [];

    for (final author in authors) {
      // Search in author names
      if (author.name.toLowerCase().contains(lowercaseQuery)) {
        searchResults.add(SearchResult(
          id: author.id,
          title: author.name,
          subtitle: '${author.books.length} books',
          imageUrl: author.image,
          type: SearchResultType.author,
          data: author,
        ));
      }

      // Search in books
      for (final book in author.books) {
        if (book.title.toLowerCase().contains(lowercaseQuery)) {
          searchResults.add(SearchResult(
            id: book.id,
            title: book.title,
            subtitle:
                'by ${book.author != null ? book.author!.split(':').first.trim() : author.name} • ${book.episodes.length} episodes',
            imageUrl: book.cover,
            type: SearchResultType.book,
            data: book,
            author: author,
          ));
        }

        // Search in episodes
        for (final episode in book.episodes) {
          if (episode.bookName.toLowerCase().contains(lowercaseQuery) ||
              episode.voiceOwner.toLowerCase().contains(lowercaseQuery)) {
            searchResults.add(SearchResult(
              id: episode.id,
              title: episode.bookName,
              subtitle:
                  'Episode in ${book.title} • Voice: ${episode.voiceOwner}',
              imageUrl: book.cover,
              type: SearchResultType.episode,
              data: episode,
              author: author,
            ));
          }
        }
      }
    }

    _results = searchResults;
    _isSearching = false;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _results = [];
    _isSearching = false;
    notifyListeners();
  }
}

// Riverpod provider
final searchProvider = ChangeNotifierProvider<SearchNotifier>((ref) {
  return SearchNotifier();
});
