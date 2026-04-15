class WindDirectionFormatter {
  const WindDirectionFormatter._();

  static const List<String> _directions = [
    'N',
    'NE',
    'E',
    'SE',
    'S',
    'SW',
    'W',
    'NW',
  ];

  static String fromDegrees(double degrees) {
    final normalized = ((degrees % 360) + 360) % 360;
    final index = ((normalized + 22.5) / 45).floor() % _directions.length;
    return _directions[index];
  }
}
