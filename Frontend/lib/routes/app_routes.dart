import 'package:flutter/material.dart';

import '../screens/navigation/admin_navigation_screen.dart';
import '../screens/admin/expenses_screen.dart';
import '../screens/admin/manage_services_screen.dart';
import '../screens/admin/manage_staff_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/delivery/delivery_dashboard_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/orders/create_order_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../screens/staff/customer_balance_screen.dart';
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/staff/staff_orders_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const register = '/register';
  static const home = '/home';
  static const createOrder = '/orders/create';
  static const orderHistory = '/orders/history';
  static const orderDetails = '/orders/details';
  static const profile = '/profile';
  static const payment = '/payments/pay';
  static const paymentHistory = '/payments/history';
  static const staffDashboard = '/staff/dashboard';
  static const staffOrders = '/staff/orders';
  static const customerBalance = '/staff/customer-balance';
  static const updateOrderStatus = '/staff/orders/status';
  static const deliveryDashboard = '/delivery/dashboard';
  static const adminDashboard = '/admin/dashboard';
  static const manageServices = '/admin/services';
  static const manageStaff = '/admin/staff';
  static const reports = '/admin/reports';
  static const expenses = '/admin/expenses';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),
    createOrder: (_) => const CreateOrderScreen(),
    orderHistory: (_) => const OrderHistoryScreen(),
    profile: (_) => const ProfileScreen(),
    staffDashboard: (_) => const StaffDashboardScreen(),
    staffOrders: (_) => const StaffOrdersScreen(),
    customerBalance: (_) => const CustomerBalanceScreen(),
    deliveryDashboard: (_) => const DeliveryDashboardScreen(),
    adminDashboard: (_) => const AdminNavigationScreen(),
    manageServices: (_) => const ManageServicesScreen(),
    manageStaff: (_) => const ManageStaffScreen(),
    reports: (_) => const ReportsScreen(),
    expenses: (_) => const ExpensesScreen(),
  };

  static String homeForRole(String? role) {
    if (role == 'Admin') return adminDashboard;
    if (role == 'Staff') return staffDashboard;
    if (role == 'Delivery') return deliveryDashboard;
    return home;
  }
}
