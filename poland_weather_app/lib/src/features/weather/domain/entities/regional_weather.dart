import 'city.dart';
import 'hourly_forecast.dart';

class RegionalWeather {
  const RegionalWeather({required this.city, required this.hourlyForecasts});

  final City city;
  final List<HourlyForecast> hourlyForecasts;

  HourlyForecast? forecastAt(int index) {
    if (index < 0 || index >= hourlyForecasts.length) {
      return null;
    }
    return hourlyForecasts[index];
  }

  HourlyForecast? forecastForTime(DateTime selectedTime) {
    for (final forecast in hourlyForecasts) {
      if (forecast.time.year == selectedTime.year &&
          forecast.time.month == selectedTime.month &&
          forecast.time.day == selectedTime.day &&
          forecast.time.hour == selectedTime.hour) {
        return forecast;
      }
    }
    return null;
  }
}
