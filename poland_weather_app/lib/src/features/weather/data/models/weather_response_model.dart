import '../../domain/entities/city.dart';
import '../../domain/entities/weather_bundle.dart';
import 'current_weather_model.dart';
import 'daily_forecast_model.dart';
import 'hourly_forecast_model.dart';
import 'regional_weather_model.dart';

class WeatherResponseModel extends WeatherBundle {
  const WeatherResponseModel({
    required super.city,
    required super.currentWeather,
    required super.dailyForecasts,
    required super.hourlyForecasts,
    required super.regionalWeather,
  });

  factory WeatherResponseModel.fromJson({
    required City city,
    required Map<String, dynamic> json,
    required List<MapEntry<City, Map<String, dynamic>>> regionalResponses,
  }) {
    final current = CurrentWeatherModel.fromJson(
      json['current'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );

    final daily = json['daily'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final dates = List<String>.from(daily['time'] as List? ?? const []);
    final maxTemperatures = List<num>.from(
      daily['temperature_2m_max'] as List? ?? const [],
    );
    final minTemperatures = List<num>.from(
      daily['temperature_2m_min'] as List? ?? const [],
    );
    final humidities = List<num>.from(
      daily['relative_humidity_2m_mean'] as List? ?? const [],
    );
    final windSpeeds = List<num>.from(
      daily['wind_speed_10m_max'] as List? ?? const [],
    );
    final windDirections = List<num>.from(
      daily['wind_direction_10m_dominant'] as List? ?? const [],
    );
    final weatherCodes = List<num>.from(
      daily['weather_code'] as List? ?? const [],
    );
    final hourly =
        json['hourly'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final hourlyTimes = List<String>.from(hourly['time'] as List? ?? const []);
    final hourlyTemperatures = List<num>.from(
      hourly['temperature_2m'] as List? ?? const [],
    );
    final hourlyPrecipitation = List<num>.from(
      hourly['precipitation'] as List? ?? const [],
    );
    final hourlyPrecipitationProbability = List<num>.from(
      hourly['precipitation_probability'] as List? ?? const [],
    );
    final hourlyWindSpeeds = List<num>.from(
      hourly['wind_speed_10m'] as List? ?? const [],
    );
    final hourlyWindDirections = List<num>.from(
      hourly['wind_direction_10m'] as List? ?? const [],
    );

    final itemCount = [
      dates.length,
      maxTemperatures.length,
      minTemperatures.length,
      humidities.length,
      windSpeeds.length,
      windDirections.length,
      weatherCodes.length,
    ].reduce((value, element) => value < element ? value : element);
    final hourlyCount = [
      hourlyTimes.length,
      hourlyTemperatures.length,
      hourlyPrecipitation.length,
      hourlyPrecipitationProbability.length,
      hourlyWindSpeeds.length,
      hourlyWindDirections.length,
    ].reduce((value, element) => value < element ? value : element);

    final forecasts = List<DailyForecastModel>.generate(itemCount, (index) {
      return DailyForecastModel.fromJson(
        date: dates[index],
        maxTemperature: maxTemperatures[index].toDouble(),
        minTemperature: minTemperatures[index].toDouble(),
        humidity: humidities[index].toDouble(),
        windSpeed: windSpeeds[index].toDouble(),
        windDirectionDegrees: windDirections[index].toDouble(),
        weatherCode: weatherCodes[index].toInt(),
      );
    });
    final hourlyForecasts = List<HourlyForecastModel>.generate(hourlyCount, (
      index,
    ) {
      return HourlyForecastModel.fromJson(
        time: hourlyTimes[index],
        temperature: hourlyTemperatures[index].toDouble(),
        precipitation: hourlyPrecipitation[index].toDouble(),
        precipitationProbability: hourlyPrecipitationProbability[index]
            .toDouble(),
        windSpeed: hourlyWindSpeeds[index].toDouble(),
        windDirectionDegrees: hourlyWindDirections[index].toDouble(),
      );
    });
    final regionalWeather = regionalResponses
        .map(
          (entry) =>
              RegionalWeatherModel.fromJson(city: entry.key, json: entry.value),
        )
        .toList();

    return WeatherResponseModel(
      city: city,
      currentWeather: current,
      dailyForecasts: forecasts,
      hourlyForecasts: hourlyForecasts,
      regionalWeather: regionalWeather,
    );
  }
}
