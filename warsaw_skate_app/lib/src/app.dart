import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'domain/skate_rules.dart';
import 'models/road_segment.dart';
import 'models/route_option.dart';
import 'services/location_service.dart';
import 'services/overpass_service.dart';
import 'services/routing_service.dart';

class WarsawSkateApp extends StatelessWidget {
  const WarsawSkateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF156F5C),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF2EFE7),
      fontFamily: 'SF Pro Display',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warsaw Skate',
      theme: theme,
      home: const SkateMapScreen(),
    );
  }
}

class SkateMapScreen extends StatefulWidget {
  const SkateMapScreen({super.key});

  @override
  State<SkateMapScreen> createState() => _SkateMapScreenState();
}

class _SkateMapScreenState extends State<SkateMapScreen> {
  static const LatLng _warsawCenter = LatLng(52.2297, 21.0122);
  static const Map<String, LatLng> _nearbyCities = <String, LatLng>{
    'Pruszkow': LatLng(52.1622, 20.8036),
    'Piaseczno': LatLng(52.0730, 21.0260),
    'Legionowo': LatLng(52.4015, 20.9266),
    'Marki': LatLng(52.3340, 21.1044),
    'Otwock': LatLng(52.1050, 21.2610),
    'Zabki': LatLng(52.2927, 21.1054),
  };

  final MapController _mapController = MapController();
  final OverpassService _overpassService = OverpassService();
  final RoutingService _routingService = RoutingService();
  final LocationService _locationService = const LocationService();

  final List<RoadSegment> _roads = <RoadSegment>[];
  final List<RouteOption> _routeOptions = <RouteOption>[];
  final List<Marker> _markers = <Marker>[];

  Timer? _loadDebounce;
  bool _loadingRoads = true;
  bool _routing = false;
  bool _showRestrictedByLaw = false;
  String? _statusText;
  String? _loadedBoundsKey;
  double _currentZoom = 11.5;
  LatLng? _start;
  LatLng? _end;
  LatLng? _currentLocation;
  final RoutePreference _selectedPreference = RoutePreference.bestSurface;
  Set<RoadSurface> _selectedSurfaces = RoadSurface.values.toSet();
  Set<RoadKind> _selectedRoadKinds = RoadKind.values.toSet();

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _statusText = 'Определяю стартовую область карты...';
    });

    LatLng? location;
    try {
      location = await _locationService.getCurrentLocation();
    } catch (_) {
      location = null;
    }

    setState(() {
      _currentLocation = location;
      _markers
        ..clear()
        ..addAll(_buildNearbyCityMarkers());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (location != null) {
        _mapController.move(location, 13);
      }
      unawaited(_loadRoadsForCurrentView(force: true));
    });
  }

  List<Marker> _buildNearbyCityMarkers() {
    return _nearbyCities.entries.map((entry) {
      return Marker(
        point: entry.value,
        width: 94,
        height: 36,
        child: _CityMarker(
          label: entry.key,
          onTap: () {
            setState(() {
              _end = entry.value;
            });
            unawaited(_rebuildRoute());
          },
        ),
      );
    }).toList();
  }

  Iterable<RoadSegment> get _matchingRoads {
    return _roads.where((road) {
      final surfaceMatch = _selectedSurfaces.contains(road.surfaceClass);
      final kindMatch = _selectedRoadKinds.contains(road.roadKind);
      return surfaceMatch && kindMatch;
    });
  }

  Iterable<RoadSegment> get _visibleRoads {
    return _matchingRoads.where((road) => !road.isRestrictedByLaw);
  }

  Iterable<RoadSegment> get _restrictedRoads {
    return _matchingRoads.where((road) => road.isRestrictedByLaw);
  }

  void _handleTap(TapPosition _, LatLng point) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = point;
        _end = null;
        _routeOptions.clear();
      } else {
        _end = point;
      }
    });

    if (_start != null && _end != null) {
      unawaited(_rebuildRoute());
    }
  }

  Future<void> _rebuildRoute() async {
    if (_start == null || _end == null) {
      return;
    }

    setState(() {
      _routing = true;
      _statusText = 'Подбираю маршруты для роликов...';
    });

    try {
      final options = await _routingService.fetchRoutes(
        start: _start!,
        end: _end!,
        roads: _roads,
      );

      setState(() {
        _routeOptions
          ..clear()
          ..addAll(options);
        _routing = false;
        _statusText = null;
      });
    } catch (error) {
      setState(() {
        _routing = false;
        _statusText = 'Маршрут не построился: $error';
      });
    }
  }

  @override
  void dispose() {
    _loadDebounce?.cancel();
    super.dispose();
  }

  void _handlePositionChanged(MapCamera camera, bool hasGesture) {
    _currentZoom = camera.zoom;
    _loadDebounce?.cancel();
    _loadDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }
      unawaited(_loadRoadsForCurrentView());
    });
  }

  Future<void> _loadRoadsForCurrentView({bool force = false}) async {
    final bounds = _mapController.camera.visibleBounds;
    final requestKey = _boundsKey(bounds);
    if (!force && requestKey == _loadedBoundsKey) {
      return;
    }

    setState(() {
      _loadingRoads = true;
      _statusText = 'Загружаю дороги для текущего участка карты...';
    });

    try {
      final roads = await _overpassService.fetchRoads(
        south: bounds.south,
        west: bounds.west,
        north: bounds.north,
        east: bounds.east,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loadedBoundsKey = requestKey;
        _roads
          ..clear()
          ..addAll(roads);
        _loadingRoads = false;
        _statusText = roads.isEmpty
            ? 'Для этой области дороги не найдены. Попробуй чуть отдалить карту.'
            : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingRoads = false;
        _statusText = 'Не удалось загрузить дороги для текущего участка: $error';
      });
    }
  }

  String _boundsKey(LatLngBounds bounds) {
    return [
      bounds.south.toStringAsFixed(2),
      bounds.west.toStringAsFixed(2),
      bounds.north.toStringAsFixed(2),
      bounds.east.toStringAsFixed(2),
    ].join(':');
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (_currentZoom + delta).clamp(3.0, 19.0);
    _currentZoom = nextZoom;
    _mapController.move(camera.center, nextZoom);
  }

  Future<void> _openFiltersSheet() async {
    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var surfaceDraft = _selectedSurfaces.toSet();
        var kindDraft = _selectedRoadKinds.toSet();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return _FilterSheet(
              selectedSurfaces: surfaceDraft,
              selectedRoadKinds: kindDraft,
              onSurfaceChanged: (surface, selected) {
                setModalState(() {
                  if (selected) {
                    surfaceDraft.add(surface);
                  } else if (surfaceDraft.length > 1) {
                    surfaceDraft.remove(surface);
                  }
                });
              },
              onRoadKindChanged: (kind, selected) {
                setModalState(() {
                  if (selected) {
                    kindDraft.add(kind);
                  } else if (kindDraft.length > 1) {
                    kindDraft.remove(kind);
                  }
                });
              },
              onReset: () {
                setModalState(() {
                  surfaceDraft = RoadSurface.values.toSet();
                  kindDraft = RoadKind.values.toSet();
                });
              },
              onApply: () {
                Navigator.of(context).pop(
                  _FilterSelection(
                    surfaces: surfaceDraft,
                    roadKinds: kindDraft,
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedSurfaces = result.surfaces;
      _selectedRoadKinds = result.roadKinds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldRenderRoads = _currentZoom >= 12.8;
    final visibleRoadsToRender = shouldRenderRoads
        ? _visibleRoads.take(700)
        : const <RoadSegment>[];
    final restrictedRoadsToRender = shouldRenderRoads
        ? _restrictedRoads.take(400)
        : const <RoadSegment>[];

    final visiblePolylines = visibleRoadsToRender.map((road) {
      final style = SkateRules.styleFor(road);
      return Polyline(
        points: road.points,
        strokeWidth: road.roadKind == RoadKind.cycleway ? 4.6 : 3.4,
        color: style.color.withValues(alpha: 0.82),
        borderColor: style.borderColor.withValues(
          alpha: road.roadKind == RoadKind.primary ? 0.62 : 0.42,
        ),
        borderStrokeWidth: road.roadKind == RoadKind.cycleway ? 1.8 : 0.9,
      );
    }).toList();

    final restrictedPolylines = restrictedRoadsToRender.map((road) {
      return Polyline(
        points: road.points,
        strokeWidth: 5,
        color: const Color(0xFFE11D48).withValues(alpha: 0.9),
        borderColor: const Color(0xFF7F1D1D),
        borderStrokeWidth: 1.4,
        pattern: const StrokePattern.dotted(),
      );
    }).toList();

    final routePolylines = _routeOptions.map((option) {
      final active = option.preference == _selectedPreference;
      return Polyline(
        points: option.points,
        strokeWidth: active ? 7 : 4,
        color: option.color.withValues(alpha: active ? 0.92 : 0.42),
      );
    }).toList();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox.expand(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _warsawCenter,
                      initialZoom: 11.5,
                      minZoom: 3,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onTap: _handleTap,
                      onPositionChanged: _handlePositionChanged,
                    ),
                    children: <Widget>[
                      TileLayer(
                        urlTemplate:
                            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.example.warsaw_skate_app',
                      ),
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
                        subdomains: const <String>['a', 'b', 'c', 'd'],
                        retinaMode: RetinaMode.isHighDensity(context),
                        userAgentPackageName: 'com.example.warsaw_skate_app',
                      ),
                      if (visiblePolylines.isNotEmpty)
                        PolylineLayer(polylines: visiblePolylines),
                      if (_showRestrictedByLaw && restrictedPolylines.isNotEmpty)
                        PolylineLayer(polylines: restrictedPolylines),
                      if (_routeOptions.isNotEmpty)
                        PolylineLayer(polylines: routePolylines),
                      MarkerLayer(
                        markers: <Marker>[
                          ..._markers,
                          if (_currentLocation != null)
                            Marker(
                              point: _currentLocation!,
                              width: 20,
                              height: 20,
                              child: const _PulseMarker(color: Color(0xFF0B6E4F)),
                            ),
                          if (_start != null)
                            Marker(
                              point: _start!,
                              width: 58,
                              height: 34,
                              child: const _PointBadge(label: 'A'),
                            ),
                          if (_end != null)
                            Marker(
                              point: _end!,
                              width: 58,
                              height: 34,
                              child: const _PointBadge(label: 'B'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 16,
                  child: SafeArea(
                    child: _MapActionButtons(
                      showRestrictedByLaw: _showRestrictedByLaw,
                      onZoomIn: () => _zoomBy(1),
                      onZoomOut: () => _zoomBy(-1),
                      onToggleRestricted: () {
                        setState(() {
                          _showRestrictedByLaw = !_showRestrictedByLaw;
                        });
                      },
                      onOpenFilters: _openFiltersSheet,
                    ),
                  ),
                ),
                if (_statusText != null || !shouldRenderRoads)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 86,
                    child: SafeArea(
                      child: _StatusBanner(
                        text: !shouldRenderRoads
                            ? 'Приблизь карту сильнее, чтобы увидеть разметку дорог и велодорожек.'
                            : _statusText!,
                        busy: shouldRenderRoads && (_loadingRoads || _routing),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.text,
    required this.busy,
  });

  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isError = text.startsWith('Не удалось') || text.startsWith('Маршрут не');

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isError
              ? const Color(0xFFFFF1F2).withValues(alpha: 0.96)
              : const Color(0xFFF8F6F0).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                Icon(
                  isError ? Icons.error_outline : Icons.info_outline,
                  color: isError ? const Color(0xFFBE123C) : const Color(0xFF173228),
                  size: 18,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isError ? const Color(0xFF9F1239) : const Color(0xFF173228),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapActionButtons extends StatelessWidget {
  const _MapActionButtons({
    required this.showRestrictedByLaw,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleRestricted,
    required this.onOpenFilters,
  });

  final bool showRestrictedByLaw;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleRestricted;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            _RoundMapButton(
              icon: Icons.add,
              tooltip: 'Приблизить карту',
              onPressed: onZoomIn,
            ),
            const SizedBox(height: 8),
            _RoundMapButton(
              icon: Icons.remove,
              tooltip: 'Отдалить карту',
              onPressed: onZoomOut,
            ),
            const SizedBox(height: 8),
            _RoundMapButton(
              icon: Icons.filter_alt_outlined,
              tooltip: 'Фильтры дорог',
              onPressed: onOpenFilters,
            ),
            const SizedBox(height: 8),
            _RoundMapButton(
              icon: showRestrictedByLaw ? Icons.gavel : Icons.gavel_outlined,
              tooltip: 'Показать, где нельзя ехать по закону',
              backgroundColor: showRestrictedByLaw
                  ? const Color(0xFFE11D48)
                  : const Color(0xFFF6E8EC),
              foregroundColor: showRestrictedByLaw
                  ? Colors.white
                  : const Color(0xFF9F1239),
              onPressed: onToggleRestricted,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: backgroundColor ?? const Color(0xFFEEF3F0),
            foregroundColor: foregroundColor ?? const Color(0xFF173228),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.selectedSurfaces,
    required this.selectedRoadKinds,
    required this.onSurfaceChanged,
    required this.onRoadKindChanged,
    required this.onReset,
    required this.onApply,
  });

  final Set<RoadSurface> selectedSurfaces;
  final Set<RoadKind> selectedRoadKinds;
  final void Function(RoadSurface surface, bool selected) onSurfaceChanged;
  final void Function(RoadKind kind, bool selected) onRoadKindChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 70),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F6F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Фильтры карты',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Сначала выбери покрытия, потом типы дорог. Неизвестное покрытие теперь не угадывается: оно означает, что в OSM нет точного тега surface.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E6A63),
                  ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Чеклист покрытий',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...RoadSurface.values.map((surface) {
                          return CheckboxListTile(
                            value: selectedSurfaces.contains(surface),
                            title: Text(SkateRules.surfaceLabel(surface)),
                            subtitle: Text(
                              switch (surface) {
                                RoadSurface.asphalt => 'Покрытие явно указано как asphalt / concrete',
                                RoadSurface.paving => 'Покрытие явно указано как paving_stones / sett / pavers',
                                RoadSurface.gravel => 'Покрытие явно указано как gravel / ground / dirt',
                                RoadSurface.unknown => 'У этого сегмента в OSM нет надёжного surface-тега',
                              },
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) =>
                                onSurfaceChanged(surface, value ?? false),
                          );
                        }),
                        const SizedBox(height: 12),
                        Text(
                          'Чеклист типов дорог',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...RoadKind.values.map((kind) {
                          return CheckboxListTile(
                            value: selectedRoadKinds.contains(kind),
                            title: Text(SkateRules.roadKindLabel(kind)),
                            subtitle: Text(
                              switch (kind) {
                                RoadKind.cycleway => 'Выделенные велодорожки',
                                RoadKind.footway => 'Тротуары',
                                RoadKind.pedestrian => 'Пешеходные зоны',
                                RoadKind.path => 'Парковые и смешанные дорожки',
                                RoadKind.livingStreet => 'Тихие жилые улицы',
                                RoadKind.residential => 'Обычные локальные улицы',
                                RoadKind.service => 'Сервисные проезды',
                                RoadKind.secondary => 'Второстепенные дороги',
                                RoadKind.primary => 'Более быстрые дороги и магистрали',
                                RoadKind.other => 'Все остальные highway-типы',
                              },
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) =>
                                onRoadKindChanged(kind, value ?? false),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReset,
                        child: const Text('Сбросить'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: onApply,
                        child: const Text('Применить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CityMarker extends StatelessWidget {
  const _CityMarker({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F4E8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFDFCCAA)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5C4424),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PulseMarker extends StatelessWidget {
  const _PulseMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
    );
  }
}

class _PointBadge extends StatelessWidget {
  const _PointBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF173228),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FilterSelection {
  const _FilterSelection({
    required this.surfaces,
    required this.roadKinds,
  });

  final Set<RoadSurface> surfaces;
  final Set<RoadKind> roadKinds;
}
