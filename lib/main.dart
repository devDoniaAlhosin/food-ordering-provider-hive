import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Provider/order_provider.dart';
import 'Services/hive_cart_service.dart';
import 'View/food_menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? hiveError;
  try {
    await HiveCartService.init();
  } catch (error) {
    hiveError = 'Local storage unavailable. Cart will not persist.';
    debugPrint('Hive init error: $error');
  }

  final orderProvider = OrderProvider();
  await orderProvider.initialize();

  runApp(
    FoodOrderingApp(
      orderProvider: orderProvider,
      hiveError: hiveError,
    ),
  );
}

class FoodOrderingApp extends StatelessWidget {
  const FoodOrderingApp({
    super.key,
    required this.orderProvider,
    this.hiveError,
  });

  final OrderProvider orderProvider;
  final String? hiveError;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrderProvider>.value(
      value: orderProvider,
      child: MaterialApp(
        title: 'Food Cart · Hive + Provider',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE65100),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true),
        ),
        home: _HomeShell(hiveError: hiveError),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({this.hiveError});

  final String? hiveError;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  @override
  void initState() {
    super.initState();
    if (widget.hiveError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.hiveError!)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const FoodMenuScreen();
  }
}
