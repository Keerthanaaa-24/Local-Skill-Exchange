import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../core/config/map_config.dart';

class GeocodingPlace {
  final String name;
  final String displayName;
  final LatLng coordinates;
  final String? city;
  final String? state;
  final String? country;

  const GeocodingPlace({
    required this.name,
    required this.displayName,
    required this.coordinates,
    this.city,
    this.state,
    this.country,
  });

  factory GeocodingPlace.fromPhoton(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coords = (geometry['coordinates'] as List<dynamic>?) ?? [0.0, 0.0];
    final props = (feature['properties'] as Map<String, dynamic>?) ?? {};

    final double lng = (coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0);
    final double lat = (coords.length > 1 ? (coords[1] as num).toDouble() : 0.0);

    final name = props['name']?.toString() ?? props['street']?.toString() ?? 'Location';
    final city = props['city']?.toString() ?? props['county']?.toString();
    final state = props['state']?.toString();
    final country = props['country']?.toString();

    final parts = [name, city, state, country].where((s) => s != null && s.isNotEmpty).toList();
    final displayName = parts.join(', ');

    return GeocodingPlace(
      name: name,
      displayName: displayName.isNotEmpty ? displayName : name,
      coordinates: LatLng(lat, lng),
      city: city,
      state: state,
      country: country,
    );
  }

  factory GeocodingPlace.fromNominatim(Map<String, dynamic> json) {
    final double lat = double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0;
    final double lng = double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0;
    final displayName = json['display_name']?.toString() ?? 'Location';
    final name = json['name']?.toString() ?? displayName.split(',').first.trim();

    final address = json['address'] as Map<String, dynamic>?;
    final city = address?['city']?.toString() ?? address?['town']?.toString();
    final state = address?['state']?.toString();
    final country = address?['country']?.toString();

    return GeocodingPlace(
      name: name,
      displayName: displayName,
      coordinates: LatLng(lat, lng),
      city: city,
      state: state,
      country: country,
    );
  }
}

class GeocodingService {
  final Dio _dio;

  GeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'User-Agent': 'LocalSkillExchange/1.0 (contact: support@localskillexchange.internal)',
                  'Accept': 'application/json',
                },
              ),
            );

  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Search places with query text using free Photon geocoding service (OSM data).
  /// Falls back to Nominatim if Photon is unavailable.
  Future<List<GeocodingPlace>> searchPlaces(
    String query, {
    int limit = 5,
    LatLng? proximityCenter,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Enforce 250ms spacing between requests to be polite to free providers
    final now = DateTime.now();
    final diff = now.difference(_lastRequestTime).inMilliseconds;
    if (diff < 250) {
      await Future.delayed(Duration(milliseconds: 250 - diff));
    }
    _lastRequestTime = DateTime.now();

    // 1. Try Photon (Primary free OSM search API)
    try {
      final queryParams = <String, dynamic>{
        'q': cleanQuery,
        'limit': limit,
      };
      if (proximityCenter != null) {
        queryParams['lat'] = proximityCenter.latitude;
        queryParams['lon'] = proximityCenter.longitude;
      }

      final response = await _dio.get(
        MapConfig.geocodingApiUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final features = (response.data['features'] as List<dynamic>?) ?? [];
        return features
            .map((f) => GeocodingPlace.fromPhoton(f as Map<String, dynamic>))
            .where((p) => p.coordinates.latitude != 0.0 || p.coordinates.longitude != 0.0)
            .toList();
      }
    } catch (e) {
      debugPrint('Photon search failed: $e, trying Nominatim fallback...');
    }

    // 2. Fallback to Nominatim (Observes OSM usage guidelines)
    try {
      final response = await _dio.get(
        '${MapConfig.nominatimApiUrl}/search',
        queryParameters: {
          'q': cleanQuery,
          'format': 'json',
          'limit': limit,
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List<dynamic>)
            .map((item) => GeocodingPlace.fromNominatim(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Nominatim search fallback error: $e');
    }

    return [];
  }

  /// Reverse geocode coordinates to a readable address string
  Future<String?> reverseGeocode(LatLng coordinates) async {
    try {
      final response = await _dio.get(
        '${MapConfig.nominatimApiUrl}/reverse',
        queryParameters: {
          'lat': coordinates.latitude,
          'lon': coordinates.longitude,
          'format': 'json',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return response.data['display_name']?.toString();
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return null;
  }
}

final geocodingServiceProvider = GeocodingService();
