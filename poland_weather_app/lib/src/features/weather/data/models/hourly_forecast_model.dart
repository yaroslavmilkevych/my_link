import '../../domain/entities/hourly_forecast.dart';

class HourlyForecastModel extends HourlyForecast {
  const HourlyForecastModel({
    required super.time,
    required super.temperature,
    required super.precipitation,
    required super.precipitationProbability,
    required super.windSpeed,
    required super.windDirectionDegrees,
  });

  factory HourlyForecastModel.fromJson({
    required String time,
    required double temperature,
    required double precipitation,
    required double precipitationProbability,
    required double windSpeed,
    required double windDirectionDegrees,
  }) {
    return HourlyForecastModel(
      time: DateTime.parse(time),
      temperature: temperature,
      precipitation: precipitation,
      precipitationProbability: precipitationProbability,
      windSpeed: windSpeed,
      windDirectionDegrees: windDirectionDegrees,
    );
  }
}
