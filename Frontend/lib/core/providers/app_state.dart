import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../storage/token_storage.dart';

class AppState extends ChangeNotifier {
  final ApiService apiService = ApiService();
  final TokenStorage tokenStorage = TokenStorage();

  bool isLoading = false;
  String? token;
  Map<String, dynamic>? user;

  int? get customerId => user?['customer_id'] as int?;
  String get customerName => user?['full_name']?.toString() ?? 'Customer';

  Future<bool> loadSession() async {
    token = await tokenStorage.getToken();
    user = await tokenStorage.getUser();
    notifyListeners();
    return token != null;
  }

  Future<void> login(String login, String password) async {
    _setLoading(true);
    try {
      final response = await apiService.login(login: login, password: password);
      token = response['token'] as String;
      user = response['user'] as Map<String, dynamic>;
      await tokenStorage.saveToken(token!);
      await tokenStorage.saveUser(user!);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await tokenStorage.clear();
    token = null;
    user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
