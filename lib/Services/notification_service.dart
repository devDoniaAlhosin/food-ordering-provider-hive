import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Model/app_notification.dart';
import '../firebase_options.dart';

/// Top-level background handler (must be a top-level or static function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is ready when a message wakes a background isolate.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint(
    'FCM background: ${AppNotification.fromRemoteMessage(message)}',
  );
}

/// Firebase Cloud Messaging + local notifications for foreground display.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String androidChannelId = 'food_orders';
  static const String androidChannelName = 'Food orders';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<AppNotification> _foregroundController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onForegroundNotification =>
      _foregroundController.stream;

  final StreamController<AppNotification> _openedController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onNotificationOpened => _openedController.stream;

  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();
  Stream<String> get onTokenRefresh => _tokenController.stream;

  /// Call once after [Firebase.initializeApp], before [runApp].
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await _requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _refreshToken();
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('FCM token refreshed: $token');
      _tokenController.add(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedMessage(initial);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        androidChannelId,
        androidChannelName,
        description: 'Order and account updates from Food Cart',
        importance: Importance.high,
      ),
    );
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Android 13+ runtime permission via local notifications plugin.
    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<String?> _refreshToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM token: $_fcmToken');
      if (_fcmToken != null) {
        _tokenController.add(_fcmToken!);
      }
      return _fcmToken;
    } catch (error, stackTrace) {
      debugPrint('FCM getToken failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Returns the current token, refreshing if needed.
  Future<String?> getToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) return _fcmToken;
    return _refreshToken();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = AppNotification.fromRemoteMessage(message);
    debugPrint('FCM foreground: $notification');
    _foregroundController.add(notification);
    await showLocalNotification(notification);
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final notification = AppNotification.fromRemoteMessage(message);
    debugPrint('FCM opened: $notification');
    _openedController.add(notification);
  }

  Future<void> showLocalNotification(AppNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: 'Order and account updates from Food Cart',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _local.show(
      notification.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification.title,
      notification.body,
      details,
      payload: notification.data.isEmpty ? null : notification.data.toString(),
    );
  }

  void dispose() {
    _foregroundController.close();
    _openedController.close();
    _tokenController.close();
  }
}
