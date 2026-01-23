import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// State of the [BookifyAudioPlayerController]
class BookifyAudioPlayerState {
  final bool isLoading;
  final bool isPlaying;
  final double currentTime;
  final double duration;
  final String title;
  final String? videoId;
  final String? error;

  BookifyAudioPlayerState({
    this.isLoading = false,
    this.isPlaying = false,
    this.currentTime = 0,
    this.duration = 0,
    this.title = 'No video loaded',
    this.videoId,
    this.error,
  });

  BookifyAudioPlayerState copyWith({
    bool? isLoading,
    bool? isPlaying,
    double? currentTime,
    double? duration,
    String? title,
    String? videoId,
    String? error,
  }) {
    return BookifyAudioPlayerState(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      currentTime: currentTime ?? this.currentTime,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      videoId: videoId ?? this.videoId,
      error: error ?? this.error,
    );
  }
}

/// Controller for YouTube-based audio playback using a WebView
class BookifyAudioPlayerController
    extends ValueNotifier<BookifyAudioPlayerState> {
  InAppWebViewController? _webViewController;
  Timer? _progressTimer;
  bool _isWebViewReady = false;

  BookifyAudioPlayerController() : super(BookifyAudioPlayerState());

  // CSS to hide video and show only audio controls
  static const String _hideVideoCSS = '''
    /* Hide video element but keep audio playing */
    video {
      position: fixed !important;
      width: 1px !important;
      height: 1px !important;
      opacity: 0 !important;
      pointer-events: none !important;
    }
    
    /* Hide video player container and UI elements */
    .html5-video-player,
    .ytp-cued-thumbnail-overlay,
    .ytp-cued-thumbnail-overlay-image,
    #player,
    #movie_player,
    .player-container,
    ytm-single-column-watch-next-results-renderer,
    ytm-item-section-renderer,
    .related-chips-slot-wrapper,
    .watch-below-the-player,
    ytm-comments-entry-point-header-renderer,
    ytm-comment-section-renderer,
    .slim-video-information-renderer,
    ytm-slim-video-information-renderer,
    ytm-mobile-topbar-renderer,
    #header,
    #masthead-container,
    .mobile-topbar-header,
    ytm-pivot-bar-renderer,
    #pivot-bar,
    .tab-content,
    ytm-single-column-browse-results-renderer,
    ytm-browse,
    .watch-next-feed,
    ytm-compact-video-renderer,
    .related-videos {
      display: none !important;
    }
    
    body, html {
      background-color: #000000 !important;
      overflow: hidden !important;
    }
    
    * {
      visibility: hidden !important;
    }
  ''';

  // JavaScript to control video playback
  static const String _controlScript = '''
    (function() {
      var video = document.querySelector('video');
      if (video) {
        return {
          currentTime: video.currentTime || 0,
          duration: video.duration || 0,
          paused: video.paused,
          title: document.title || 'Unknown'
        };
      }
      return null;
    })();
  ''';

  void _onWebViewCreated(InAppWebViewController controller) {
    _webViewController = controller;
    _isWebViewReady = true;
  }

  Future<void> load(String url) async {
    final videoId = _extractVideoId(url);
    if (videoId == null) {
      value = value.copyWith(error: 'Invalid YouTube URL');
      return;
    }

    value = value.copyWith(
      isLoading: true,
      videoId: videoId,
      error: null,
    );

    final mobileUrl = 'https://m.youtube.com/watch?v=$videoId';
    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(mobileUrl)),
    );
  }

  Future<void> play() async {
    await _webViewController?.evaluateJavascript(
      source: 'document.querySelector("video")?.play();',
    );
    await Future.delayed(const Duration(milliseconds: 200));
    _updateProgress();
  }

  Future<void> pause() async {
    await _webViewController?.evaluateJavascript(
      source: 'document.querySelector("video")?.pause();',
    );
    await Future.delayed(const Duration(milliseconds: 200));
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
    await _webViewController?.evaluateJavascript(
      source:
          'if(document.querySelector("video")) document.querySelector("video").currentTime = $seconds;',
    );
    value = value.copyWith(currentTime: seconds);
  }

  Future<void> seekRelative(double seconds) async {
    final newTime = (value.currentTime + seconds).clamp(0.0, value.duration);
    await seekTo(newTime);
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateProgress();
    });
  }

  Future<void> _updateProgress() async {
    if (_webViewController == null || !_isWebViewReady) return;

    try {
      final result = await _webViewController?.evaluateJavascript(
        source: _controlScript,
      );

      if (result != null && result != 'null') {
        final data = result as Map<dynamic, dynamic>?;
        if (data != null) {
          final title = data['title'] as String? ?? 'Unknown';
          final cleanTitle = title.replaceAll(' - YouTube', '');

          value = value.copyWith(
            currentTime: (data['currentTime'] as num?)?.toDouble() ?? 0,
            duration: (data['duration'] as num?)?.toDouble() ?? 0,
            isPlaying: !(data['paused'] as bool? ?? true),
            title: cleanTitle.isNotEmpty ? cleanTitle : null,
          );
        }
      }
    } catch (e) {
      // Ignore errors during progress update
    }
  }

  Future<void> _injectStyles() async {
    await _webViewController?.evaluateJavascript(
      source: '''
      (function() {
        var style = document.createElement('style');
        style.type = 'text/css';
        style.innerHTML = `$_hideVideoCSS`;
        document.head.appendChild(style);
        
        var video = document.querySelector('video');
        if (video) {
          var player = document.querySelector('#movie_player');
          if (player && player.setPlaybackQualityRange) {
            player.setPlaybackQualityRange('tiny', 'tiny');
          }
        }
      })();
    ''',
    );
  }

  String? _extractVideoId(String url) {
    final patterns = [
      RegExp(
          r'(?:youtube\.com\/watch\?v=|youtu\.be\/|m\.youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}

/// The actual widget that hosts the hidden WebView.
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
      _startForegroundService();
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
    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0,
        child: InAppWebView(
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            javaScriptEnabled: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            cacheEnabled: true,
            userAgent:
                'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
            allowBackgroundAudioPlaying: true,
            preferredContentMode: UserPreferredContentMode.MOBILE,
          ),
          onWebViewCreated: widget.controller._onWebViewCreated,
          onLoadStart: (controller, url) {
            widget.controller.value =
                widget.controller.value.copyWith(isLoading: true);
          },
          onLoadStop: (controller, url) async {
            widget.controller.value =
                widget.controller.value.copyWith(isLoading: false);
            await widget.controller._injectStyles();
            widget.controller._startProgressTimer();

            // Auto-play after load
            await Future.delayed(const Duration(seconds: 2));
            await widget.controller.play();
          },
          onProgressChanged: (controller, progress) {
            if (progress > 50) {
              widget.controller._injectStyles();
            }
          },
        ),
      ),
    );
  }
}
