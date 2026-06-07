import 'order_item_model.dart';

class OrderModel {
  final int orderId;
  final int customerId;
  final String? customerName;
  final String? customerPhone;
  final String pickupAddress;
  final String? pickupDate;
  final double totalAmount;
  final double? amountPaid;
  final double? balanceAmount;
  final String orderStatus;
  final String paymentStatus;
  final String? specialNotes;
  final String? createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.orderId,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.pickupAddress,
    this.pickupDate,
    required this.totalAmount,
    this.amountPaid,
    this.balanceAmount,
    required this.orderStatus,
    required this.paymentStatus,
    this.specialNotes,
    this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    return OrderModel(
      orderId: json['order_id'] as int,
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      pickupAddress: json['pickup_address'] as String,
      pickupDate: json['pickup_date']?.toString(),
      totalAmount: double.parse(json['total_amount'].toString()),
      amountPaid: _optionalDouble(json, [
        'amount_paid',
        'paid_amount',
        'paid_total',
        'total_paid',
      ]),
      balanceAmount: _optionalDouble(json, [
        'balance',
        'balance_amount',
        'amount_due',
        'remaining_balance',
      ]),
      orderStatus: json['order_status'] as String,
      paymentStatus: json['payment_status'] as String,
      specialNotes: json['special_notes'] as String?,
      createdAt: json['created_at']?.toString(),
      items: rawItems
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  double get balance {
    if (balanceAmount != null) return balanceAmount! < 0 ? 0 : balanceAmount!;
    if (amountPaid != null) {
      final remaining = totalAmount - amountPaid!;
      return remaining < 0 ? 0 : remaining;
    }
    return paymentStatus.toLowerCase() == 'paid' ? 0 : totalAmount;
  }

  static double? _optionalDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }
}
