import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/playlist_service.dart';

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
  return PlaylistNotifier();
});

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  final PlaylistService _playlistService = PlaylistService();

  PlaylistNotifier() : super([]) {
    loadPlaylists();
  }

  void loadPlaylists() {
    state = _playlistService.getPlaylists();
  }

  Future<void> createPlaylist(String name) async {
    await _playlistService.createPlaylist(name);
    loadPlaylists();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistService.deletePlaylist(playlistId);
    loadPlaylists();
  }

  Future<void> addToPlaylist(
      String playlistId, Book book, Author author) async {
    await _playlistService.addToPlaylist(playlistId, book, author);
    loadPlaylists();
  }

  Future<void> removeFromPlaylist(String playlistId, String bookId) async {
    await _playlistService.removeFromPlaylist(playlistId, bookId);
    loadPlaylists();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    await _playlistService.renamePlaylist(playlistId, newName);
    loadPlaylists();
  }
}
