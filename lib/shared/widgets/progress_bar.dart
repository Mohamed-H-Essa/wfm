import 'package:flutter/material.dart';
import '../../app/themes/colors.dart';
import '../../app/themes/typography.dart';

/// Progress Bar Widget - Matching Standup Progress
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final LinearGradient? gradient;
  
  const ProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: IntraZeroTypography.caption,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: IntraZeroTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: IntraZeroColors.borderLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient ?? IntraZeroColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

