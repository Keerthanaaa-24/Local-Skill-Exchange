import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      child: _buildButton(child, context),
    );
  }

  Widget _buildButton(Widget child, BuildContext context) {
    switch (type) {
      case ButtonType.secondary:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ButtonType.outlined:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL, vertical: 14),
            side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ButtonType.text:
        return TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: 10),
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }
}
