import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';
import '../models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/loading_state.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_avatar.dart';
import 'features/edit_profile_screen.dart';
import '../routes/app_routes.dart';
import '../providers/certificate/certificate_providers.dart';
import '../providers/community_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      if (!mounted) return;
      setState(() => _isUploadingImage = true);

      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name.isNotEmpty ? pickedFile.name : 'avatar.png';

      await ref.read(profileProvider.notifier).uploadProfileImageBytes(bytes, filename: fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile photo updated and saved successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings & Preferences',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileProvider.notifier).refreshProfile();
        },
        child: profileAsyncValue.when(
          data: (profile) => _buildProfileContent(context, profile),
          loading: () => const LoadingFullScreen(message: 'Loading Profile...'),
          error: (error, stackTrace) => _buildErrorState(context, error.toString()),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: AppConstants.paddingL),
            CustomButton(
              text: 'Retry',
              onPressed: () => ref.read(profileProvider.notifier).refreshProfile(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfile profile) {
    final userId = int.tryParse(profile.id) ?? 0;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100, left: AppConstants.paddingM, right: AppConstants.paddingM),
      child: Column(
        children: [
          const SizedBox(height: AppConstants.paddingM),
          _buildProfileHeader(context, profile),
          const SizedBox(height: AppConstants.paddingL),
          _buildStatsRow(context, profile),
          const SizedBox(height: AppConstants.paddingM),
          _buildPassportCard(context),
          const SizedBox(height: AppConstants.paddingL),
          _buildTrustIndicators(context, ref, userId),
          const SizedBox(height: AppConstants.paddingL),
          _buildSectionHeader(context, 'About Me', actionTitle: 'Edit', onAction: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            if (res == true) {
              ref.read(profileProvider.notifier).refreshProfile();
            }
          }),
          const SizedBox(height: AppConstants.paddingS),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              profile.bio ?? 'No bio provided yet. Tap Edit to add a bio.',
              style: TextStyle(color: profile.bio == null ? Colors.grey : Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
            ).animate().fade().slideY(begin: 0.1, delay: 200.ms),
          ),
          const SizedBox(height: AppConstants.paddingL),
          _buildSectionHeader(context, 'Skills & Learning Goals', actionTitle: 'Edit', onAction: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            if (res == true) {
              ref.read(profileProvider.notifier).refreshProfile();
            }
          }),
          _buildSkillsList(context, profile.skills, profile.wantedSkills),
          const SizedBox(height: AppConstants.paddingL),
          _buildCertificatesSection(context, ref),
          const SizedBox(height: AppConstants.paddingL),
          _buildActivitySection(context, ref, userId),
          const SizedBox(height: AppConstants.paddingL),
          _buildReviewsSection(context, ref, profile),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.primaryColor, width: 3),
              ),
            ),
            CustomAvatar(
              radius: 54,
              imageUrl: profile.profileImageUrl,
              name: profile.name,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                  ),
                  child: _isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: AppConstants.paddingM),
        Text(
          profile.name,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fade().slideY(begin: 0.2),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ).animate().fade().slideY(begin: 0.2, delay: 100.ms),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, UserProfile profile) {
    return Consumer(
      builder: (context, ref, child) {
        final userId = int.tryParse(profile.id) ?? 0;
        final reviewsAsync = ref.watch(userReviewsProvider(userId));
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(context, Icons.account_balance_wallet_rounded, Colors.orange, '${profile.credits}', 'Credits'),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: reviewsAsync.maybeWhen(
                data: (state) => _buildStatCard(context, Icons.star_rounded, Colors.amber, state.stats.averageRating.toStringAsFixed(1), '${state.stats.totalReviews} Reviews'),
                orElse: () => _buildStatCard(context, Icons.star_rounded, Colors.amber, profile.rating.toStringAsFixed(1), '${profile.reviewCount} Reviews'),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ).animate().fade().scale(delay: 200.ms);
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required String actionTitle, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onAction,
          child: Text(actionTitle, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildSkillsList(BuildContext context, List<String> skills, [List<String> wantedSkills = const []]) {
    if (skills.isEmpty && wantedSkills.isEmpty) {
      return const EmptyStateWidget(type: EmptyStateType.noSkills);
    }
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (skills.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.school, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                'Skills I Teach',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                );
              }).toList(),
            ),
          ).animate().fade().slideX(delay: 300.ms),
        ],
        if (wantedSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                'Learning Goals',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: wantedSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                );
              }).toList(),
            ),
          ).animate().fade().slideX(delay: 400.ms),
        ],
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, WidgetRef ref, UserProfile profile) {
    final userId = int.tryParse(profile.id) ?? 0;
    final reviewsAsync = ref.watch(userReviewsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'My Reviews', actionTitle: ''),
        const SizedBox(height: AppConstants.paddingS),
        reviewsAsync.when(
          data: (state) {
            if (state.reviews.isEmpty) {
              return const Text('No reviews received yet.', style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: state.reviews.map((review) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CustomAvatar(radius: 12, imageUrl: review.reviewerImageUrl, name: review.reviewerName),
                              const SizedBox(width: 8),
                              Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: List.generate(5, (index) => Icon(
                              index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber, size: 14,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(review.comment.isNotEmpty ? review.comment : 'No comment provided.', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const Text('Failed to load reviews.'),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, delay: 500.ms);
  }

  Widget _buildCertificatesSection(BuildContext context, WidgetRef ref) {
    final certsAsync = ref.watch(userCertificatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'My Certificates',
          actionTitle: 'View All',
          onAction: () => Navigator.pushNamed(context, AppRoutes.certificates),
        ),
        const SizedBox(height: AppConstants.paddingS),
        certsAsync.when(
          data: (certs) {
            if (certs.isEmpty) {
              return Card(
                elevation: 0,
                color: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_outlined, color: Colors.grey, size: 28),
                      const SizedBox(width: AppConstants.paddingM),
                      const Expanded(
                        child: Text(
                          'No certificates yet. Complete learning paths to get certified!',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: certs.take(2).map((c) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37)),
                    title: Text(c.learningPathTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('ID: ${c.certificateNumber}', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.certificateDetail, arguments: c),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const SizedBox(),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, delay: 450.ms);
  }

  Widget _buildPassportCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.passport),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppConstants.paddingM),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skill Passport',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View your skills, certificates & learning stats',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, delay: 250.ms);
  }

  Widget _buildTrustIndicators(BuildContext context, WidgetRef ref, int userId) {
    final profileAsync = ref.watch(communityProfileProvider(userId));
    return profileAsync.when(
      data: (cp) {
        final ti = cp.trustIndicators;
        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Community Trust & Reputation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (ti.isVerifiedMentor)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text('Mentor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTrustStat(context, '${ti.verifiedCertificatesCount}', 'Certificates', Icons.workspace_premium_rounded, Colors.purple),
                  ),
                  Expanded(
                    child: _buildTrustStat(context, '${ti.completedExchanges}', 'Exchanges', Icons.swap_horiz_rounded, Colors.teal),
                  ),
                  Expanded(
                    child: _buildTrustStat(context, '${ti.skillsOfferedCount}', 'Offered', Icons.volunteer_activism_rounded, Colors.indigo),
                  ),
                  Expanded(
                    child: _buildTrustStat(context, '${ti.skillsLearnedCount}', 'Learned', Icons.school_rounded, Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fade().slideY(begin: 0.1, delay: 280.ms);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildTrustStat(BuildContext context, String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, WidgetRef ref, int userId) {
    final activityAsync = ref.watch(userActivityProvider(userId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'My Community Activity', actionTitle: ''),
        const SizedBox(height: AppConstants.paddingS),
        activityAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Card(
                elevation: 0,
                color: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(AppConstants.paddingM),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: Colors.grey, size: 24),
                      SizedBox(width: AppConstants.paddingM),
                      Expanded(
                        child: Text(
                          'No recent community activity yet. Complete lessons or exchanges to build your trail!',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: items.take(4).map((item) {
                IconData icon;
                Color color;
                switch (item.type) {
                  case 'certificate':
                    icon = Icons.workspace_premium_rounded;
                    color = const Color(0xFFD4AF37);
                    break;
                  case 'path_completed':
                    icon = Icons.check_circle_rounded;
                    color = Colors.green;
                    break;
                  case 'exchange_completed':
                    icon = Icons.swap_horiz_rounded;
                    color = Colors.teal;
                    break;
                  case 'review':
                    icon = Icons.star_rounded;
                    color = Colors.amber;
                    break;
                  default:
                    icon = Icons.bubble_chart_rounded;
                    color = Colors.blue;
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(item.description, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      '${item.timestamp.day}/${item.timestamp.month}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, delay: 480.ms);
  }
}
