import '../../domain/entities/daily_forecast.dart';

class DailyForecastModel extends DailyForecast {
  const DailyForecastModel({
    required super.date,
    required super.maxTemperature,
    required super.minTemperature,
    required super.humidity,
    required super.windSpeed,
    required super.windDirectionDegrees,
    required super.weatherCode,
  });

  factory DailyForecastModel.fromJson({
    required String date,
    required double maxTemperature,
    required double minTemperature,
    required double humidity,
    required double windSpeed,
    required double windDirectionDegrees,
    required int weatherCode,
  }) {
    return DailyForecastModel(
      date: DateTime.parse(date),
      maxTemperature: maxTemperature,
      minTemperature: minTemperature,
      humidity: humidity,
      windSpeed: windSpeed,
      windDirectionDegrees: windDirectionDegrees,
      weatherCode: weatherCode,
    );
  }
}
