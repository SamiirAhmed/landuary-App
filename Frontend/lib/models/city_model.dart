class CityModel {
  final int cityId;
  final String cityName;
  final String status;

  CityModel({
    required this.cityId,
    required this.cityName,
    required this.status,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: json['city_id'] as int,
      cityName: json['city_name'] as String,
      status: json['status'] as String? ?? 'Active',
    );
  }
}
