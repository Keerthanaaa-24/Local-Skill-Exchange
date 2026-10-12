import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/skill_passport_model.dart';
import '../../repositories/passport_repository.dart';

// Provider to fetch authenticated user's Skill Passport
final myPassportProvider = FutureProvider.autoDispose<SkillPassportModel>((ref) async {
  final repo = ref.watch(passportRepositoryProvider);
  return await repo.getMyPassport();
});

// Provider to fetch safe public Skill Passport by user ID
final userPassportProvider = FutureProvider.autoDispose.family<SkillPassportModel, int>((ref, userId) async {
  final repo = ref.watch(passportRepositoryProvider);
  return await repo.getPublicPassport(userId);
});
