class OrderItemModel {
  final int? orderItemId;
  final int serviceId;
  final String serviceName;
  final int clothTypeId;
  final String clothName;
  final int? quantity;
  final double? weight;
  final double unitPrice;
  final double subtotal;
  final String? notes;

  OrderItemModel({
    this.orderItemId,
    required this.serviceId,
    required this.serviceName,
    required this.clothTypeId,
    required this.clothName,
    this.quantity,
    this.weight,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      orderItemId: json['order_item_id'] as int?,
      serviceId: json['service_id'] as int,
      serviceName: json['service_name'] as String,
      clothTypeId: json['cloth_type_id'] as int,
      clothName: json['cloth_name'] as String,
      quantity: json['quantity'] as int?,
      weight: json['weight'] == null
          ? null
          : double.parse(json['weight'].toString()),
      unitPrice: double.parse(json['unit_price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'service_id': serviceId,
      'cloth_type_id': clothTypeId,
      'quantity': quantity,
      'weight': weight,
      'notes': notes,
    };
  }
}
