import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../providers/certificate/certificate_providers.dart';
import '../../routes/app_routes.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certsAsync = ref.watch(userCertificatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: const Text('Verify'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.verifyCertificate);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userCertificatesProvider);
        },
        child: certsAsync.when(
          loading: () => const Center(child: LoadingCircular()),
          error: (err, stack) => ErrorStateWidget(
            error: err,
            onRetry: () => ref.refresh(userCertificatesProvider),
          ),
          data: (certificates) {
            if (certificates.isEmpty) {
              return _buildEmptyState(context);
            }

            final dateFormat = DateFormat('MMM d, yyyy');

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: certificates.length,
              itemBuilder: (context, index) {
                final cert = certificates[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.certificateDetail,
                        arguments: cert,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingM),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFF8E1),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Color(0xFFD4AF37),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cert.learningPathTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Skill: ${cert.skillName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Issued: ${dateFormat.format(cert.issuedAt)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_membership_rounded,
                size: 64,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              'No Certificates Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              'Complete 100% of lessons in any learning path to earn verified certificates to showcase your skills.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            ElevatedButton.icon(
              icon: const Icon(Icons.school_outlined),
              label: const Text('Explore Learning Hub'),
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.learningHub);
              },
            ),
          ],
        ),
      ),
    );
  }
}
