import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poland_weather_app/src/core/utils/wind_direction_formatter.dart';

import '../../domain/entities/daily_forecast.dart';
import 'weather_metric_chip.dart';

class ForecastDayCard extends StatelessWidget {
  const ForecastDayCard({super.key, required this.forecast});

  final DailyForecast forecast;

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('EEEE').format(forecast.date);
    final dateLabel = DateFormat('d MMM').format(forecast.date);
    final direction = WindDirectionFormatter.fromDegrees(
      forecast.windDirectionDegrees,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7C8C),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${forecast.averageTemperature.toStringAsFixed(0)}°C',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F6CBD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Min ${forecast.minTemperature.toStringAsFixed(0)}°C • Max ${forecast.maxTemperature.toStringAsFixed(0)}°C',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4F6478)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                WeatherMetricChip(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '${forecast.humidity.toStringAsFixed(0)}%',
                ),
                WeatherMetricChip(
                  icon: Icons.air_rounded,
                  label: 'Wind',
                  value: '${forecast.windSpeed.toStringAsFixed(0)} km/h',
                ),
                WeatherMetricChip(
                  icon: Icons.navigation_outlined,
                  label: 'Direction',
                  value: direction,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
