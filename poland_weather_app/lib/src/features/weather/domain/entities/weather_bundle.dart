import 'city.dart';
import 'current_weather.dart';
import 'daily_forecast.dart';
import 'hourly_forecast.dart';
import 'regional_weather.dart';

class WeatherBundle {
  const WeatherBundle({
    required this.city,
    required this.currentWeather,
    required this.dailyForecasts,
    required this.hourlyForecasts,
    required this.regionalWeather,
  });

  final City city;
  final CurrentWeather currentWeather;
  final List<DailyForecast> dailyForecasts;
  final List<HourlyForecast> hourlyForecasts;
  final List<RegionalWeather> regionalWeather;
}
