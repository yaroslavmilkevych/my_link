import '../../domain/entities/city.dart';
import '../../domain/entities/regional_weather.dart';
import 'hourly_forecast_model.dart';

class RegionalWeatherModel extends RegionalWeather {
  const RegionalWeatherModel({
    required super.city,
    required super.hourlyForecasts,
  });

  factory RegionalWeatherModel.fromJson({
    required City city,
    required Map<String, dynamic> json,
  }) {
    final hourly =
        json['hourly'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final times = List<String>.from(hourly['time'] as List? ?? const []);
    final temperatures = List<num>.from(
      hourly['temperature_2m'] as List? ?? const [],
    );
    final precipitationValues = List<num>.from(
      hourly['precipitation'] as List? ?? const [],
    );
    final precipitationProbabilities = List<num>.from(
      hourly['precipitation_probability'] as List? ?? const [],
    );
    final windSpeeds = List<num>.from(
      hourly['wind_speed_10m'] as List? ?? const [],
    );
    final windDirections = List<num>.from(
      hourly['wind_direction_10m'] as List? ?? const [],
    );

    final count = [
      times.length,
      temperatures.length,
      precipitationValues.length,
      precipitationProbabilities.length,
      windSpeeds.length,
      windDirections.length,
    ].reduce((value, element) => value < element ? value : element);

    final forecasts = List<HourlyForecastModel>.generate(count, (index) {
      return HourlyForecastModel.fromJson(
        time: times[index],
        temperature: temperatures[index].toDouble(),
        precipitation: precipitationValues[index].toDouble(),
        precipitationProbability: precipitationProbabilities[index].toDouble(),
        windSpeed: windSpeeds[index].toDouble(),
        windDirectionDegrees: windDirections[index].toDouble(),
      );
    });

    return RegionalWeatherModel(city: city, hourlyForecasts: forecasts);
  }
}
