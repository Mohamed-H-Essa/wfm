import 'package:flutter/material.dart';
import 'colors.dart';

/// IntraZero 2026 Typography - Matching Standup Features Design
class IntraZeroTypography {
  static const fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, sans-serif';
  
  static const h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: IntraZeroColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: IntraZeroColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: IntraZeroColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: IntraZeroColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: IntraZeroColors.textSecondary,
    fontFamily: fontFamily,
  );
  
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: IntraZeroColors.textSecondary,
    fontFamily: fontFamily,
  );
  
  static const label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: IntraZeroColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const statValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: IntraZeroColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const statLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: IntraZeroColors.textTertiary,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );
}

