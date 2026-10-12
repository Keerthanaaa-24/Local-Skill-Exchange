import 'package:flutter/material.dart';
import '../config/env.dart';

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String name;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.name = '',
  });

  String? get _resolvedUrl {
    if (imageUrl == null || imageUrl!.trim().isEmpty) return null;
    final url = imageUrl!.trim();
    if (url.contains('pravatar') || url.contains('ui-avatars')) return null;
    if (url.startsWith('/uploads') || url.startsWith('uploads/')) {
      final cleanPath = url.startsWith('/') ? url : '/$url';
      return '${Env.serverBaseUrl}$cleanPath';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return null;
  }

  String get _initials {
    final clean = name.trim();
    if (clean.isEmpty) return '';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedUrl;
    final theme = Theme.of(context);

    if (resolved != null) {
      return ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          color: theme.primaryColor.withValues(alpha: 0.12),
          child: Image.network(
            resolved,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(context),
          ),
        ),
      );
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials;

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : Icon(
              Icons.person_rounded,
              size: radius * 1.2,
              color: theme.primaryColor,
            ),
    );
  }
}
