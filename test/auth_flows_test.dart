import 'package:flutter_test/flutter_test.dart';
import 'package:local_skill_exchange/models/auth_models.dart';
import 'package:local_skill_exchange/core/config/env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Auth Models & Guest Mode Tests', () {
    test('User model properly marks guest accounts', () {
      final regularUser = User.fromJson({
        'id': 1,
        'email': 'developer@example.com',
        'name': 'Dev User',
      });
      expect(regularUser.isGuest, isFalse);

      final guestUser = User.fromJson({
        'id': 99,
        'email': 'guest_user@localskillexchange.internal',
        'name': 'Guest Explorer',
        'is_guest': true,
      });
      expect(guestUser.isGuest, isTrue);

      final guestByFlag = User.fromJson({
        'id': 100,
        'email': 'temporary@domain.com',
        'name': 'Temp User',
        'is_guest': true,
      });
      expect(guestByFlag.isGuest, isTrue);
    });

    test('AuthResponse handles guest responses correctly', () {
      final guestResponse = AuthResponse.fromJson({
        'access_token': 'dummy-jwt-guest-token',
        'token_type': 'bearer',
        'is_guest': true,
        'user': {
          'id': 99,
          'email': 'guest_user@localskillexchange.internal',
          'name': 'Guest Explorer',
        },
      });
      expect(guestResponse.isGuest, isTrue);
      expect(guestResponse.user.isGuest, isTrue);
      expect(guestResponse.accessToken, equals('dummy-jwt-guest-token'));
    });

    test('Env URL normalization and physical device configuration', () {
      // Physical device should default to LAN host, not 127.0.0.1
      expect(Env.defaultLanHost, equals('192.168.1.2'));
      expect(Env.defaultPort, equals(8000));
      expect(Env.fallbackPort, equals(8001));

      // Custom URL setting & normalization
      Env.setCustomApiBaseUrl('http://192.168.1.50:8000');
      expect(Env.apiBaseUrl, equals('http://192.168.1.50:8000/api/v1'));
      expect(Env.serverBaseUrl, equals('http://192.168.1.50:8000'));

      Env.setCustomApiBaseUrl('http://192.168.1.50:8000/api/v1/');
      expect(Env.apiBaseUrl, equals('http://192.168.1.50:8000/api/v1'));

      // Clear custom URL
      Env.setCustomApiBaseUrl(null);
    });
  });
}
