import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as mobile;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as web;
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

/// Controller for YouTube-based audio playback using the appropriate platform player
class BookifyAudioPlayerController extends ValueNotifier<BookifyAudioPlayerState> {
  mobile.YoutubePlayerController? _mobileController;
  web.YoutubePlayerController? _webController;
  Timer? _progressTimer;

  BookifyAudioPlayerController() : super(BookifyAudioPlayerState());

  mobile.YoutubePlayerController? get mobileController => _mobileController;
  web.YoutubePlayerController? get webController => _webController;

  Future<void> load(String url, {double startPosition = 0}) async {
    print('Loading URL: $url at position: $startPosition (Web: $kIsWeb)');
    
    // Convert URL to ID
    String? videoId;
    if (kIsWeb) {
      videoId = web.YoutubePlayerController.convertUrlToId(url);
    } else {
      videoId = mobile.YoutubePlayer.convertUrlToId(url);
    }
    
    if (videoId == null) {
      value = value.copyWith(error: 'Invalid YouTube URL');
      return;
    }

    // Dispose previous controllers & timers
    _progressTimer?.cancel();
    _mobileController?.dispose();
    _webController?.close();
    _mobileController = null;
    _webController = null;

    final newLoadId = DateTime.now().toIso8601String();
    
    // Reset state before loading new video
    value = BookifyAudioPlayerState(
      isLoading: true,
      isPlaying: true, // Optimistically set to true because autoPlay is enabled
      videoId: videoId,
      error: null,
      loadId: newLoadId,
    );

    if (kIsWeb) {
      _webController = web.YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        startSeconds: startPosition,
        params: web.YoutubePlayerParams(
          showControls: false,
          mute: false,
          showFullscreenButton: false,
          enableCaption: false,
        ),
      );
      final webCtrl = _webController;
      if (webCtrl == null) return;

      // Listen for updates on web
      webCtrl.stream.listen((state) {
        _onWebPlayerStateChange(state);
      });
    } else {
      _mobileController = mobile.YoutubePlayerController(
        initialVideoId: videoId,
        flags: mobile.YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          forceHD: false,
          enableCaption: false,
          hideControls: true,
          startAt: startPosition.toInt(),
        ),
      );
      final mobileCtrl = _mobileController;
      if (mobileCtrl != null) {
        mobileCtrl.addListener(_onMobilePlayerStateChange);
      }
    }

    // Start progress timer
    _startProgressTimer();

    // Trigger widget rebuild
    notifyListeners();

    // Update loading state
    await Future.delayed(Duration(milliseconds: kIsWeb ? 100 : 300));
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

  void _onMobilePlayerStateChange() {
    final mobileCtrl = _mobileController;
    if (mobileCtrl == null) return;

    final metadata = mobileCtrl.metadata;
    final playerState = mobileCtrl.value;
    value = value.copyWith(
      isPlaying: playerState.isPlaying || playerState.playerState == mobile.PlayerState.buffering,
      currentTime: playerState.position.inSeconds.toDouble(),
      duration: metadata.duration.inSeconds.toDouble(),
      title: metadata.title.isNotEmpty ? metadata.title : value.title,
    );
  }

  void _onWebPlayerStateChange(state) {
    if (_webController == null) return;
    value = value.copyWith(
      isPlaying: state.playerState == web.PlayerState.playing ||
          state.playerState == web.PlayerState.buffering,
    );
  }



  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
    if (kIsWeb) {
      _webController?.playVideo();
    } else {
      _mobileController?.play();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _updateProgress();
  }

  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
    if (kIsWeb) {
      _webController?.pauseVideo();
    } else {
      _mobileController?.pause();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _updateProgress();
  }

  Future<void> togglePlayPause() async {
    if (value.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(double seconds) async {
    if (kIsWeb) {
      _webController?.seekTo(seconds: seconds);
    } else {
      _mobileController?.seekTo(Duration(seconds: seconds.toInt()));
    }
    value = value.copyWith(currentTime: seconds);
  }

  Future<void> seekRelative(double seconds) async {
    final newTime = (value.currentTime + seconds).clamp(0.0, value.duration);
    await seekTo(newTime);
  }

  Future<void> setPlaybackRate(double rate) async {
    if (kIsWeb) {
      _webController?.setPlaybackRate(rate);
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateProgress();
    });
  }

  Future<void> _updateProgress() async {
    double currentTime = 0;
    double duration = 0;
    bool isPlaying = false;
    String title = value.title;

    final webCtrl = _webController;
    final mobileCtrl = _mobileController;

    if (kIsWeb && webCtrl != null) {
      try {
        currentTime = await webCtrl.currentTime;
        duration = await webCtrl.duration;
        isPlaying = webCtrl.value.playerState == web.PlayerState.playing ||
            webCtrl.value.playerState == web.PlayerState.buffering;
      } catch (e) {
        print('BookifyAudioPlayer: Error updating web progress: $e');
        return;
      }
    } else if (!kIsWeb && mobileCtrl != null) {
      final state = mobileCtrl.value;
      currentTime = state.position.inSeconds.toDouble();
      duration = mobileCtrl.metadata.duration.inSeconds.toDouble();
      isPlaying =
          state.isPlaying || state.playerState == mobile.PlayerState.buffering;
      title = mobileCtrl.metadata.title.isNotEmpty
          ? mobileCtrl.metadata.title
          : title;
    } else {
      return;
    }


    // SponsorBlock skipping logic
    if (value.sponsorSegments != null && value.sponsorSegments!.isNotEmpty) {
      for (final segment in value.sponsorSegments!) {
        if (segment is SponsorSegment) {
          if (currentTime >= segment.start && currentTime < segment.end) {
            print('SponsorBlock: Skipping segment from ${segment.start} to ${segment.end}');
            await seekTo(segment.end);
            currentTime = segment.end;
            break;
          }
        }
      }
    }

    value = value.copyWith(
      currentTime: currentTime,
      duration: duration,
      isPlaying: isPlaying,
      title: title,
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _mobileController?.dispose();
    _webController?.close();
    super.dispose();
  }
}

/// The actual widget that hosts the YouTube player (hidden for audio-only playback).
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
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    if (state == AppLifecycleState.paused) {
      final shouldPlayInBackground = widget.controller.value.isPlaying;
      _startForegroundService();
      if (shouldPlayInBackground) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) widget.controller.play();
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _stopForegroundService();
    }
  }

  Future<void> _startForegroundService() async {
    if (kIsWeb) return;
    if (widget.controller.value.isPlaying) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'AudioBook Player',
        notificationText: widget.controller.value.title,
      );
    }
  }

  Future<void> _stopForegroundService() async {
    if (kIsWeb) return;
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
    return ValueListenableBuilder<BookifyAudioPlayerState>(
      valueListenable: widget.controller,
      builder: (context, state, child) {
        final videoId = state.videoId;
        if (videoId == null) return const SizedBox.shrink();

        // Check platform specific controllers
        final mobileCtrl = widget.controller.mobileController;
        final webCtrl = widget.controller.webController;
        if (mobileCtrl == null && webCtrl == null) return const SizedBox.shrink();

        return Positioned(
          left: -1000,
          top: -1000,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Opacity(
              opacity: 0.01,
              child: kIsWeb
                  ? (webCtrl != null
                      ? web.YoutubePlayer(
                          key: ValueKey('${videoId}_${state.loadId}'),
                          controller: webCtrl,
                        )
                      : const SizedBox.shrink())
                  : (mobileCtrl != null
                      ? mobile.YoutubePlayer(
                          key: ValueKey('${videoId}_${state.loadId}'),
                          controller: mobileCtrl,
                          showVideoProgressIndicator: false,
                        )
                      : const SizedBox.shrink()),
            ),
          ),
        );
      },
    );
  }
}
