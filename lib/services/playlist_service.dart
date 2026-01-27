import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class PlaylistService {
  static const String boxName = 'playlists';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  Box get _box => Hive.box(boxName);

  List<Playlist> getPlaylists() {
    return _box.values
        .map((e) => Playlist.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> createPlaylist(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newPlaylist = Playlist(
      id: id,
      name: name,
      items: [],
      createdAt: DateTime.now(),
    );
    await _box.put(id, newPlaylist.toJson());
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _box.delete(playlistId);
  }

  Future<void> addToPlaylist(
      String playlistId, Book book, Author author) async {
    final data = _box.get(playlistId);
    if (data != null) {
      final playlist = Playlist.fromJson(Map<String, dynamic>.from(data));

      // Check if book already exists in playlist
      if (playlist.items.any((item) => item.book.id == book.id)) {
        return;
      }

      final newItem = PlaylistItem(
        book: book,
        author: author,
        addedAt: DateTime.now(),
      );

      final updatedPlaylist = Playlist(
        id: playlist.id,
        name: playlist.name,
        items: [...playlist.items, newItem],
        createdAt: playlist.createdAt,
      );

      await _box.put(playlistId, updatedPlaylist.toJson());
    }
  }

  Future<void> removeFromPlaylist(String playlistId, String bookId) async {
    final data = _box.get(playlistId);
    if (data != null) {
      final playlist = Playlist.fromJson(Map<String, dynamic>.from(data));
      final updatedItems =
          playlist.items.where((item) => item.book.id != bookId).toList();

      final updatedPlaylist = Playlist(
        id: playlist.id,
        name: playlist.name,
        items: updatedItems,
        createdAt: playlist.createdAt,
      );

      await _box.put(playlistId, updatedPlaylist.toJson());
    }
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final data = _box.get(playlistId);
    if (data != null) {
      final playlist = Playlist.fromJson(Map<String, dynamic>.from(data));
      final updatedPlaylist = Playlist(
        id: playlist.id,
        name: newName,
        items: playlist.items,
        createdAt: playlist.createdAt,
      );
      await _box.put(playlistId, updatedPlaylist.toJson());
    }
  }
}
