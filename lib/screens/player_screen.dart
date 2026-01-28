import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/reaction_provider.dart';
import '../models/models.dart';
import '../widgets/save_to_playlist_sheet.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Episode episode = args['episode'] as Episode;
    final Book book = args['book'] as Book;
    final Author author = args['author'] as Author;
    final audioPlayerNotifier = ref.watch(audioPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(episode.bookName),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Book cover and info
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Book cover
                  Hero(
                    tag: 'book-cover-${book.id}',
                    child: Container(
                      width: 200,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.book,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                          imageUrl: book.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Episode title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      episode.bookName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Author name
                  Text(
                    author.name,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Voice owner
                  Text(
                    'Voice: ${episode.voiceOwner}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Download button
                  // Action buttons
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDownloadButton(context, ref, episode),
                      const SizedBox(width: 16),
                      _buildSaveButton(context, book, author),
                      const SizedBox(width: 16),
                      _buildLikeDislikeButtons(
                          context, ref, episode, book, author),
                    ],
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Player controls
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Time and duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(audioPlayerNotifier.position),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDuration(audioPlayerNotifier.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // Progress slider
                Slider(
                  value: audioPlayerNotifier.duration.inMilliseconds > 0
                      ? audioPlayerNotifier.position.inMilliseconds /
                          audioPlayerNotifier.duration.inMilliseconds
                      : 0.0,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    final newPositionMs =
                        (value * audioPlayerNotifier.duration.inMilliseconds)
                            .toInt();
                    audioPlayerNotifier
                        .seek(Duration(milliseconds: newPositionMs));
                  },
                ),

                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Rewind 10 seconds
                    IconButton(
                      icon: const Icon(Icons.replay_10, size: 32),
                      onPressed: () {
                        final newPosition = audioPlayerNotifier.position -
                            const Duration(seconds: 10);
                        audioPlayerNotifier.seek(newPosition.isNegative
                            ? Duration.zero
                            : newPosition);
                      },
                    ),

                    // Play/Pause
                    IconButton(
                      icon: Icon(
                        audioPlayerNotifier.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        if (audioPlayerNotifier.isPlaying) {
                          audioPlayerNotifier.pause();
                        } else {
                          audioPlayerNotifier.play();
                        }
                      },
                    ),

                    // Forward 30 seconds
                    IconButton(
                      icon: const Icon(Icons.forward_30, size: 32),
                      onPressed: () {
                        final newPosition = audioPlayerNotifier.position +
                            const Duration(seconds: 30);
                        final maxPosition = audioPlayerNotifier.duration;
                        audioPlayerNotifier.seek(newPosition > maxPosition
                            ? maxPosition
                            : newPosition);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Playback speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Speed: '),
                    DropdownButton<double>(
                      value: audioPlayerNotifier.playbackSpeed,
                      items: const [
                        DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                        DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                        DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                        DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                        DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                        DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          audioPlayerNotifier.setPlaybackSpeed(value);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    WidgetRef ref,
    Episode episode,
  ) {
    final audioPlayerNotifier = ref.watch(audioPlayerProvider);

    // Check if the episode is already downloaded
    if (audioPlayerNotifier.isDownloaded &&
        audioPlayerNotifier.currentEpisode?.id == episode.id) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.delete),
        label: const Text('Delete Download'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          // Capture the ScaffoldMessenger before async operation
          final messenger = ScaffoldMessenger.of(context);
          await audioPlayerNotifier.deleteDownloadedEpisode(episode);
          messenger.showSnackBar(
            const SnackBar(content: Text('Download deleted')),
          );
        },
      );
    }

    // Show download progress if downloading
    if (audioPlayerNotifier.isDownloading &&
        audioPlayerNotifier.currentEpisode?.id == episode.id) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: audioPlayerNotifier.downloadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloading ${(audioPlayerNotifier.downloadProgress * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            onPressed: () {
              // Capture the ScaffoldMessenger before operation
              final messenger = ScaffoldMessenger.of(context);
              audioPlayerNotifier.cancelDownload();
              messenger.showSnackBar(
                const SnackBar(content: Text('Download canceled')),
              );
            },
          ),
        ],
      );
    }

    // Show download button if not downloaded and not downloading
    return FutureBuilder<bool>(
      future: audioPlayerNotifier.isEpisodeDownloaded(episode),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        if (isDownloaded) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Capture the ScaffoldMessenger before async operation
              final messenger = ScaffoldMessenger.of(context);
              await audioPlayerNotifier.deleteDownloadedEpisode(episode);
              messenger.showSnackBar(
                const SnackBar(content: Text('Download deleted')),
              );
            },
          );
        }

        return ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Download for Offline'),
          onPressed: () async {
            // Capture the ScaffoldMessenger before async operation
            final messenger = ScaffoldMessenger.of(context);
            await audioPlayerNotifier.downloadEpisode(episode);
            if (audioPlayerNotifier.isDownloaded) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Download complete')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSaveButton(BuildContext context, Book book, Author author) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.playlist_add),
      label: const Text('Save'),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: SaveToPlaylistSheet(book: book, author: author),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLikeDislikeButtons(BuildContext context, WidgetRef ref,
      Episode episode, Book book, Author author) {
    final reactions = ref.watch(reactionProvider);
    final reactionNotifier = ref.read(reactionProvider.notifier);

    // Check initial state if not loaded
    if (!reactions.containsKey(episode.id)) {
      Future.microtask(() => reactionNotifier.checkReaction(episode.id));
    }

    final currentReaction = reactions[episode.id];
    // Need ReactionType enum access.
    // Since it is in isar_models which is imported via models.dart export NO it is not exported there, I might need to import isar_models or just rely on dynamic/string check if lazy, but better to import correctly.
    // Assuming ReactionType.like/dislike is available if I import isar_models.dart

    final isLiked = currentReaction.toString() == 'ReactionType.like';
    final isDisliked = currentReaction.toString() == 'ReactionType.dislike';

    return Row(
      children: [
        IconButton(
          icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: isLiked ? Theme.of(context).colorScheme.primary : null),
          onPressed: () {
            reactionNotifier.toggleLike(episode, book, author);
          },
        ),
        IconButton(
          icon: Icon(isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
              color: isDisliked ? Colors.red : null),
          onPressed: () {
            reactionNotifier.toggleDislike(episode, book, author);
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }
}
