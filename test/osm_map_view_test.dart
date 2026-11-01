import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:local_skill_exchange/widgets/osm_map_view.dart';
import 'package:local_skill_exchange/services/location_service.dart';

void main() {
  testWidgets('OsmMapView renders OSM tile layer, attribution, and markers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final markers = [
      OsmMapMarkerItem(
        id: 'mentor_1',
        position: const LatLng(12.9716, 77.5946),
        title: 'Alice Johnson',
        subtitle: 'Flutter & Python Mentor • 4.9★',
        rating: 4.9,
      ),
      OsmMapMarkerItem(
        id: 'mentor_2',
        position: const LatLng(12.9750, 77.6000),
        title: 'Bob Smith',
        subtitle: 'Digital Marketing Expert • 4.7★',
        rating: 4.7,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userLocationNotifierProvider.overrideWith(
            (ref) => _MockUserLocationNotifier(
              const UserLocationState(
                position: LatLng(12.9716, 77.5946),
                status: LocationStatus.ready,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: OsmMapView(
              initialCenter: const LatLng(12.9716, 77.5946),
              markers: markers,
              showControls: true,
              showUserLocation: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify OSM attribution is visible
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

    // Verify map controls (Zoom in, Zoom out, My Location)
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('My Location'), findsOneWidget);

    // Tap marker
    final markerIcons = find.byIcon(Icons.person_pin_circle_rounded);
    expect(markerIcons, findsWidgets);

    await tester.tap(markerIcons.first);
    await tester.pumpAndSettle();

    // Verify tapped marker info card displays mentor details
    expect(find.text('Alice Johnson'), findsOneWidget);
    expect(find.text('Flutter & Python Mentor • 4.9★'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
  });

  testWidgets('OsmMapView displays permission denied banner gracefully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userLocationNotifierProvider.overrideWith(
            (ref) => _MockUserLocationNotifier(
              const UserLocationState(
                status: LocationStatus.permissionDenied,
                errorMessage: 'Location permission was denied',
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OsmMapView(
              initialCenter: LatLng(12.9716, 77.5946),
              markers: [],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify permission denied warning banner is displayed non-blockingly
    expect(find.text('Location access denied. Showing default area.'), findsOneWidget);
    expect(find.text('Enable'), findsOneWidget);
  });
}

class _MockUserLocationNotifier extends UserLocationNotifier {
  final UserLocationState _initialState;

  _MockUserLocationNotifier(this._initialState) : super(locationService) {
    state = _initialState;
  }

  @override
  Future<void> locateUser() async {
    // No-op for mock
  }
}
