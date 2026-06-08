class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Android emulator reaches the host machine at 10.0.2.2.
  // Use http://127.0.0.1:5000/api for Windows/iOS simulator, or after adb reverse.

  static const String login = '/auth/login';
  static const String forgotPasswordVerify = '/auth/forgot-password/verify';
  static const String forgotPasswordReset = '/auth/forgot-password/reset';
  static const String registerCustomer = '/customers/register';
  static const String createOrder = '/orders/create';
  static const String updateOrderStatus = '/orders/status';
  static String customerOrders(int customerId) =>
      '/orders/customer/$customerId';
  static String orderDetails(int orderId) => '/orders/$orderId';

  static const String makePayment = '/payments/make';
  static String paymentHistory(int orderId) => '/payments/order/$orderId';

  static const String staffDashboard = '/staff/dashboard';
  static const String staffOrders = '/staff/orders';
  static const String staffCustomerBalances = '/staff/customer-balances';
  static const String staffList = '/staff/list';
  static const String staffStatus = '/staff/status';
  static const String staffUpdate = '/staff/update';
  static const String staffDelete = '/staff/delete';

  static const String deliveryOrders = '/delivery/orders';
  static const String deliveryPickedUp = '/delivery/picked-up';
  static const String deliveryDelivered = '/delivery/delivered';

  static const String adminDashboard = '/admin/dashboard';
  static const String adminServices = '/admin/services';
  static const String adminReports = '/admin/reports';
  static const String adminExpenses = '/admin/expenses';

  static const String cities = '/lookups/cities';
  static String districts(int cityId) => '/lookups/districts/$cityId';
  static const String services = '/lookups/services';
  static const String clothTypes = '/lookups/cloth-types';
}
