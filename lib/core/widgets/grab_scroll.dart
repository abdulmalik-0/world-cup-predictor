import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Enables click-and-drag scrolling on web/desktop (mouse) as well as touch.
class GrabScrollBehavior extends MaterialScrollBehavior {
  const GrabScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

/// Vertical list — press and drag to scroll (touch + mouse).
class GrabScrollListView extends StatefulWidget {
  const GrabScrollListView({
    super.key,
    required this.children,
    this.padding,
    this.controller,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  State<GrabScrollListView> createState() => _GrabScrollListViewState();
}

class _GrabScrollListViewState extends State<GrabScrollListView> {
  ScrollController? _owned;

  ScrollController get _controller =>
      widget.controller ?? (_owned ??= ScrollController());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  void _dragScroll(double deltaDy) {
    if (!_controller.hasClients || deltaDy == 0) return;
    final max = _controller.position.maxScrollExtent;
    _controller.jumpTo(
      (_controller.offset - deltaDy).clamp(0.0, max),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const GrabScrollBehavior(),
      child: Listener(
        onPointerMove: (event) {
          if (event.buttons == 0) return;
          _dragScroll(event.delta.dy);
        },
        child: ListView(
          controller: _controller,
          padding: widget.padding,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: widget.children,
        ),
      ),
    );
  }
}

/// Vertical single-child scroll — press and drag to scroll.
class GrabScrollSingleChildScrollView extends StatefulWidget {
  const GrabScrollSingleChildScrollView({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  State<GrabScrollSingleChildScrollView> createState() =>
      _GrabScrollSingleChildScrollViewState();
}

class _GrabScrollSingleChildScrollViewState
    extends State<GrabScrollSingleChildScrollView> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dragScroll(double deltaDy) {
    if (!_controller.hasClients || deltaDy == 0) return;
    final max = _controller.position.maxScrollExtent;
    _controller.jumpTo(
      (_controller.offset - deltaDy).clamp(0.0, max),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const GrabScrollBehavior(),
      child: Listener(
        onPointerMove: (event) {
          if (event.buttons == 0) return;
          _dragScroll(event.delta.dy);
        },
        child: SingleChildScrollView(
          controller: _controller,
          padding: widget.padding,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Horizontal row — press and drag to scroll (day filter chips).
class GrabScrollHorizontal extends StatefulWidget {
  const GrabScrollHorizontal({super.key, required this.child});

  final Widget child;

  @override
  State<GrabScrollHorizontal> createState() => _GrabScrollHorizontalState();
}

class _GrabScrollHorizontalState extends State<GrabScrollHorizontal> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dragScroll(double deltaDx) {
    if (!_controller.hasClients || deltaDx == 0) return;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final dx = isRtl ? -deltaDx : deltaDx;
    final max = _controller.position.maxScrollExtent;
    _controller.jumpTo(
      (_controller.offset - dx).clamp(0.0, max),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const GrabScrollBehavior(),
      child: Listener(
        onPointerMove: (event) {
          if (event.buttons == 0) return;
          _dragScroll(event.delta.dx);
        },
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
