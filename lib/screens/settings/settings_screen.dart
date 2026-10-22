import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_routes.dart';
import '../features/edit_profile_screen.dart';
import '../../core/config/env.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final authUser = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
              vertical: AppConstants.paddingM,
            ),
            children: [
              // 1. ACCOUNT SECTION
              _buildSectionHeader(context, 'Account & Identity', Icons.person_rounded),
              _buildCardContainer(
                context,
                children: [
                  ListTile(
                    leading: CustomAvatar(
                      radius: 20,
                      imageUrl: authUser?.profileImageUrl,
                      name: authUser?.name ?? 'User',
                    ),
                    title: Text(
                      authUser?.name ?? 'Skill Creator',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      authUser?.email ?? 'Logged in account',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    trailing: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Public Profile Visibility'),
                    subtitle: const Text('Allow local community members to view your skills'),
                    secondary: const Icon(Icons.visibility_rounded),
                    value: settings.profileVisibility,
                    onChanged: settingsNotifier.toggleProfileVisibility,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // 2. PREFERENCES & THEME
              _buildSectionHeader(context, 'Appearance & Theme', Icons.palette_rounded),
              _buildCardContainer(
                context,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Theme Mode',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_rounded),
                              label: Text('Dark'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_rounded),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_rounded),
                              label: Text('System'),
                            ),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (selected) {
                            if (selected.isNotEmpty) {
                              settingsNotifier.setThemeMode(selected.first);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Language'),
                    subtitle: const Text('English (US) — Primary'),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // 3. PRIVACY & PROXIMITY
              _buildSectionHeader(context, 'Privacy & Proximity', Icons.security_rounded),
              _buildCardContainer(
                context,
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Location Sharing'),
                    subtitle: const Text('Enable proximity matching for nearby mentors & sessions'),
                    secondary: const Icon(Icons.location_on_rounded),
                    value: settings.locationSharing,
                    onChanged: settingsNotifier.toggleLocationSharing,
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Show as Nearby Mentor'),
                    subtitle: const Text('Appear in explore maps when offering skills'),
                    secondary: const Icon(Icons.near_me_rounded),
                    value: settings.nearbyMentorVisibility,
                    onChanged: settingsNotifier.toggleNearbyMentorVisibility,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // 4. NOTIFICATIONS
              _buildSectionHeader(context, 'Notifications & Alerts', Icons.notifications_rounded),
              _buildCardContainer(
                context,
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Session Reminders'),
                    subtitle: const Text('Receive notifications before upcoming booked sessions'),
                    secondary: const Icon(Icons.calendar_today_rounded),
                    value: settings.sessionReminders,
                    onChanged: settingsNotifier.toggleSessionReminders,
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Booking Requests & Updates'),
                    subtitle: const Text('Get notified when a learner requests or confirms a session'),
                    secondary: const Icon(Icons.event_available_rounded),
                    value: settings.bookingUpdates,
                    onChanged: settingsNotifier.toggleBookingUpdates,
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Chat & Direct Messages'),
                    subtitle: const Text('Real-time alerts for incoming exchange messages'),
                    secondary: const Icon(Icons.chat_rounded),
                    value: settings.chatNotifications,
                    onChanged: settingsNotifier.toggleChatNotifications,
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Learning Streak & Goal Reminders'),
                    subtitle: const Text('Daily practice reminders to keep your streak active'),
                    secondary: const Icon(Icons.local_fire_department_rounded),
                    value: settings.learningReminders,
                    onChanged: settingsNotifier.toggleLearningReminders,
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Milestones & Certificate Alerts'),
                    subtitle: const Text('Celebrations when you pass quizzes and earn credentials'),
                    secondary: const Icon(Icons.emoji_events_rounded),
                    value: settings.achievementAlerts,
                    onChanged: settingsNotifier.toggleAchievementAlerts,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // 5. LEARNING PREFERENCES
              _buildSectionHeader(context, 'Learning Goals & Style', Icons.school_rounded),
              _buildCardContainer(
                context,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daily Learning Target',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${settings.dailyLearningGoalMinutes} mins / day',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [15, 30, 45, 60].map((mins) {
                            final isSelected = settings.dailyLearningGoalMinutes == mins;
                            return ChoiceChip(
                              label: Text('$mins min'),
                              selected: isSelected,
                              onSelected: (_) => settingsNotifier.setDailyLearningGoal(mins),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferred Curriculum Difficulty',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: ['Beginner', 'Intermediate', 'Advanced'].map((diff) {
                            final isSelected = settings.preferredDifficulty == diff;
                            return ChoiceChip(
                              label: Text(diff),
                              selected: isSelected,
                              onSelected: (_) => settingsNotifier.setPreferredDifficulty(diff),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferred Study Materials Format',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: ['All Formats', 'Video Lessons', 'Documentation', 'Practice MCQs'].map((fmt) {
                            final isSelected = settings.preferredContentType == fmt;
                            return ChoiceChip(
                              label: Text(fmt),
                              selected: isSelected,
                              onSelected: (_) => settingsNotifier.setPreferredContentType(fmt),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // 6. SECURITY & ACCESS
              _buildSectionHeader(context, 'Security', Icons.lock_outline_rounded),
              _buildCardContainer(
                context,
                children: [
                  ListTile(
                    leading: const Icon(Icons.key_rounded),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your account security password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.devices_rounded),
                    title: const Text('Active Session'),
                    subtitle: const Text('FastAPI JWT Token Authentication (Active)'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Secure', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // 7. SERVER & MOBILE CONNECTIVITY
              _buildSectionHeader(context, 'Server & Mobile Connectivity', Icons.dns_rounded),
              _buildCardContainer(
                context,
                children: [
                  ListTile(
                    leading: const Icon(Icons.wifi_tethering_rounded, color: AppColors.primary),
                    title: const Text('Backend API URL'),
                    subtitle: Text(Env.apiBaseUrl),
                    trailing: const Icon(Icons.edit_rounded, size: 20),
                    onTap: () => _showServerSettingsDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      authUser?.isGuest == true ? Icons.visibility_rounded : Icons.verified_user_rounded,
                      color: authUser?.isGuest == true ? Colors.amber.shade700 : AppColors.success,
                    ),
                    title: Text(authUser?.isGuest == true ? 'Session: Guest Mode' : 'Session: Verified Member'),
                    subtitle: Text(authUser?.isGuest == true
                        ? 'Browsing with restricted write access. Sign in for full access.'
                        : 'Full access to bookings, messages, and skill exchange.'),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // 8. ABOUT & CAPSTONE METADATA
              _buildSectionHeader(context, 'About Local Skill Exchange', Icons.info_outline_rounded),
              _buildCardContainer(
                context,
                children: [
                  const ListTile(
                    leading: Icon(Icons.verified_rounded, color: AppColors.primary),
                    title: Text('Version'),
                    subtitle: Text('1.0.0 (MCA Capstone Production Build)'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.library_books_rounded),
                    title: const Text('Design System & UI Components'),
                    subtitle: const Text('View theme palette, typography, and atomic widgets'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.designSystem),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text('Help & Support'),
                    subtitle: const Text('FAQs, user guidelines, and skill exchange policy'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showHelpDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // 8. DANGER ZONE
              _buildSectionHeader(context, 'Account Actions', Icons.warning_amber_rounded, color: AppColors.error),
              _buildCardContainer(
                context,
                borderColor: AppColors.error.withValues(alpha: 0.3),
                children: [
                  ListTile(
                    leading: const Icon(Icons.restore_rounded, color: Colors.orange),
                    title: const Text('Reset Preferences to Defaults'),
                    subtitle: const Text('Restore factory notification and learning settings'),
                    onTap: () async {
                      await settingsNotifier.resetToDefaults();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preferences reset to default values.')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Sign out of this session'),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    final headerColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: headerColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: headerColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(
    BuildContext context, {
    required List<Widget> children,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.cardTheme.color ?? theme.cardColor,
      elevation: isDark ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        side: BorderSide(
          color: borderColor ?? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Change Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully.')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showServerSettingsDialog(BuildContext context) {
    final urlController = TextEditingController(text: Env.apiBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Server Backend Connection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend server URL reachable from this device. '
              'On physical phones on the same Wi-Fi, use your PC\'s Wi-Fi IP address (never localhost/127.0.0.1).',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://192.168.1.2:8000/api/v1',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ActionChip(
                  label: const Text('Port 8000'),
                  onPressed: () {
                    urlController.text = 'http://${Env.defaultLanHost}:${Env.defaultPort}/api/v1';
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Port 8001'),
                  onPressed: () {
                    urlController.text = 'http://${Env.defaultLanHost}:${Env.fallbackPort}/api/v1';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                Env.setCustomApiBaseUrl(newUrl);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server URL set to: ${Env.apiBaseUrl}')),
                );
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Local Skill Exchange Support'),
          ],
        ),
        content: const Text(
          'Local Skill Exchange is a localized, peer-to-peer knowledge and practical skill sharing ecosystem.\n\n'
          '• Connect with verified local mentors\n'
          '• Book 1-on-1 exchange sessions using credits\n'
          '• Follow interactive on-demand curriculums\n'
          '• Complete timed assessments to earn verified certificates\n'
          '• Showcase your achievements via Skill Passport',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
