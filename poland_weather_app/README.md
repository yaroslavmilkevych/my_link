# Poland Weather App

Minimalist Flutter weather application for iOS and Android with a 7-day forecast focused on Poland, especially Warsaw and the Mazowieckie region.

## Features

- 7-day weather forecast
- Current weather card
- Interactive map of Poland with hourly wind and rain visualization
- City search limited to Poland
- Clean architecture with feature-based folders
- Riverpod state management
- Dio HTTP client
- JSON parsing from Open-Meteo API
- Loading, error, empty and success states
- Responsive mobile-first UI with modern forecast cards
- Hour selector to inspect forecast changes during the day

## Stack

- Flutter
- Dart
- Riverpod
- Dio
- Open-Meteo public API

## Project Structure

```text
lib/
  main.dart
  src/
    app.dart
    core/
      constants/
      network/
      theme/
      utils/
    features/
      weather/
        data/
          models/
          repositories/
          services/
        domain/
          entities/
          repositories/
        presentation/
          providers/
          screens/
          widgets/
test/
  wind_direction_formatter_test.dart
```

## API

This app uses the public Open-Meteo APIs:

- Forecast API: `https://api.open-meteo.com/v1/forecast`
- Geocoding API: `https://geocoding-api.open-meteo.com/v1/search`

No API key is required.

## Run

1. Install Flutter SDK.
2. Open the project:

```bash
cd poland_weather_app
```

3. Fetch dependencies:

```bash
flutter pub get
```

4. Run on a simulator or device:

```bash
flutter run
```

## Test

```bash
flutter test
```

## Notes

- Default forecast location: Warsaw, Poland
- Wind direction is converted from degrees to `N`, `NE`, `E`, `SE`, `S`, `SW`, `W`, `NW`
- Rain movement is represented as hourly forecast changes across multiple Polish cities on the map
- Units:
  - Temperature: `°C`
  - Humidity: `%`
  - Wind: `km/h`
