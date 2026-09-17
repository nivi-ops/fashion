import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../onesignal_rest_key.dart';

/// Centralized OneSignal wrapper — every OneSignal call goes through here.
class OneSignalService {
  static final OneSignalService instance = OneSignalService._internal();
  factory OneSignalService() => instance;
  OneSignalService._internal();

  bool _isInitialized = false;
  bool _dialogShown = false;

  void initialize(String appId) {
    if (_isInitialized) return;
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose); // remove in production
    OneSignal.initialize(appId);
    _isInitialized = true;
  }

  /// Tags this device — use "admin" in the Admin app, "customer" in the
  /// customer app, so pushes can target the right audience.
  void setRoleTag(String role) {
    OneSignal.User.addTagWithKey('role', role);
  }

     Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }

  /// Sends a push notification to every device tagged with the given
  /// role (e.g. "admin") via the OneSignal REST API. This is what
  /// makes the admin get a push even when the app is fully closed.
  Future<void> sendPushToRole(String role, String title, String body) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $oneSignalRestApiKey',
        },
        body: jsonEncode({
          'app_id': oneSignalAppId,
          'filters': [
            {'field': 'tag', 'key': 'role', 'relation': '=', 'value': role},
          ],
          'headings': {'en': title},
          'contents': {'en': body},
        }),
      );
      debugPrint(
        'OneSignal push status: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      debugPrint('OneSignal push error: $e');
    }
  }

  bool _isRegistered(String? id) =>
      id != null && id.isNotEmpty && !id.startsWith('local-');

  void _maybeShowDialog(BuildContext context, String? subscriptionId) {
    if (_isRegistered(subscriptionId) && !_dialogShown) {
      _dialogShown = true;
      _showIntegrationCompleteDialog(context);
    }
  }

  /// Call this once from a screen that stays alive (e.g. SplashScreen or
  /// home screen's initState) — confirms the device registered with
  /// OneSignal and asks for notification permission.
  void setupPushSubscriptionObserver(BuildContext context) {
    OneSignal.User.pushSubscription.addObserver((state) {
      _maybeShowDialog(context, state.current.id);
    });
    _maybeShowDialog(context, OneSignal.User.pushSubscription.id);
  }

  void _showIntegrationCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Notifications Ready!'),
        content: const Text(
          'Tap below to enable order updates and offer notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              OneSignal.Notifications.requestPermission(true);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}