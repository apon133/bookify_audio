import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/playlist_provider.dart';

class SaveToPlaylistSheet extends ConsumerStatefulWidget {
  final Book book;
  final Author author;

  const SaveToPlaylistSheet({
    super.key,
    required this.book,
    required this.author,
  });

  @override
  ConsumerState<SaveToPlaylistSheet> createState() =>
      _SaveToPlaylistSheetState();
}

class _SaveToPlaylistSheetState extends ConsumerState<SaveToPlaylistSheet> {
  bool _isCreatingNew = false;
  final TextEditingController _newPlaylistController = TextEditingController();

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistProvider);
    final playlistNotifier = ref.read(playlistProvider.notifier);

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Save to playlist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _isCreatingNew = true;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // New Playlist Input
          if (_isCreatingNew)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newPlaylistController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'New playlist name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      if (_newPlaylistController.text.isNotEmpty) {
                        await playlistNotifier
                            .createPlaylist(_newPlaylistController.text);
                        _newPlaylistController.clear();
                        setState(() {
                          _isCreatingNew = false;
                        });
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            ),

          // Playlist List
          if (playlists.isEmpty && !_isCreatingNew)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.playlist_add, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No playlists yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isCreatingNew = true;
                        });
                      },
                      child: const Text('Create New Playlist'))
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final isInPlaylist = playlist.items
                      .any((item) => item.book.id == widget.book.id);

                  return CheckboxListTile(
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.items.length} videos'),
                    value: isInPlaylist,
                    onChanged: (bool? value) {
                      if (value == true) {
                        playlistNotifier.addToPlaylist(
                            playlist.id, widget.book, widget.author);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${playlist.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        playlistNotifier.removeFromPlaylist(
                            playlist.id, widget.book.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed from ${playlist.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          )
        ],
      ),
    );
  }
}
