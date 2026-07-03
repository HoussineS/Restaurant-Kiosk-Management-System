import 'package:flutter/material.dart';

/// App-wide breakpoint constants.
abstract class AppBreakpoints {
  /// Screens narrower than this are treated as mobile.
  static const double mobile = 600;

  /// Screens between [mobile] and [tablet] are treated as tablet.
  static const double tablet = 900;
}

/// Describes the current screen size tier.
enum ScreenSize { mobile, tablet, desktop }

/// Convenience extension on [BuildContext] for responsive helpers.
extension ResponsiveContext on BuildContext {
  /// Returns the [ScreenSize] tier based on the current window width.
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < AppBreakpoints.mobile) return ScreenSize.mobile;
    if (width < AppBreakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Returns a value based on the current [ScreenSize].
  T responsive<T>({
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }
}
