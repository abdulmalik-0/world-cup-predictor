import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:video_player/video_player.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/widgets/wc_mask_paths.dart';
import 'package:world_cup_predictor/services/hero_video_service.dart';

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
    this.needsUserGesture = false,
    this.onUserPlay,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final double maxH;
  final double minH;
  final bool needsUserGesture;
  final Future<void> Function()? onUserPlay;

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
          // 3) Tap-to-play overlay if the browser blocked autoplay.
          if (needsUserGesture && onUserPlay != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => onUserPlay!(),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.55),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 44),
                  ),
                ),
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
      old.needsUserGesture != needsUserGesture ||
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

/// Small LOOPING "26 / trophy / NEW YORK NEW JERSEY" video clip for the top
/// nav bar. Uses the SHARED [HeroVideoService] controller — no second decode.
class WcMiniLogo extends ConsumerWidget {
  const WcMiniLogo({super.key, this.height = 42});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(heroVideoServiceProvider);
    final c = svc.controller;
    final Widget inner = (svc.ready && c != null && c.value.isInitialized)
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
      height: height,
      width: height * 2.55,
      child: ClipPath(clipper: _WcShapeClipper(), child: inner),
    );
  }
}

/// Full-bleed FIXED parallax hero: the masked "26" video fills the area and
/// stays pinned while page content scrolls OVER it. The white surround fades
/// out as you scroll (driven by [collapse]). Used as a Positioned.fill layer
/// behind the scrollable content on mobile.
class WcMaskedHero extends ConsumerWidget {
  const WcMaskedHero({super.key, required this.collapse});

  final ValueNotifier<double> collapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(heroVideoServiceProvider);
    final c = svc.controller;
    final Widget video = (svc.ready && c != null && c.value.isInitialized)
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
          // Video revealed only through the "26 / trophy / NY NJ" shape.
          Positioned.fill(
            child: ClipPath(clipper: _WcShapeClipper(), child: video),
          ),
          // White surround that fades out as the user scrolls.
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: collapse,
              builder: (context, t, _) {
                final op = (1 - t / 0.7).clamp(0.0, 1.0);
                if (op <= 0.01) return const SizedBox.shrink();
                return Opacity(
                  opacity: op,
                  child: const CustomPaint(painter: _NegativeMaskPainter()),
                );
              },
            ),
          ),
        ],
      ),
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
    final r = widget.kickoff.difference(DateTime.now());
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
