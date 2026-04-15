class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirectionDegrees,
    required this.weatherCode,
  });

  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final double humidity;
  final double windSpeed;
  final double windDirectionDegrees;
  final int weatherCode;

  double get averageTemperature => (maxTemperature + minTemperature) / 2;
}
