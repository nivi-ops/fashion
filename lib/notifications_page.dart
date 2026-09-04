import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../app_colors.dart';
import '../app_state.dart';
import '../api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;

  // True once we know the OS has denied notification permission for this app.
  // Drives the "enable notifications" banner below the app bar.
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
    _load();
  }

  /// Just READS the current permission status to decide whether to show
  /// the "notifications are off" banner. Does NOT request permission here
  /// — that already happens once at app startup via NotificationService,
  /// so the native Allow/Block popup shows on first app open, not when
  /// this page is opened.
  Future<void> _checkPermissionStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();

    _permissionDenied =
        settings.authorizationStatus == AuthorizationStatus.denied;

    if (mounted) setState(() {});
  }

    Future<void> _load() async {
  setState(() => _loading = true);
  final serverNotifs = await ApiService.fetchNotifications();
  for (final n in serverNotifs) {
    AppState.instance.addNotification(
      n.title,
      n.message,
      serverId: n.id,   // <-- ADD THIS
    );
  }
  if (mounted) setState(() => _loading = false);
}

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final notifs = state.notifications;
        return Scaffold(
          backgroundColor: AppColors.light,
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              if (notifs.isNotEmpty)
                TextButton(
                  onPressed: state.markAllNotificationsRead,
                  child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
            ],
          ),
          body: Column(
            children: [
              if (_permissionDenied) _buildPermissionBanner(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: notifs.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.notifications_none, size: 64, color: AppColors.textLight),
                                          const SizedBox(height: 12),
                                          const Text('No notifications yet', style: TextStyle(color: AppColors.textLight)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                itemCount: notifs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final n = notifs[i];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => state.markNotificationRead(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: n.read ? Colors.white : AppColors.primary.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: n.read ? Colors.transparent : AppColors.primary.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(top: 4, right: 10),
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: n.read ? Colors.transparent : AppColors.secondary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                const SizedBox(height: 3),
                                                Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${n.time.day}/${n.time.month}/${n.time.year}  ${n.time.hour}:${n.time.minute.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shown when the OS-level notification permission is denied, so the user
  /// knows why they aren't getting order/offer alerts and can go fix it.
  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_off_outlined, color: AppColors.secondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Notifications are turned off. Enable them in your phone's Settings to get order updates and offers.",
              style: TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}