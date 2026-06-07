import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/app_state.dart';
import 'routes/app_routes.dart';
import 'screens/orders/order_details_screen.dart';
import 'screens/payments/payment_history_screen.dart';
import 'screens/payments/payment_screen.dart';
import 'screens/staff/update_order_status_screen.dart';

void main() {
  runApp(const LaundryApp());
}

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Laundry App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          scaffoldBackgroundColor: const Color(0xFFF4F8FF),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1554B7),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1554B7),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.login,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.orderDetails) {
            final orderId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(orderId: orderId),
            );
          }
          if (settings.name == AppRoutes.payment) {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => PaymentScreen(
                orderId: args['order_id'] as int,
                totalAmount: double.parse(args['total_amount'].toString()),
              ),
            );
          }
          if (settings.name == AppRoutes.paymentHistory) {
            final orderId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => PaymentHistoryScreen(orderId: orderId),
            );
          }
          if (settings.name == AppRoutes.updateOrderStatus) {
            final order = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => UpdateOrderStatusScreen(order: order),
            );
          }
          return null;
        },
      ),
    );
  }
}
