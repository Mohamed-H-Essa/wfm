import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../app/themes/colors.dart';

/// Glassmorphism Card Widget - Matching Standup Design
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  
  const GlassmorphismCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (backgroundColor ?? IntraZeroColors.surface).withOpacity(0.95),
            (backgroundColor ?? IntraZeroColors.surface).withOpacity(0.95),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

