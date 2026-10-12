import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/certificate_model.dart';
import '../../repositories/certificate_repository.dart';

// Provider to fetch all certificates for current user
final userCertificatesProvider = FutureProvider.autoDispose<List<CertificateModel>>((ref) async {
  final repo = ref.watch(certificateRepositoryProvider);
  return await repo.getCertificates();
});

// Provider to fetch single certificate by ID
final certificateDetailProvider = FutureProvider.autoDispose.family<CertificateModel, int>((ref, certId) async {
  final repo = ref.watch(certificateRepositoryProvider);
  return await repo.getCertificate(certId);
});

// Provider to check certificate by learning path id if user already has it
final certificateForPathProvider = FutureProvider.autoDispose.family<CertificateModel?, int>((ref, pathId) async {
  final repo = ref.watch(certificateRepositoryProvider);
  final certificates = await repo.getCertificates();
  try {
    return certificates.firstWhere((c) => c.learningPathId == pathId);
  } catch (_) {
    return null;
  }
});

// Issue Certificate Notifier State
class IssueCertificateState {
  final bool isLoading;
  final CertificateModel? certificate;
  final String? error;

  IssueCertificateState({
    this.isLoading = false,
    this.certificate,
    this.error,
  });
}

class IssueCertificateNotifier extends StateNotifier<IssueCertificateState> {
  final CertificateRepository _repository;
  final Ref _ref;

  IssueCertificateNotifier(this._repository, this._ref) : super(IssueCertificateState());

  Future<CertificateModel?> issue(int learningPathId) async {
    state = IssueCertificateState(isLoading: true);
    try {
      final cert = await _repository.issueCertificate(learningPathId);
      state = IssueCertificateState(isLoading: false, certificate: cert);
      // Refresh user certificates list
      _ref.invalidate(userCertificatesProvider);
      _ref.invalidate(certificateForPathProvider(learningPathId));
      return cert;
    } catch (e) {
      state = IssueCertificateState(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  void reset() {
    state = IssueCertificateState();
  }
}

final issueCertificateProvider = StateNotifierProvider.autoDispose<IssueCertificateNotifier, IssueCertificateState>((ref) {
  final repo = ref.watch(certificateRepositoryProvider);
  return IssueCertificateNotifier(repo, ref);
});

// Verification State
class VerificationState {
  final bool isLoading;
  final CertificateVerificationModel? result;
  final String? error;

  VerificationState({
    this.isLoading = false,
    this.result,
    this.error,
  });
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final CertificateRepository _repository;

  VerificationNotifier(this._repository) : super(VerificationState());

  Future<void> verifyCode(String code) async {
    if (code.trim().isEmpty) {
      state = VerificationState(error: 'Please enter a verification code');
      return;
    }
    state = VerificationState(isLoading: true);
    try {
      final result = await _repository.verifyCertificate(code.trim());
      state = VerificationState(isLoading: false, result: result);
    } catch (e) {
      state = VerificationState(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clear() {
    state = VerificationState();
  }
}

final verificationNotifierProvider = StateNotifierProvider.autoDispose<VerificationNotifier, VerificationState>((ref) {
  final repo = ref.watch(certificateRepositoryProvider);
  return VerificationNotifier(repo);
});
