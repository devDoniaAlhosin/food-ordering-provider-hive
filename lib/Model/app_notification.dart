import 'package:firebase_messaging/firebase_messaging.dart';

/// App-level representation of an FCM push / notification message.
class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    this.data = const {},
    this.messageId,
  });

  final String title;
  final String body;
  final Map<String, String> data;
  final String? messageId;

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = <String, String>{
      for (final entry in message.data.entries)
        entry.key: entry.value.toString(),
    };

    return AppNotification(
      title: notification?.title?.trim().isNotEmpty == true
          ? notification!.title!.trim()
          : (data['title'] ?? 'Food Cart'),
      body: notification?.body?.trim().isNotEmpty == true
          ? notification!.body!.trim()
          : (data['body'] ?? 'You have a new message'),
      data: data,
      messageId: message.messageId,
    );
  }

  @override
  String toString() =>
      'AppNotification(title: $title, body: $body, messageId: $messageId)';
}
