import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../providers/authors_provider.dart';
import 'author_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final authors = ref.read(authorsProvider).authors;
    ref.read(searchProvider).search(query, authors);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchProvider).clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchNotifier = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Search Bar
            Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
            
                // Search field
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _performSearch,
                      onSubmitted: (query) {
                        if (query.trim().isNotEmpty) {
                          ref.read(searchProvider).addRecentSearch(query);
                        }
                      },
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search authors, books, episodes...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyLarge?.color
                              ?.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color:
                                      theme.iconTheme.color?.withOpacity(0.7),
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            
                const SizedBox(width: 8),
              ],
            ),

            // Search Results or Recent Searches
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(searchNotifier, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchNotifier searchNotifier, ThemeData theme) {
    if (searchNotifier.isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (searchNotifier.query.isEmpty) {
      return _buildRecentSearches(searchNotifier, theme);
    }

    if (searchNotifier.results.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildSearchResults(searchNotifier, theme);
  }

  Widget _buildRecentSearches(SearchNotifier searchNotifier, ThemeData theme) {
    if (searchNotifier.recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for audiobooks',
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find your favorite authors, books, and episodes',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              TextButton(
                onPressed: () {
                  searchNotifier.clearRecentSearches();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: searchNotifier.recentSearches.length,
            itemBuilder: (context, index) {
              final search = searchNotifier.recentSearches[index];
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color: theme.iconTheme.color?.withOpacity(0.6),
                ),
                title: Text(search),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),
                  onPressed: () {
                    searchNotifier.removeRecentSearch(search);
                  },
                ),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: theme.iconTheme.color?.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchNotifier searchNotifier, ThemeData theme) {
    // Group results by type
    final authors = searchNotifier.results
        .where((r) => r.type == SearchResultType.author)
        .toList();
    final books = searchNotifier.results
        .where((r) => r.type == SearchResultType.book)
        .toList();
    final episodes = searchNotifier.results
        .where((r) => r.type == SearchResultType.episode)
        .toList();

    return ListView(
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${searchNotifier.results.length} results found',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
          ),
        ),

        // Authors section
        if (authors.isNotEmpty) ...[
          _buildSectionHeader('Authors', authors.length, theme),
          ...authors.map((result) => _buildAuthorItem(result, theme)),
        ],

        // Books section
        if (books.isNotEmpty) ...[
          _buildSectionHeader('Books', books.length, theme),
          ...books.map((result) => _buildBookItem(result, theme)),
        ],

        // Episodes section
        if (episodes.isNotEmpty) ...[
          _buildSectionHeader('Episodes', episodes.length, theme),
          ...episodes.map((result) => _buildEpisodeItem(result, theme)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        '$title ($count)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildAuthorItem(SearchResult result, ThemeData theme) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: result.imageUrl.isNotEmpty
            ? CachedNetworkImageProvider(result.imageUrl)
            : null,
        backgroundColor: theme.primaryColor.withOpacity(0.2),
        child: result.imageUrl.isEmpty
            ? Text(
                result.title.isNotEmpty ? result.title[0] : '?',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        result.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(result.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ref
            .read(searchProvider)
            .addRecentSearch(ref.read(searchProvider).query);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthorScreen(author: result.data),
          ),
        );
      },
    );
  }

  Widget _buildBookItem(SearchResult result, ThemeData theme) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: result.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: result.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) {
                    return Container(
                      color: theme.primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.book,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                )
              : Container(
                  color: theme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.book,
                    color: theme.primaryColor,
                  ),
                ),
        ),
      ),
      title: Text(
        result.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ref
            .read(searchProvider)
            .addRecentSearch(ref.read(searchProvider).query);
        Navigator.pushNamed(
          context,
          '/book',
          arguments: {
            'book': result.data,
            'author': result.author,
          },
        );
      },
    );
  }

  Widget _buildEpisodeItem(SearchResult result, ThemeData theme) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: result.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: result.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) {
                    return Container(
                      color: theme.primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.headphones,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                )
              : Container(
                  color: theme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.headphones,
                    color: theme.primaryColor,
                  ),
                ),
        ),
      ),
      title: Text(
        result.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.play_circle_outline),
      onTap: () {
        ref
            .read(searchProvider)
            .addRecentSearch(ref.read(searchProvider).query);
        // Navigate to book screen which contains the episode
        Navigator.pushNamed(
          context,
          '/book',
          arguments: {
            'book': result.author?.books.firstWhere(
              (book) => book.episodes.any((ep) => ep.id == result.id),
            ),
            'author': result.author,
          },
        );
      },
    );
  }
}
