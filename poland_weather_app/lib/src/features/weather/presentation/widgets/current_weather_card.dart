import 'package:flutter/material.dart';
import 'package:poland_weather_app/src/core/utils/wind_direction_formatter.dart';

import '../../domain/entities/current_weather.dart';
import 'weather_metric_chip.dart';

class CurrentWeatherCard extends StatelessWidget {
  const CurrentWeatherCard({
    super.key,
    required this.cityLabel,
    required this.currentWeather,
  });

  final String cityLabel;
  final CurrentWeather currentWeather;

  @override
  Widget build(BuildContext context) {
    final direction = WindDirectionFormatter.fromDegrees(
      currentWeather.windDirectionDegrees,
    );

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F6CBD), Color(0xFF4AA3A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current weather',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cityLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${currentWeather.temperature.toStringAsFixed(1)}°C',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                WeatherMetricChip(
                  icon: Icons.water_drop_rounded,
                  label: 'Humidity',
                  value: '${currentWeather.humidity.toStringAsFixed(0)}%',
                  dark: true,
                ),
                WeatherMetricChip(
                  icon: Icons.air_rounded,
                  label: 'Wind',
                  value: '${currentWeather.windSpeed.toStringAsFixed(0)} km/h',
                  dark: true,
                ),
                WeatherMetricChip(
                  icon: Icons.explore_rounded,
                  label: 'Direction',
                  value: direction,
                  dark: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
