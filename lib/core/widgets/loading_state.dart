import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';

class LoadingSkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadiusGeometry? borderRadius;

  const LoadingSkeletonCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.5) ?? Colors.grey.withValues(alpha: 0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.radiusM),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(
          begin: 0.5,
          end: 1.0,
          duration: 1.seconds,
          curve: Curves.easeInOut,
        );
  }
}

class LoadingCircular extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingCircular({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          color: color ?? Theme.of(context).primaryColor,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

class LoadingFullScreen extends StatelessWidget {
  final String? message;

  const LoadingFullScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingCircular(size: 60),
            if (message != null) ...[
              const SizedBox(height: AppConstants.paddingL),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
