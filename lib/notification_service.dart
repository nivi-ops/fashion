import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// ---------------------------------------------------------------------
/// NOTIFICATION SERVICE
///
/// Handles:
/// - Asking for OS notification permission (Allow / Block popup) as soon
///   as the app starts — same as WhatsApp / other apps do on first launch.
/// - Showing FCM push notifications in the phone's system tray, even
///   while the app is open (foreground) or in background.
/// - Getting this device's FCM token and sending it to the PHP backend,
///   so the admin dashboard can target this device/user directly.
/// - Filtering OUT order-related pushes from foreground display — only
///   admin broadcast notifications show a local notification. Requires
///   the backend to send `"data": {"type": "order"}` (or similar) on
///   order-confirmation pushes so this can tell them apart.
/// ---------------------------------------------------------------------

/// Must be a TOP-LEVEL function (not inside a class) — this is required
/// by Firebase so it can run even when the app is fully closed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No need to manually show a notification here — FCM automatically
  // displays a system tray notification when the app is in the
  // background/terminated AND the push payload has a "notification" block
  // (which our PHP script sends). This handler is just for any extra data
  // processing you want to do (e.g. updating local storage) while the
  // app is not open.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'Order & Offer Updates', // title shown in phone's notification settings
    description: 'Order status updates, offers and admin announcements.',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Call this once, early in main(), right after Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Register the background handler (must be set before runApp).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Set up local notifications so we can show a system-tray
    //    notification even when the app is OPEN (foreground). FCM does
    //    NOT show a tray notification automatically while the app is in
    //    foreground — we have to do that ourselves.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Ask the OS for permission RIGHT NOW (app-start), not only when
    //    the user opens the Notifications page. This makes the native
    //    Allow/Block popup appear on first app open, like other apps.
    await requestPermissionAndRegister();

    // 4. Foreground listener — show a system tray notification manually
    //    when a push arrives while the app is open. Skips order-related
    //    pushes; only admin broadcasts should show here.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Only show a local notification for admin broadcasts, not order
      // events. Backend must send "data": {"type": "order"} on
      // order-confirmation pushes for this filter to catch them.
      if (message.data['type'] == 'order') return;

      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  /// Asks for OS permission (shows native Allow/Block popup the first
  /// time) and, if granted, fetches the FCM token and saves it to the
  /// PHP backend so the admin dashboard can send this device a push.
  Future<void> requestPermissionAndRegister() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) return;

    final token = await messaging.getToken();
    if (token != null) {
      await ApiService.saveFcmToken(token);
    }

    // Keep the backend updated if the token ever changes/refreshes.
    messaging.onTokenRefresh.listen((newToken) {
      ApiService.saveFcmToken(newToken);
    });
  }
}