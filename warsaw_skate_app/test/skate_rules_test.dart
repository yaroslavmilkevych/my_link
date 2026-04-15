import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:warsaw_skate_app/src/domain/skate_rules.dart';
import 'package:warsaw_skate_app/src/models/road_segment.dart';
import 'package:warsaw_skate_app/src/models/route_option.dart';

void main() {
  group('SkateRules', () {
    test('classifies asphalt and cycleway correctly', () {
      expect(
        SkateRules.classifySurface(surface: 'asphalt'),
        RoadSurface.asphalt,
      );
      expect(
        SkateRules.classifySurface(surface: null),
        RoadSurface.unknown,
      );
      expect(
        SkateRules.classifyRoadKind('cycleway'),
        RoadKind.cycleway,
      );
      expect(
        SkateRules.hasReliableSurfaceTag(null),
        isFalse,
      );
    });

    test('marks roads with foot=no as restricted', () {
      const road = RoadSegment(
        id: 1,
        highway: 'service',
        roadKind: RoadKind.service,
        points: <LatLng>[LatLng(52.2, 21.0), LatLng(52.21, 21.01)],
        surfaceClass: RoadSurface.asphalt,
        hasExplicitSurface: true,
        isRestrictedByLaw: false,
        foot: 'no',
      );

      expect(SkateRules.isRestrictedByLaw(road), isTrue);
    });

    test('prefers comfort for best-surface scoring', () {
      final comfortFirst = SkateRules.routeScore(
        preference: RoutePreference.bestSurface,
        durationSeconds: 900,
        distanceMeters: 3200,
        qualityScore: 0.95,
        safetyScore: 0.75,
        restrictedShare: 0,
      );
      final roughButFast = SkateRules.routeScore(
        preference: RoutePreference.bestSurface,
        durationSeconds: 700,
        distanceMeters: 3200,
        qualityScore: 0.35,
        safetyScore: 0.5,
        restrictedShare: 0.1,
      );

      expect(comfortFirst, greaterThan(roughButFast));
    });
  });
}
