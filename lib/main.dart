import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Provider/auth_provider.dart';
import 'Provider/order_provider.dart';
import 'Services/hive_cart_service.dart';
import 'View/auth_gate.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? hiveError;
  try {
    await HiveCartService.init();
  } catch (error) {
    hiveError = 'Local storage unavailable. Cart will not persist.';
    debugPrint('Hive init error: $error');
  }

  final firebase = await _bootstrapFirebase();

  final orderProvider = OrderProvider();
  await orderProvider.initialize();

  runApp(
    FoodOrderingApp(
      orderProvider: orderProvider,
      hiveError: hiveError,
      firebaseError: firebase.error,
      firebaseReady: firebase.ready,
    ),
  );
}

class _FirebaseBootstrap {
  const _FirebaseBootstrap({required this.ready, this.error});

  final bool ready;
  final String? error;
}

Future<_FirebaseBootstrap> _bootstrapFirebase() async {
  if (DefaultFirebaseOptions.isPlaceholder) {
    return const _FirebaseBootstrap(
      ready: false,
      error: 'Firebase is not configured yet. Run `flutterfire configure` '
          'and enable Email/Password auth in the Firebase Console.',
    );
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Touch Auth once so native bridge failures surface here (not as a red screen).
    await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 8));

    return const _FirebaseBootstrap(ready: true);
  } catch (error, stackTrace) {
    debugPrint('Firebase init error: $error');
    debugPrintStack(stackTrace: stackTrace);
    return _FirebaseBootstrap(
      ready: false,
      error: 'Firebase Auth failed to start.\n\n'
          '1. Run: flutterfire configure\n'
          '2. Enable Email/Password in Firebase Console\n'
          '3. flutter clean && flutter pub get && flutter run\n\n'
          'Details: $error',
    );
  }
}

class FoodOrderingApp extends StatelessWidget {
  const FoodOrderingApp({
    super.key,
    required this.orderProvider,
    this.hiveError,
    this.firebaseError,
    this.firebaseReady = false,
  });

  final OrderProvider orderProvider;
  final String? hiveError;
  final String? firebaseError;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
        if (firebaseReady)
          ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ],
      child: MaterialApp(
        title: 'Food Cart - Hive + Provider',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _HomeShell(
          hiveError: hiveError,
          firebaseError: firebaseError,
          firebaseReady: firebaseReady,
        ),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({
    this.hiveError,
    this.firebaseError,
    required this.firebaseReady,
  });

  final String? hiveError;
  final String? firebaseError;
  final bool firebaseReady;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  @override
  void initState() {
    super.initState();
    final message = widget.hiveError;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) {
      return _FirebaseSetupScreen(message: widget.firebaseError);
    }
    return const AuthGate();
  }
}

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Firebase setup required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message ??
                    'Configure Firebase Auth before using login / register.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '1. Create a Firebase project\n'
                '2. Enable Authentication â†’ Email/Password\n'
                '3. Run:\n'
                '   dart pub global activate flutterfire_cli\n'
                '   flutterfire configure\n'
                '4. flutter clean\n'
                '5. flutter pub get\n'
                '6. flutter run',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
