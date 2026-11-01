import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/config/map_config.dart';

enum LocationStatus {
  initial,
  loading,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class UserLocationState {
  final LatLng? position;
  final LocationStatus status;
  final String? errorMessage;

  const UserLocationState({
    this.position,
    this.status = LocationStatus.initial,
    this.errorMessage,
  });

  bool get hasLocation => position != null;
  bool get isDenied =>
      status == LocationStatus.permissionDenied ||
      status == LocationStatus.permissionDeniedForever;

  UserLocationState copyWith({
    LatLng? position,
    LocationStatus? status,
    String? errorMessage,
  }) {
    return UserLocationState(
      position: position ?? this.position,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request GPS permission and fetch the current user position
  Future<UserLocationState> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled on the device
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const UserLocationState(
          status: LocationStatus.serviceDisabled,
          errorMessage: 'Device location services are disabled. Please enable GPS in settings.',
          position: MapConfig.defaultLocation,
        );
      }
    } catch (e) {
      debugPrint('Geolocator serviceEnabled check error: $e');
    }

    // Check location permission
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const UserLocationState(
            status: LocationStatus.permissionDenied,
            errorMessage: 'Location permission was denied. Tap to grant permission or use default location.',
            position: MapConfig.defaultLocation,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const UserLocationState(
          status: LocationStatus.permissionDeniedForever,
          errorMessage: 'Location permissions are permanently denied. You can enable them in system settings.',
          position: MapConfig.defaultLocation,
        );
      }

      // Location permission granted: fetch coordinates with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return UserLocationState(
        position: LatLng(position.latitude, position.longitude),
        status: LocationStatus.ready,
      );
    } catch (e) {
      debugPrint('Error getting GPS position: $e');
      return UserLocationState(
        position: MapConfig.defaultLocation,
        status: LocationStatus.error,
        errorMessage: 'Unable to acquire accurate GPS position. Using default location.',
      );
    }
  }

  /// Open device app settings for permanently denied permissions
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open device location service settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}

final locationService = LocationService();

final locationServiceProvider = Provider<LocationService>((ref) {
  return locationService;
});

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  final LocationService _service;

  UserLocationNotifier(this._service) : super(const UserLocationState(status: LocationStatus.initial)) {
    locateUser();
  }

  Future<void> locateUser() async {
    state = state.copyWith(status: LocationStatus.loading);
    final result = await _service.determinePosition();
    state = result;
  }

  void setCustomLocation(LatLng coords) {
    state = UserLocationState(
      position: coords,
      status: LocationStatus.ready,
    );
  }
}

final userLocationNotifierProvider =
    StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return UserLocationNotifier(service);
});
