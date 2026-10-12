import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import 'custom_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'Something went wrong';
    String message = error.toString();
    IconData icon = Icons.error_outline_rounded;
    Color color = Colors.redAccent;

    if (message.contains('Unauthorized')) {
      title = 'Session Expired';
      message = 'Please log in again to continue.';
      icon = Icons.lock_outline_rounded;
      color = Colors.orange;
    } else if (message.contains('Server Error')) {
      title = 'Server Error';
      message = 'We are experiencing technical difficulties. Please try again later.';
      icon = Icons.cloud_off_rounded;
    } else if (message.contains('Network') || message.contains('connection')) {
      title = 'You\'re Offline';
      message = 'Please check your internet connection and try again.';
      icon = Icons.wifi_off_rounded;
      color = Colors.blueGrey;
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: color,
              ),
            ).animate().fade().scale(),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ).animate().fade().slideY(begin: 0.2, delay: 100.ms),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              message.replaceAll('Exception: ', ''),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ).animate().fade().slideY(begin: 0.2, delay: 200.ms),
            const SizedBox(height: AppConstants.paddingXL),
            CustomButton(
              text: 'Retry',
              onPressed: onRetry,
            ).animate().fade().slideY(begin: 0.2, delay: 300.ms),
          ],
        ),
      ),
      ),
    );
  }
}
