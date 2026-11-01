import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../core/config/map_config.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final bool isFallback;
  final String? errorMessage;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.isFallback = false,
    this.errorMessage,
  });
}

class RoutingService {
  final Dio _dio;

  RoutingService({Dio? dio})
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

  DateTime _lastRouteRequest = DateTime.fromMillisecondsSinceEpoch(0);

  /// Calculate a driving/travel route between start and destination using OSRM demo server.
  /// Observes demo-server rate limits with spacing and timeout handling.
  /// If the demo server is unreachable or times out, returns a straight-line fallback.
  Future<RouteResult> getRoute(LatLng start, LatLng destination) async {
    // Respect public demo server: rate-limit requests to 1 per 500ms
    final now = DateTime.now();
    final elapsed = now.difference(_lastRouteRequest).inMilliseconds;
    if (elapsed < 500) {
      await Future.delayed(Duration(milliseconds: 500 - elapsed));
    }
    _lastRouteRequest = DateTime.now();

    final url =
        '${MapConfig.osrmApiUrl}/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final code = data['code'];
        final routes = data['routes'] as List<dynamic>?;

        if (code == 'Ok' && routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coords = (geometry?['coordinates'] as List<dynamic>?) ?? [];

          final points = coords.map((c) {
            final list = c as List<dynamic>;
            return LatLng((list[1] as num).toDouble(), (list[0] as num).toDouble());
          }).toList();

          final double meters = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final double seconds = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

          return RouteResult(
            points: points,
            distanceKm: (meters / 1000.0),
            durationMinutes: (seconds / 60.0).round(),
            isFallback: false,
          );
        }
      }
    } catch (e) {
      debugPrint('OSRM routing demo server unavailable or timed out: $e');
    }

    // Fallback: Calculate approximate direct distance and straight-line points
    const Distance distanceCalculator = Distance();
    final double meterDist = distanceCalculator.as(
      LengthUnit.Meter,
      start,
      destination,
    );

    return RouteResult(
      points: [start, destination],
      distanceKm: meterDist / 1000.0,
      durationMinutes: ((meterDist / 1000.0) / 30.0 * 60).round(), // approx 30km/h
      isFallback: true,
      errorMessage: 'Public routing service unavailable. Showing direct path.',
    );
  }
}

final routingServiceProvider = RoutingService();
