import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import '../../models/city_model.dart';
import '../../models/cloth_type_model.dart';
import '../../models/district_model.dart';
import '../../models/order_model.dart';
import '../../models/service_model.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  final TokenStorage _tokenStorage = TokenStorage();

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = {'Content-Type': 'application/json'};

    if (authenticated) {
      final token = await _tokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _decode(http.Response response) {
    final body =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic>
          ? body['message']?.toString() ?? 'Request failed'
          : 'Request failed';
      throw ApiException(message);
    }

    return body;
  }

  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    final response = await http.post(
      _uri(ApiConstants.login),
      headers: await _headers(),
      body: jsonEncode({'login': login, 'password': password}),
    );

    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword({
    required String newPassword,
  }) async {
    final response = await http.post(
      _uri('/auth/change-password'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({
        'newPassword': newPassword,
      }),
    );
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerCustomer(
      Map<String, dynamic> data) async {
    final response = await http.post(
      _uri(ApiConstants.registerCustomer),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerStaff(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri('/staff/register'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );

    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyForgotPassword(String login) async {
    final response = await http.post(
      _uri(ApiConstants.forgotPasswordVerify),
      headers: await _headers(),
      body: jsonEncode({'login': login}),
    );

    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetForgotPassword({
    required String resetToken,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      _uri(ApiConstants.forgotPasswordReset),
      headers: await _headers(),
      body: jsonEncode({
        'reset_token': resetToken,
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    return _decode(response) as Map<String, dynamic>;
  }

  Future<List<CityModel>> getCities() async {
    final response =
        await http.get(_uri(ApiConstants.cities), headers: await _headers());
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['cities'] as List<dynamic>? ??
        body['data'] as List<dynamic>? ??
        [];
    return data
        .map((item) => CityModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DistrictModel>> getDistricts(int cityId) async {
    final response = await http.get(_uri(ApiConstants.districts(cityId)),
        headers: await _headers());
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['districts'] as List<dynamic>? ??
        body['data'] as List<dynamic>? ??
        [];
    return data
        .map((item) => DistrictModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ServiceModel>> getServices() async {
    final response =
        await http.get(_uri(ApiConstants.services), headers: await _headers());
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['services'] as List<dynamic>? ??
        body['data'] as List<dynamic>? ??
        [];
    return data
        .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ClothTypeModel>> getClothTypes() async {
    final response = await http.get(_uri(ApiConstants.clothTypes),
        headers: await _headers());
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['clothTypes'] as List<dynamic>? ??
        body['cloth_types'] as List<dynamic>? ??
        body['data'] as List<dynamic>? ??
        [];
    return data
        .map((item) => ClothTypeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri(ApiConstants.createOrder),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    final body = _decode(response) as Map<String, dynamic>;
    return OrderModel.fromJson(body['order'] as Map<String, dynamic>);
  }

  Future<List<OrderModel>> getCustomerOrders(int customerId) async {
    final response = await http.get(
      _uri(ApiConstants.customerOrders(customerId)),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['orders'] as List<dynamic>? ?? [];
    return data
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> getOrderDetails(int orderId) async {
    final response = await http.get(
      _uri(ApiConstants.orderDetails(orderId)),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    return OrderModel.fromJson(body['order'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> makePayment(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri(ApiConstants.makePayment),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    return _decode(response) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(int orderId) async {
    final response = await http.get(
      _uri(ApiConstants.paymentHistory(orderId)),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['payments'] as List<dynamic>? ?? [];
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(ApiConstants.updateOrderStatus),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStaffDashboard() async {
    final response = await http.get(
      _uri(ApiConstants.staffDashboard),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    return body['dashboard'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getStaffOrders() async {
    final response = await http.get(
      _uri(ApiConstants.staffOrders),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['orders'] as List<dynamic>? ?? [];
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getStaffCustomerBalances() async {
    final response = await http.get(
      _uri(ApiConstants.staffCustomerBalances),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['customers'] as List<dynamic>? ?? [];
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      _uri(ApiConstants.adminDashboard),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    return body['dashboard'] as Map<String, dynamic>;
  }

  Future<void> addService(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri(ApiConstants.adminServices),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  Future<List<ServiceModel>> getAdminServices() async {
    final response = await http.get(
      _uri(ApiConstants.adminServices),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['services'] as List<dynamic>? ?? [];
    return data
        .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateService(Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(ApiConstants.adminServices),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  Future<void> deleteService(int serviceId) async {
    final response = await http.delete(
      _uri(ApiConstants.adminServices),
      headers: await _headers(authenticated: true),
      body: jsonEncode({'service_id': serviceId}),
    );
    _decode(response);
  }

  Future<List<Map<String, dynamic>>> getStaffList() async {
    final response = await http.get(
      _uri(ApiConstants.staffList),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['staff'] as List<dynamic>? ?? [];
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<void> updateStaffStatus(Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(ApiConstants.staffStatus),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  Future<void> updateStaff(Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(ApiConstants.staffUpdate),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  Future<void> deleteStaff(int staffId) async {
    final response = await http.delete(
      _uri(ApiConstants.staffDelete),
      headers: await _headers(authenticated: true),
      body: jsonEncode({'staff_id': staffId}),
    );
    _decode(response);
  }

  Future<Map<String, dynamic>> getReports() async {
    final response = await http.get(
      _uri(ApiConstants.adminReports),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    return body['reports'] as Map<String, dynamic>;
  }

  Future<void> addExpense(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri(ApiConstants.adminExpenses),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final response = await http.get(
      _uri(ApiConstants.adminExpenses),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['expenses'] as List<dynamic>? ?? [];
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getDeliveryOrders() async {
    final response = await http.get(
      _uri(ApiConstants.deliveryOrders),
      headers: await _headers(authenticated: true),
    );
    final body = _decode(response) as Map<String, dynamic>;
    final data = body['orders'] as List<dynamic>? ?? [];
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<void> markPickedUp(Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(ApiConstants.deliveryPickedUp),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  Future<void> markDelivered(Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(ApiConstants.deliveryDelivered),
      headers: await _headers(authenticated: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }
}
