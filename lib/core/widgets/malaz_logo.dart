import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Malaz Capital wordmark — white version for dark backgrounds
/// (keeps the blue gradient swoosh).
class MalazLogo extends StatelessWidget {
  const MalazLogo({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/malaz_logo.svg',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
