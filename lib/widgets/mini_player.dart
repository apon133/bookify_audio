import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioPlayerNotifier = ref.watch(audioPlayerProvider);

    if (!audioPlayerNotifier.isMiniPlayerVisible) {
      return const SizedBox.shrink();
    }

    final episode = audioPlayerNotifier.currentEpisode;
    final book = audioPlayerNotifier.currentBook;
    final author = audioPlayerNotifier.currentAuthor;

    if (episode == null || book == null || author == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/player',
          arguments: {
            'episode': episode,
            'book': book,
            'author': author,
          },
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? 1000 : double.infinity,
          ),
          child: Container(
            margin: isWide ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10) : EdgeInsets.zero,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: isWide ? BorderRadius.circular(16) : BorderRadius.zero,
              color: theme.colorScheme.surface.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: isWide ? BorderRadius.circular(16) : BorderRadius.zero,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  children: [
                    // Progress bar
                    LinearProgressIndicator(
                      value: audioPlayerNotifier.duration.inMilliseconds > 0
                          ? audioPlayerNotifier.position.inMilliseconds /
                              audioPlayerNotifier.duration.inMilliseconds
                          : 0.0,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      minHeight: 2,
                    ),

                    // Player controls and info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            // Book cover
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: book.cover.isNotEmpty
                                  ? CachedNetworkImage(
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      imageUrl: book.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.book, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.book, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 12),

                            // Episode info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    episode.bookName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    author.name,
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Play/Pause button
                            IconButton(
                              icon: Icon(
                                audioPlayerNotifier.isPlaying
                                    ? Icons.play_circle_filled
                                    : Icons.pause_circle_filled,
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () {
                                if (audioPlayerNotifier.isPlaying) {
                                  audioPlayerNotifier.pause();
                                } else {
                                  audioPlayerNotifier.play();
                                }
                              },
                            ),

                            // Close button
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                await audioPlayerNotifier.stop();
                                Future.microtask(() {
                                  audioPlayerNotifier.hideMiniPlayer();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
