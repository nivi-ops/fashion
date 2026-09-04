// api_service.dart
// Handles all data operations for Sumathi's Styles.
// Product fetching, notifications, and FCM token saving now call the
// real PHP backend. Only fill in `baseUrl` below with your actual
// Railway/InfinityFree URL — everything else is already wired.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'app_state.dart';

/// -----------------------------------------------------------------
/// IMPORTANT: set this ONCE to your real backend URL.
/// Example: 'https://sumathistyles.up.railway.app'
/// Do NOT add a trailing slash.
/// -----------------------------------------------------------------
const String baseUrl = 'http://192.168.1.5/fashion/backend';

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

  // ---------------- MOCK DATA (still used for services/addresses/orders
  // until those flows are wired to the backend too) ----------------

  static final List<StitchingService> _mockServices = [
    const StitchingService(
      id: 's1',
      name: 'Blouse Stitching',
      description: 'Custom-fit blouse stitching with your choice of design.',
      price: 450,
      imageUrl: 'https://picsum.photos/seed/blouse/400/300',
      category: 'Blouse',
    ),
    const StitchingService(
      id: 's2',
      name: 'Saree Fall & Pico',
      description: 'Neat fall stitching and pico edging for your saree.',
      price: 150,
      imageUrl: 'https://picsum.photos/seed/saree/400/300',
      category: 'Saree',
    ),
    const StitchingService(
      id: 's3',
      name: 'Suit / Salwar Stitching',
      description: 'Complete salwar suit stitching, made to measure.',
      price: 700,
      imageUrl: 'https://picsum.photos/seed/suit/400/300',
      category: 'Suit',
    ),
    const StitchingService(
      id: 's4',
      name: 'Alterations',
      description: 'Quick alterations for length, fit, and repairs.',
      price: 200,
      imageUrl: 'https://picsum.photos/seed/alter/400/300',
      category: 'Alteration',
    ),
    const StitchingService(
      id: 's5',
      name: 'Custom Design Stitching',
      description: 'Bring your own design or reference photo to life.',
      price: 1200,
      imageUrl: 'https://picsum.photos/seed/custom/400/300',
      category: 'Custom',
    ),
  ];

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
    await Future.delayed(const Duration(milliseconds: 500));
    if (category == null || category == 'All') return _mockServices;
    return _mockServices.where((s) => s.category == category).toList();
  }

  Future<StitchingService?> getServiceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockServices.firstWhere((s) => s.id == id);
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
  /// NOTE: this follows the same in-memory mock pattern as addAddress
  /// above, since addresses aren't wired to the PHP backend yet. When
  /// you add a real endpoint (e.g. update_address.php), swap the body
  /// below for an http.post call the same way fetchProducts does.
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
  /// NOTE: same in-memory mock pattern as addAddress — swap for a real
  /// backend call (e.g. delete_address.php) once that endpoint exists.
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

  /// Fetches real products from the PHP/MySQL backend (uploaded via the
  /// admin dashboard). Falls back to an empty list if the request fails,
  /// so the UI's existing "no products" placeholder logic still applies.
  static Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_products.php'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map<Product>((item) {
          return Product(
            id: int.tryParse(item['id'].toString()) ?? 0,
            name: item['name']?.toString() ?? '',
            price: double.tryParse(item['price'].toString()) ?? 0,
            image: item['image_url']?.toString() ?? '',
            rating: double.tryParse(item['rating']?.toString() ?? '') ?? 4.5,
          );
        }).toList();
      }
    } catch (_) {
      // Network/parse error — fall through to empty list below.
    }

    return [];
  }

  // ---------------- STATIC METHODS (used by notifications_page.dart) ----------------

  /// Fetches admin-broadcast notifications (matches admin.html broadcast
  /// feature) from the real backend.
  static Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_notifications.php'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map<AppNotification>((item) {
          return AppNotification(
            id: int.tryParse(item['id'].toString()) ?? 0,
            title: item['title']?.toString() ?? '',
            message: item['message']?.toString() ?? '',
            time: DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {
      // Network/parse error — fall through to empty list below.
    }

    return [];
  }

  // ---------------- STATIC METHODS (used by product_upload_page.dart, admin side) ----------------

  /// Uploads a new product from the admin panel to the PHP/MySQL backend
  /// (upload_product.php). Returns a map with `success` (bool) and
  /// `message` (String) so the UI can show a success/error banner, plus
  /// `product_id` on success.
  ///
  /// `highlights` — list of highlight strings (e.g. ["Pure cotton", "Hand embroidered"])
  /// `priceTags`  — list of maps like {"tag": "S", "price": "400"} for size/type variations
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
      final response = await http.post(
        Uri.parse('$baseUrl/upload_product.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'category': category,
          'description': description,
          'highlights': highlights,
          'price_tags': priceTags,
          'price': price,
          'stock_status': stockStatus,
          'visible': visible,
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: $e',
      };
    }
  }

  // ---------------- STATIC METHODS (used by notification_service.dart) ----------------

  /// Sends this device's FCM token to the backend so push notifications
  /// can be targeted to this user/device from the admin dashboard.
  static Future<void> saveFcmToken(String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/save_fcm_token.php'),
        body: {
          'user_id': AppState.instance.userId ?? '',
          'fcm_token': token,
        },
      );
    } catch (e) {
      // Silently ignore for now — token save failing shouldn't crash the app.
    }
  }
}