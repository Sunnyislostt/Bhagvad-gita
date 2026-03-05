import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.2,
    this.color = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: color.withValues(
                alpha: opacity * 2,
              ), // Slightly more opaque border for definition
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
