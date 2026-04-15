class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirectionDegrees,
    required this.weatherCode,
  });

  final double temperature;
  final double humidity;
  final double windSpeed;
  final double windDirectionDegrees;
  final int weatherCode;
}
