import 'package:google_sign_in/google_sign_in.dart';
import '../core/config/env.dart';

class GoogleAuthException implements Exception {
  final String message;
  final String? code;
  GoogleAuthException(this.message, [this.code]);
  @override
  String toString() => message;
}

class GoogleAuthResult {
  final String idToken;
  final String? accessToken;
  final String? email;
  final String? name;
  final String? avatarUrl;

  GoogleAuthResult({
    required this.idToken,
    this.accessToken,
    this.email,
    this.name,
    this.avatarUrl,
  });
}

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;

  GoogleAuthService._internal();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: Env.googleServerClientId.isNotEmpty ? Env.googleServerClientId : null,
      );
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  Future<GoogleAuthResult?> signIn() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw GoogleAuthException(
          'Google Sign-In returned an empty ID token. '
          'Please ensure a Web Client ID is configured in GOOGLE_SERVER_CLIENT_ID '
          'and registered in your Google Cloud Console project.',
          'MISSING_ID_TOKEN',
        );
      }

      return GoogleAuthResult(
        idToken: idToken,
        accessToken: null,
        email: account.email,
        name: account.displayName,
        avatarUrl: account.photoUrl,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      String errorExplanation = e.description ?? e.toString();
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError ||
          e.code == GoogleSignInExceptionCode.unknownError) {
        errorExplanation = 
          'Google OAuth Setup Required:\n'
          '1. Package name: com.example.local_skill_exchange\n'
          '2. SHA-1 Fingerprint: AF:1E:A3:F8:79:DD:C9:91:0A:0B:4E:FB:11:A3:FA:BE:2B:CE:D0:87\n'
          '3. SHA-256 Fingerprint: 34:49:D6:1A:4E:DC:20:45:05:C6:D0:26:DA:E6:17:D7:90:9D:D3:35:77:03:99:15:80:A7:DC:CA:6B:FE:35:3D\n'
          'Please register this SHA-1 in your Google Cloud Console / Firebase project.';
      }
      throw GoogleAuthException(errorExplanation, e.code.name);
    } catch (e) {
      if (e is GoogleAuthException) rethrow;
      String errStr = e.toString();
      if (errStr.contains('10') || errStr.contains('12500')) {
        errStr = 
          'Google OAuth Setup Required:\n'
          '1. Package name: com.example.local_skill_exchange\n'
          '2. SHA-1 Fingerprint: AF:1E:A3:F8:79:DD:C9:91:0A:0B:4E:FB:11:A3:FA:BE:2B:CE:D0:87\n'
          'Please register this SHA-1 in your Google Cloud Console project.';
      }
      throw GoogleAuthException('Google Sign-In: $errStr');
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}

final googleAuthService = GoogleAuthService();
