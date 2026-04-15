class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.precipitation,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.windDirectionDegrees,
  });

  final DateTime time;
  final double temperature;
  final double precipitation;
  final double precipitationProbability;
  final double windSpeed;
  final double windDirectionDegrees;
}
