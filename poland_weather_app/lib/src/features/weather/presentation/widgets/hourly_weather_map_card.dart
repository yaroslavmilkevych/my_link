import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:poland_weather_app/src/core/utils/wind_direction_formatter.dart';

import '../../domain/entities/city.dart';
import '../../domain/entities/hourly_forecast.dart';
import '../../domain/entities/regional_weather.dart';

class HourlyWeatherMapCard extends StatefulWidget {
  const HourlyWeatherMapCard({
    super.key,
    required this.selectedCity,
    required this.selectedForecast,
    required this.selectedTime,
    required this.regionalWeather,
    required this.userLocation,
  });

  final City selectedCity;
  final HourlyForecast selectedForecast;
  final DateTime selectedTime;
  final List<RegionalWeather> regionalWeather;
  final LatLng? userLocation;

  @override
  State<HourlyWeatherMapCard> createState() => _HourlyWeatherMapCardState();
}

class _HourlyWeatherMapCardState extends State<HourlyWeatherMapCard>
    with SingleTickerProviderStateMixin {
  static const LatLng _defaultCenter = LatLng(52.05, 19.35);
  static const double _defaultZoom = 6.1;
  static const double _focusedZoom = 8.8;

  late final AnimationController _animationController;
  late final MapController _mapController;
  double _zoom = _defaultZoom;
  bool _didCenterOnUser = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant HourlyWeatherMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_didCenterOnUser && widget.userLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnUser();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleRegionalWeather = widget.regionalWeather
        .where((entry) => entry.forecastForTime(widget.selectedTime) != null)
        .toList();
    final selectedRegional = visibleRegionalWeather
        .where(
          (entry) =>
              entry.city.name == widget.selectedCity.name &&
              entry.city.admin1 == widget.selectedCity.admin1,
        )
        .cast<RegionalWeather?>()
        .firstOrNull;
    final selectedForecast =
        selectedRegional?.forecastForTime(widget.selectedTime) ??
        widget.selectedForecast;
    final rainLabel = _buildRainMovementLabel(
      visibleRegionalWeather,
      widget.selectedTime,
    );

    if (!_didCenterOnUser && widget.userLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnUser();
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live wind field map',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'The whole area is animated. Wind lines flow in the direction of movement, and stronger wind appears longer, denser and darker.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF587086)),
            ),
            const SizedBox(height: 14),
            _SelectedHourSummary(
              city: widget.selectedCity,
              forecast: selectedForecast,
              rainLabel: rainLabel,
              selectedTime: widget.selectedTime,
              isUsingUserLocation: widget.userLocation != null,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 420,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, _) {
                        return FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                widget.userLocation ?? _defaultCenter,
                            initialZoom: widget.userLocation != null
                                ? _focusedZoom
                                : _defaultZoom,
                            interactionOptions: const InteractionOptions(
                              flags:
                                  InteractiveFlag.drag |
                                  InteractiveFlag.pinchZoom |
                                  InteractiveFlag.doubleTapZoom,
                            ),
                            onPositionChanged: (position, _) {
                              final zoom = position.zoom;
                              if (mounted) {
                                setState(() {
                                  _zoom = zoom;
                                });
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.poland_weather_app',
                            ),
                            MarkerLayer(
                              markers: _buildRainMarkers(
                                visibleRegionalWeather,
                                widget.selectedTime,
                              ),
                            ),
                            MarkerLayer(
                              markers: _buildWindArrowMarkers(
                                visibleRegionalWeather,
                                widget.selectedTime,
                                _animationController.value,
                              ),
                            ),
                            MarkerLayer(
                              markers: _buildWindSpeedMarkers(
                                visibleRegionalWeather,
                                widget.selectedTime,
                              ),
                            ),
                            if (widget.userLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: widget.userLocation!,
                                    width: 24,
                                    height: 24,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F6CBD),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _MapControls(
                        onZoomIn: _zoomIn,
                        onZoomOut: _zoomOut,
                        onLocate: _centerOnUser,
                        canLocate: widget.userLocation != null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _MapLegend(),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    final center = _mapController.camera.center;
    final nextZoom = (_zoom + 0.7).clamp(4.0, 13.0);
    _mapController.move(center, nextZoom);
    setState(() {
      _zoom = nextZoom;
    });
  }

  void _zoomOut() {
    final center = _mapController.camera.center;
    final nextZoom = (_zoom - 0.7).clamp(4.0, 13.0);
    _mapController.move(center, nextZoom);
    setState(() {
      _zoom = nextZoom;
    });
  }

  void _centerOnUser() {
    final location = widget.userLocation;
    if (location == null) {
      return;
    }

    _mapController.move(location, _focusedZoom);
    setState(() {
      _zoom = _focusedZoom;
      _didCenterOnUser = true;
    });
  }

  List<Marker> _buildRainMarkers(
    List<RegionalWeather> entries,
    DateTime selectedTime,
  ) {
    const latMin = 49.0;
    const latMax = 54.8;
    const lonMin = 14.0;
    const lonMax = 24.3;

    final markers = <Marker>[];

    for (var row = 0; row < 10; row++) {
      for (var column = 0; column < 14; column++) {
        final lat = latMin + ((latMax - latMin) / 9) * row;
        final lon = lonMin + ((lonMax - lonMin) / 13) * column;
        final rain = _interpolateRain(entries, selectedTime, lat, lon);
        if (rain == null || rain < 0.25) {
          continue;
        }

        final color = _rainStrengthColor(rain);
        final count = rain >= 2.2
            ? 3
            : rain >= 1
            ? 2
            : 1;

        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 40,
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                count,
                (index) => Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 2),
                  child: Icon(
                    Icons.water_drop_rounded,
                    size: 12 + (count * 2),
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<Marker> _buildWindArrowMarkers(
    List<RegionalWeather> entries,
    DateTime selectedTime,
    double phase,
  ) {
    const latMin = 49.0;
    const latMax = 54.8;
    const lonMin = 14.0;
    const lonMax = 24.3;

    final markers = <Marker>[];

    for (var row = 0; row < 22; row++) {
      for (var column = 0; column < 32; column++) {
        final lat = latMin + ((latMax - latMin) / 21) * row;
        final lon = lonMin + ((lonMax - lonMin) / 31) * column;
        final sample = _interpolateWind(entries, selectedTime, lat, lon);
        if (sample == null || sample.speed < 4) {
          continue;
        }

        final speedFactor = (sample.speed / 35).clamp(0.12, 1.0);
        final radians = sample.directionDegrees * math.pi / 180;
        final travel = ((phase % 1.0) - 0.5) * (0.18 + speedFactor * 0.18);
        final shiftedLat = lat + math.cos(radians) * travel;
        final shiftedLon = lon + math.sin(radians) * travel;

        markers.add(
          Marker(
            point: LatLng(shiftedLat, shiftedLon),
            width: 16,
            height: 16,
            child: Transform.rotate(
              angle: radians,
              child: Icon(
                Icons.arrow_right_alt_rounded,
                size: 9 + (speedFactor * 10),
                color: Colors.black.withValues(alpha: 0.86),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<Marker> _buildWindSpeedMarkers(
    List<RegionalWeather> entries,
    DateTime selectedTime,
  ) {
    const latMin = 49.0;
    const latMax = 54.8;
    const lonMin = 14.0;
    const lonMax = 24.3;

    final markers = <Marker>[];

    for (var row = 1; row < 14; row += 3) {
      for (var column = 1; column < 20; column += 4) {
        final lat = latMin + ((latMax - latMin) / 13) * row;
        final lon = lonMin + ((lonMax - lonMin) / 19) * column;
        final sample = _interpolateWind(entries, selectedTime, lat, lon);
        if (sample == null || sample.speed < 16) {
          continue;
        }

        markers.add(
          Marker(
            point: LatLng(lat - 0.08, lon + 0.08),
            width: 62,
            height: 22,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${sample.speed.toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  _InterpolatedWind? _interpolateWind(
    List<RegionalWeather> entries,
    DateTime selectedTime,
    double latitude,
    double longitude,
  ) {
    var totalWeight = 0.0;
    var x = 0.0;
    var y = 0.0;
    var weightedSpeed = 0.0;

    for (final entry in entries) {
      final forecast = entry.forecastForTime(selectedTime);
      if (forecast == null) {
        continue;
      }

      final dx = latitude - entry.city.latitude;
      final dy = longitude - entry.city.longitude;
      final distanceSquared = (dx * dx) + (dy * dy) + 0.16;
      final weight = 1 / distanceSquared;
      final flowDegrees = (forecast.windDirectionDegrees + 180) % 360;
      final radians = flowDegrees * math.pi / 180;

      x += math.cos(radians) * weight;
      y += math.sin(radians) * weight;
      weightedSpeed += forecast.windSpeed * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) {
      return null;
    }

    return _InterpolatedWind(
      speed: weightedSpeed / totalWeight,
      directionDegrees: (math.atan2(y, x) * 180 / math.pi + 360) % 360,
    );
  }

  double? _interpolateRain(
    List<RegionalWeather> entries,
    DateTime selectedTime,
    double latitude,
    double longitude,
  ) {
    var totalWeight = 0.0;
    var weightedRain = 0.0;

    for (final entry in entries) {
      final forecast = entry.forecastForTime(selectedTime);
      if (forecast == null) {
        continue;
      }

      final dx = latitude - entry.city.latitude;
      final dy = longitude - entry.city.longitude;
      final distanceSquared = (dx * dx) + (dy * dy) + 0.18;
      final weight = 1 / distanceSquared;

      weightedRain += forecast.precipitation * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) {
      return null;
    }

    return weightedRain / totalWeight;
  }

  String _buildRainMovementLabel(
    List<RegionalWeather> entries,
    DateTime selectedTime,
  ) {
    final rainyCities = <String>[];
    for (final entry in entries) {
      final forecast = entry.forecastForTime(selectedTime);
      if (forecast != null && forecast.precipitation > 0.2) {
        rainyCities.add(entry.city.name);
      }
    }

    if (rainyCities.isEmpty) {
      return 'This selected time looks mostly dry across the sampled Polish area.';
    }

    return 'Rain is forming near ${rainyCities.join(', ')}. Switch day or hour to watch how the rain zone moves.';
  }
}

class _SelectedHourSummary extends StatelessWidget {
  const _SelectedHourSummary({
    required this.city,
    required this.forecast,
    required this.rainLabel,
    required this.selectedTime,
    required this.isUsingUserLocation,
  });

  final City city;
  final HourlyForecast forecast;
  final String rainLabel;
  final DateTime selectedTime;
  final bool isUsingUserLocation;

  @override
  Widget build(BuildContext context) {
    final windDirection = WindDirectionFormatter.fromDegrees(
      forecast.windDirectionDegrees,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            city.fullLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${selectedTime.day.toString().padLeft(2, '0')}.${selectedTime.month.toString().padLeft(2, '0')}.${selectedTime.year} ${selectedTime.hour.toString().padLeft(2, '0')}:00',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5D7186)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text('Temp: ${forecast.temperature.toStringAsFixed(0)}°C'),
              Text('Wind: ${forecast.windSpeed.toStringAsFixed(0)} km/h'),
              Text('Direction: $windDirection'),
              Text('Rain: ${forecast.precipitation.toStringAsFixed(1)} mm'),
              if (isUsingUserLocation)
                const Text('Map centered on your position'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rainLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5D7186)),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocate,
    required this.canLocate,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocate;
  final bool canLocate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapControlButton(icon: Icons.add_rounded, onTap: onZoomIn),
        const SizedBox(height: 8),
        _MapControlButton(icon: Icons.remove_rounded, onTap: onZoomOut),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: Icons.my_location_rounded,
          onTap: canLocate ? onLocate : null,
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: onTap == null
                ? const Color(0xFF9AA9B7)
                : const Color(0xFF17324D),
          ),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: const [
        _LegendPill(label: 'Black arrows = wind', color: Colors.black),
        _LegendPill(label: 'Speed labels', color: Color(0xFF5A5A5A)),
        _LegendPill(label: 'Rain drops = rain zone', color: Color(0xFF59A5FF)),
        _LegendPill(label: 'Heavy rain', color: Color(0xFF1F6FEB)),
      ],
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

Color _rainStrengthColor(double precipitation) {
  if (precipitation >= 3) {
    return const Color(0xFF1F6FEB);
  }
  if (precipitation >= 1) {
    return const Color(0xFF59A5FF);
  }
  if (precipitation > 0.2) {
    return const Color(0xFF9DD3FF);
  }
  return const Color(0xFF9BD4A4);
}

class _InterpolatedWind {
  const _InterpolatedWind({
    required this.speed,
    required this.directionDegrees,
  });

  final double speed;
  final double directionDegrees;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
