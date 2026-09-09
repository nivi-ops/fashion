// api_service.dart
// Handles all data operations for Sumathi's Styles.
// Product fetching, notifications, product upload, and FCM token saving
// now talk to Firebase (Cloud Firestore) instead of the old Railway/PHP
// backend. No baseUrl / http calls needed anymore for these flows.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'app_state.dart';

/// A tailoring/stitching service offered by the shop.
class StitchingService {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final List<String> highlights;

  const StitchingService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.highlights = const [],
  });
}

/// A saved customer address (pickup/delivery for measurements or orders).
class ShopAddress {
  final String id;
  final String label;
  final String addressLine;
  final String city;
  final String pincode;
  final String? phone;
  final double? latitude;
  final double? longitude;

  const ShopAddress({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    required this.pincode,
    this.phone,
    this.latitude,
    this.longitude,
  });
}

/// A customer order for one or more stitching services.
class TailoringOrder {
  final String id;
  final String serviceName;
  final DateTime orderDate;
  final String status;
  final double amount;

  const TailoringOrder({
    required this.id,
    required this.serviceName,
    required this.orderDate,
    required this.status,
    required this.amount,
  });
}

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- MOCK DATA (still used for services/addresses/orders
  // until those flows are wired to Firestore too) ----------------

     

  static final List<TailoringOrder> _mockOrders = [
    TailoringOrder(
      id: 'o1',
      serviceName: 'Blouse Stitching',
      orderDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'In Progress',
      amount: 450,
    ),
    TailoringOrder(
      id: 'o2',
      serviceName: 'Saree Fall & Pico',
      orderDate: DateTime.now().subtract(const Duration(days: 12)),
      status: 'Delivered',
      amount: 150,
    ),
  ];

  // ---------------- Small shared helper ----------------

  /// Reads a Firestore `highlights` field (a List of dynamic) into a
  /// clean List<String>, dropping any blank entries. Returns an empty
  /// list when the field is missing/not a List, so callers never need
  /// to null-check.
      static List<String> _parseHighlights(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Returns the logged-in user's id if available, otherwise falls back
  /// to a persistent per-device guest id (saved once in SharedPreferences)
  /// so address saving still works before login is implemented.
  static Future<String> _resolveUserId() async {
    final loggedInId = AppState.instance.userId;
    if (loggedInId != null && loggedInId.isNotEmpty) {
      return loggedInId;
    }

    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString('ss_guest_id');
    if (guestId == null || guestId.isEmpty) {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('ss_guest_id', guestId);
    }
    return guestId;
  }

  // ---------------- INSTANCE METHODS (used by shop_page.dart) ----------------

    Future<List<StitchingService>> getServices({String? category}) async {
    try {
      final snap = await _db.collection('products').get();

      final visibleDocs = snap.docs.where((doc) {
        final v = doc.data()['visible'];
        return v == 'yes' || v == true;
      });

      var services = visibleDocs.map<StitchingService>((doc) {
        final item = doc.data();

        final photos = item['photos'];
        String image = '';
        if (photos is List && photos.isNotEmpty) {
          image = photos.first.toString();
        } else {
          image = item['image_url']?.toString() ??
              item['photo']?.toString() ??
              '';
        }

        return StitchingService(
          id: doc.id,
          name: item['name']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          price: double.tryParse('${item['price'] ?? 0}') ?? 0,
          imageUrl: image,
          category: item['category']?.toString() ??
              item['cat']?.toString() ??
              'Other',
          highlights: _parseHighlights(item['highlights']),
        );
      }).toList();

      if (category != null && category != 'All') {
        services = services.where((s) => s.category == category).toList();
      }

      return services;
    } catch (e) {
      // ignore: avoid_print
      print('❌ getServices error: $e');
      return [];
    }
  }

     Future<StitchingService?> getServiceById(String id) async {
    try {
      final doc = await _db.collection('products').doc(id).get();
      if (!doc.exists) return null;
      final item = doc.data()!;

      final photos = item['photos'];
      String image = '';
      if (photos is List && photos.isNotEmpty) {
        image = photos.first.toString();
      } else {
        image = item['image_url']?.toString() ??
            item['photo']?.toString() ??
            '';
      }

      return StitchingService(
        id: doc.id,
        name: item['name']?.toString() ?? '',
        description: item['description']?.toString() ?? '',
        price: double.tryParse('${item['price'] ?? 0}') ?? 0,
        imageUrl: image,
        category: item['category']?.toString() ??
            item['cat']?.toString() ??
            'Other',
        highlights: _parseHighlights(item['highlights']),
      );
    } catch (_) {
      return null;
    }
  }

        Future<List<ShopAddress>> getAddresses() async {
    try {
      final userId = await _resolveUserId();

      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('created_at', descending: true)
          .get();

      return snap.docs.map((doc) {
        final item = doc.data();
        return ShopAddress(
          id: doc.id,
          label: item['label']?.toString() ?? 'Other',
          addressLine: item['address_line']?.toString() ?? '',
          city: item['city']?.toString() ?? '',
          pincode: item['pincode']?.toString() ?? '',
          phone: item['phone']?.toString(),
          latitude: (item['latitude'] as num?)?.toDouble(),
          longitude: (item['longitude'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ getAddresses error: $e');
      return [];
    }
  }

     Future<ShopAddress> addAddress(ShopAddress address) async {
    final userId = await _resolveUserId();

    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .set({
      'label': address.label,
      'address_line': address.addressLine,
      'city': address.city,
      'pincode': address.pincode,
      'phone': address.phone,
      'latitude': address.latitude,
      'longitude': address.longitude,
      'created_at': FieldValue.serverTimestamp(),
    });

    return address;
  }

  /// Updates an existing saved address (matched by id) — used by the
  /// "Edit" option in the delivery-address 3-dot menu and by the map
  /// picker's "Update pin and proceed" when editing.
   Future<ShopAddress> updateAddress(ShopAddress address) async {
    final userId = await _resolveUserId();

    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .set({
      'label': address.label,
      'address_line': address.addressLine,
      'city': address.city,
      'pincode': address.pincode,
      'phone': address.phone,
      'latitude': address.latitude,
      'longitude': address.longitude,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return address;
  }

  /// Deletes a saved address by id — used by the "Delete" option in the
  /// delivery-address 3-dot menu.
    Future<void> deleteAddress(String id) async {
    final userId = await _resolveUserId();

    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(id)
        .delete();
  }

  Future<List<TailoringOrder>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_mockOrders);
  }

  Future<TailoringOrder> placeOrder({
    required String serviceName,
    required double amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final order = TailoringOrder(
      id: 'o${_mockOrders.length + 1}',
      serviceName: serviceName,
      orderDate: DateTime.now(),
      status: 'Pending',
      amount: amount,
    );
    _mockOrders.insert(0, order);
    return order;
  }

  // ---------------- STATIC METHODS (used by home_page.dart) ----------------

  /// Fetches real products from Firestore's `products` collection
  /// (uploaded via the admin dashboard). Only products marked visible
  /// to customers are returned. Falls back to an empty list on any
  /// error, so the UI's existing "no products" placeholder logic still
  /// applies.
    static Future<List<Product>> fetchProducts() async {
    try {
      // Fetch ALL products, then filter client-side so both string 'yes'
      // and boolean true (older/inconsistent entries) count as visible —
      // matching what the admin panel's own list already shows as
      // "✅ Visible".
      final snap = await _db.collection('products').get();

      final visibleDocs = snap.docs.where((doc) {
        final v = doc.data()['visible'];
        return v == 'yes' || v == true;
      });

      return visibleDocs.map<Product>((doc) {
        final item = doc.data();

        // Prefer the `photos` list (used by admin_page.dart's upload
        // flow) and fall back to image_url/photo (used by the older
        // uploadProduct() below), so any product — old or new — shows
        // its image correctly.
        final photos = item['photos'];
        String image = '';
        if (photos is List && photos.isNotEmpty) {
          image = photos.first.toString();
        } else {
          image = item['image_url']?.toString() ??
              item['photo']?.toString() ??
              '';
        }

        return Product(
          id: int.tryParse(doc.id) ?? doc.id.hashCode,
          name: item['name']?.toString() ?? '',
          price: double.tryParse('${item['price'] ?? 0}') ?? 0,
          image: image,
          rating: double.tryParse(item['rating']?.toString() ?? '') ?? 4.5,
          description: item['description']?.toString() ?? '',
          highlights: _parseHighlights(item['highlights']),
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ fetchProducts error: $e');
    }

    return [];
  }
  // ---------------- STATIC METHODS (used by notifications_page.dart) ----------------

  /// Fetches admin-broadcast notifications (matches admin.html broadcast
  /// feature) from Firestore's `notifications` collection.
  static Future<List<AppNotification>> fetchNotifications() async {
    try {
      final snap = await _db
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .get();

      return snap.docs.map<AppNotification>((doc) {
        final item = doc.data();
        final createdAt = item['created_at'];
        DateTime time;
        if (createdAt is Timestamp) {
          time = createdAt.toDate();
        } else {
          time = DateTime.tryParse(createdAt?.toString() ?? '') ??
              DateTime.now();
        }
        return AppNotification(
          id: int.tryParse(doc.id) ?? doc.id.hashCode,
          title: item['title']?.toString() ?? '',
          message: item['message']?.toString() ?? '',
          time: time,
        );
      }).toList();
    } catch (_) {
      // Network/parse error — fall through to empty list below.
    }

    return [];
  }

  // ---------------- STATIC METHODS (used by product_upload_page.dart, admin side) ----------------

  /// Uploads a new product from the admin panel into Firestore's
  /// `products` collection. Returns a map with `success` (bool) and
  /// `message` (String) so the UI can show a success/error banner, plus
  /// `product_id` on success.
  ///
  /// `highlights` — list of highlight strings (e.g. ["Pure cotton", "Hand embroidered"])
  /// `priceTags`  — list of maps like {"tag": "S", "price": "400"} for size/type variations
  /// `imageUrl`   — should be a Firebase Storage download URL (upload the
  ///                photo to Storage first, then pass its URL here).
  static Future<Map<String, dynamic>> uploadProduct({
    required String name,
    required String category,
    required String description,
    List<String> highlights = const [],
    List<Map<String, String>> priceTags = const [],
    double price = 0,
    String stockStatus = 'Available',
    String visible = 'yes',
    String imageUrl = '',
  }) async {
    try {
      final doc = await _db.collection('products').add({
        'name': name,
        'category': category,
        'description': description,
        'highlights': highlights,
        'price_tags': priceTags,
        'price': price,
        'stock': stockStatus,
        'visible': visible,
        'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {
        'status': 'success',
        'success': true,
        'message': 'Product uploaded successfully',
        'product_id': doc.id,
      };
    } catch (e) {
      return {
        'status': 'error',
        'success': false,
        'message': 'Upload failed: $e',
      };
    }
  }

  // ---------------- STATIC METHODS (used by notification_service.dart) ----------------

  /// Saves this device's FCM token in Firestore so push notifications
  /// can be targeted to this user/device from the admin dashboard.
  /// Stored under users/{userId} with merge, so it doesn't wipe out
  /// other fields already saved for that user.
    static Future<void> saveFcmToken(String token) async {
    try {
      final userId = await _resolveUserId();

      await _db.collection('users').doc(userId).set({
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently ignore for now — token save failing shouldn't crash the app.
    }
  }
}