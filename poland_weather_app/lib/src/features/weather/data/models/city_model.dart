import '../../domain/entities/city.dart';

class CityModel extends City {
  const CityModel({
    required super.name,
    required super.admin1,
    required super.country,
    required super.latitude,
    required super.longitude,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      name: json['name'] as String? ?? '',
      admin1: json['admin1'] as String? ?? '',
      country: json['country'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
