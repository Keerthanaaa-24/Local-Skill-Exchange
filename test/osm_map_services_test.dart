import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:local_skill_exchange/core/config/map_config.dart';
import 'package:local_skill_exchange/services/geocoding_service.dart';
import 'package:local_skill_exchange/services/routing_service.dart';
import 'package:local_skill_exchange/services/location_service.dart';

void main() {
  group('MapConfig & OSM Environment Tests', () {
    test('Default tile URL points to standard OpenStreetMap tiles', () {
      expect(MapConfig.tileUrlTemplate, contains('tile.openstreetmap.org'));
      expect(MapConfig.osmAttribution, contains('OpenStreetMap contributors'));
    });

    test('Custom tile URL overrides default template at runtime', () {
      const customUrl = 'https://custom-tiles.example.org/{z}/{x}/{y}.png';
      MapConfig.setCustomTileUrl(customUrl);
      expect(MapConfig.tileUrlTemplate, equals(customUrl));

      // Reset back
      MapConfig.setCustomTileUrl('');
      expect(MapConfig.tileUrlTemplate, contains('tile.openstreetmap.org'));
    });

    test('Default coordinates fallback is valid Bangalore Tech Hub', () {
      expect(MapConfig.defaultLocation.latitude, closeTo(12.9716, 0.001));
      expect(MapConfig.defaultLocation.longitude, closeTo(77.5946, 0.001));
    });

    test('User-Agent package name is defined and non-empty', () {
      expect(MapConfig.userAgentPackageName, isNotEmpty);
    });
  });

  group('Geocoding Place Parser Tests', () {
    test('Parses Photon GeoJSON feature correctly', () {
      final mockFeature = {
        'geometry': {
          'coordinates': [77.5946, 12.9716],
          'type': 'Point',
        },
        'properties': {
          'name': 'Koramangala 4th Block',
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'country': 'India',
        },
      };

      final place = GeocodingPlace.fromPhoton(mockFeature);
      expect(place.name, equals('Koramangala 4th Block'));
      expect(place.coordinates.latitude, closeTo(12.9716, 0.0001));
      expect(place.coordinates.longitude, closeTo(77.5946, 0.0001));
      expect(place.city, equals('Bengaluru'));
      expect(place.displayName, contains('Koramangala 4th Block, Bengaluru, Karnataka, India'));
    });

    test('Parses Nominatim JSON response correctly', () {
      final mockNominatim = {
        'lat': '12.9352',
        'lon': '77.6245',
        'display_name': 'Koramangala, Bengaluru South, Karnataka, 560034, India',
        'name': 'Koramangala',
        'address': {
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'country': 'India',
        },
      };

      final place = GeocodingPlace.fromNominatim(mockNominatim);
      expect(place.name, equals('Koramangala'));
      expect(place.coordinates.latitude, closeTo(12.9352, 0.0001));
      expect(place.coordinates.longitude, closeTo(77.6245, 0.0001));
      expect(place.country, equals('India'));
    });
  });

  group('UserLocationState & Permissions Tests', () {
    test('UserLocationState properly identifies denied and missing states', () {
      const deniedState = UserLocationState(
        status: LocationStatus.permissionDenied,
        errorMessage: 'Permission denied by user',
      );

      expect(deniedState.isDenied, isTrue);
      expect(deniedState.hasLocation, isFalse);

      const readyState = UserLocationState(
        position: LatLng(12.9716, 77.5946),
        status: LocationStatus.ready,
      );

      expect(readyState.isDenied, isFalse);
      expect(readyState.hasLocation, isTrue);
      expect(readyState.position!.latitude, closeTo(12.9716, 0.0001));
    });

    test('UserLocationState copyWith preserves or replaces fields correctly', () {
      const initial = UserLocationState(
        status: LocationStatus.loading,
      );
      final updated = initial.copyWith(
        position: const LatLng(13.0827, 80.2707),
        status: LocationStatus.ready,
      );

      expect(updated.status, equals(LocationStatus.ready));
      expect(updated.position!.latitude, closeTo(13.0827, 0.0001));
    });
  });

  group('Routing Results & Calculations Tests', () {
    test('RouteResult carries point coordinates and metadata', () {
      final points = [
        const LatLng(12.9716, 77.5946),
        const LatLng(12.9750, 77.6000),
      ];

      final result = RouteResult(
        points: points,
        distanceKm: 2.4,
        durationMinutes: 8,
        isFallback: false,
      );

      expect(result.points.length, equals(2));
      expect(result.distanceKm, equals(2.4));
      expect(result.durationMinutes, equals(8));
      expect(result.isFallback, isFalse);
    });
  });
}
