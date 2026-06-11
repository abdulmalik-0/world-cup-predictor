import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:video_player/video_player.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/utils/saudi_time.dart';
import 'package:world_cup_predictor/core/widgets/wc_mask_paths.dart';

/// FIFA-NYNJ hero: the looping video is revealed only inside the World Cup
/// "26 / trophy / NEW YORK NEW JERSEY" shape on a white background. As you
/// scroll, the whole masked shape simply SHRINKS (it stays masked the entire
/// time) while the page content rises underneath — exactly like the reference
/// site. Use as a pinned [SliverPersistentHeader].
class WcHeroDelegate extends SliverPersistentHeaderDelegate {
  WcHeroDelegate({
    required this.controller,
    required this.ready,
    required this.maxH,
    required this.minH,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final double maxH;
  final double minH;

  @override
  double get maxExtent => maxH;

  @override
  double get minExtent => minH;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final current = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : ((maxExtent - current) / range).clamp(0.0, 1.0);
    // White surround fades out as the hero collapses, so the shrunk shape
    // floats on the app background (no white edges).
    final whiteOpacity = (1 - t / 0.7).clamp(0.0, 1.0);

    final c = controller;
    final Widget videoLayer =
        (ready && c != null && c.value.isInitialized)
            ? FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              )
            : Image.asset('assets/images/hero_poster.webp', fit: BoxFit.cover);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Video shown ONLY inside the WC "26 / trophy" shape; the area
          //    around it is transparent (so the app background shows through).
          Positioned.fill(
            child: ClipPath(
              clipper: _WcShapeClipper(),
              child: videoLayer,
            ),
          ),
          // 2) White surround that fades out as you scroll (reference look at
          //    full size, clean shape on the background once shrunk).
          if (whiteOpacity > 0.01)
            Positioned.fill(
              child: Opacity(
                opacity: whiteOpacity,
                child: const CustomPaint(painter: _NegativeMaskPainter()),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant WcHeroDelegate old) =>
      old.controller != controller ||
      old.ready != ready ||
      old.maxH != maxH ||
      old.minH != minH;
}

/// Shared scaled "26 / trophy / NEW YORK NEW JERSEY" shape for a given size.
class _WcMask {
  static final ui.Path horizontal = parseSvgPathData(wcMaskHorizontalPath);
  static final ui.Path vertical = parseSvgPathData(wcMaskVerticalPath);

  static ui.Path fitted(Size size) {
    final useHorizontal = size.width / size.height >= 1.25;
    final base = useHorizontal ? horizontal : vertical;
    final design = useHorizontal ? wcMaskHorizontalSize : wcMaskVerticalSize;
    const pad = 0.88;
    final s = math.min(
      size.width * pad / design.width,
      size.height * pad / design.height,
    );
    final tx = (size.width - design.width * s) / 2;
    final ty = (size.height - design.height * s) / 2;
    final m = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
    return base.transform(m.storage);
  }
}

class _WcShapeClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) => _WcMask.fitted(size);

  @override
  bool shouldReclip(covariant _WcShapeClipper oldClipper) => true;
}

/// Small LOOPING "26 / trophy / NEW YORK NEW JERSEY" video clip for the top nav
/// bar. Runs its own muted looping controller so it keeps playing even while
/// scrolled (independent of the full-screen hero).
class WcMiniLogo extends StatefulWidget {
  const WcMiniLogo({super.key, this.height = 42});

  final double height;

  @override
  State<WcMiniLogo> createState() => _WcMiniLogoState();
}

class _WcMiniLogoState extends State<WcMiniLogo> {
  VideoPlayerController? _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.asset('assets/video/hero.mp4');
    _c = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      c.addListener(() {
        final v = c.value;
        if (v.isInitialized &&
            !v.isPlaying &&
            v.duration > Duration.zero &&
            v.position >= v.duration - const Duration(milliseconds: 250)) {
          c.seekTo(Duration.zero);
          c.play();
        }
      });
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Falls back to the poster image.
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final Widget inner = (_ready && c != null && c.value.isInitialized)
        ? FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          )
        : Image.asset('assets/images/hero_poster.webp', fit: BoxFit.cover);

    return SizedBox(
      height: widget.height,
      width: widget.height * 2.55,
      child: ClipPath(clipper: _WcShapeClipper(), child: inner),
    );
  }
}

class _NegativeMaskPainter extends CustomPainter {
  const _NegativeMaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _WcMask.fitted(size);
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawPath(
      shape,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..color = const Color(0xFF000000),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NegativeMaskPainter oldDelegate) => true;
}

/// Slim live countdown bar to the next match (shown under the hero).
class MatchCountdownBar extends StatefulWidget {
  const MatchCountdownBar({super.key, required this.kickoff, this.title});

  final DateTime kickoff;
  final String? title;

  @override
  State<MatchCountdownBar> createState() => _MatchCountdownBarState();
}

class _MatchCountdownBarState extends State<MatchCountdownBar> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final r = widget.kickoff.difference(nowInSaudi());
    if (mounted) setState(() => _remaining = r);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final live = _remaining.isNegative;
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final mins = _remaining.inMinutes % 60;
    final secs = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1A3A), Color(0xFF0A1426)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2766FF).withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2766FF).withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('⚽', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  live
                      ? (s.ar ? 'المباراة الآن 🔴' : 'Live now 🔴')
                      : (s.ar ? 'المباراة القادمة' : 'Next match'),
                  style: const TextStyle(
                    color: Color(0xFFE8B23A),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                if (widget.title != null)
                  Text(
                    widget.title!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          if (!live) ...[
            _flipUnit(days, 'DAYS'),
            const SizedBox(width: 6),
            _flipUnit(hours, 'HOURS'),
            const SizedBox(width: 6),
            _flipUnit(mins, 'MINUTES'),
            const SizedBox(width: 6),
            _flipUnit(secs, 'SECONDS'),
          ],
        ],
      ),
    );
  }

  /// FIFA-style mini countdown box: bold red number on a dark tile, with a
  /// small uppercase label below. Compact — fits inline next to the title.
  Widget _flipUnit(int value, String label) {
    final text = value.toString().padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B0A0F), Color(0xFF120709)],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFE23B5A).withValues(alpha: 0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE23B5A).withValues(alpha: 0.18),
                blurRadius: 10,
                spreadRadius: -4,
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              text,
              key: ValueKey(text),
              style: const TextStyle(
                color: Color(0xFFE23B5A),
                fontWeight: FontWeight.w900,
                fontSize: 19,
                height: 1.0,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w700,
            fontSize: 8,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
