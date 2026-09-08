import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';
import 'admin_page.dart';
import 'app_state.dart';
import 'login_page.dart';
import 'shop_page.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
/// ---------------------------------------------------------------------
/// MODELS
/// ---------------------------------------------------------------------
class AppUser {
  String name;
  String phone;
  String email;
  AppUser({this.name = '', this.phone = '', this.email = ''});
  bool get isLoggedIn => phone.isNotEmpty;
}

class SavedAddress {
  String name;
  String door;
  String street;
  String city;
  String pin;
  SavedAddress({
    required this.name,
    required this.door,
    required this.street,
    required this.city,
    this.pin = '',
  });
  String get detail => '$door, $street, $city${pin.isNotEmpty ? ', $pin' : ''}';
  bool get isOffice => name.toUpperCase().contains('OFFICE');
}

class MyOrder {
  final String id;
  final String docId;
  final String product;
  final double amount;
  String status; // Ordered, Processing, Delivered, Cancelled
  MyOrder({
    required this.id,
    required this.docId,
    required this.product,
    required this.amount,
    this.status = 'Ordered',
  });
}

enum _Panel {
  home,
  profile,
  orders,
  wishlist,
  coins,
  addresses,
  notif,
  privacyMenu,
  privacyPolicy,
  requestData,
  grievance,
  deactivate,
  deleteAccount,
  terms,
  faq,
  help,
  reviews,
}

/// ---------------------------------------------------------------------
/// SETTINGS PAGE — mirrors settings.html (Flipkart-style "My Account")
/// ---------------------------------------------------------------------
class SettingsPage extends StatefulWidget {
  final AppUser? user;
  final VoidCallback? onLoginRequested;
  final ValueChanged<AppUser?>? onUserChanged;
  final VoidCallback? onLogout;

  const SettingsPage({
    super.key,
    this.user,
    this.onLoginRequested,
    this.onUserChanged,
    this.onLogout,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _Panel _panel = _Panel.home;
  AppUser _user = AppUser();

  // Profile edit controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  // Notification toggles (persisted locally via SharedPreferences —
  // see _loadNotifPrefs / _setNotifPref for the backend/FCM TODOs
  // needed to actually deliver a push when admin sends one).
  bool _notifOrder = true;
  bool _notifPromo = true;
  bool _notifClass = false;

  // Consent toggles (privacy)
  // bool _consentMarketing = true;
  // bool _consentLocation = false;

  // Orders — starts empty. Real orders should be loaded from your
  // backend in _loadOrders() (see TODO there); no sample/dummy data.
  bool _loadingOrders = false;
  String _orderFilter = 'all';
  final List<MyOrder> _orders = [];

  // Reviews
  bool _loadingReviews = false;
  final List<Map<String, dynamic>> _reviews = [];
  final _reviewCommentCtrl = TextEditingController();
  int _reviewRating = 5;

  // Addresses
  final List<SavedAddress> _addresses = [
    SavedAddress(name: 'Home', door: '12', street: 'Kamaraj Street', city: 'Chennai', pin: '600117'),
  ];
  int _addrEditIndex = -1;
  bool _showAddrForm = false;
  final _addrNameCtrl = TextEditingController();
  final _addrDoorCtrl = TextEditingController();
  final _addrStreetCtrl = TextEditingController();
  final _addrCityCtrl = TextEditingController();
  final _addrPinCtrl = TextEditingController();

  // Grievance
  final _grievanceSubjectCtrl = TextEditingController();
  final _grievanceOrderIdCtrl = TextEditingController();
  final _grievanceDescCtrl = TextEditingController();

  // Delete account confirm
  final _deleteConfirmCtrl = TextEditingController();
  final _deactivateReasonCtrl = TextEditingController();

  // Contact details used by Help Center's Call Us / Mail Us buttons.
  static const String _supportPhone = '+918610703658';
  static const String _supportEmail = 'sumathisstyles@gmail.com';

  final List<Map<String, String>> _faqData = const [
    {
      'q': 'How long does a custom order take?',
      'a': 'Most custom stitching orders are ready within 10-15 days from order confirmation, depending on the design and current workload. Bridal outfits and heavy aari work may take a little longer.',
    },
    {
      'q': 'Can I cancel my order?',
      'a': "Yes, free of cost as long as stitching hasn't started. Once cutting or stitching begins, cancellation may not be possible.",
    },
    {
      'q': 'How do I track my order?',
      'a': "Visit 'My Orders' — each order shows a live status tracker: Ordered, Processing, Delivered.",
    },
    {
      'q': 'What payment methods are accepted?',
      'a': 'UPI (GPay, PhonePe, Paytm), Card, and Cash on Delivery.',
    },
    {
      'q': 'How do Super Coins work?',
      'a': 'Earn 10 coins for every ₹500 spent on completed orders. 1 coin = ₹1. Redemption launching soon!',
    },
  ];
  final Set<int> _openFaq = {};

    @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onAppStateChanged);
    _syncFromAppState();
    _loadNotifPrefs();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _addrNameCtrl.dispose();
    _addrDoorCtrl.dispose();
    _addrStreetCtrl.dispose();
    _addrCityCtrl.dispose();
    _addrPinCtrl.dispose();
    _grievanceSubjectCtrl.dispose();
    _grievanceOrderIdCtrl.dispose();
    _grievanceDescCtrl.dispose();
    _deleteConfirmCtrl.dispose();
    _deactivateReasonCtrl.dispose();
    _reviewCommentCtrl.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(_syncFromAppState);
  }

  void _syncFromAppState() {
    final state = AppState.instance;
    final newPhone = state.isLoggedIn ? (state.userId ?? '') : '';
    // Only true when the logged-in identity itself changed (login,
    // logout, or switched account) — not on every unrelated AppState
    // notification.
    final identityChanged = newPhone != _user.phone;
    if (state.isLoggedIn) {
      _user = AppUser(
        name: state.userName ?? '',
        phone: state.userId ?? '',
        email: _user.email,
      );
    } else {
      _user = AppUser();
    }
    // Refresh the Edit Profile text fields ONLY when identity changed.
    // Otherwise, if the user is mid-typing in Edit Profile, a routine
    // AppState notification (e.g. from elsewhere in the app) would wipe
    // out what they just typed before they hit Save.
    if (identityChanged) {
      _syncControllersFromUser();
    }
  }
  void _syncControllersFromUser() {
    final parts = _user.name.split(' ');
    _firstNameCtrl.text = parts.isNotEmpty ? parts.first : '';
    _lastNameCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _emailCtrl.text = _user.email;
    _mobileCtrl.text = _user.phone;
  }

  void _openPanel(_Panel p) {
    setState(() => _panel = p);
    if (p == _Panel.orders || p == _Panel.coins) _loadOrders();
    if (p == _Panel.reviews) _loadReviews();
  }

      Future<void> _loadOrders() async {
    if (!_user.isLoggedIn) return;
    setState(() => _loadingOrders = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('mobile', isEqualTo: _user.phone)
          .get();
      final loaded = snap.docs.map((doc) {
        final m = doc.data();
        return MyOrder(
          id: doc.id.length > 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id,
          docId: doc.id,
          product: '${m['product'] ?? ''}',
          amount: (num.tryParse('${m['amount'] ?? 0}') ?? 0).toDouble(),
          status: '${m['status'] ?? 'Ordered'}',
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(loaded);
      });
    } catch (e) {
      if (mounted) _showToast('Could not load orders: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  // ---------------------------------------------------------------
  // REVIEWS (Firestore-backed, shown under Privacy Center)
  // ---------------------------------------------------------------
  Future<void> _loadReviews() async {
    if (!_user.isLoggedIn) return;
    setState(() => _loadingReviews = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('mobile', isEqualTo: _user.phone)
          .get();
      final loaded = snap.docs.map((doc) {
        final m = doc.data();
        return {
          'id': doc.id,
          'name': '${m['name'] ?? ''}',
          'rating': (num.tryParse('${m['rating'] ?? 5}') ?? 5).toInt(),
          'comment': '${m['comment'] ?? ''}',
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _reviews
          ..clear()
          ..addAll(loaded);
      });
    } catch (e) {
      if (mounted) _showToast('Could not load reviews: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (!_user.isLoggedIn) {
      _showToast('Please login to write a review!', error: true);
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'mobile': _user.phone,
        'name': _user.name,
        'rating': _reviewRating,
        'comment': _reviewCommentCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _showToast('Thank you for your review!');
      await _loadReviews();
    } catch (e) {
      if (mounted) _showToast('Could not submit review: $e', error: true);
    }
  }

  Future<void> _editReview(Map<String, dynamic> review) async {
    if (!_user.isLoggedIn) {
      _showToast('Please login first!', error: true);
      return;
    }

    final reviewId = review['id']?.toString() ?? '';
    if (reviewId.isEmpty) {
      _showToast('Unable to edit this review.', error: true);
      return;
    }

    final commentCtrl = TextEditingController(
      text: review['comment']?.toString() ?? '',
    );
    int rating = (review['rating'] as num?)?.toInt() ?? 5;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'Edit your review',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your rating',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return IconButton(
                            tooltip: '$star star',
                            onPressed: () => setDialogState(() => rating = star),
                            icon: Icon(
                              star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: AppColors.secondary,
                              size: 30,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your review',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: commentCtrl,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Share your experience...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != true) return;

      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update({
        'rating': rating,
        'comment': commentCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showToast('Review updated successfully!');
      await _loadReviews();
    } catch (e) {
      if (mounted) _showToast('Could not update review: $e', error: true);
    } finally {
      commentCtrl.dispose();
    }
  }

  Future<void> _deleteReview(Map<String, dynamic> review) async {
    if (!_user.isLoggedIn) {
      _showToast('Please login first!', error: true);
      return;
    }

    final reviewId = review['id']?.toString() ?? '';
    if (reviewId.isEmpty) {
      _showToast('Unable to delete this review.', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete your review?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to delete this review? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
      if (!mounted) return;
      _showToast('Review deleted successfully!');
      await _loadReviews();
    } catch (e) {
      if (mounted) _showToast('Could not delete review: $e', error: true);
    }
  }

  void _openReviewForm() {
    if (!_user.isLoggedIn) {
      _showToast('Please login to write a review!', error: true);
      return;
    }
    _reviewCommentCtrl.clear();
    _reviewRating = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Write a review',
                              style: TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text("Share your experience with Sumathi's Style",
                        style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(height: 20),

                    // Logged-in user preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 23,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              _user.name.isNotEmpty ? _user.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                                            Text(_user.name.isNotEmpty ? _user.name : 'You',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                                const SizedBox(height: 3),
                                Text(_formatContact(_user.phone),
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textLight)),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text('Your Rating',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starNumber = i + 1;
                        final selected = starNumber <= _reviewRating;
                        return IconButton(
                          tooltip: '$starNumber star',
                          onPressed: () => setSheet(() => _reviewRating = starNumber),
                          iconSize: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          icon: Icon(
                            selected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: selected ? AppColors.secondary : Colors.grey.shade500,
                          ),
                        );
                      }),
                    ),
                    Center(
                      child: Text(
                        _reviewRating == 0 ? 'Tap a star to rate' : '$_reviewRating out of 5 stars',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textLight),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text('Your Review',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reviewCommentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tell us about your experience...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_reviewRating == 0) {
                            _showToast('Please select a star rating!', error: true);
                            return;
                          }
                          Navigator.pop(sheetCtx);
                          await _submitReview();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 17),
                        label: const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

     // Only prefix +91 when it's an actual 10-digit phone number.
  // Prevents "+91someone@gmail.com" when phone field holds an email.
  String _formatContact(String value) {
    final isPhone = RegExp(r'^\d{10}$').hasMatch(value);
    return isPhone ? '+91$value' : value;
  }

  void _showToast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------
  // NOTIFICATION PREFS (local persistence)
  // ---------------------------------------------------------------
  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifOrder = prefs.getBool('notif_order') ?? true;
      _notifPromo = prefs.getBool('notif_promo') ?? true;
      _notifClass = prefs.getBool('notif_class') ?? false;
    });
  }

  // Maps the SharedPreferences key used by each toggle to the matching
  // FCM topic name (kept in one place in NotificationService so the
  // Cloud Function and this screen never drift apart).
  static const Map<String, String> _notifTopicByKey = {
    'notif_order': NotificationService.topicOrder,
    'notif_promo': NotificationService.topicPromo,
    'notif_class': NotificationService.topicClass,
  };

  Future<void> _setNotifPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    // Subscribe/unsubscribe this device's FCM topic right away, so the
    // change takes effect immediately — no app restart needed. Once the
    // Cloud Function in functions/index.js is deployed, admin broadcasts
    // of that type will now reach (or stop reaching) this device.
    final topic = _notifTopicByKey[key];
    if (topic != null) {
      await NotificationService.instance.setTopicSubscription(topic, value);
    }
  }

  Future<void> _callUs() async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      _showToast('Could not open the dialer', error: true);
    }
  }

  Future<void> _mailUs() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent("Query from Sumathi's Style App")}',
    );
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      _showToast('Could not open a mail app', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
          child: _buildPanelBody(),
        ),
      ),
    );
  }

  Widget _buildPanelBody() {
    switch (_panel) {
      case _Panel.home:
        return _buildHomePanel();
      case _Panel.profile:
        return _buildProfilePanel();
      case _Panel.orders:
        return _buildOrdersPanel();
      case _Panel.wishlist:
        return _buildWishlistPanel();
      case _Panel.coins:
        return _buildCoinsPanel();
      case _Panel.addresses:
        return _buildAddressesPanel();
      case _Panel.notif:
        return _buildNotifPanel();
      case _Panel.privacyMenu:
        return _buildPrivacyMenuPanel();
      case _Panel.privacyPolicy:
        return _buildPrivacyPolicyPanel();
      case _Panel.requestData:
        return _buildRequestDataPanel();
      case _Panel.grievance:
        return _buildGrievancePanel();
      case _Panel.deactivate:
        return _buildDeactivatePanel();
      case _Panel.deleteAccount:
        return _buildDeleteAccountPanel();
      case _Panel.terms:
        return _buildTermsPanel();
      case _Panel.faq:
        return _buildFaqPanel();
      case _Panel.help:
        return _buildHelpPanel();
      case _Panel.reviews:
        return _buildReviewsPanel();
    }
  }

  // ---------------------------------------------------------------
  // shared: panel header with back button
  // ---------------------------------------------------------------
  Widget _panelHeader(String title, IconData icon, {_Panel back = _Panel.home}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          InkWell(
            onTap: () => _openPanel(back),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------
  // HOME PANEL
  // ---------------------------------------------------------------
  Widget _buildHomePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile hero card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Profile avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user.isLoggedIn ? (_user.name.isNotEmpty ? _user.name : 'User') : 'Guest User',
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _user.isLoggedIn ? '+91${_user.phone}' : 'Not logged in',
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
                             if (!_user.isLoggedIn)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.dark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Quick action grid — icons/labels centered in each cell.
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            _quickGridItem(Icons.inventory_2_outlined, 'Orders', () => _openPanel(_Panel.orders)),
            _quickGridItem(Icons.favorite_border, 'Wishlist', () => _openPanel(_Panel.wishlist)),
            _quickGridItem(Icons.monetization_on_outlined, 'Super Coins', () => _openPanel(_Panel.coins),
                iconColor: AppColors.secondary),
            _quickGridItem(Icons.support_agent, 'Help Center', () => _openPanel(_Panel.help)),
          ],
        ),
        const SizedBox(height: 20),

        // Account settings menu card
        _menuCard('ACCOUNT SETTINGS', [
          _menuRow(Icons.edit, 'Edit Profile', () => _openPanel(_Panel.profile)),
          _menuRow(Icons.inventory_2_outlined, 'My Orders', () => _openPanel(_Panel.orders)),
          _menuRow(Icons.favorite_border, 'My Wishlist', () => _openPanel(_Panel.wishlist), iconColor: AppColors.danger),
          _menuRow(Icons.location_on_outlined, 'Saved Addresses', () => _openPanel(_Panel.addresses)),
          _menuRow(Icons.notifications_none, 'Notification Settings', () => _openPanel(_Panel.notif),
              iconColor: AppColors.secondary),
          _menuRow(Icons.shield_outlined, 'Privacy Center', () => _openPanel(_Panel.privacyMenu),
              iconColor: AppColors.success),
          _menuRow(Icons.star_outline, 'My Reviews', () => _openPanel(_Panel.reviews),
              iconColor: AppColors.secondary),
        ]),

        _menuCard('FEEDBACK & INFORMATION', [
          _menuRow(Icons.description_outlined, 'Terms, Policies and Licenses', () => _openPanel(_Panel.terms)),
          _menuRow(Icons.help_outline, 'Browse FAQs', () => _openPanel(_Panel.faq)),
        ]),

        // Logout button — always visible directly below Browse FAQs.
        _menuCard(null, [
          _menuRow(
            Icons.logout,
            'Log Out',
            _doLogout,
            iconColor: AppColors.danger,
            labelColor: AppColors.danger,
          ),
        ]),

        // Admin Panel entry: tap to open the separate AdminPage. Kept
        // subtle so regular customers don't accidentally open it, but
        // it now lives right after Logout as requested.
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminPage()),
              );
            },
            child: Opacity(
              opacity: 0.18,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.admin_panel_settings_outlined, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Admin Panel',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickGridItem(IconData icon, String label, VoidCallback onTap, {Color iconColor = AppColors.primary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(String? title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 0.5),
              ),
            ),
          ...rows,
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, VoidCallback onTap,
      {Color iconColor = AppColors.primary, Color labelColor = AppColors.text}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

    Future<void> _doLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out of your account?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Clear the current login state.
    AppState.instance.logout();

    // Update this SettingsPage immediately.
    if (mounted) {
      setState(() {
        _user = AppUser();
        _syncControllersFromUser();
        _panel = _Panel.home;
      });
    }

    // Tell the parent/main page to switch to the Home tab.
    widget.onUserChanged?.call(null);
    widget.onLogout?.call();

    if (mounted) {
      _showToast('Logged out successfully!');
    }

    // If Settings was opened as a pushed page (e.g. from the drawer or
    // the account icon on Home), pop all the way back so the user
    // actually lands on the Home page instead of staying here.
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ---------------------------------------------------------------
  // PROFILE PANEL
  // ---------------------------------------------------------------
  Widget _buildProfilePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Profile Information', Icons.edit),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _textField(_firstNameCtrl, 'First Name')),
                  const SizedBox(width: 12),
                  Expanded(child: _textField(_lastNameCtrl, 'Last Name')),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _savePersonalInfo,
                style: _saveBtnStyle(),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 14),
              _textField(_emailCtrl, 'Enter email address'),
              const SizedBox(height: 12),
              // NOTE: real OTP verification flow (Send OTP -> 6-digit input -> Verify)
              // wires up the same way as mobile below — call your backend OTP endpoint here.
              ElevatedButton.icon(
                onPressed: () {
                  final email = _emailCtrl.text.trim();
                  if (!email.contains('@') || !email.contains('.')) {
                    _showToast('Enter a valid email address!', error: true);
                    return;
                  }
                  setState(() => _user.email = email);
                  widget.onUserChanged?.call(_user);
                  _showToast('Email updated!');
                },
                style: _saveBtnStyle(),
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save Email'),
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.phone_android, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 14),
              _textField(_mobileCtrl, '10-digit number', keyboardType: TextInputType.phone, maxLength: 10),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveMobileNumber,
                style: _saveBtnStyle(),
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save Mobile'),
              ),
              const SizedBox(height: 8),
              const Text(
                "Note: changing mobile number here won't move your past orders — those stay linked to the number you logged in with.",
                style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ButtonStyle _saveBtnStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      );

  Widget _textField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType, int? maxLength}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  void _savePersonalInfo() {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    if (first.isEmpty) {
      _showToast('Please enter your first name!', error: true);
      return;
    }
    setState(() => _user.name = [first, last].where((s) => s.isNotEmpty).join(' '));
    widget.onUserChanged?.call(_user);
    _showToast('Name updated!');
  }

  void _saveMobileNumber() {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10 || int.tryParse(mobile) == null) {
      _showToast('Enter a valid 10-digit number!', error: true);
      return;
    }
    // TODO: trigger real OTP verification via your backend before saving
    setState(() => _user.phone = mobile);
    widget.onUserChanged?.call(_user);
    _showToast('Mobile number updated!');
  }

  // ---------------------------------------------------------------
  // ORDERS PANEL
  // ---------------------------------------------------------------
  Widget _buildOrdersPanel() {
    final filtered = _orderFilter == 'all'
        ? _orders
        : _orders.where((o) => o.status == _orderFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('My Orders', Icons.inventory_2_outlined),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['all', 'Ordered', 'Processing', 'Delivered', 'Cancelled'].map((f) {
              final active = _orderFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f == 'all' ? 'All' : f),
                  selected: active,
                  onSelected: (_) => setState(() => _orderFilter = f),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: active ? Colors.white : AppColors.primary, fontSize: 12.5),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.primary),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingOrders)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
         else if (!_user.isLoggedIn)
  _emptyState(Icons.inventory_2_outlined, 'Login required', 'Login to see your orders', 'Login', () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  })
        else if (filtered.isEmpty)
          _emptyState(Icons.inventory_2_outlined, 'No orders yet', 'Start shopping to see your orders here!',
              'Shop Now', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()));
          })
        else
          ...filtered.map(_orderCard),
      ],
    );
  }

  Widget _orderCard(MyOrder o) {
    final canCancel = o.status != 'Cancelled' && o.status != 'Delivered';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order ID: #${o.id}', style: const TextStyle(fontSize: 12.5, color: AppColors.textLight)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(o.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(o.status,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(o.status))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: AppColors.gray, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.checkroom, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.product, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('₹${o.amount.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (canCancel)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _confirmCancelOrder(o),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Cancel Order', style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Processing':
        return const Color(0xFFF57F17);
      case 'Delivered':
        return const Color(0xFF1565C0);
      case 'Cancelled':
        return AppColors.danger;
      default:
        return const Color(0xFFC9820A);
    }
  }

  void _confirmCancelOrder(MyOrder o) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        const reasons = [
          'Ordered by mistake',
          'Found a better price elsewhere',
          'Delivery time is too long',
          'Want to change design/size/measurements',
          'Other reason',
        ];
        String? selected;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cancel this order?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text("Please tell us why you're cancelling",
                    style: TextStyle(color: AppColors.textLight, fontSize: 12.5)),
                const SizedBox(height: 12),
                ...reasons.map((r) => RadioListTile<String>(
                      value: r,
                      groupValue: selected,
                      onChanged: (v) => setSheet(() => selected = v),
                      title: Text(r, style: const TextStyle(fontSize: 13.5)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Go Back'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selected == null ? null : () => Navigator.pop(ctx, selected),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                        child: const Text('Cancel Order'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (reason == null) return;
    try {
      await FirebaseFirestore.instance.collection('orders').doc(o.docId).update({
        'status': 'Cancelled',
        'cancel_reason': reason,
      });
      if (!mounted) return;
      setState(() => o.status = 'Cancelled');
      _showToast('Order cancelled successfully');
    } catch (e) {
      if (mounted) _showToast('Could not cancel order: $e', error: true);
    }
  }

  // ---------------------------------------------------------------
  // WISHLIST PANEL (data comes from your product store — hook up onLoad)
  // ---------------------------------------------------------------
  Widget _buildWishlistPanel() {
    // TODO: replace with real wishlist product data (see home_page.dart Product model)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('My Wishlist', Icons.favorite, back: _Panel.home),
        _emptyState(Icons.heart_broken_outlined, 'Your wishlist is empty', 'Save your favourite products here!',
    'Explore Shop', () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()));
    }),
      ],
    );
  }

  // ---------------------------------------------------------------
  // SUPER COINS PANEL — like Flipkart SuperCoins: a wallet balance up
  // top, then a per-order "+coins earned" history list below.
  // ---------------------------------------------------------------
  Widget _buildCoinsPanel() {
    final eligibleOrders = _orders.where((o) => o.status != 'Cancelled').toList();
    final totalSpent = eligibleOrders.fold<double>(0, (s, o) => s + o.amount);
    final coins = (totalSpent / 500).floor() * 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Super Coins', Icons.monetization_on_outlined),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.secondaryLight]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Icon(Icons.monetization_on, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text('$coins',
                  style: const TextStyle(
                      fontFamily: 'PlayfairDisplay', fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Sumathi Coins Available', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            children: [
              _coinsInfoRow(Icons.shopping_bag_outlined, 'Earn on every order',
                  'Get 10 coins for every ₹500 you spend on stitching, sarees, aari work & more.'),
              const Divider(height: 24),
              _coinsInfoRow(Icons.card_giftcard, 'Redeem for discounts',
                  'Use your coins to get discounts on your next custom order. Coming soon!'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text('COINS HISTORY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        if (_loadingOrders)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!_user.isLoggedIn)
          _emptyState(Icons.monetization_on_outlined, 'Login required', 'Login to see your Super Coins', 'Login', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          })
        else if (eligibleOrders.isEmpty)
          _emptyState(Icons.monetization_on_outlined, 'No coins yet',
              'Place an order to start earning Super Coins!', 'Shop Now', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()));
          })
        else
          ...eligibleOrders.map(_coinHistoryRow),
      ],
    );
  }

  Widget _coinHistoryRow(MyOrder o) {
    final earned = (o.amount / 500).floor() * 10;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.monetization_on, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.product, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text('Order #${o.id} • ₹${o.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textLight)),
              ],
            ),
          ),
          Text(earned > 0 ? '+$earned' : '0',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary)),
        ],
      ),
    );
  }

  Widget _coinsInfoRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // ADDRESSES PANEL
  // ---------------------------------------------------------------
  Widget _buildAddressesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Saved Addresses', Icons.location_on_outlined),
        ..._addresses.asMap().entries.map((e) => _addressCard(e.key, e.value)),
        OutlinedButton.icon(
          onPressed: () => _openAddressForm(-1),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primaryLight, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add New Address'),
        ),
        if (_showAddrForm) ...[
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_addrEditIndex >= 0 ? 'Edit Address' : 'Add New Address',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _textField(_addrNameCtrl, 'Address Name (e.g. Home, Office)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _textField(_addrDoorCtrl, 'Door No')),
                    const SizedBox(width: 10),
                    Expanded(child: _textField(_addrStreetCtrl, 'Street Name')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _textField(_addrCityCtrl, 'City')),
                    const SizedBox(width: 10),
                    Expanded(child: _textField(_addrPinCtrl, 'Pincode', maxLength: 6)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton(onPressed: _saveAddress, style: _saveBtnStyle(), child: const Text('Save Address')),
                    const SizedBox(width: 10),
                    TextButton(onPressed: _closeAddressForm, child: const Text('Cancel')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _addressCard(int index, SavedAddress a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.gray, borderRadius: BorderRadius.circular(8)),
            child: Icon(a.isOffice ? Icons.work_outline : Icons.home_outlined, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.gray, borderRadius: BorderRadius.circular(4)),
                      child: Text(a.isOffice ? 'OFFICE' : 'HOME',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(a.detail, style: const TextStyle(fontSize: 12.5, color: AppColors.textLight)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textLight),
            onPressed: () => _openAddressForm(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            onPressed: () => _deleteAddress(index),
          ),
        ],
      ),
    );
  }

  void _openAddressForm(int index) {
    setState(() {
      _addrEditIndex = index;
      _showAddrForm = true;
      if (index >= 0) {
        final a = _addresses[index];
        _addrNameCtrl.text = a.name;
        _addrDoorCtrl.text = a.door;
        _addrStreetCtrl.text = a.street;
        _addrCityCtrl.text = a.city;
        _addrPinCtrl.text = a.pin;
      } else {
        _addrNameCtrl.clear();
        _addrDoorCtrl.clear();
        _addrStreetCtrl.clear();
        _addrCityCtrl.clear();
        _addrPinCtrl.clear();
      }
    });
  }

  void _closeAddressForm() {
    setState(() {
      _showAddrForm = false;
      _addrEditIndex = -1;
    });
  }

  void _saveAddress() {
    final name = _addrNameCtrl.text.trim();
    final door = _addrDoorCtrl.text.trim();
    final street = _addrStreetCtrl.text.trim();
    final city = _addrCityCtrl.text.trim();
    if (name.isEmpty || door.isEmpty || street.isEmpty || city.isEmpty) {
      _showToast('Please fill Address Name, Door No, Street Name and City!', error: true);
      return;
    }
    final entry = SavedAddress(name: name, door: door, street: street, city: city, pin: _addrPinCtrl.text.trim());
    setState(() {
      if (_addrEditIndex >= 0) {
        _addresses[_addrEditIndex] = entry;
      } else {
        _addresses.add(entry);
      }
      _showAddrForm = false;
      _addrEditIndex = -1;
    });
    _showToast('Address saved!');
  }

  void _deleteAddress(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _addresses.removeAt(index));
    _showToast('Address deleted');
  }

  // ---------------------------------------------------------------
  // NOTIFICATION SETTINGS PANEL
  // ---------------------------------------------------------------
  Widget _buildNotifPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Notification Settings', Icons.notifications_none),
        _card(
          child: Column(
            children: [
              _toggleRow('Order Updates', 'Get notified about order status', _notifOrder, (v) {
                setState(() => _notifOrder = v);
                _setNotifPref('notif_order', v);
              }),
              const Divider(height: 26),
              _toggleRow('Promotions', 'Receive offers and discounts', _notifPromo, (v) {
                setState(() => _notifPromo = v);
                _setNotifPref('notif_promo', v);
              }),
              const Divider(height: 26),
              _toggleRow('Class Reminders', 'Reminders for enrolled classes', _notifClass, (v) {
                setState(() => _notifClass = v);
                _setNotifPref('notif_class', v);
              }),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'These switches control which admin announcements this device '
          'receives as a push notification, in real time.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textLight, height: 1.5),
        ),
      ],
    );
  }

  Widget _toggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textLight)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
      ],
    );
  }

  // ---------------------------------------------------------------
  // PRIVACY CENTER MENU
  // ---------------------------------------------------------------
  Widget _buildPrivacyMenuPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Privacy Center', Icons.shield_outlined),
        _menuCard(null, [
          _menuRow(Icons.description_outlined, 'Privacy Policy', () => _openPanel(_Panel.privacyPolicy)),
          _menuRow(Icons.download_outlined, 'Request My Data', () => _openPanel(_Panel.requestData)),
          _menuRow(Icons.gavel_outlined, 'Grievance Redressal', () => _openPanel(_Panel.grievance)),
          _menuRow(Icons.person_off_outlined, 'De-activate my Account', () => _openPanel(_Panel.deactivate),
              iconColor: AppColors.secondary),
          _menuRow(Icons.delete_outline, 'Delete my Account', () => _openPanel(_Panel.deleteAccount),
              iconColor: AppColors.danger, labelColor: AppColors.danger),
        ]),
      ],
    );
  }

  Widget _buildPrivacyPolicyPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Privacy Policy', Icons.description_outlined, back: _Panel.privacyMenu),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _PolicySection(
                title: '1. Introduction',
                body:
                    "Welcome to Sumathi's Style — Tailoring Boutique with 30 Years of Experience. We respect your privacy and are committed to protecting your personal data.",
              ),
              _PolicySection(
                title: '2. Information We Collect',
                body:
                    'Personal information (name, phone, email, address), order details (measurements, design preferences), payment transaction details, and device information for security.',
              ),
              _PolicySection(
                title: '3. How We Use Your Data',
                body:
                    'To process and deliver orders, communicate updates via SMS/WhatsApp/Email, improve our services, and comply with legal obligations.',
              ),
              _PolicySection(
                title: '4. Data Sharing & Disclosure',
                body:
                    'We never sell your data. We only share it with delivery partners, payment gateways, and legal authorities when required by law.',
              ),
              _PolicySection(
                title: '5. Your Rights',
                body: 'Access, correction, deletion of your data, and the ability to withdraw consent anytime.',
              ),
              _PolicySection(
                title: '6. Contact Us',
                body: 'For privacy questions, contact sumathisstyles@gmail.com or WhatsApp +91 86107 03658.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestDataPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Request My Data', Icons.download_outlined, back: _Panel.privacyMenu),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Download Your Personal Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              const Text(
                'You have the right to access a full copy of the personal data we hold about you — profile info, order history, saved addresses, wishlist, and Super Coins balance.',
                style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _requestDataDownload,
                style: _saveBtnStyle(),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Request Data Export'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _requestDataDownload() {
    if (!_user.isLoggedIn) {
      _showToast('Please login to request your data!', error: true);
      return;
    }
    // TODO: call request_data_export.php with { phone, email, name }
    // and/or generate + share a JSON export file locally.
    _showToast('Your data export request has been submitted!');
  }

  Widget _buildGrievancePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Grievance Redressal', Icons.gavel_outlined, back: _Panel.privacyMenu),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Grievance Officer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 8),
              Text(
                'Name: Sumathi.M\nDesignation: Proprietor, Sumathi\'s Style\nEmail: sumathisstyles@gmail.com\nPhone: +91 86107 03658',
                style: TextStyle(fontSize: 12.5, color: AppColors.textLight, height: 1.7),
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submit a Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              _textField(_grievanceSubjectCtrl, 'Complaint Subject'),
              const SizedBox(height: 10),
              _textField(_grievanceOrderIdCtrl, 'Order ID (if applicable)'),
              const SizedBox(height: 10),
              TextField(
                controller: _grievanceDescCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Please describe your issue in detail...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _submitGrievance,
                style: _saveBtnStyle(),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Submit Complaint'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submitGrievance() {
    final subject = _grievanceSubjectCtrl.text.trim();
    final desc = _grievanceDescCtrl.text.trim();
    if (subject.isEmpty || desc.isEmpty) {
      _showToast('Please fill in the subject and description!', error: true);
      return;
    }
    // TODO: POST to submit_grievance.php with name/phone/email/subject/order_id/description
    _showToast("Complaint submitted! We'll respond within 48 hours.");
    _grievanceSubjectCtrl.clear();
    _grievanceOrderIdCtrl.clear();
    _grievanceDescCtrl.clear();
  }

  Widget _buildDeactivatePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('De-activate my Account', Icons.person_off_outlined, back: _Panel.privacyMenu),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "De-activating your account will temporarily disable your access. Your orders, measurements, and preferences will remain safely saved. You can re-activate anytime by logging back in.",
                style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
              ),
              const SizedBox(height: 16),
              _textField(_deactivateReasonCtrl, 'Reason for de-activation (optional)'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _deactivateAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.dark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.person_off, size: 16),
                label: const Text('De-activate Account'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _deactivateAccount() async {
    if (!_user.isLoggedIn) {
      _showToast('Please login first!', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure you want to temporarily de-activate your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('De-activate')),
        ],
      ),
    );
    if (confirmed != true) return;
    // TODO: POST to deactivate_account.php with { phone, reason }
    setState(() {
      _user = AppUser();
      _syncControllersFromUser();
    });
    widget.onUserChanged?.call(null);
    widget.onLogout?.call();
    _showToast('Account de-activated. Login anytime to re-activate.');
    _openPanel(_Panel.home);
  }

  Widget _buildDeleteAccountPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Delete my Account', Icons.delete_outline, back: _Panel.privacyMenu),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is irreversible. Once deleted, all your data — order history, saved addresses, wishlist, measurements, Super Coins — will be permanently removed and cannot be recovered.',
                style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  border: Border.all(color: const Color(0xFFFFE3E3), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You will lose: order history, saved addresses, wishlist items, all Super Coins, and account access permanently.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textLight, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
                  children: [
                    TextSpan(text: 'To confirm, please type '),
                    TextSpan(text: 'DELETE', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    TextSpan(text: ' in the box below:'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _textField(_deleteConfirmCtrl, 'Type DELETE to confirm'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _deleteAccountFinal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.delete_forever, size: 16),
                label: const Text('Permanently Delete Account'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _deleteAccountFinal() async {
    if (_deleteConfirmCtrl.text.trim() != 'DELETE') {
      _showToast('Please type DELETE exactly to confirm!', error: true);
      return;
    }
    if (!_user.isLoggedIn) {
      _showToast('Please login first!', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('This is your final confirmation. Delete your account permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    // TODO: POST to delete_account.php with { phone }
    setState(() {
      _user = AppUser();
      _syncControllersFromUser();
      _addresses.clear();
    });
    widget.onUserChanged?.call(null);
    widget.onLogout?.call();
    _showToast('Your account has been permanently deleted.');
    _openPanel(_Panel.home);
  }

  // ---------------------------------------------------------------
  // TERMS PANEL
  // ---------------------------------------------------------------
  Widget _buildTermsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Terms, Policies & Licenses', Icons.description_outlined),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 10),
              Text(
                "By placing an order with Sumathi's Style, you agree to our custom-order process. Please review your measurements and design instructions carefully before confirming, as orders are custom-made to your specifications.",
                style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.6),
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Cancellation Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 10),
              Text(
                'Orders can be cancelled free of charge before stitching work has begun. Once stitching has started, custom-stitched items generally cannot be cancelled or refunded.',
                style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // FAQ PANEL
  // ---------------------------------------------------------------
  Widget _buildFaqPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Browse FAQs', Icons.help_outline),
        _card(
          child: Column(
            children: _faqData.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              final open = _openFaq.contains(i);
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => open ? _openFaq.remove(i) : _openFaq.add(i)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(f['q']!,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                          Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  if (open)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(f['a']!,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textLight, height: 1.6)),
                      ),
                    ),
                  if (i != _faqData.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // HELP CENTER PANEL
  // ---------------------------------------------------------------
  Widget _buildHelpPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('Help Center', Icons.support_agent),
        _card(
          child: Column(
            children: [
              const Icon(Icons.support_agent, size: 44, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text("We're Here to Help!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              const Text(
                'If you have questions about your order, contact us using the number below. Feedback and suggestions are always welcome via email.',
                style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _callUs,
                style: _saveBtnStyle().copyWith(minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 46))),
                icon: const Icon(Icons.call, size: 16),
                label: const Text('Call Us'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _mailUs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.dark,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.email, size: 16),
                label: const Text('Mail Us'),
              ),
              const SizedBox(height: 14),
              const Text('We usually respond within 24-48 hours.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textLight)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // MY REVIEWS PANEL — matches the Catering Reviews UI style.
  // ---------------------------------------------------------------
  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<int>(
      0,
      (sum, review) => sum + ((review['rating'] as num?)?.toInt() ?? 0),
    );
    return total / _reviews.length;
  }

  int _countForRating(int stars) {
    return _reviews.where((review) {
      return (review['rating'] as num?)?.toInt() == stars;
    }).length;
  }

  Widget _buildReviewsPanel() {
    final average = _averageRating;
    final ratingText = average == 0 ? '0.0' : average.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader('My Reviews', Icons.star_outline),

        if (_loadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!_user.isLoggedIn)
          _emptyState(
            Icons.star_outline,
            'Login required',
            'Login to see and write your reviews',
            'Login',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          )
        else ...[
          // Rating summary — same layout as Catering Reviews.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      ratingText,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '★★★★★',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_reviews.length} reviews',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((stars) {
                      final count = _countForRating(stars);
                      final percent = _reviews.isEmpty
                          ? 0.0
                          : count / _reviews.length;

                      return _reviewRatingBar('$stars★', percent);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logged-in user review prompt — same Catering style.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _user.name.isNotEmpty
                            ? _user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user.name.isNotEmpty
                                ? 'Hi, ${_user.name}'
                                : 'Hi there',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                const Text(
                  'How was your experience?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star_border_rounded,
                      color: AppColors.secondary,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _openReviewForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text(
                      'Write a review',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (_reviews.isEmpty)
            _emptyState(
              Icons.star_outline,
              'No reviews yet',
              'Share your experience about a product you ordered!',
              'Write a Review',
              _openReviewForm,
            )
          else
            ..._reviews.map(_reviewCard),
        ],
      ],
    );
  }

  Widget _reviewRatingBar(String label, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 7,
                backgroundColor: AppColors.gray,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '${(percent * 100).round()}%',
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 5;
    final comment = review['comment']?.toString() ?? '';
    final rawName = review['name']?.toString().trim() ?? '';
    final displayName = rawName.isNotEmpty
        ? rawName
        : (_user.name.isNotEmpty ? _user.name : 'You');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(
            color: AppColors.secondary,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.primary,
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '★' * rating + '☆' * (5 - rating),
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Review options',
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppColors.textLight,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editReview(review);
                  } else if (value == 'delete') {
                    _deleteReview(review);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textLight,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // shared empty state
  // ---------------------------------------------------------------
  Widget _emptyState(
    IconData icon,
    String title,
    String subtitle,
    String btnLabel,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: const Color(0xFFDDDDDD)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onTap,
            style: _saveBtnStyle(),
            child: Text(btnLabel),
          ),
        ],
      ),
    );
  }
}
class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 12.5, color: AppColors.textLight, height: 1.6)),
        ],
      ),
    );
  }
}