import 'package:flutter/material.dart';

/// Helper class for responsive layouts across phone and tablet devices
class ResponsiveHelper {
  /// Check if the device is a tablet (shortest side >= 600dp)
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600;
  }

  static bool isMobile(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return size.shortestSide < 600;
}

  /// Check if device is a large tablet (shortest side >= 720dp)
  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 720;
  }

  /// Get the screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get the screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive grid cross axis count based on screen width
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 6;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isLargeTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    return const EdgeInsets.all(16);
  }

  /// Get responsive horizontal padding only
  static double getHorizontalPadding(BuildContext context) {
    if (isLargeTablet(context)) return 48;
    if (isTablet(context)) return 32;
    return 16;
  }

  /// Get responsive font size multiplier
  static double getFontScaleFactor(BuildContext context) {
    if (isLargeTablet(context)) return 1.2;
    if (isTablet(context)) return 1.1;
    return 1.0;
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {double baseSize = 24}) {
    if (isLargeTablet(context)) return baseSize * 1.4;
    if (isTablet(context)) return baseSize * 1.2;
    return baseSize;
  }

  /// Get responsive card aspect ratio for grid items
  static double getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 1.4;
    if (width >= 900) return 1.5;
    if (width >= 600) return 1.6;
    return 1.6;
  }

  /// Get max content width for centering on large screens
  static double getMaxContentWidth(BuildContext context) {
    if (isLargeTablet(context)) return 1000;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {double baseSpacing = 12}) {
    if (isLargeTablet(context)) return baseSpacing * 1.5;
    if (isTablet(context)) return baseSpacing * 1.25;
    return baseSpacing;
  }

  /// Get responsive avatar radius
  static double getAvatarRadius(BuildContext context, {double baseRadius = 28}) {
    if (isLargeTablet(context)) return baseRadius * 1.4;
    if (isTablet(context)) return baseRadius * 1.2;
    return baseRadius;
  }
}
