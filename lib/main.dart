import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookify_audio/package/audio_player.dart';
import 'package:bookify_audio/providers/audio_player_provider.dart';
import 'package:bookify_audio/services/history_service.dart';
import 'package:bookify_audio/services/playlist_service.dart';
import 'screens/home_screen.dart';
import 'screens/book_screen.dart';
import 'screens/player_screen.dart';
import 'screens/search_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services (Isar)
  await PlaylistService.init();
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





// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// void main() {
//   runApp(const MaterialApp(
//     home: SponsorBlockVideoPlayer(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

// class SponsorBlockVideoPlayer extends StatefulWidget {
//   const SponsorBlockVideoPlayer({super.key});

//   @override
//   State<SponsorBlockVideoPlayer> createState() => _SponsorBlockVideoPlayerState();
// }

// class _SponsorBlockVideoPlayerState extends State<SponsorBlockVideoPlayer> {
//   late YoutubePlayerController _controller;
//   final TextEditingController _urlController = TextEditingController(
//     text: 'https://www.youtube.com/watch?v=RL-KEUfUrp8',
//   );

//   List<Map<String, double>> _segments = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = YoutubePlayerController(
//       initialVideoId: 'RL-KEUfUrp8',
//       flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
//     )..addListener(_listener);
//   }

//   void _listener() {
//     if (_controller.value.isReady && mounted) {
//       _checkAndSkipSponsors();
//       setState(() {});
//     }
//   }

//   Future<void> _fetchSegments(String videoId) async {
//     try {
//       final response = await http.get(Uri.parse(
//           'https://sponsor.ajay.app/api/skipSegments?videoID=$videoId&category=sponsor&category=intro'));

//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         setState(() {
//           _segments = data.map<Map<String, double>>((s) {
//             return {
//               'start': (s['segment'][0] as num).toDouble(),
//               'end': (s['segment'][1] as num).toDouble(),
//             };
//           }).toList();
//         });
//       } else {
//         setState(() => _segments = []);
//       }
//     } catch (e) {
//       setState(() => _segments = []);
//     }
//   }

//   void _checkAndSkipSponsors() {
//     final currentSecond = _controller.value.position.inSeconds.toDouble();
//     for (var segment in _segments) {
//       if (currentSecond >= segment['start']! && currentSecond < segment['end']!) {
//         _controller.seekTo(Duration(seconds: segment['end']!.toInt() + 1));
//         break;
//       }
//     }
//   }

//   void _loadVideo() async {
//     final videoId = YoutubePlayer.convertUrlToId(_urlController.text.trim());
//     if (videoId != null) {
//       setState(() => _isLoading = true);
//       await _fetchSegments(videoId);
//       _controller.load(videoId);
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('SponsorBlock Visualizer'), backgroundColor: Colors.red),
//       body: Column(
//         children: [
//           YoutubePlayer(
//             controller: _controller,
//             showVideoProgressIndicator: true,
//             // ডিফল্ট প্রগ্রেস বার সরিয়ে আমরা নিচে কাস্টম বার দেব
//             bottomActions: [
//               const SizedBox(width: 14.0),
//               CurrentPosition(),
//               const SizedBox(width: 8.0),
//               // এই কাস্টম উইজেটটি স্লাইডারে কালার দেখাবে
//               Expanded(child: _buildCustomProgressBar()),
//               const SizedBox(width: 8.0),
//               RemainingDuration(),
//               PlaybackSpeedButton(),
//             ],
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _urlController,
//                   decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'YouTube URL'),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _loadVideo,
//                   style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
//                   child: Text(_isLoading ? 'Loading...' : 'Load Video'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // স্লাইডারে সেগমেন্ট কালার দেখানোর লজিক
//   Widget _buildCustomProgressBar() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         double totalDuration = _controller.metadata.duration.inSeconds.toDouble();
//         if (totalDuration == 0) totalDuration = 1; // Division by zero এড়াতে

//         return Stack(
//           alignment: Alignment.centerLeft,
//           children: [
//             // ১. মূল প্রগ্রেস বার (ডিফল্ট ইউটিউব স্টাইল)
//             ProgressBar(
//               controller: _controller,
//               isExpanded: true,
//               colors: const ProgressBarColors(
//                 playedColor: Colors.red,
//                 handleColor: Colors.redAccent,
//                 bufferedColor: Colors.white24,
//                 backgroundColor: Colors.white10,
//               ),
//             ),
//             // ২. স্পন্সর সেগমেন্টের মার্কিং (হলুদ রঙে)
//             IgnorePointer(
//               child: SizedBox(
//                 width: constraints.maxWidth,
//                 height: 4, // স্লাইডারের মোটা অনুযায়ী
//                 child: Stack(
//                   children: _segments.map((segment) {
//                     double startPos = (segment['start']! / totalDuration) * constraints.maxWidth;
//                     double endPos = (segment['end']! / totalDuration) * constraints.maxWidth;
//                     double width = endPos - startPos;

//                     return Positioned(
//                       left: startPos,
//                       child: Container(
//                         width: width > 0 ? width : 0,
//                         height: 4,
//                         color: Colors.yellow.withOpacity(0.8),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }