import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/author.dart';
import '../providers/authors_provider.dart';
import 'author_screen.dart';

class WriterProfileScreen extends ConsumerStatefulWidget {
  const WriterProfileScreen({super.key});

  @override
  ConsumerState<WriterProfileScreen> createState() => _WriterProfileScreenState();
}

class _WriterProfileScreenState extends ConsumerState<WriterProfileScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch authors to ensure they are available for "View All Books" matching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authorsProvider).fetchAuthors();
    });
  }

  // Hardcoded list of top authors with biographical info in Bengali
  final List<Author> _topAuthors = [
    Author(
      id: '1',
      name: 'হুমায়ূন আহমেদ',
      image: 'https://i.postimg.cc/L6YqN8Lw/humayun-ahmed.jpg',
      born: '১৩ নভেম্বর ১৯৪৮',
      bornYear: 1948,
      death: '১৯ জুলাই ২০১২',
      deathYear: 2012,
      bornLocation: 'কুতুবপুর, নেত্রকোণা',
      education: 'ঢাকা বিশ্ববিদ্যালয়',
      occupation: 'লেখক, নাট্যকার, চলচ্চিত্র পরিচালক',
      otherInfo: 'তিনি বিংশ শতাব্দীর অন্যতম জনপ্রিয় বাঙালি কথাসাহিত্যিক। তাকে বাংলাদেশের স্বাধীনতোত্তর শ্রেষ্ঠ লেখক হিসেবে গণ্য করা হয়।',
      books: [],
    ),
    Author(
      id: '2',
      name: 'রবীন্দ্রনাথ ঠাকুর',
      image: 'https://i.postimg.cc/L6YqN8Lw/rabindranath.jpg',
      born: '৭ মে ১৮৬১',
      bornYear: 1861,
      death: '৭ আগস্ট ১৯৪১',
      deathYear: 1941,
      bornLocation: 'জোড়াসাঁকো ঠাকুরবাড়ি, কলকাতা',
      education: 'গৃহশিক্ষা',
      occupation: 'কবি, ঔপন্যাসিক, সংগীতজ্ঞ, চিত্রকর',
      otherInfo: '১৯১৩ সালে গীতাঞ্জলি কাব্যগ্রন্থের জন্য তিনি সাহিত্যে নোবেল পুরস্কার লাভ করেন।',
      books: [],
    ),
    Author(
      id: '3',
      name: 'কাজী নজরুল ইসলাম',
      image: 'https://i.postimg.cc/L6YqN8Lw/kazi-nazrul.jpg',
      born: '২৪ মে ১৮৯৯',
      bornYear: 1899,
      death: '২৯ আগস্ট ১৯৭৬',
      deathYear: 1976,
      bornLocation: 'চুরুলিয়া, বর্ধমান',
      education: 'শিয়ারসোল রাজ হাই স্কুল',
      occupation: 'কবি, লেখক, সংগীতজ্ঞ, সাংবাদিক',
      otherInfo: 'তিনি বাংলাদেশের জাতীয় কবি। তাকে \'বিদ্রোহী কবি\' বলা হয়।',
      books: [],
    ),
    Author(
      id: '4',
      name: 'শরৎচন্দ্র চট্টোপাধ্যায়',
      image: 'https://i.postimg.cc/L6YqN8Lw/sarat-chandra.jpg',
      born: '১৫ সেপ্টেম্বর ১৮৭৬',
      bornYear: 1876,
      death: '১৬ জানুয়ারি ১৯৩৮',
      deathYear: 1938,
      bornLocation: 'দেবানন্দপুর, হুগলি',
      education: 'তেজনারায়ণ জুবিলি কলেজ',
      occupation: 'ঔপন্যাসিক, ছোটগল্পকার',
      otherInfo: 'তিনি জনপ্রিয়তার দিক থেকে বাংলা সাহিত্যের অন্যতম প্রধান লেখক।',
      books: [],
    ),
    Author(
      id: '5',
      name: 'মুহম্মদ জাফর ইকবাল',
      image: 'https://i.postimg.cc/9fKqYZJL/jafar-iqbal.jpg',
      born: '২৩ ডিসেম্বর ১৯৫২',
      bornYear: 1952,
      death: null,
      deathYear: null,
      bornLocation: 'সিলেট',
      education: 'ঢাকা বিশ্ববিদ্যালয়, ওয়াশিংটন বিশ্ববিদ্যালয়',
      occupation: 'লেখক, পদার্থবিদ, অধ্যাপক',
      otherInfo: 'তিনি বাংলাদেশের একজন অত্যন্ত জনপ্রিয় বিজ্ঞান কল্পকাহিনী লেখক এবং শিক্ষাবিদ।',
      books: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedAuthor = _topAuthors[_selectedIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar - 5 Author Rectangles
            Container(
              width: 100,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black12,
                    width: 1,
                  ),
                ),
              ),
              child: ListView.builder(
                itemCount: _topAuthors.length,
                itemBuilder: (context, index) {
                  final author = _topAuthors[index];
                  final isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      height: 80,
                      margin: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withOpacity(0.2)
                            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: theme.primaryColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            author.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? theme.primaryColor : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Right Detail View - Circular Profile and Info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Large Circular Profile Image
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: selectedAuthor.image,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, size: 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Information section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('নাম', selectedAuthor.name, theme),
                          _buildInfoRow('বয়স', selectedAuthor.calculatedAge, theme),
                          _buildInfoRow('জন্ম', selectedAuthor.born ?? 'অজানা', theme),
                          _buildInfoRow('জন্মস্থান', selectedAuthor.bornLocation ?? 'অজানা', theme),
                          _buildInfoRow('মৃত্যু', selectedAuthor.death ?? 'চলমান', theme),
                          _buildInfoRow('শিক্ষা', selectedAuthor.education ?? 'অজানা', theme),
                          _buildInfoRow('পেশা', selectedAuthor.occupation ?? 'অজানা', theme),
                          _buildInfoRow('অন্যান্য তথ্য', selectedAuthor.otherInfo ?? 'তথ্য নেই', theme),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Button to view books
                    ElevatedButton.icon(
                      onPressed: () {
                        final authorsNotifier = ref.read(authorsProvider);
                        final apiAuthors = authorsNotifier.authors;
                        
                        if (authorsNotifier.isLoading && apiAuthors.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('লাইব্রেরি লোড হচ্ছে, দয়া করে অপেক্ষা করুন...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          return;
                        }

                        // Try to find the exact author in the API results
                        Author? author;
                        try {
                          // Match by first part of name or full name
                          final firstName = selectedAuthor.name.split(' ')[0];
                          author = apiAuthors.firstWhere(
                            (a) => a.name.contains(firstName) || 
                                   selectedAuthor.name.contains(a.name) ||
                                   a.name == selectedAuthor.name,
                          );
                        } catch (_) {
                          author = null;
                        }

                        if (author != null && author.books.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthorScreen(author: author!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(author == null 
                                ? 'লাইব্রেরিতে ${selectedAuthor.name}-কে পাওয়া যায়নি।'
                                : '${selectedAuthor.name}-এর কোনো বই এই মুহূর্তে পাওয়া যায়নি।'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.book),
                      label: const Text('সব বই দেখুন'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
