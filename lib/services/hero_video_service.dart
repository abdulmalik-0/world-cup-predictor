import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Centralised hero-video controller. A SINGLE [VideoPlayerController] is
/// created and shared by both the full-screen masked hero AND the small "26"
/// clip in the top nav bar. This:
///  * halves the bandwidth + GPU/CPU footprint (one decode, two displays);
///  * keeps both displays perfectly in sync;
///  * gives us ONE place to handle Chrome's autoplay policy + restarts.
class HeroVideoService extends ChangeNotifier {
  HeroVideoService() {
    _init();
  }

  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;

  bool _ready = false;
  bool get ready => _ready;

  /// True if [play] failed (e.g. Chrome blocked autoplay) — UI can show a
  /// tap-to-play hint.
  bool _needsUserGesture = false;
  bool get needsUserGesture => _needsUserGesture;

  Timer? _watchdog;

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.asset('assets/video/hero.mp4');
      _controller = c;
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0); // muted enables autoplay in modern browsers
      _ready = true;
      notifyListeners();
      await _tryPlay();
      _startWatchdog();
    } catch (e) {
      debugPrint('HeroVideoService init failed: $e');
    }
  }

  Future<void> _tryPlay() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.play();
      _needsUserGesture = false;
    } catch (_) {
      // Autoplay blocked — surface a tap-to-play affordance.
      _needsUserGesture = true;
    }
    notifyListeners();
  }

  /// Public hook for tap-to-play UI.
  Future<void> userPlay() => _tryPlay();

  /// Watchdog runs every 2s: if the clip somehow stopped near the end (looping
  /// glitched) or paused without user input, rewind + play again. Cheap and
  /// robust — replaces the noisy per-frame listener pattern.
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      final c = _controller;
      if (c == null) return;
      final v = c.value;
      if (!v.isInitialized || v.duration == Duration.zero) return;
      final atEnd =
          v.position >= v.duration - const Duration(milliseconds: 400);
      if (atEnd && !v.isPlaying) {
        c.seekTo(Duration.zero);
        _tryPlay();
        return;
      }
      if (!v.isPlaying && !v.isBuffering && !_needsUserGesture) {
        _tryPlay();
      }
    });
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

/// One [HeroVideoService] per app — survives navigation between pages, so the
/// video stays loaded once initialised.
final heroVideoServiceProvider =
    ChangeNotifierProvider<HeroVideoService>((ref) => HeroVideoService());
