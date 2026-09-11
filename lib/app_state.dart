import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// ---------------------------------------------------------------------
/// APP STATE — single source of truth for cart / wishlist / notifications
/// / delivery location / login / recently viewed. Uses plain
/// ChangeNotifier + ListenableBuilder so no external package
/// (provider/riverpod) is required.
///
/// TODO (backend): every method below has a comment showing which PHP
/// endpoint on your Railway backend should be called so this state stays
/// in sync with the DB (submit_forms.php style pattern you already use).
/// ---------------------------------------------------------------------
class AppState extends ChangeNotifier {
  AppState._internal();
  static final AppState instance = AppState._internal();

  // ---------------- LOGIN / USER ----------------
  bool _isLoggedIn = false;
  String? _userName;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userId => _userId;
 
    static const _kUserIdKey = 'user_id';
  static const _kUserNameKey = 'user_name';

  Future<void> login({required String userId, required String userName}) async {
    _isLoggedIn = true;
    _userId = userId;
    _userName = userName;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserIdKey, userId);
    await prefs.setString(_kUserNameKey, userName);
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    _userName = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserIdKey);
    await prefs.remove(_kUserNameKey);
  }

  Future<void> loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_kUserIdKey);
    final savedName = prefs.getString(_kUserNameKey);
    if (savedId != null && savedId.trim().isNotEmpty) {
      _isLoggedIn = true;
      _userId = savedId;
      _userName = savedName;
      notifyListeners();
    }
  }

  // ---------------- CART ----------------
  final Map<int, Product> _cart = {};
  List<Product> get cartItems => _cart.values.toList();
  int get cartCount => _cart.values.fold(0, (sum, p) => sum + p.qty);
  double get cartTotal =>
      _cart.values.fold(0.0, (sum, p) => sum + (p.price * p.qty));

  void addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      final existing = _cart[product.id]!;
      _cart[product.id] = existing.copyWith(qty: existing.qty + 1);
    } else {
      _cart[product.id] = product.copyWith(qty: 1);
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void updateQty(int productId, int qty) {
    if (!_cart.containsKey(productId)) return;
    if (qty <= 0) {
      removeFromCart(productId);
      return;
    }
    _cart[productId] = _cart[productId]!.copyWith(qty: qty);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ---------------- WISHLIST ----------------
  final Map<int, Product> _wishlist = {};
  Set<int> get wishlistIds => _wishlist.keys.toSet();
  List<Product> get wishlistItems => _wishlist.values.toList();
  int get wishlistCount => _wishlist.length;

    void toggleWishlist(Product product) {
    if (_wishlist.containsKey(product.id)) {
      _wishlist.remove(product.id);
    } else {
      _wishlist[product.id] = product;
    }
    notifyListeners();
  }

  void addToWishlist(Product product) {
    _wishlist[product.id] = product;
    notifyListeners();
  }

  // ---------------- RECENTLY VIEWED ----------------
  final List<Product> _recentlyViewed = [];
  List<Product> get recentlyViewed => List.unmodifiable(_recentlyViewed);

  void addRecentlyViewed(Product product) {
    _recentlyViewed.removeWhere((p) => p.id == product.id);
    _recentlyViewed.insert(0, product);
    if (_recentlyViewed.length > 10) {
      _recentlyViewed.removeLast();
    }
    notifyListeners();
  }

  // ---------------- NOTIFICATIONS ----------------
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(
        _notifications..sort((a, b) => b.time.compareTo(a.time)),
      );
  int get unreadNotifCount => _notifications.where((n) => !n.read).length;

  void addNotification(String title, String message, {int? serverId}) {
    final id = serverId ?? DateTime.now().millisecondsSinceEpoch;
    if (_notifications.any((n) => n.id == id)) return;
    _notifications.add(
      AppNotification(
        id: id,
        title: title,
        message: message,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markNotificationRead(int index) {
    final sorted = notifications;
    final target = sorted[index];
    final n = _notifications.firstWhere((x) => x.id == target.id);
    n.read = true;
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  Future<void> loadNotificationsFromServer() async {
    // Example:
    // final res = await http.get(Uri.parse('https://YOUR-RAILWAY-URL/get_notifications.php'));
    // parse JSON -> _notifications.addAll(...) -> notifyListeners();
  }

    // ---------------- DELIVERY LOCATION ----------------
  String _deliveryLocation = 'Chennai';
  double? _deliveryLat;
  double? _deliveryLng;
  String _deliveryPincode = '';
  String? _deliveryAddressId;

  String get deliveryLocation => _deliveryLocation;
  double? get deliveryLat => _deliveryLat;
  double? get deliveryLng => _deliveryLng;
  String get deliveryPincode => _deliveryPincode;
  // Id of the saved ShopAddress currently used for delivery — used to
  // show the "Selected" chip against the matching card in the saved
  // addresses list (Flipkart-style).
  String? get deliveryAddressId => _deliveryAddressId;

  static const _kLocationKey = 'delivery_location';
  static const _kLatKey = 'delivery_lat';
  static const _kLngKey = 'delivery_lng';
  static const _kPincodeKey = 'delivery_pincode';
  static const _kAddressIdKey = 'delivery_address_id';

  Future<void> setDeliveryLocation(
    String location, {
    double? lat,
    double? lng,
    String? pincode,
    String? addressId,
  }) async {
    _deliveryLocation = location;
    _deliveryLat = lat;
    _deliveryLng = lng;
    if (pincode != null && pincode.trim().isNotEmpty) {
      _deliveryPincode = pincode.trim();
    }
    // addressId is passed explicitly (even as null) when the location was
    // NOT picked from a saved address (e.g. plain map pin), so the old
    // "Selected" chip doesn't stay stuck on a stale saved address. Only
    // skip updating it when the caller didn't mention addressId at all
    // is not distinguishable in Dart optional params, so callers should
    // always pass addressId (or an empty string) when relevant.
    _deliveryAddressId = addressId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocationKey, location);
    if (lat != null) await prefs.setDouble(_kLatKey, lat);
    if (lng != null) await prefs.setDouble(_kLngKey, lng);
    if (pincode != null && pincode.trim().isNotEmpty) {
      await prefs.setString(_kPincodeKey, pincode.trim());
    }
    if (addressId != null && addressId.trim().isNotEmpty) {
      await prefs.setString(_kAddressIdKey, addressId);
    } else {
      await prefs.remove(_kAddressIdKey);
    }
  }

  Future<void> loadSavedDeliveryLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocationKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _deliveryLocation = saved;
      _deliveryLat = prefs.getDouble(_kLatKey);
      _deliveryLng = prefs.getDouble(_kLngKey);
      _deliveryPincode = prefs.getString(_kPincodeKey) ?? '';
      _deliveryAddressId = prefs.getString(_kAddressIdKey);
      notifyListeners();
    }
  }

}