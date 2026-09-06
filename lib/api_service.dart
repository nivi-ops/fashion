// api_service.dart
// Handles all data operations for Sumathi's Styles.
// Product fetching, notifications, product upload, and FCM token saving
// now talk to Firebase (Cloud Firestore) instead of the old Railway/PHP
// backend. No baseUrl / http calls needed anymore for these flows.

import 'package:cloud_firestore/cloud_firestore.dart';
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

  const StitchingService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
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

  static final List<ShopAddress> _mockAddresses = [
    const ShopAddress(
      id: 'a1',
      label: 'Home',
      addressLine: '12, Gandhi Street',
      city: 'Chennai',
      pincode: '600001',
      latitude: 13.0827,
      longitude: 80.2707,
    ),
  ];

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
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<ShopAddress>> getAddresses() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_mockAddresses);
  }

  Future<ShopAddress> addAddress(ShopAddress address) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _mockAddresses.add(address);
    return address;
  }

  /// Updates an existing saved address (matched by id) — used by the
  /// "Edit" option in the delivery-address 3-dot menu and by the map
  /// picker's "Update pin and proceed" when editing.
  ///
  /// NOTE: this still follows the in-memory mock pattern, since addresses
  /// aren't wired to Firestore yet. When you're ready, swap the body below
  /// for a `_db.collection('addresses').doc(address.id).set(...)` call the
  /// same way fetchProducts below now uses Firestore.
  Future<ShopAddress> updateAddress(ShopAddress address) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockAddresses.indexWhere((a) => a.id == address.id);
    if (index == -1) {
      // Address wasn't found (shouldn't normally happen) — add it fresh
      // instead of silently failing.
      _mockAddresses.add(address);
    } else {
      _mockAddresses[index] = address;
    }
    return address;
  }

  /// Deletes a saved address by id — used by the "Delete" option in the
  /// delivery-address 3-dot menu.
  ///
  /// NOTE: same in-memory mock pattern as addAddress — swap for
  /// `_db.collection('addresses').doc(id).delete()` once that's wired up.
  Future<void> deleteAddress(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockAddresses.removeWhere((a) => a.id == id);
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
      final userId = AppState.instance.userId;
      if (userId == null || userId.isEmpty) return;

      await _db.collection('users').doc(userId).set({
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently ignore for now — token save failing shouldn't crash the app.
    }
  }
}