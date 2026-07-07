import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Breakpoints
// ─────────────────────────────────────────────────────────────────────────────

/// App-wide breakpoint constants (in logical pixels).
abstract class AppBreakpoints {
  /// Screens narrower than this are treated as mobile.
  static const double mobile = 600;

  /// Screens between [mobile] and [tablet] are treated as tablet.
  static const double tablet = 960;

  /// Wide desktop – navigation rail can show labels expanded.
  static const double wideDesktop = 1280;
}

// ─────────────────────────────────────────────────────────────────────────────
// ScreenSize enum
// ─────────────────────────────────────────────────────────────────────────────

/// Describes the current screen-size tier.
enum ScreenSize { mobile, tablet, desktop }

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extension – driven by MediaQuery (window-level)
// ─────────────────────────────────────────────────────────────────────────────

/// Convenience extension on [BuildContext] for responsive helpers.
///
/// Uses [MediaQuery.sizeOf] which re-renders the subtree every time the
/// window is resized on desktop – no extra listener is needed.
extension ResponsiveContext on BuildContext {
  /// Returns the [ScreenSize] tier based on the current window width.
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < AppBreakpoints.mobile) return ScreenSize.mobile;
    if (width < AppBreakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile  => screenSize == ScreenSize.mobile;
  bool get isTablet  => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Returns `true` when the window is wide enough to show extended rail labels.
  bool get isWideDesktop =>
      MediaQuery.sizeOf(this).width >= AppBreakpoints.wideDesktop;

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

// ─────────────────────────────────────────────────────────────────────────────
// ResponsiveLayout widget – LayoutBuilder-based (local constraints)
// ─────────────────────────────────────────────────────────────────────────────

/// Builds different widgets based on the **local** available width reported
/// by [LayoutBuilder].  Use this when you want a widget to adapt to the space
/// it is actually given (e.g. inside a panel or column) rather than the full
/// window width.
///
/// ```dart
/// ResponsiveLayout(
///   mobile:  MobileWidget(),
///   tablet:  TabletWidget(),
///   desktop: DesktopWidget(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    Widget? tablet,
    required this.desktop,
  }) : tablet = tablet ?? desktop;

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < AppBreakpoints.mobile) return mobile;
        if (width < AppBreakpoints.tablet) return tablet;
        return desktop;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ResponsiveBuilder – callback version
// ─────────────────────────────────────────────────────────────────────────────

typedef ResponsiveWidgetBuilder =
    Widget Function(BuildContext context, ScreenSize size, BoxConstraints constraints);

/// Like [ResponsiveLayout] but exposes the raw [BoxConstraints] and
/// [ScreenSize] to the builder callback for maximum flexibility.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final ScreenSize size;
        if (width < AppBreakpoints.mobile) {
          size = ScreenSize.mobile;
        } else if (width < AppBreakpoints.tablet) {
          size = ScreenSize.tablet;
        } else {
          size = ScreenSize.desktop;
        }
        return builder(context, size, constraints);
      },
    );
  }
}
