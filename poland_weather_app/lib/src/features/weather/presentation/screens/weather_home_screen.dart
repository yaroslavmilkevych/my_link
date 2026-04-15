import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/city.dart';
import '../../domain/entities/hourly_forecast.dart';
import '../providers/weather_providers.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/forecast_day_card.dart';
import '../widgets/hourly_timeline_selector.dart';
import '../widgets/hourly_weather_map_card.dart';
import '../widgets/search_city_bar.dart';
import '../widgets/state_views.dart';

class WeatherHomeScreen extends ConsumerWidget {
  const WeatherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherControllerProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE4F1FF), Color(0xFFF3F7FB), Color(0xFFF7FBFF)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(weatherControllerProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  'Poland Weather',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '7-day forecast focused on Warsaw and Mazowieckie, with city search across Poland.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4F6478),
                  ),
                ),
                const SizedBox(height: 20),
                SearchCityBar(
                  selectedCity: selectedCity,
                  onCitySelected: (city) => ref
                      .read(weatherControllerProvider.notifier)
                      .changeCity(city),
                ),
                const SizedBox(height: 20),
                weatherState.when(
                  loading: () => const LoadingStateView(),
                  error: (error, _) => ErrorStateView(
                    message: mapErrorMessage(error),
                    onRetry: () =>
                        ref.read(weatherControllerProvider.notifier).refresh(),
                  ),
                  data: (bundle) {
                    if (bundle.dailyForecasts.isEmpty) {
                      return const EmptyStateView(
                        title: 'No forecast available',
                        message:
                            'Weather API returned an empty 7-day forecast for this location.',
                      );
                    }

                    return _WeatherContent(city: selectedCity);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherContent extends ConsumerWidget {
  const _WeatherContent({required this.city});

  final City city;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(weatherControllerProvider).valueOrNull;
    final selectedDayIndex = ref.watch(selectedDayIndexProvider);
    final selectedHourlyIndex = ref.watch(selectedHourlyIndexProvider);
    final currentLocation = ref.watch(currentLocationProvider).valueOrNull;
    if (bundle == null) {
      return const SizedBox.shrink();
    }

    final dayOptions = _groupHourlyForecasts(bundle.hourlyForecasts);
    final safeDayIndex = dayOptions.isEmpty
        ? 0
        : selectedDayIndex.clamp(0, dayOptions.length - 1);
    final selectedDay = dayOptions.isEmpty
        ? HourlyDayOption(date: nullDate, label: '', hours: [])
        : dayOptions[safeDayIndex];
    final safeHourIndex = selectedDay.hours.isEmpty
        ? 0
        : selectedHourlyIndex.clamp(0, selectedDay.hours.length - 1);
    final selectedForecast = selectedDay.hours.isEmpty
        ? null
        : selectedDay.hours[safeHourIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentWeatherCard(
          cityLabel: city.fullLabel,
          currentWeather: bundle.currentWeather,
        ),
        const SizedBox(height: 22),
        HourlyTimelineSelector(
          days: dayOptions,
          selectedDayIndex: safeDayIndex,
          selectedHourIndex: safeHourIndex,
          onDaySelected: (index) {
            ref.read(selectedDayIndexProvider.notifier).state = index;
            ref.read(selectedHourlyIndexProvider.notifier).state = 0;
          },
          onHourSelected: (index) =>
              ref.read(selectedHourlyIndexProvider.notifier).state = index,
        ),
        const SizedBox(height: 12),
        if (selectedForecast != null)
          HourlyWeatherMapCard(
            selectedCity: city,
            selectedForecast: selectedForecast,
            selectedTime: selectedForecast.time,
            regionalWeather: bundle.regionalWeather,
            userLocation: currentLocation,
          ),
        const SizedBox(height: 22),
        Text(
          'Week at a glance',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...bundle.dailyForecasts.map(
          (forecast) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ForecastDayCard(forecast: forecast),
          ),
        ),
      ],
    );
  }

  List<HourlyDayOption> _groupHourlyForecasts(List<HourlyForecast> forecasts) {
    final buckets = <HourlyDayOption>[];

    for (final forecast in forecasts) {
      final index = buckets.indexWhere(
        (bucket) =>
            bucket.date.year == forecast.time.year &&
            bucket.date.month == forecast.time.month &&
            bucket.date.day == forecast.time.day,
      );

      if (index == -1) {
        buckets.add(
          HourlyDayOption(
            date: DateTime(
              forecast.time.year,
              forecast.time.month,
              forecast.time.day,
            ),
            label: buckets.isEmpty
                ? 'Today'
                : DateFormat('EEE d MMM').format(forecast.time),
            hours: [forecast],
          ),
        );
      } else {
        buckets[index].hours.add(forecast);
      }
    }

    return buckets.take(7).toList();
  }
}

final nullDate = DateTime(2000);
