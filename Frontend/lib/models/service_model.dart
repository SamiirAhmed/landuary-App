class ServiceModel {
  final int serviceId;
  final String serviceName;
  final String priceType;
  final double price;
  final String? description;
  final String status;

  ServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.priceType,
    required this.price,
    this.description,
    this.status = 'Active',
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['service_id'] as int,
      serviceName: json['service_name'] as String,
      priceType: json['price_type'] as String,
      price: double.parse(json['price'].toString()),
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'Active',
    );
  }
}
