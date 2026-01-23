import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bookify_audio/package/audio_player.dart';
import 'package:bookify_audio/providers/audio_player_provider.dart';
import 'package:bookify_audio/services/history_service.dart';
import 'screens/home_screen.dart';
import 'screens/book_screen.dart';
import 'screens/player_screen.dart';
import 'screens/search_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open boxes
  await Hive.openBox('settings');
  await Hive.openBox('player_data');
  await HistoryService.init();

  // Lock to portrait mode for better audio-book experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Bookify Audio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(), // MainScreen handles BottomNav
        '/home': (context) => const HomeScreen(),
        '/book': (context) => const BookScreen(),
        '/player': (context) => const PlayerScreen(),
        '/search': (context) => const SearchScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      builder: (context, child) {
        final playerProvider = ref.watch(audioPlayerProvider);
        return Stack(
          children: [
            if (child != null) child,
            BookifyAudioWebPlayer(
              controller: playerProvider.service.controller,
            ),
          ],
        );
      },
    );
  }
}
