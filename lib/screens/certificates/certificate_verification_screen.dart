import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/certificate/certificate_providers.dart';

class CertificateVerificationScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const CertificateVerificationScreen({super.key, this.initialCode});

  @override
  ConsumerState<CertificateVerificationScreen> createState() => _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState extends ConsumerState<CertificateVerificationScreen> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(verificationNotifierProvider.notifier).verifyCode(widget.initialCode!);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref.read(verificationNotifierProvider.notifier).verifyCode(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Certificate'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              elevation: 0,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppConstants.paddingM),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 32),
                    SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: Text(
                        'Enter a unique 32-character verification code to authenticate any certificate issued by Local Skill Exchange.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            // Input field
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                hintText: 'e.g. a30ea52bae0226ebe228209cd3e98cdb',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
                suffixIcon: _codeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _codeController.clear();
                          ref.read(verificationNotifierProvider.notifier).clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppConstants.paddingM),
            ElevatedButton.icon(
              onPressed: verificationState.isLoading ? null : _submit,
              icon: verificationState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Verify Certificate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            // Result Presentation
            if (verificationState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppColors.error, size: 28),
                    const SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: Text(
                        verificationState.error!,
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (verificationState.result != null) ...[
              _buildVerificationResultCard(context, verificationState.result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationResultCard(BuildContext context, dynamic result) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final dateStr = result.issuedAt != null ? dateFormat.format(result.issuedAt!) : 'N/A';

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.success, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.1),
            blurRadius: 12,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.success, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'AUTHENTIC & VALID',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 28),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            result.title ?? 'Certificate of Completion',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          const Divider(),
          const SizedBox(height: AppConstants.paddingS),
          _detailRow('Recipient', result.recipientName ?? 'Learner'),
          const SizedBox(height: 8),
          _detailRow('Skill', result.skill ?? 'N/A'),
          const SizedBox(height: 8),
          _detailRow('Certificate ID', result.certificateNumber ?? 'N/A'),
          const SizedBox(height: 8),
          _detailRow('Issued On', dateStr),
          const SizedBox(height: 8),
          _detailRow('Status', (result.status ?? 'valid').toUpperCase()),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
