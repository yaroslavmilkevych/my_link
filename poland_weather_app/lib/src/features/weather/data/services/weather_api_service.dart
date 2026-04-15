import 'package:dio/dio.dart';

class WeatherApiService {
  const WeatherApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchForecast({
    required double latitude,
    required double longitude,
    required String timezone,
    required int forecastDays,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'forecast_days': forecastDays,
        'timezone': timezone,
        'current': [
          'temperature_2m',
          'relative_humidity_2m',
          'wind_speed_10m',
          'wind_direction_10m',
          'weather_code',
        ].join(','),
        'daily': [
          'temperature_2m_max',
          'temperature_2m_min',
          'relative_humidity_2m_mean',
          'wind_speed_10m_max',
          'wind_direction_10m_dominant',
          'weather_code',
        ].join(','),
        'hourly': [
          'temperature_2m',
          'precipitation',
          'precipitation_probability',
          'wind_speed_10m',
          'wind_direction_10m',
        ].join(','),
        'wind_speed_unit': 'kmh',
      },
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://geocoding-api.open-meteo.com/v1/search',
      queryParameters: {
        'name': query,
        'count': 12,
        'language': 'en',
        'format': 'json',
        'countryCode': 'PL',
      },
    );

    final results = response.data?['results'] as List<dynamic>?;
    if (results == null) {
      return const [];
    }

    return results.whereType<Map<String, dynamic>>().toList();
  }
}
