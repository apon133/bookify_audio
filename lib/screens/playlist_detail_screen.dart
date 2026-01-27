import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/playlist_provider.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider to get updates if items are removed
    final playlists = ref.watch(playlistProvider);
    // Find the current version of this playlist
    final currentPlaylist = playlists.firstWhere(
      (p) => p.id == playlist.id,
      orElse: () => playlist,
    );

    final playlistNotifier = ref.read(playlistProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlaylist.name),
      ),
      body: currentPlaylist.items.isEmpty
          ? const Center(
              child: Text('No audiobooks in this playlist'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentPlaylist.items.length,
              itemBuilder: (context, index) {
                final item = currentPlaylist.items[index];
                return Dismissible(
                  key: Key(item.book.id),
                  background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white)),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    playlistNotifier.removeFromPlaylist(
                        currentPlaylist.id, item.book.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Image.network(
                        item.book.cover,
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 50, child: Icon(Icons.book)),
                      ),
                      title: Text(item.book.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item.author.name),
                      onTap: () {
                        // Play the first episode of the book or resume?
                        // For now, let's just go to book screen or player if we know the episode.
                        // Ideally we'd play the book.
                        if (item.book.episodes.isNotEmpty) {
                          Navigator.pushNamed(context, '/player', arguments: {
                            'episode': item.book.episodes.first,
                            'book': item.book,
                            'author': item.author,
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'No episodes available for this book')));
                        }
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          // Show options like remove
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.delete),
                                        title:
                                            const Text('Remove from playlist'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          playlistNotifier.removeFromPlaylist(
                                              currentPlaylist.id, item.book.id);
                                        },
                                      )
                                    ],
                                  ),
                                );
                              });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
