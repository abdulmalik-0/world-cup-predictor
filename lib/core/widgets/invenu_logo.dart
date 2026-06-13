import 'package:flutter/material.dart';

/// ENTERGAME wordmark — full lockup (EG mark + "ENTERGAME / SPORTS MARKETING").
/// The PNG is already pre-rendered in white with anti-aliased alpha, so it
/// looks sharp at any size on dark backgrounds — no runtime tinting needed.
class InvenuLogo extends StatelessWidget {
  const InvenuLogo({super.key, this.height = 22});

  /// Vertical pixel height of the logo.
  final double height;

  @override
  Widget build(BuildContext context) {
    // Multiply by devicePixelRatio so the underlying bitmap is decoded at a
    // higher resolution than the layout slot — keeps it crisp on Retina.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      'assets/images/entergame_logo.png',
      height: height,
      fit: BoxFit.contain,
      cacheHeight: (height * dpr * 2).round(),
      filterQuality: FilterQuality.high,
    );
  }
}
