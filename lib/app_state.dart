import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// ---------------------------------------------------------------------
/// APP STATE — single source of truth for cart / wishlist / notifications
/// / delivery location / login / recently viewed.
///
/// Wishlist and cart are persisted locally so the same state is available
/// when the user moves between Home -> Shop -> Settings -> Product Details
/// and after restarting the app.
/// ---------------------------------------------------------------------
class AppState extends ChangeNotifier {
  AppState._internal() {
    _restorePersistentState();
  }

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

  // Persistent cart / wishlist keys.
  static const _kCartKey = 'sumathi_cart_products';
  static const _kWishlistKey = 'sumathi_wishlist_products';

  Future<void> login({
    required String userId,
    required String userName,
  }) async {
    _isLoggedIn = true;
    _userId = userId;
    _userName = userName;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserIdKey, userId);
    await prefs.setString(_kUserNameKey, userName);

    // Restore again after login in case the app was opened before the
    // SharedPreferences read completed.
    await _restorePersistentState();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    _userName = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserIdKey);
    await prefs.remove(_kUserNameKey);

    // Keep cart/wishlist locally available after logout. This matches the
    // app's current local-state behaviour and prevents accidental loss.
  }

  Future<void> loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final savedId = prefs.getString(_kUserIdKey);
    final savedName = prefs.getString(_kUserNameKey);

    if (savedId != null && savedId.trim().isNotEmpty) {
      _isLoggedIn = true;
      _userId = savedId;
      _userName = savedName;
    }

    await _restorePersistentState();
    notifyListeners();
  }

  // ---------------- CART ----------------
  final Map<int, Product> _cart = {};

  List<Product> get cartItems => _cart.values.toList(growable: false);

  int get cartCount =>
      _cart.values.fold(0, (sum, p) => sum + p.qty);

  double get cartTotal =>
      _cart.values.fold(0.0, (sum, p) => sum + (p.price * p.qty));

  void addToCart(Product product) {
    final existing = _cart[product.id];

    if (existing != null) {
      _cart[product.id] = existing.copyWith(
        qty: existing.qty + 1,
      );
    } else {
      _cart[product.id] = product.copyWith(qty: 1);
    }

    _saveCart();
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.remove(productId);
    _saveCart();
    notifyListeners();
  }

  void updateQty(int productId, int qty) {
    if (!_cart.containsKey(productId)) return;

    if (qty <= 0) {
      _cart.remove(productId);
    } else {
      _cart[productId] = _cart[productId]!.copyWith(qty: qty);
    }

    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _saveCart();
    notifyListeners();
  }

  // ---------------- WISHLIST ----------------
  final Map<int, Product> _wishlist = {};

  Set<int> get wishlistIds => _wishlist.keys.toSet();

  List<Product> get wishlistItems =>
      _wishlist.values.toList(growable: false);

  int get wishlistCount => _wishlist.length;

  /// Adds/removes the complete Product object, not just its ID.
  ///
  /// This is important because Settings -> My Wishlist opens the same
  /// ProductDetailsPage and therefore needs the product's image,
  /// description and highlights too.
  void toggleWishlist(Product product) {
    if (_wishlist.containsKey(product.id)) {
      _wishlist.remove(product.id);
    } else {
      _wishlist[product.id] = product;
    }

    _saveWishlist();
    notifyListeners();
  }

  void addToWishlist(Product product) {
    _wishlist[product.id] = product;
    _saveWishlist();
    notifyListeners();
  }

  void removeFromWishlist(int productId) {
    _wishlist.remove(productId);
    _saveWishlist();
    notifyListeners();
  }

  /// If the same product is received later with fresh admin data,
  /// update the stored wishlist copy without changing its wishlisted state.
  void refreshWishlistProduct(Product product) {
    if (!_wishlist.containsKey(product.id)) return;

    _wishlist[product.id] = product;
    _saveWishlist();
    notifyListeners();
  }

  // ---------------- PERSISTENCE ----------------

  Future<void> _restorePersistentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final wishlistJson = prefs.getString(_kWishlistKey);
      if (wishlistJson != null && wishlistJson.isNotEmpty) {
        final decoded = jsonDecode(wishlistJson);

        if (decoded is List) {
          _wishlist.clear();

          for (final raw in decoded) {
            final product = _productFromJson(raw);
            if (product != null) {
              _wishlist[product.id] = product;
            }
          }
        }
      }

      final cartJson = prefs.getString(_kCartKey);
      if (cartJson != null && cartJson.isNotEmpty) {
        final decoded = jsonDecode(cartJson);

        if (decoded is List) {
          _cart.clear();

          for (final raw in decoded) {
            final product = _productFromJson(raw);
            if (product != null) {
              _cart[product.id] = product;
            }
          }
        }
      }
    } catch (_) {
      // Corrupt/old local data must never stop the app from opening.
    }
  }

  Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = _wishlist.values
          .map(_productToJson)
          .toList(growable: false);

      await prefs.setString(_kWishlistKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = _cart.values
          .map(_productToJson)
          .toList(growable: false);

      await prefs.setString(_kCartKey, jsonEncode(data));
    } catch (_) {}
  }

  Map<String, dynamic> _productToJson(Product p) {
    return <String, dynamic>{
      'id': p.id,
      'name': p.name,
      'price': p.price,
      'image': p.image,
      'rating': p.rating,
      'qty': p.qty,
      'description': p.description,
      'highlights': p.highlights,
    };
  }

  Product? _productFromJson(dynamic raw) {
    if (raw is! Map) return null;

    try {
      final id = _toInt(raw['id']);
      if (id == null) return null;

      final name = raw['name']?.toString() ?? '';
      final image = raw['image']?.toString() ?? '';

      final highlightsRaw = raw['highlights'];
      final highlights = <String>[];

      if (highlightsRaw is List) {
        for (final item in highlightsRaw) {
          final value = item.toString().trim();
          if (value.isNotEmpty) highlights.add(value);
        }
      } else if (highlightsRaw is String &&
          highlightsRaw.trim().isNotEmpty) {
        highlights.addAll(
          highlightsRaw
              .split(RegExp(r'[\n,]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty),
        );
      }

      return Product(
        id: id,
        name: name,
        price: _toDouble(raw['price']),
        image: image,
        rating: _toDouble(raw['rating'], fallback: 4.5),
        qty: _toInt(raw['qty']) ?? 1,
        description: raw['description']?.toString() ?? '',
        highlights: highlights,
      );
    } catch (_) {
      return null;
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  // ---------------- RECENTLY VIEWED ----------------
  final List<Product> _recentlyViewed = [];

  List<Product> get recentlyViewed =>
      List.unmodifiable(_recentlyViewed);

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
        _notifications..sort(
            (a, b) => b.time.compareTo(a.time),
          ),
      );

  int get unreadNotifCount =>
      _notifications.where((n) => !n.read).length;

  void addNotification(
    String title,
    String message, {
    int? serverId,
  }) {
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
    if (index < 0 || index >= sorted.length) return;

    final target = sorted[index];

    final n = _notifications.firstWhere(
      (x) => x.id == target.id,
    );

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
    // final res = await http.get(
    //   Uri.parse('https://YOUR-RAILWAY-URL/get_notifications.php'),
    // );
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

    _deliveryAddressId = addressId;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kLocationKey, location);

    if (lat != null) {
      await prefs.setDouble(_kLatKey, lat);
    }

    if (lng != null) {
      await prefs.setDouble(_kLngKey, lng);
    }

    if (pincode != null && pincode.trim().isNotEmpty) {
      await prefs.setString(
        _kPincodeKey,
        pincode.trim(),
      );
    }

    if (addressId != null && addressId.trim().isNotEmpty) {
      await prefs.setString(
        _kAddressIdKey,
        addressId,
      );
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
      _deliveryPincode =
          prefs.getString(_kPincodeKey) ?? '';
      _deliveryAddressId =
          prefs.getString(_kAddressIdKey);

      notifyListeners();
    }
  }
}
