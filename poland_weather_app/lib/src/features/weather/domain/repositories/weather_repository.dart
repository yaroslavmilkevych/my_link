import '../entities/city.dart';
import '../entities/weather_bundle.dart';

abstract class WeatherRepository {
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required City city,
  });

  Future<List<City>> searchCities(String query);
}
