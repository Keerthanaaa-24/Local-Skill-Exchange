import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/config/map_config.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';

class OsmMapMarkerItem {
  final String id;
  final LatLng position;
  final String title;
  final String subtitle;
  final double? rating;
  final dynamic payload;
  final VoidCallback? onTap;

  const OsmMapMarkerItem({
    required this.id,
    required this.position,
    required this.title,
    required this.subtitle,
    this.rating,
    this.payload,
    this.onTap,
  });
}

class OsmMapView extends ConsumerStatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;
  final List<OsmMapMarkerItem> markers;
  final bool showUserLocation;
  final bool showControls;
  final bool showRouteToSelected;
  final OsmMapMarkerItem? selectedMarker;
  final ValueChanged<OsmMapMarkerItem>? onMarkerSelected;
  final VoidCallback? onClearSelection;
  final Widget? emptyStateWidget;

  const OsmMapView({
    super.key,
    this.initialCenter,
    this.initialZoom = 13.0,
    this.markers = const [],
    this.showUserLocation = true,
    this.showControls = true,
    this.showRouteToSelected = true,
    this.selectedMarker,
    this.onMarkerSelected,
    this.onClearSelection,
    this.emptyStateWidget,
  });

  @override
  ConsumerState<OsmMapView> createState() => _OsmMapViewState();
}

class _OsmMapViewState extends ConsumerState<OsmMapView> {
  late final MapController _mapController;
  OsmMapMarkerItem? _activeMarker;
  RouteResult? _activeRoute;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _activeMarker = widget.selectedMarker;
  }

  @override
  void didUpdateWidget(covariant OsmMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMarker != oldWidget.selectedMarker) {
      _activeMarker = widget.selectedMarker;
      if (_activeMarker != null) {
        _onMarkerTapped(_activeMarker!);
      } else {
        setState(() {
          _activeRoute = null;
        });
      }
    }
  }

  void _onMarkerTapped(OsmMapMarkerItem marker) {
    setState(() {
      _activeMarker = marker;
    });

    widget.onMarkerSelected?.call(marker);
    marker.onTap?.call();

    // Center on the tapped marker
    _mapController.move(marker.position, 14.5);

    // Compute route if user location is available and enabled
    if (widget.showRouteToSelected) {
      final userLoc = ref.read(userLocationNotifierProvider).position;
      if (userLoc != null) {
        _fetchRoute(userLoc, marker.position);
      }
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng dest) async {
    setState(() {
      _isLoadingRoute = true;
    });
    try {
      final route = await routingServiceProvider.getRoute(start, dest);
      if (mounted) {
        setState(() {
          _activeRoute = route;
          _isLoadingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _recenterOnUser() async {
    final locState = ref.read(userLocationNotifierProvider);
    if (locState.position != null) {
      _mapController.move(locState.position!, 14.0);
    } else {
      await ref.read(userLocationNotifierProvider.notifier).locateUser();
      final updated = ref.read(userLocationNotifierProvider);
      if (updated.position != null && mounted) {
        _mapController.move(updated.position!, 14.0);
      } else if (mounted) {
        _showPermissionSnackbar(updated);
      }
    }
  }

  void _showPermissionSnackbar(UserLocationState state) {
    final msg = state.errorMessage ?? 'Unable to acquire GPS location.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        action: state.status == LocationStatus.permissionDeniedForever
            ? SnackBarAction(
                label: 'Settings',
                onPressed: () => locationService.openAppSettings(),
              )
            : SnackBarAction(
                label: 'Retry',
                onPressed: () => ref.read(userLocationNotifierProvider.notifier).locateUser(),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userLocState = ref.watch(userLocationNotifierProvider);
    final LatLng centerPoint = widget.initialCenter ??
        userLocState.position ??
        (widget.markers.isNotEmpty ? widget.markers.first.position : MapConfig.defaultLocation);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: widget.initialZoom,
            minZoom: MapConfig.defaultMinZoom,
            maxZoom: MapConfig.defaultMaxZoom,
            onTap: (tapPosition, point) {
              if (_activeMarker != null) {
                setState(() {
                  _activeMarker = null;
                  _activeRoute = null;
                });
                widget.onClearSelection?.call();
              }
            },
          ),
          children: [
            // Standard OpenStreetMap Tiles
            TileLayer(
              urlTemplate: MapConfig.tileUrlTemplate,
              userAgentPackageName: MapConfig.userAgentPackageName,
              maxZoom: 19,
            ),

            // OSRM Route Polyline Layer
            if (_activeRoute != null && _activeRoute!.points.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _activeRoute!.points,
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                    strokeWidth: 4.5,
                  ),
                ],
              ),

            // Marker Layer
            MarkerLayer(
              markers: [
                // User Location GPS Marker
                if (widget.showUserLocation && userLocState.position != null)
                  Marker(
                    point: userLocState.position!,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Skill Mentor Markers
                ...widget.markers.map((m) {
                  final isSelected = _activeMarker?.id == m.id;
                  return Marker(
                    point: m.position,
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 48 : 40,
                    child: GestureDetector(
                      onTap: () => _onMarkerTapped(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected ? theme.colorScheme.primary : Colors.black45)
                                  .withValues(alpha: 0.35),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: isSelected ? 28 : 22,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),

            // Free OSM License Attribution Widget
            SimpleAttributionWidget(
              source: const Text(
                MapConfig.osmAttribution,
                style: TextStyle(fontSize: 10, color: Colors.black87),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.75),
              alignment: Alignment.bottomLeft,
            ),
          ],
        ),

        // Permission / Location Notice Banner
        if (userLocState.isDenied)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.location_off_rounded, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location access denied. Showing default area.',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          ref.read(userLocationNotifierProvider.notifier).locateUser(),
                      child: const Text('Enable', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Controls: Zoom in, Zoom out, My Location
        if (widget.showControls)
          Positioned(
            right: 12,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom in',
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom out',
                  onPressed: _zoomOut,
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'My Location',
                  onPressed: _recenterOnUser,
                  color: userLocState.hasLocation ? theme.colorScheme.primary : null,
                ),
              ],
            ),
          ),

        // Selected Mentor Info Callout Sheet / Card
        if (_activeMarker != null)
          Positioned(
            left: 12,
            right: 60,
            bottom: 12,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _activeMarker!.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_activeMarker!.rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  _activeMarker!.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              _activeMarker = null;
                              _activeRoute = null;
                            });
                            widget.onClearSelection?.call();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeMarker!.subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_activeRoute != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.directions_car_rounded,
                              size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '~${_activeRoute!.distanceKm.toStringAsFixed(1)} km (${_activeRoute!.durationMinutes} min drive)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (_activeRoute!.isFallback)
                            const Text(' (approx)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ] else if (_isLoadingRoute) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text('Calculating route...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        // Empty state overlay if no markers exist
        if (widget.markers.isEmpty && widget.emptyStateWidget != null)
          Positioned.fill(
            child: widget.emptyStateWidget!,
          ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color ?? Colors.grey.shade800),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
