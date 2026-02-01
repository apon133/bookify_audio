import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authors_provider.dart';
import '../providers/recommendation_provider.dart';
import '../recommendation/recommendation_service.dart';
import '../services/api_service.dart';
import 'author_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _selectedLanguage = '';
  String _selectedBrowseMode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedLanguage = _apiService.currentLanguage;
        _selectedBrowseMode = _apiService.currentBrowseMode;
      });
      ref.read(authorsProvider).fetchAuthors();
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (languageCode == _selectedLanguage) return;
    setState(() => _selectedLanguage = languageCode);
    await _apiService.setLanguage(languageCode);
    ref.read(authorsProvider).fetchAuthors(languageCode: languageCode);
  }

  Future<void> _changeBrowseMode(String browseMode) async {
    if (browseMode == _selectedBrowseMode) return;
    setState(() => _selectedBrowseMode = browseMode);
    await _apiService.setBrowseMode(browseMode);
    ref.read(authorsProvider).fetchAuthors(browseMode: browseMode);
  }

  @override
  Widget build(BuildContext context) {
    final authorsNotifier = ref.watch(authorsProvider);
    final availableLanguages = _apiService.getAvailableLanguages();
    final availableBrowseModes = _apiService.getAvailableBrowseModes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookify Audio'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: _selectedBrowseMode.isEmpty ? null : _selectedBrowseMode,
              underline: const SizedBox(),
              dropdownColor: Theme.of(context).colorScheme.surface,
              icon: const Icon(Icons.filter_list),
              items: availableBrowseModes.map((mode) {
                return DropdownMenuItem<String>(
                  value: mode['code'],
                  child: Text(mode['name'] ?? ''),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) _changeBrowseMode(newValue);
              },
            ),
          ),
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
                if (newValue != null) _changeLanguage(newValue);
              },
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (authorsNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authorsNotifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${authorsNotifier.error}',
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => authorsNotifier.fetchAuthors(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (authorsNotifier.authors.isEmpty) {
            return const Center(child: Text('No authors found'));
          }

          final recommendationsNotifier = ref.watch(recommendationProvider);
          final recommendations = recommendationsNotifier.recommendations;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: authorsNotifier.authors.length +
                (recommendations.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (recommendations.isNotEmpty && index == 0) {
                return _buildRecommendationSection(context, recommendations);
              }

              final authorIndex =
                  recommendations.isNotEmpty ? index - 1 : index;
              final author = authorsNotifier.authors[authorIndex];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: author.image.isNotEmpty
                              ? CachedNetworkImageProvider(author.image)
                              : null,
                          backgroundColor: Colors.grey[300],
                          child: author.image.isEmpty
                              ? Text(
                                  author.name.isNotEmpty ? author.name[0] : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(author.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        AuthorScreen(author: author)));
                          },
                          child: const Text('See More'),
                        ),
                      ],
                    ),
                  ),
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
                            Navigator.pushNamed(context, '/book',
                                arguments: {'book': book, 'author': author});
                          },
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'book-cover-${book.id}',
                                  child: Container(
                                    height: 170,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 3)),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: book.cover.isNotEmpty
                                          ? CachedNetworkImage(
                                              fit: BoxFit.cover,
                                              errorWidget: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                          Icons.book,
                                                          size: 40,
                                                          color: Colors.grey)),
                                              imageUrl: book.cover,
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.book,
                                                  size: 40,
                                                  color: Colors.grey)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(book.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                if (book.author != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(book.author!,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
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
          );
        },
      ),
    );
  }

  Widget _buildRecommendationSection(
      BuildContext context, List<RecommendedBook> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Recommended For You',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: recommendations.length,
            itemBuilder: (context, bookIndex) {
              final recommended = recommendations[bookIndex];
              return _buildBookItem(context, recommended);
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(),
        ),
      ],
    );
  }

  Widget _buildBookItem(BuildContext context, RecommendedBook recommended) {
    final book = recommended.book;
    final author = recommended.author;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/book',
            arguments: {'book': book, 'author': author});
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'book-recommendation-${book.id}',
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: book.cover.isNotEmpty
                      ? CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: book.cover,
                          errorWidget: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.book,
                                size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.book,
                              size: 40, color: Colors.grey),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (book.author != null)
              Text(
                book.author!.split(':').first,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
