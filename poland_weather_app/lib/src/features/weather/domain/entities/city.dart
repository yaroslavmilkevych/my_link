class City {
  const City({
    required this.name,
    required this.admin1,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String admin1;
  final String country;
  final double latitude;
  final double longitude;

  String get fullLabel {
    if (admin1.isEmpty) {
      return '$name, $country';
    }
    return '$name, $admin1';
  }
}
