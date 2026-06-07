class DistrictModel {
  final int districtId;
  final int cityId;
  final String districtName;
  final String status;

  DistrictModel({
    required this.districtId,
    required this.cityId,
    required this.districtName,
    required this.status,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      districtId: json['district_id'] as int,
      cityId: json['city_id'] as int,
      districtName: json['district_name'] as String,
      status: json['status'] as String? ?? 'Active',
    );
  }
}
