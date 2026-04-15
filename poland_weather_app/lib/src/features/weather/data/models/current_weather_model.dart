import '../../domain/entities/current_weather.dart';

class CurrentWeatherModel extends CurrentWeather {
  const CurrentWeatherModel({
    required super.temperature,
    required super.humidity,
    required super.windSpeed,
    required super.windDirectionDegrees,
    required super.weatherCode,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    return CurrentWeatherModel(
      temperature: (json['temperature_2m'] as num?)?.toDouble() ?? 0,
      humidity: (json['relative_humidity_2m'] as num?)?.toDouble() ?? 0,
      windSpeed: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      windDirectionDegrees:
          (json['wind_direction_10m'] as num?)?.toDouble() ?? 0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
    );
  }
}
