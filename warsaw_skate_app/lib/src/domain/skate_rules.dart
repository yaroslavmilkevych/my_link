import 'package:flutter/material.dart';

import '../models/road_segment.dart';
import '../models/route_option.dart';

class RoadStyle {
  const RoadStyle({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.isSurfaceReliable,
  });

  final String label;
  final Color color;
  final Color borderColor;
  final bool isSurfaceReliable;
}

class SkateRules {
  static const List<String> _allowedForSkates = <String>[
    'cycleway',
    'footway',
    'path',
    'pedestrian',
    'living_street',
    'steps',
  ];

  static const List<String> _fastRoads = <String>[
    'motorway',
    'motorway_link',
    'trunk',
    'trunk_link',
    'primary',
    'primary_link',
  ];

  static const List<String> _peopleFirstRoads = <String>[
    'cycleway',
    'footway',
    'path',
    'pedestrian',
    'living_street',
  ];

  static RoadSurface classifySurface({
    String? surface,
  }) {
    switch (surface) {
      case 'asphalt':
      case 'concrete':
      case 'concrete:plates':
        return RoadSurface.asphalt;
      case 'paving_stones':
      case 'sett':
      case 'concrete:pavers':
        return RoadSurface.paving;
      case 'compacted':
      case 'fine_gravel':
      case 'gravel':
      case 'ground':
      case 'dirt':
        return RoadSurface.gravel;
      default:
        return RoadSurface.unknown;
    }
  }

  static bool hasReliableSurfaceTag(String? surface) {
    return classifySurface(surface: surface) != RoadSurface.unknown;
  }

  static RoadKind classifyRoadKind(String highway) {
    switch (highway) {
      case 'cycleway':
        return RoadKind.cycleway;
      case 'footway':
        return RoadKind.footway;
      case 'pedestrian':
        return RoadKind.pedestrian;
      case 'path':
        return RoadKind.path;
      case 'living_street':
        return RoadKind.livingStreet;
      case 'residential':
        return RoadKind.residential;
      case 'service':
        return RoadKind.service;
      case 'secondary':
      case 'secondary_link':
      case 'tertiary':
      case 'tertiary_link':
        return RoadKind.secondary;
      case 'primary':
      case 'primary_link':
      case 'trunk':
      case 'trunk_link':
      case 'motorway':
      case 'motorway_link':
        return RoadKind.primary;
      default:
        return RoadKind.other;
    }
  }

  static String roadKindLabel(RoadKind kind) {
    switch (kind) {
      case RoadKind.cycleway:
        return 'Велодорожка';
      case RoadKind.footway:
        return 'Тротуар';
      case RoadKind.pedestrian:
        return 'Пешеходная зона';
      case RoadKind.path:
        return 'Дорожка / path';
      case RoadKind.livingStreet:
        return 'Жилая улица';
      case RoadKind.residential:
        return 'Локальная улица';
      case RoadKind.service:
        return 'Сервисный проезд';
      case RoadKind.secondary:
        return 'Второстепенная дорога';
      case RoadKind.primary:
        return 'Магистральная дорога';
      case RoadKind.other:
        return 'Другой тип';
    }
  }

  static String surfaceLabel(RoadSurface surface) {
    switch (surface) {
      case RoadSurface.asphalt:
        return 'Асфальт';
      case RoadSurface.paving:
        return 'Плитка';
      case RoadSurface.gravel:
        return 'Гравий / грунт';
      case RoadSurface.unknown:
        return 'Неизвестно';
    }
  }

  static String reliabilityLabel(bool isReliable) {
    return isReliable ? 'подтверждено OSM' : 'покрытие не указано';
  }

  static bool isRestrictedByLaw(RoadSegment road) {
    if (road.foot == 'no' || road.access == 'no') {
      return true;
    }
    if (_allowedForSkates.contains(road.highway)) {
      return false;
    }
    if (_fastRoads.contains(road.highway)) {
      return true;
    }
    if (road.sidewalk != null && road.sidewalk != 'no') {
      return true;
    }
    if (!_peopleFirstRoads.contains(road.highway)) {
      return true;
    }
    return false;
  }

  static double routeScore({
    required RoutePreference preference,
    required double durationSeconds,
    required double distanceMeters,
    required double qualityScore,
    required double safetyScore,
    required double restrictedShare,
  }) {
    switch (preference) {
      case RoutePreference.bestSurface:
        return qualityScore * 4.8 + safetyScore * 2.6 - restrictedShare * 12 - durationSeconds / 1800;
      case RoutePreference.fastest:
        return 120 - durationSeconds / 60 - restrictedShare * 8 + qualityScore * 0.9;
      case RoutePreference.safest:
        return safetyScore * 5.4 + qualityScore * 1.3 - restrictedShare * 15 - distanceMeters / 3000;
    }
  }

  static double surfaceComfort(RoadSurface surface) {
    switch (surface) {
      case RoadSurface.asphalt:
        return 1.0;
      case RoadSurface.paving:
        return 0.56;
      case RoadSurface.gravel:
        return 0.14;
      case RoadSurface.unknown:
        return 0.4;
    }
  }

  static double roadSafety(RoadSegment road) {
    if (isRestrictedByLaw(road)) {
      return 0.05;
    }
    if (_peopleFirstRoads.contains(road.highway)) {
      return 0.98;
    }
    if (road.highway == 'service' || road.highway == 'residential') {
      return 0.7;
    }
    return 0.45;
  }

  static RoadStyle styleFor(RoadSegment road) {
    if (road.isRestrictedByLaw) {
      return RoadStyle(
        label: 'Избегать по закону',
        color: const Color(0xFFB42318),
        borderColor: const Color(0xFF6C0C16),
        isSurfaceReliable: road.hasExplicitSurface,
      );
    }

    final borderColor = switch (road.roadKind) {
      RoadKind.cycleway => const Color(0xFF125E95),
      RoadKind.footway || RoadKind.pedestrian || RoadKind.path => const Color(0xFF5D6B63),
      RoadKind.livingStreet || RoadKind.residential || RoadKind.service => const Color(0xFF8D6E63),
      RoadKind.secondary => const Color(0xFF8A4F08),
      RoadKind.primary => const Color(0xFF7A1F1F),
      RoadKind.other => const Color(0xFF6D7C75),
    };

    switch (road.surfaceClass) {
      case RoadSurface.asphalt:
        return RoadStyle(
          label: '${roadKindLabel(road.roadKind)} • Асфальт • ${reliabilityLabel(road.hasExplicitSurface)}',
          color: road.hasExplicitSurface
              ? const Color(0xFFE53935)
              : const Color(0xFFB0BEC5),
          borderColor: borderColor,
          isSurfaceReliable: road.hasExplicitSurface,
        );
      case RoadSurface.paving:
        return RoadStyle(
          label: '${roadKindLabel(road.roadKind)} • Плитка • ${reliabilityLabel(road.hasExplicitSurface)}',
          color: road.hasExplicitSurface
              ? const Color(0xFF4FC3F7)
              : const Color(0xFFB0BEC5),
          borderColor: borderColor,
          isSurfaceReliable: road.hasExplicitSurface,
        );
      case RoadSurface.gravel:
        return RoadStyle(
          label: '${roadKindLabel(road.roadKind)} • Гравий • ${reliabilityLabel(road.hasExplicitSurface)}',
          color: const Color(0xFF8B5E3C),
          borderColor: borderColor,
          isSurfaceReliable: road.hasExplicitSurface,
        );
      case RoadSurface.unknown:
        return RoadStyle(
          label: '${roadKindLabel(road.roadKind)} • Покрытие неизвестно',
          color: const Color(0xFF90A4AE),
          borderColor: borderColor,
          isSurfaceReliable: false,
        );
    }
  }
}
