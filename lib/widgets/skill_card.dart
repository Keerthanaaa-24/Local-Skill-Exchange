import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../core/widgets/custom_avatar.dart';
import '../models/user_model.dart';

class SkillCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const SkillCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppConstants.paddingM),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Cover/Avatar area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusM)),
              child: Stack(
                children: [
                  Container(
                    height: 80,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    width: double.infinity,
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: CustomAvatar(
                      radius: 20,
                      imageUrl: user.avatarUrl,
                      name: user.name,
                    ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      top: 45,
                      left: 45,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).cardTheme.color!, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.skillsOffered.isNotEmpty ? user.skillsOffered.first : 'Various Skills',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${user.rating} (${user.reviews})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), delay: 100.ms),
    );
  }
}
