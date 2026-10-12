import 'package:flutter/material.dart';
import '../screens/design_system/design_system_screen.dart';
import '../models/lesson_model.dart';
import '../models/learning_path_model.dart';
import '../models/recommendation_model.dart';
import '../models/booking_model.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/forgot_password_success_screen.dart';
import '../screens/main_layout.dart';
import '../screens/features/notifications_screen.dart';
import '../screens/features/search_filter_screen.dart';
import '../screens/features/wallet_screen.dart';
import '../screens/features/ai_match_screen.dart';
import '../screens/features/session_details_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

import '../screens/features/mentor_profile_screen.dart';
import '../models/skill_model.dart';
import '../screens/learning/lesson_screen.dart';
import '../screens/learning/learning_hub_screen.dart';
import '../screens/learning/skill_learning_screen.dart';
import '../screens/learning/practice_screen.dart';
import '../screens/learning/quiz_screen.dart';
import '../models/certificate_model.dart';
import '../screens/certificates/certificates_screen.dart';
import '../screens/certificates/certificate_detail_screen.dart';
import '../screens/certificates/certificate_verification_screen.dart';
import '../screens/passport/skill_passport_screen.dart';
import '../screens/gamification/leaderboard_screen.dart';
import '../screens/conversation_screen.dart';
import '../models/chat_model.dart';

import '../screens/features/ai_coach_hub_screen.dart';

import '../screens/settings/settings_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String forgotPasswordSuccess = '/forgot_password_success';
  static const String home = '/home';
  static const String designSystem = '/design_system';
  static const String settings = '/settings';
  
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';
  static const String review = '/review';
  static const String aiMatch = '/ai_match';
  static const String aiCoach = '/ai_coach';
  static const String sessionDetails = '/session_details';
  static const String searchFilter = '/search_filter';
  static const String mentorProfile = '/mentor_profile';
  static const String admin = '/admin';
  static const String learningHub = '/learning_hub';
  static const String skillLearning = '/skill_learning';
  static const String lesson = '/lesson';
  static const String practice = '/practice';
  static const String quiz = '/quiz';
  static const String certificates = '/certificates';
  static const String certificateDetail = '/certificate_detail';
  static const String verifyCertificate = '/verify_certificate';
  static const String passport = '/passport';
  static const String leaderboard = '/leaderboard';
  static const String conversation = '/conversation';
  static const String explore = '/home';
  static const String bookings = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case forgotPasswordSuccess:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordSuccessScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const MainLayout());
      case designSystem:
        return MaterialPageRoute(builder: (_) => const DesignSystemScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case wallet:
        return MaterialPageRoute(builder: (_) => const WalletScreen());
      case aiMatch:
        return MaterialPageRoute(builder: (_) => const AiMatchScreen());
      case aiCoach:
        return MaterialPageRoute(builder: (_) => const AiCoachHubScreen());
      case sessionDetails:
        final booking = settings.arguments as BookingModel?;
        if (booking == null) return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Booking not found'))));
        return MaterialPageRoute(builder: (_) => SessionDetailsScreen(booking: booking));
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case learningHub:
        return MaterialPageRoute(builder: (_) => const LearningHubScreen());
      case skillLearning:
        final skill = settings.arguments as SkillModel?;
        if (skill == null) return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Skill not found'))));
        return MaterialPageRoute(builder: (_) => SkillLearningScreen(skill: skill));
      case lesson:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('lesson') || !args.containsKey('path')) {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Lesson data missing'))));
        }
        final lesson = args['lesson'] as LessonModel;
        final path = args['path'] as LearningPathModel;
        return MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson, path: path));
      case practice:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('lesson') || !args.containsKey('path')) {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Practice data missing'))));
        }
        final lesson = args['lesson'] as LessonModel;
        final path = args['path'] as LearningPathModel;
        return MaterialPageRoute(builder: (_) => PracticeScreen(lesson: lesson, path: path));
      case quiz:
        final path = settings.arguments as LearningPathModel?;
        if (path == null) {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Quiz path missing'))));
        }
        return MaterialPageRoute(builder: (_) => QuizScreen(path: path));
      case certificates:
        return MaterialPageRoute(builder: (_) => const CertificatesScreen());
      case certificateDetail:
        final cert = settings.arguments as CertificateModel?;
        if (cert == null) return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Certificate data missing'))));
        return MaterialPageRoute(builder: (_) => CertificateDetailScreen(certificate: cert));
      case verifyCertificate:
        final code = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => CertificateVerificationScreen(initialCode: code));
      case passport:
        final userId = settings.arguments as int?;
        return MaterialPageRoute(builder: (_) => SkillPassportScreen(userId: userId));
      case leaderboard:
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
      case searchFilter:
        return MaterialPageRoute(builder: (_) => const SearchFilterScreen());
      case mentorProfile:
        final args = settings.arguments;
        RecommendationModel? rec;
        if (args is RecommendationModel) {
          rec = args;
        } else if (args is SkillModel) {
          rec = RecommendationModel.fromSkill(args);
        }
        if (rec == null) return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Profile not found'))));
        return MaterialPageRoute(builder: (_) => MentorProfileScreen(recommendation: rec!));
      case conversation:
        final args = settings.arguments;
        int chatId = 0;
        ChatModel? chat;
        if (args is int) {
          chatId = args;
        } else if (args is ChatModel) {
          chatId = args.chatId;
          chat = args;
        } else if (args is Map<String, dynamic>) {
          chatId = (args['chatId'] ?? args['chat_id'] ?? 0) as int;
          chat = args['chat'] as ChatModel?;
        }
        return MaterialPageRoute(
          builder: (_) => ConversationScreen(chatId: chatId, chat: chat),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
