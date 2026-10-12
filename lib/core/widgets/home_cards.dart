import 'package:flutter/material.dart';
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../models/recommendation_model.dart';
import '../../screens/features/mentor_profile_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'custom_avatar.dart';

class SkillCategoryItem {
  final String id;
  final String name;
  final String icon;
  final IconData? iconData;
  final Color? color;

  const SkillCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    this.iconData,
    this.color,
  });
}

class CategoryCard extends StatelessWidget {
  final SkillCategoryItem category;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        width: 105,
        margin: const EdgeInsets.only(right: AppConstants.paddingM),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (category.iconData != null)
              Icon(category.iconData, size: 28, color: category.color ?? theme.colorScheme.primary)
            else
              Text(
                category.icon,
                style: const TextStyle(
                  fontSize: 26,
                  fontFamilyFallback: [
                    'Noto Color Emoji',
                    'Apple Color Emoji',
                    'Segoe UI Emoji',
                    'Segoe UI Symbol',
                    'sans-serif',
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              category.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeSkillCard extends StatelessWidget {
  final SkillModel skill;

  const HomeSkillCard({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MentorProfileScreen(recommendation: RecommendationModel.fromSkill(skill)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: AppConstants.paddingM),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
              child: skill.imageUrl != null && skill.imageUrl!.isNotEmpty
                  ? Image.network(
                      skill.imageUrl!,
                      height: 115,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 115,
                          width: double.infinity,
                          color: theme.primaryColor.withValues(alpha: 0.08),
                          child: Icon(Icons.school_outlined, size: 36, color: theme.primaryColor),
                        );
                      },
                    )
                  : Container(
                      height: 115,
                      width: double.infinity,
                      color: theme.primaryColor.withValues(alpha: 0.08),
                      child: Icon(Icons.school_outlined, size: 36, color: theme.primaryColor),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (skill.categoryName != null)
                    Text(
                      skill.categoryName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 3),
                          Text(
                            skill.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            ' (${skill.reviewCount})',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.primary, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            '${skill.credits} XP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MentorCard extends StatelessWidget {
  final User user;

  const MentorCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        final rec = RecommendationModel(
          mentorId: int.tryParse(user.id) ?? 0,
          mentorName: user.name,
          mentorProfileImage: user.avatarUrl,
          mentorRating: user.rating,
          mentorReviewCount: user.reviews,
          mentorLatitude: user.lat,
          mentorLongitude: user.lng,
          skillId: 1,
          skillTitle: user.title,
          skillDescription: 'Offering ${user.skillsOffered.join(", ")}',
          skillCategory: user.skillsOffered.isNotEmpty ? user.skillsOffered.first : 'General',
          matchScore: 90.0,
          explanation: '${user.distanceKm} km away',
          distanceKm: user.distanceKm,
          rating: user.rating,
          reason: 'Recommended local mentor available for exchange sessions.',
          canLearn: true,
          canTeach: false,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MentorProfileScreen(recommendation: rec)),
        );
      },
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomAvatar(
              radius: 28,
              imageUrl: user.avatarUrl,
              name: user.name,
            ),
            const SizedBox(height: 8),
            Text(
              user.name,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              user.title.isNotEmpty ? user.title : (user.skillsOffered.isNotEmpty ? user.skillsOffered.first : 'Mentor'),
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryLight, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Text(
                  user.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                const SizedBox(width: 6),
                Text(
                  '${user.distanceKm} km',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreditBalanceCard extends StatelessWidget {
  final int balance;
  
  const CreditBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skill Wallet & Energy',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '$balance XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

