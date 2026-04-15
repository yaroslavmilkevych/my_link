import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:poland_weather_app/src/core/constants/app_constants.dart';
import 'package:poland_weather_app/src/core/network/dio_provider.dart';
import 'package:poland_weather_app/src/core/services/location_service.dart';

import '../../data/repositories/weather_repository_impl.dart';
import '../../data/services/weather_api_service.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/weather_bundle.dart';
import '../../domain/repositories/weather_repository.dart';

final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  return WeatherApiService(ref.watch(dioProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepositoryImpl(ref.watch(weatherApiServiceProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final currentLocationProvider = FutureProvider<LatLng?>((ref) async {
  return ref.watch(locationServiceProvider).getCurrentLocation();
});

final selectedCityProvider = StateProvider<City>((ref) {
  return const City(
    name: AppConstants.defaultCityName,
    admin1: AppConstants.defaultRegion,
    country: AppConstants.defaultCountry,
    latitude: AppConstants.defaultLatitude,
    longitude: AppConstants.defaultLongitude,
  );
});

final selectedDayIndexProvider = StateProvider<int>((ref) => 0);
final selectedHourlyIndexProvider = StateProvider<int>((ref) => 0);

class WeatherController extends AsyncNotifier<WeatherBundle> {
  @override
  Future<WeatherBundle> build() async {
    ref.read(selectedDayIndexProvider.notifier).state = 0;
    ref.read(selectedHourlyIndexProvider.notifier).state = 0;
    final city = ref.watch(selectedCityProvider);
    return _fetchWeatherFor(city);
  }

  Future<void> refresh() async {
    ref.read(selectedDayIndexProvider.notifier).state = 0;
    ref.read(selectedHourlyIndexProvider.notifier).state = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final city = ref.read(selectedCityProvider);
      return _fetchWeatherFor(city);
    });
  }

  Future<void> changeCity(City city) async {
    ref.read(selectedCityProvider.notifier).state = city;
    ref.read(selectedDayIndexProvider.notifier).state = 0;
    ref.read(selectedHourlyIndexProvider.notifier).state = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchWeatherFor(city));
  }

  Future<WeatherBundle> _fetchWeatherFor(City city) {
    return ref
        .read(weatherRepositoryProvider)
        .fetchWeather(
          latitude: city.latitude,
          longitude: city.longitude,
          city: city,
        );
  }
}

final weatherControllerProvider =
    AsyncNotifierProvider<WeatherController, WeatherBundle>(
      WeatherController.new,
    );

final citySearchQueryProvider = StateProvider<String>((ref) => '');

final citySearchResultsProvider = FutureProvider<List<City>>((ref) async {
  final query = ref.watch(citySearchQueryProvider).trim();
  if (query.isEmpty) {
    return const [];
  }

  return ref.watch(weatherRepositoryProvider).searchCities(query);
});

String mapErrorMessage(Object error) {
  if (error is DioException) {
    final details = error.message?.trim();
    if (details != null && details.isNotEmpty) {
      return 'Unable to load weather data. $details';
    }
    return 'Unable to load weather data. Check your connection and try again.';
  }
  return 'Something went wrong while loading the forecast.';
}
