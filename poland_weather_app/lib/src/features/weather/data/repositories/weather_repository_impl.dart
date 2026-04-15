import 'package:poland_weather_app/src/core/constants/app_constants.dart';

import '../../domain/entities/city.dart';
import '../../domain/entities/weather_bundle.dart';
import '../../domain/repositories/weather_repository.dart';
import '../models/city_model.dart';
import '../models/weather_response_model.dart';
import '../poland_map_cities.dart';
import '../services/weather_api_service.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  const WeatherRepositoryImpl(this._apiService);

  final WeatherApiService _apiService;

  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required City city,
  }) async {
    final regionalCities = _buildRegionalCities(city);
    final mainResponse = await _apiService.fetchForecast(
      latitude: latitude,
      longitude: longitude,
      timezone: AppConstants.timezone,
      forecastDays: AppConstants.forecastDays,
    );
    final regionalResponses = <MapEntry<City, Map<String, dynamic>>>[];

    for (final regionalCity in regionalCities) {
      try {
        final response = await _apiService.fetchForecast(
          latitude: regionalCity.latitude,
          longitude: regionalCity.longitude,
          timezone: AppConstants.timezone,
          forecastDays: AppConstants.forecastDays,
        );
        regionalResponses.add(MapEntry(regionalCity, response));
      } catch (_) {
        // Keep the main forecast available even if a regional map point fails.
      }
    }

    return WeatherResponseModel.fromJson(
      city: city,
      json: mainResponse,
      regionalResponses: regionalResponses,
    );
  }

  @override
  Future<List<City>> searchCities(String query) async {
    if (query.trim().isEmpty) {
      return const [];
    }

    final response = await _apiService.searchCities(query.trim());
    return response.map(CityModel.fromJson).toList();
  }

  List<City> _buildRegionalCities(City selectedCity) {
    final combined = [...PolandMapCities.cities];
    final alreadyIncluded = combined.any(
      (city) =>
          city.name.toLowerCase() == selectedCity.name.toLowerCase() &&
          city.admin1.toLowerCase() == selectedCity.admin1.toLowerCase(),
    );
    if (!alreadyIncluded) {
      combined.add(selectedCity);
    }
    return combined;
  }
}
