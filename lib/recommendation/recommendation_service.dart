import 'dart:math';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/reaction_service.dart';
import '../services/playlist_service.dart';

class RecommendedBook {
  final Book book;
  final Author author;
  RecommendedBook({required this.book, required this.author});
}

class RecommendationService {
  final ApiService _apiService = ApiService();
  final HistoryService _historyService = HistoryService();
  final ReactionService _reactionService = ReactionService();
  final PlaylistService _playlistService = PlaylistService();

  Future<List<RecommendedBook>> getRecommendations() async {
    // 1. Fetch user history
    final history = _historyService.getHistory(uniqueByBook: false);

    // REQUIREMENT: Minimum 10 audio plays before creating recommendations
    if (history.length < 10) {
      return [];
    }

    // 2. Fetch all books from the library
    final allAuthors = await _apiService.fetchAuthors();
    final List<Book> allBooks = [];
    final Map<String, Author> bookToAuthor = {};

    for (var author in allAuthors) {
      for (var book in author.books) {
        allBooks.add(book);
        bookToAuthor[book.id] = author;
      }
    }

    if (allBooks.isEmpty) return [];

    // 3. Fetch other user data
    final reactions = _reactionService.getLikedAudios();
    final disliked = _reactionService.getDislikedAudios();
    final playlists = _playlistService.getPlaylists();

    // 4. Scoring Maps
    final Map<String, double> bookScores = {};
    final Map<String, double> authorScores = {};
    final Map<String, double> genreScores = {};

    // A. Process Likes
    for (var reaction in reactions) {
      final book = _historyService.fromBookEntity(reaction.book);
      final author = _historyService.fromAuthorEntity(reaction.author);
      final ag = parseAuthorGenre(book, author);

      authorScores[ag.author] = (authorScores[ag.author] ?? 0) + 12;
      if (ag.genre.isNotEmpty) {
        genreScores[ag.genre] = (genreScores[ag.genre] ?? 0) + 10;
      }
      bookScores[book.id] = (bookScores[book.id] ?? 0) + 8;
    }

    // B. Process Dislikes
    for (var reaction in disliked) {
      final book = _historyService.fromBookEntity(reaction.book);
      final author = _historyService.fromAuthorEntity(reaction.author);
      final ag = parseAuthorGenre(book, author);

      authorScores[ag.author] = (authorScores[ag.author] ?? 0) - 30;
      if (ag.genre.isNotEmpty) {
        genreScores[ag.genre] = (genreScores[ag.genre] ?? 0) - 25;
      }
      bookScores[book.id] = (bookScores[book.id] ?? 0) - 200;
    }

    // C. Process History
    for (var item in history) {
      final ag = parseAuthorGenre(item.book, item.author);
      double progress = item.duration > 0 ? (item.position / item.duration) : 0;

      if (progress > 0.05 && progress < 0.95) {
        bookScores[item.book.id] = (bookScores[item.book.id] ?? 0) + 20;
      } else if (progress >= 0.95) {
        authorScores[ag.author] = (authorScores[ag.author] ?? 0) + 6;
        if (ag.genre.isNotEmpty) {
          genreScores[ag.genre] = (genreScores[ag.genre] ?? 0) + 4;
        }
        bookScores[item.book.id] = (bookScores[item.book.id] ?? 0) + 3;
      }
    }

    // D. Process Playlists
    for (var playlist in playlists) {
      for (var item in playlist.items) {
        final ag = parseAuthorGenre(item.book, item.author);
        authorScores[ag.author] = (authorScores[ag.author] ?? 0) + 7;
        if (ag.genre.isNotEmpty) {
          genreScores[ag.genre] = (genreScores[ag.genre] ?? 0) + 5;
        }
        bookScores[item.book.id] = (bookScores[item.book.id] ?? 0) + 5;
      }
    }

    // 5. Final Scoring with timed randomness for stability
    final List<_ScoredItem> scoredItems = [];

    // Use a seed that changes every hour to keep suggestions fresh but stable
    // This prevents the "jumping" effect every few seconds
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day + now.hour;
    final random = Random(seed);

    for (var book in allBooks) {
      final authorOfBook = bookToAuthor[book.id]!;
      final ag = parseAuthorGenre(book, authorOfBook);

      double score = bookScores[book.id] ?? 0;
      score += authorScores[ag.author] ?? 0;
      score += genreScores[ag.genre] ?? 0;

      if (score > 0) {
        // Random boost is now stable for the current hour
        score += random.nextDouble() * 15.0;
        scoredItems.add(_ScoredItem(book, authorOfBook, score));
      }
    }

    // 6. Sort and Return top 15
    scoredItems.sort((a, b) => b.score.compareTo(a.score));

    return scoredItems
        .take(15)
        .map((si) => RecommendedBook(book: si.book, author: si.author))
        .toList();
  }

  // Helper to extract author and genre from book.author field
  AuthorGenreInfo parseAuthorGenre(Book book, Author author) {
    String authorName = author.name;
    String genre = '';

    if (book.author != null && book.author!.contains(':')) {
      final parts = book.author!.split(':');
      authorName = parts[0].trim();
      genre = parts[1].trim();
    }
    return AuthorGenreInfo(authorName, genre);
  }
}

class AuthorGenreInfo {
  final String author;
  final String genre;
  AuthorGenreInfo(this.author, this.genre);
}

class _ScoredItem {
  final Book book;
  final Author author;
  final double score;
  _ScoredItem(this.book, this.author, this.score);
}
