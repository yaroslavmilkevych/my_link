import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum RoutePreference {
  bestSurface('Лучшее покрытие', Color(0xFF2E8B57)),
  fastest('Самый быстрый', Color(0xFFCC7A00)),
  safest('Самый безопасный', Color(0xFF1D70A2));

  const RoutePreference(this.label, this.color);

  final String label;
  final Color color;
}

class RouteOption {
  const RouteOption({
    required this.preference,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.qualityScore,
    required this.safetyScore,
    required this.restrictedShare,
  });

  final RoutePreference preference;
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final double qualityScore;
  final double safetyScore;
  final double restrictedShare;

  Color get color => preference.color;

  String get title => preference.label;

  double get distanceKm => distanceMeters / 1000;

  double get durationMinutes => durationSeconds / 60;

  String get summary {
    final comfort = (qualityScore * 100).round();
    final safety = (safetyScore * 100).round();
    return 'комфорт $comfort%, безопасность $safety%';
  }

  String get legalNote {
    final restricted = (restrictedShare * 100).round();
    if (restricted == 0) {
      return 'Юридических ограничений по найденным сегментам не обнаружено.';
    }
    return 'Около $restricted% маршрута попадает на участки, которые лучше объехать по польским правилам движения.';
  }
}
