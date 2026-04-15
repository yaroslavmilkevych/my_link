import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../domain/skate_rules.dart';
import '../models/road_segment.dart';

class OverpassService {
  static final List<Uri> _endpoints = <Uri>[
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://overpass.kumi.systems/api/interpreter'),
  ];

  Future<List<RoadSegment>> fetchRoads({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final expandedBounds = _expandBounds(
      south: south,
      west: west,
      north: north,
      east: east,
    );
    final query = '''
[out:json][timeout:40];
(
  way
    ["highway"~"cycleway|footway|pedestrian|path|living_street|residential|service|secondary|secondary_link|tertiary|tertiary_link|primary|primary_link"]
    (${expandedBounds.south.toStringAsFixed(5)},${expandedBounds.west.toStringAsFixed(5)},${expandedBounds.north.toStringAsFixed(5)},${expandedBounds.east.toStringAsFixed(5)});
);
out body;
>;
out skel qt;
''';

    http.Response? response;
    Object? lastError;

    for (final endpoint in _endpoints) {
      try {
        final candidate = await http.post(endpoint, body: query);
        if (candidate.statusCode == 200) {
          response = candidate;
          break;
        }
        lastError = 'Overpass вернул ${candidate.statusCode}';
      } catch (error) {
        lastError = error;
      }
    }

    if (response == null) {
      throw Exception(lastError ?? 'Не удалось получить ответ от Overpass');
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> elements = data['elements'] as List<dynamic>;
    final Map<int, LatLng> nodes = <int, LatLng>{};

    for (final dynamic element in elements) {
      final item = element as Map<String, dynamic>;
      if (item['type'] == 'node') {
        nodes[item['id'] as int] = LatLng(
          (item['lat'] as num).toDouble(),
          (item['lon'] as num).toDouble(),
        );
      }
    }

    final List<RoadSegment> roads = <RoadSegment>[];
    for (final dynamic element in elements) {
      final item = element as Map<String, dynamic>;
      if (item['type'] != 'way') {
        continue;
      }

      final tags = (item['tags'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final highway = tags['highway'] as String?;
      final refs = (item['nodes'] as List<dynamic>? ?? <dynamic>[])
          .map((nodeId) => nodes[nodeId as int])
          .whereType<LatLng>()
          .toList();

      if (highway == null || refs.length < 2) {
        continue;
      }

      final surfaceTag = tags['surface'] as String?;
      final draft = RoadSegment(
        id: item['id'] as int,
        highway: highway,
        points: refs,
        roadKind: SkateRules.classifyRoadKind(highway),
        surfaceClass: SkateRules.classifySurface(surface: surfaceTag),
        hasExplicitSurface: SkateRules.hasReliableSurfaceTag(surfaceTag),
        isRestrictedByLaw: false,
        surfaceTag: surfaceTag,
        foot: tags['foot'] as String?,
        access: tags['access'] as String?,
        sidewalk: tags['sidewalk'] as String?,
      );

      roads.add(
        RoadSegment(
          id: draft.id,
          highway: draft.highway,
          points: draft.points,
          roadKind: draft.roadKind,
          surfaceClass: draft.surfaceClass,
          hasExplicitSurface: draft.hasExplicitSurface,
          isRestrictedByLaw: SkateRules.isRestrictedByLaw(draft),
          surfaceTag: draft.surfaceTag,
          foot: draft.foot,
          access: draft.access,
          sidewalk: draft.sidewalk,
        ),
      );
    }

    return roads;
  }

  ({double south, double west, double north, double east}) _expandBounds({
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    const padding = 0.02;
    return (
      south: south - padding,
      west: west - padding,
      north: north + padding,
      east: east + padding,
    );
  }
}
