import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

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