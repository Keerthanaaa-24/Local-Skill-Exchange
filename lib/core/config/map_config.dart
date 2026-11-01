import 'package:latlong2/latlong.dart';

/// Configuration for OpenStreetMap, Geocoding, and Routing services.
/// All URLs and providers can be configured via environment flags (--dart-define)
/// or updated dynamically at runtime without rebuilding.
class MapConfig {
  /// Default center coordinates (Bangalore tech hub default)
  static const LatLng defaultLocation = LatLng(12.9716, 77.5946);
  static const double defaultZoom = 13.0;
  static const double defaultMaxZoom = 18.5;
  static const double defaultMinZoom = 3.0;

  /// OpenStreetMap Tile URL template
  /// Respects OSM tile usage policy: https://operations.osmfoundation.org/policies/tiles/
  static const String _defaultOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static String _customOsmTileUrl = '';

  static String get tileUrlTemplate {
    if (_customOsmTileUrl.isNotEmpty) return _customOsmTileUrl;
    const envUrl = String.fromEnvironment('OSM_TILE_URL', defaultValue: '');
    return envUrl.isNotEmpty ? envUrl : _defaultOsmTileUrl;
  }

  static void setCustomTileUrl(String url) {
    _customOsmTileUrl = url.trim();
  }

  /// User-Agent Package identifier required by OpenStreetMap Tile Servers
  static const String userAgentPackageName = String.fromEnvironment(
    'OSM_USER_AGENT',
    defaultValue: 'com.example.local_skill_exchange',
  );

  /// Attribution required by OpenStreetMap license (ODbL)
  static const String osmAttribution = '© OpenStreetMap contributors';

  /// Free Geocoding endpoints
  /// 1. Photon (powered by OpenStreetMap / Komoot) - fast, generous query policy for apps
  static const String _defaultPhotonUrl = 'https://photon.komoot.io/api';
  /// 2. Nominatim fallback - strict 1 req/sec policy
  static const String _defaultNominatimUrl = 'https://nominatim.openstreetmap.org';

  static const String geocodingApiUrl = String.fromEnvironment(
    'GEOCODING_API_URL',
    defaultValue: _defaultPhotonUrl,
  );

  static const String nominatimApiUrl = String.fromEnvironment(
    'NOMINATIM_API_URL',
    defaultValue: _defaultNominatimUrl,
  );

  /// Free OSRM (Open Source Routing Machine) public demo endpoint
  /// Note: Demo server has rate limits and is not guaranteed for high-volume production.
  static const String osrmApiUrl = String.fromEnvironment(
    'OSRM_API_URL',
    defaultValue: 'https://router.project-osrm.org',
  );
}
