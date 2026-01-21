import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authors_provider.dart';
import '../services/api_service.dart';
import '../widgets/mini_player.dart';
import 'author_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _selectedLanguage = '';

  @override
  void initState() {
    super.initState();
    // Get current language and fetch authors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedLanguage = _apiService.currentLanguage;
      });
      ref.read(authorsProvider).fetchAuthors();
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (languageCode == _selectedLanguage) return;

    setState(() {
      _selectedLanguage = languageCode;
    });

    // Save language preference
    await _apiService.setLanguage(languageCode);

    // Reload authors with new language
    ref.read(authorsProvider).fetchAuthors(languageCode: languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final authorsNotifier = ref.watch(authorsProvider);
    final availableLanguages = _apiService.getAvailableLanguages();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookify Audio'),
        elevation: 0,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),

          // Language dropdown
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedLanguage.isEmpty ? null : _selectedLanguage,
              underline: const SizedBox(),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: availableLanguages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang['code'],
                  child: Text(lang['name'] ?? ''),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _changeLanguage(newValue);
                }
              },
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (authorsNotifier.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (authorsNotifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${authorsNotifier.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      authorsNotifier.fetchAuthors();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (authorsNotifier.authors.isEmpty) {
            return const Center(
              child: Text('No authors found'),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(
                    bottom: 80), // Add padding for mini player
                itemCount: authorsNotifier.authors.length,
                itemBuilder: (context, index) {
                  final author = authorsNotifier.authors[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author section header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  CachedNetworkImageProvider(author.image),
                              onBackgroundImageError: (_, __) {},
                              backgroundColor: Colors.grey[300],
                              child: author.image.isEmpty
                                  ? Text(
                                      author.name.isNotEmpty
                                          ? author.name[0]
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                author.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AuthorScreen(author: author),
                                  ),
                                );
                              },
                              child: const Text('See More'),
                            ),
                          ],
                        ),
                      ),

                      // Books horizontal list
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: author.books.length,
                          itemBuilder: (context, bookIndex) {
                            final book = author.books[bookIndex];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/book',
                                  arguments: {
                                    'book': book,
                                    'author': author,
                                  },
                                );
                              },
                              child: Container(
                                width: 120,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Book cover
                                    Hero(
                                      tag: 'book-cover-${book.id}',
                                      child: Container(
                                        height: 170,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, error, stackTrace) {
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

                                    const SizedBox(height: 8),

                                    // Book title
                                    Text(
                                      book.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),

              // Mini player at the bottom
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MiniPlayer(),
              ),
            ],
          );
        },
      ),
    );
  }
}
