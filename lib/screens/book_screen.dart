import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/mini_player.dart';

class BookScreen extends ConsumerWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Book book = args['book'] as Book;
    final Author author = args['author'] as Author;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        elevation: 0,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Book header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book cover
                      Hero(
                        tag: 'book-cover-${book.id}',
                        child: Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
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
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              imageUrl: book.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Book info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              author.name,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${book.episodes.length} episode${book.episodes.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Episodes section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Episodes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (book.episodes.isNotEmpty)
                        Consumer(
                          builder: (context, ref, child) {
                            final audioPlayerNotifier =
                                ref.watch(audioPlayerProvider);
                            return TextButton.icon(
                              icon: const Icon(Icons.play_circle_filled),
                              label: const Text('Play All'),
                              onPressed: () {
                                // Play the first episode
                                audioPlayerNotifier.playEpisode(
                                  book.episodes.first,
                                  book,
                                  author,
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Episodes list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final episode = book.episodes[index];
                    return Consumer(
                      builder: (context, ref, child) {
                        final audioPlayerNotifier =
                            ref.watch(audioPlayerProvider);
                        final isCurrentEpisode =
                            audioPlayerNotifier.currentEpisode?.id ==
                                episode.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrentEpisode
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCurrentEpisode && audioPlayerNotifier.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: isCurrentEpisode
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                          title: Text(
                            episode.bookName,
                            style: TextStyle(
                              fontWeight: isCurrentEpisode
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('Voice: ${episode.voiceOwner}'),
                          onTap: () {
                            if (isCurrentEpisode) {
                              if (audioPlayerNotifier.isPlaying) {
                                audioPlayerNotifier.pause();
                              } else {
                                audioPlayerNotifier.play();
                              }
                            } else {
                              audioPlayerNotifier.playEpisode(
                                  episode, book, author);
                            }
                          },
                        );
                      },
                    );
                  },
                  childCount: book.episodes.length,
                ),
              ),

              // Bottom padding for mini player
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 80),
              ),
            ],
          ),

          // Mini player at the bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
