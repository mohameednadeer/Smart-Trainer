import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/theme/theme_ext.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final double blurRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(24.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(24.0)),
    this.blurRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: context.glassBgColor, // Semi-transparent
            borderRadius: borderRadius,
            border: Border.all(
              color: context.glassBorderColor, // faint white border
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
