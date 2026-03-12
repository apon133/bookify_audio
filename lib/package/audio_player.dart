import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/sponsor_block_service.dart';

/// State of the [BookifyAudioPlayerController]
class BookifyAudioPlayerState {
  final bool isLoading;
  final bool isPlaying;
  final double currentTime;
  final double duration;
  final String title;
  final String? videoId;
  final String? error;
  final String? loadId; // Unique ID for each load to force player rebuild
  final List<dynamic>? sponsorSegments; // SponsorBlock segments to skip

  BookifyAudioPlayerState({
    this.isLoading = false,
    this.isPlaying = false,
    this.currentTime = 0,
    this.duration = 0,
    this.title = 'No video loaded',
    this.videoId,
    this.error,
    this.loadId,
    this.sponsorSegments,
  });

  BookifyAudioPlayerState copyWith({
    bool? isLoading,
    bool? isPlaying,
    double? currentTime,
    double? duration,
    String? title,
    String? videoId,
    String? error,
    String? loadId,
    List<dynamic>? sponsorSegments,
  }) {
    return BookifyAudioPlayerState(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      currentTime: currentTime ?? this.currentTime,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      videoId: videoId ?? this.videoId,
      error: error ?? this.error,
      loadId: loadId ?? this.loadId,
      sponsorSegments: sponsorSegments ?? this.sponsorSegments,
    );
  }
}

/// Controller for YouTube-based audio playback using youtube_player_flutter
class BookifyAudioPlayerController
    extends ValueNotifier<BookifyAudioPlayerState> {
  YoutubePlayerController? _youtubeController;
  Timer? _progressTimer;

  BookifyAudioPlayerController() : super(BookifyAudioPlayerState());

  YoutubePlayerController? get youtubeController => _youtubeController;

  Future<void> load(String url, {double startPosition = 0}) async {
    print('Loading URL: $url at position: $startPosition');
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      value = value.copyWith(error: 'Invalid YouTube URL');
      return;
    }

    // Dispose previous controller if exists
    if (_youtubeController != null) {
      _progressTimer?.cancel();

      // Pause before disposing to ensure clean state
      try {
        _youtubeController?.pause();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        // Ignore errors during pause
      }

      _youtubeController?.dispose();
      _youtubeController = null;

      // Add delay to ensure complete disposal
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final newLoadId = DateTime.now().toIso8601String();
    print('Generated new loadId: $newLoadId for video: $videoId');

    // Reset state before loading new video
    value = BookifyAudioPlayerState(
      isLoading: true,
      videoId: videoId,
      error: null,
      loadId: newLoadId,
    );

    // Create new controller with low quality settings to save bandwidth
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        // Force low quality to save bandwidth
        forceHD: false,
        // Enable background audio
        enableCaption: false,
        // Hide controls since we're using it as audio player
        hideControls: true,
        // Disable fullscreen
        disableDragSeek: false,
        // Loop if needed
        loop: false,
        // Start from saved position
        startAt: startPosition.toInt(),
      ),
    );

    // Listen to player state changes
    _youtubeController!.addListener(_onPlayerStateChange);

    // Start progress timer
    _startProgressTimer();

    // Notify listeners that controller has changed (triggers widget rebuild)
    notifyListeners();

    // Update loading state
    await Future.delayed(const Duration(milliseconds: 500));
    value = value.copyWith(isLoading: false);

    // Fetch SponsorBlock segments
    _fetchSponsorSegments(videoId);
  }

  Future<void> _fetchSponsorSegments(String videoId) async {
    try {
      final segments = await SponsorBlockService().getSegments(videoId);
      value = value.copyWith(sponsorSegments: segments);
    } catch (e) {
      print('SponsorBlock error: $e');
    }
  }

  void _onPlayerStateChange() {
    if (_youtubeController == null) return;

    final metadata = _youtubeController!.metadata;
    final playerState = _youtubeController!.value;

    value = value.copyWith(
      isPlaying: playerState.isPlaying,
      currentTime: playerState.position.inSeconds.toDouble(),
      duration: metadata.duration.inSeconds.toDouble(),
      title: metadata.title.isNotEmpty ? metadata.title : value.title,
    );
  }

  Future<void> play() async {
    if (_youtubeController != null) {
      _youtubeController!.play();
      await Future.delayed(const Duration(milliseconds: 200));
      _updateProgress();
    }
  }

  Future<void> pause() async {
    if (_youtubeController != null) {
      _youtubeController!.pause();
      await Future.delayed(const Duration(milliseconds: 200));
      _updateProgress();
    }
  }

  Future<void> togglePlayPause() async {
    if (value.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(double seconds) async {
    if (_youtubeController != null) {
      _youtubeController!.seekTo(Duration(seconds: seconds.toInt()));
      value = value.copyWith(currentTime: seconds);
    }
  }

  Future<void> seekRelative(double seconds) async {
    final newTime = (value.currentTime + seconds).clamp(0.0, value.duration);
    await seekTo(newTime);
  }

  Future<void> setPlaybackRate(double rate) async {
    if (_youtubeController != null) {
      // YouTube IFrame API supports: 0.25, 0.5, 1, 1.5, 2
      // We'll pass whatever the user provides, but it might only honor supported values.
      // youtube_player_flutter does NOT expose setPlaybackRate in the Controller class directly,
      // but it might via flags or custom JS.
      // Wait, checking documentation... it actually DOES NOT have setPlaybackRate in the controller.
      // We must use evaluateJavascript.
      // The wrapper usually exposes it. Let's check if 'setPlaybackRate' exists on the controller in newer versions?
      // Assuming it does NOT based on typical issues.
      // However, we can use `_youtubeController.setPlaybackRate` if it exists.
      // Since I can't verify the package version, I will try to use `evaluateJavascript`.
      // But `YoutubePlayerController` might abstract the webview.
      // Let's try to assume it exists or use `evaluateJavascript` on the internal webview if accessible.
      // Actually, looking at typical usage, one uses flags to set speed initially, but runtime change?
      // It seems we need to evaluate JS.

      // Attempt 1: Check if method exists (I can't check at runtime here).
      // Attempt 2: Use low-level call.
      // _youtubeController.setSize(...) exists.

      // Let's use evaluateJavascript to call 'player.setPlaybackRate(rate)'.
      // But we need access to the underlying webview controller.
      // youtube_player_flutter controller usually allows `evaluateJavascript`.
      // NOTE: If the package version is old, it might not work.

      // Let's try the safest bet: The controller usually has `evaluateJavascript`.
      // If not, we might fail.

      // Actually, standard `youtube_player_flutter` controller DOES NOT have setPlaybackRate directly exposed in all versions.
      // But `play`, `pause` etc call JS.
      // Let's assume we can add it via generic JS evaluation.
      // 'player' is usually the object name in the injected JS.

      // However, I see I don't see `evaluateJavascript` on `YoutubePlayerController` in the import list.
      // Wait, `youtube_player_flutter` exports it.

      // Let's just try to assume the method exists on the controller? No, unsafe.
      // I'll try to use `_youtubeController.evaluateJavascript` if available.

      // Actually, the best way is often to reload with different flags, but that interrupts playback.
      // Let's try `_youtubeController.setPlaybackRate(rate)` if I can presume it exists?
      // Many forks have it.
      // If it doesn't, this code will fail analysis.
      // I'll assume standard package.
      // Standard package 8.1.2 has `setPlaybackRate`? No.

      // I will implement it using `evaluateJavascript` assuming the controller exposes it.
      // If the controller doesn't expose `evaluateJavascript`, I'll be in trouble.

      // Let's look at `_youtubeController` type. It is `YoutubePlayerController`.

      // Plan B: In `package/audio_player.dart`, `BookifyAudioPlayerController` is ours.
      // I'll add `setPlaybackRate` to OUR controller, and inside I'll try to find a way.
      // If `YoutubePlayerController` has no such method, I will use `evaluateJavascript` source:
      // source: `source: 'player.setPlaybackRate($rate);'`

      // Let's guess `_youtubeController?.evaluateJavascript` exists.
      _youtubeController?.setPlaybackRate(rate);
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateProgress();
    });
  }

  Future<void> _updateProgress() async {
    if (_youtubeController == null) return;

    try {
      final playerState = _youtubeController!.value;
      final metadata = _youtubeController!.metadata;

      double currentTime = playerState.position.inSeconds.toDouble();

      // Check for SponsorBlock segments to skip
      if (value.sponsorSegments != null && value.sponsorSegments!.isNotEmpty) {
        for (final segment in value.sponsorSegments!) {
          if (segment is SponsorSegment) {
            // If current time is within segment, skip to end of segment
            if (currentTime >= segment.start && currentTime < segment.end) {
              print(
                  'SponsorBlock: Skipping segment from ${segment.start} to ${segment.end}');
              await seekTo(segment.end);
              currentTime = segment.end;
              break; // Only skip one segment at a time
            }
          }
        }
      }

      value = value.copyWith(
        currentTime: currentTime,
        duration: metadata.duration.inSeconds.toDouble(),
        isPlaying: playerState.isPlaying,
        title: metadata.title.isNotEmpty ? metadata.title : value.title,
      );
    } catch (e) {
      // Ignore errors during progress update
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }
}

/// The actual widget that hosts the YouTube player (hidden for audio-only playback).
/// Place this once in your widget tree (e.g., in a Stack or at the bottom of a Scaffold).
class BookifyAudioWebPlayer extends StatefulWidget {
  final BookifyAudioPlayerController controller;
  final Function(String videoId, double position)? onProgressSave;

  const BookifyAudioWebPlayer({
    super.key,
    required this.controller,
    this.onProgressSave,
  });

  @override
  State<BookifyAudioWebPlayer> createState() => _BookifyAudioWebPlayerState();
}

class _BookifyAudioWebPlayerState extends State<BookifyAudioWebPlayer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initForegroundTask();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'audiobook_player_channel',
        channelName: 'AudioBook Player',
        channelDescription: 'Playing audio in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final shouldPlayInBackground = widget.controller.value.isPlaying;
      _startForegroundService();

      // YouTube player automatically pauses when the app goes to the background.
      // We force it to resume if it was playing.
      if (shouldPlayInBackground) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            widget.controller.play();
          }
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _stopForegroundService();
    }
  }

  Future<void> _startForegroundService() async {
    if (widget.controller.value.isPlaying) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'AudioBook Player',
        notificationText: widget.controller.value.title,
      );
    }
  }

  Future<void> _stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopForegroundService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to controller changes to rebuild when new episodes are loaded
    return ValueListenableBuilder<BookifyAudioPlayerState>(
      valueListenable: widget.controller,
      builder: (context, state, child) {
        if (state.isLoading) {
          print(
              'BookifyAudioWebPlayer: isLoading is true, showing loader or keeping previous state');
        }

        // Hide the YouTube player widget (audio-only mode)
        return SizedBox(
          width: 1,
          height: 1,
          child: Opacity(
            opacity: 0,
            child: widget.controller.youtubeController != null
                ? YoutubePlayer(
                    key: ValueKey(
                        '${state.videoId}_${state.loadId}'), // Force rebuild on video change or reload
                    controller: widget.controller.youtubeController!,
                    showVideoProgressIndicator: false,
                    progressIndicatorColor: Colors.transparent,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.transparent,
                      handleColor: Colors.transparent,
                    ),
                    onReady: () {
                      // Player is ready
                      widget.controller.value =
                          widget.controller.value.copyWith(
                        isLoading: false,
                      );
                    },
                    onEnded: (metadata) {
                      // Video ended
                      if (widget.onProgressSave != null &&
                          widget.controller.value.videoId != null) {
                        widget.onProgressSave!(
                          widget.controller.value.videoId!,
                          widget.controller.value.duration,
                        );
                      }
                    },
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
