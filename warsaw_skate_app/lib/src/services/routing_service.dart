import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../domain/skate_rules.dart';
import '../models/road_segment.dart';
import '../models/route_option.dart';

class RoutingService {
  static final Uri _baseUri = Uri.parse('https://router.project-osrm.org');
  static final Distance _distance = const Distance();

  Future<List<RouteOption>> fetchRoutes({
    required LatLng start,
    required LatLng end,
    required List<RoadSegment> roads,
  }) async {
    final coordinates = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    final uri = _baseUri.replace(
      path: '/route/v1/foot/$coordinates',
      queryParameters: <String, String>{
        'alternatives': 'true',
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('OSRM вернул ${response.statusCode}');
    }

    final Map<String, dynamic> payload = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> routes = (payload['routes'] as List<dynamic>? ?? <dynamic>[]);
    if (routes.isEmpty) {
      throw Exception('Маршруты не найдены.');
    }

    final List<_RouteMetrics> metrics = routes.map((dynamic rawRoute) {
      final route = rawRoute as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinatesList = geometry['coordinates'] as List<dynamic>;
      final points = coordinatesList.map((dynamic pair) {
        final values = pair as List<dynamic>;
        return LatLng((values[1] as num).toDouble(), (values[0] as num).toDouble());
      }).toList();

      return _evaluateRoute(
        points: points,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
        roads: roads,
      );
    }).toList();

    final List<RouteOption> options = <RouteOption>[];
    for (final preference in RoutePreference.values) {
      final best = metrics.reduce((current, next) {
        final currentScore = SkateRules.routeScore(
          preference: preference,
          durationSeconds: current.durationSeconds,
          distanceMeters: current.distanceMeters,
          qualityScore: current.qualityScore,
          safetyScore: current.safetyScore,
          restrictedShare: current.restrictedShare,
        );
        final nextScore = SkateRules.routeScore(
          preference: preference,
          durationSeconds: next.durationSeconds,
          distanceMeters: next.distanceMeters,
          qualityScore: next.qualityScore,
          safetyScore: next.safetyScore,
          restrictedShare: next.restrictedShare,
        );
        return nextScore > currentScore ? next : current;
      });

      options.add(
        RouteOption(
          preference: preference,
          points: best.points,
          distanceMeters: best.distanceMeters,
          durationSeconds: best.durationSeconds,
          qualityScore: best.qualityScore,
          safetyScore: best.safetyScore,
          restrictedShare: best.restrictedShare,
        ),
      );
    }

    return options;
  }

  _RouteMetrics _evaluateRoute({
    required List<LatLng> points,
    required double distanceMeters,
    required double durationSeconds,
    required List<RoadSegment> roads,
  }) {
    if (points.isEmpty || roads.isEmpty) {
      return _RouteMetrics(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        qualityScore: 0.5,
        safetyScore: 0.5,
        restrictedShare: 0,
      );
    }

    double quality = 0;
    double safety = 0;
    int restrictedHits = 0;

    for (final point in points) {
      final road = _closestRoad(point, roads);
      quality += SkateRules.surfaceComfort(road.surfaceClass);
      safety += SkateRules.roadSafety(road);
      if (road.isRestrictedByLaw) {
        restrictedHits += 1;
      }
    }

    final count = points.length.toDouble();
    return _RouteMetrics(
      points: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      qualityScore: quality / count,
      safetyScore: safety / count,
      restrictedShare: restrictedHits / count,
    );
  }

  RoadSegment _closestRoad(LatLng point, List<RoadSegment> roads) {
    RoadSegment? bestRoad;
    double bestDistance = double.infinity;

    for (final road in roads) {
      for (final roadPoint in road.points) {
        final meters = _distance.as(LengthUnit.Meter, point, roadPoint);
        if (meters < bestDistance) {
          bestDistance = meters;
          bestRoad = road;
        }
      }
    }

    return bestRoad ?? roads.first;
  }
}

class _RouteMetrics {
  const _RouteMetrics({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.qualityScore,
    required this.safetyScore,
    required this.restrictedShare,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final double qualityScore;
  final double safetyScore;
  final double restrictedShare;
}
