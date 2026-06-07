class ClothTypeModel {
  final int clothTypeId;
  final String clothName;
  final String status;

  ClothTypeModel({
    required this.clothTypeId,
    required this.clothName,
    required this.status,
  });

  factory ClothTypeModel.fromJson(Map<String, dynamic> json) {
    return ClothTypeModel(
      clothTypeId: json['cloth_type_id'] as int,
      clothName: json['cloth_name'] as String,
      status: json['status'] as String? ?? 'Active',
    );
  }
}
