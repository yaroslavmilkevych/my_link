import 'package:latlong2/latlong.dart';

enum RoadKind {
  cycleway,
  footway,
  pedestrian,
  path,
  livingStreet,
  residential,
  service,
  secondary,
  primary,
  other,
}

enum RoadSurface {
  asphalt,
  paving,
  gravel,
  unknown,
}

class RoadSegment {
  const RoadSegment({
    required this.id,
    required this.highway,
    required this.points,
    required this.roadKind,
    required this.surfaceClass,
    required this.hasExplicitSurface,
    required this.isRestrictedByLaw,
    this.surfaceTag,
    this.foot,
    this.access,
    this.sidewalk,
  });

  final int id;
  final String highway;
  final List<LatLng> points;
  final RoadKind roadKind;
  final RoadSurface surfaceClass;
  final bool hasExplicitSurface;
  final bool isRestrictedByLaw;
  final String? surfaceTag;
  final String? foot;
  final String? access;
  final String? sidewalk;
}
