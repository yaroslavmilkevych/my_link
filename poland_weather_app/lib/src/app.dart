import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/weather/presentation/screens/weather_home_screen.dart';

class PolandWeatherApp extends StatelessWidget {
  const PolandWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poland Weather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WeatherHomeScreen(),
    );
  }
}
