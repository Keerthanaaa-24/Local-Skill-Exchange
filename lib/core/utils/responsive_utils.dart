import 'package:flutter/material.dart';

enum DeviceScreenType { mobile, tablet, desktop, largeDesktop }

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double screenHeight(BuildContext context) => MediaQuery.sizeOf(context).height;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) return DeviceScreenType.mobile;
    if (width < tabletBreakpoint) return DeviceScreenType.tablet;
    if (width < desktopBreakpoint) return DeviceScreenType.desktop;
    return DeviceScreenType.largeDesktop;
  }

  static bool isMobile(BuildContext context) => screenWidth(context) < mobileBreakpoint;
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= mobileBreakpoint && screenWidth(context) < tabletBreakpoint;
  static bool isDesktop(BuildContext context) => screenWidth(context) >= tabletBreakpoint;
  static bool isLargeDesktop(BuildContext context) => screenWidth(context) >= desktopBreakpoint;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case DeviceScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceScreenType.tablet:
        return tablet ?? mobile;
      case DeviceScreenType.mobile:
        return mobile;
    }
  }

  static int gridColumnCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    return value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceScreenType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = ResponsiveUtils.getDeviceType(context);
        return builder(context, type);
      },
    );
  }
}
