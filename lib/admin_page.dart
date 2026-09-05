import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Flutter conversion of the supplied "Sumathi's Styles – Admin Dashboard".
/// The login screen matches admin.html: black top bar ("Admin Login"),
/// blue shield icon with a person badge, "Admin Panel" title, plain
/// bordered Email/Password fields, and a full-width blue pill LOGIN button.
///
/// NOW CONNECTED TO FIREBASE (Firestore + Storage) instead of the
/// Railway/PHP backend. Collections used:
///   products            — product catalogue (name, category, price,
///                          description, stock, visible, highlights,
///                          price_tags, photos [list of Storage URLs])
///   orders              — both normal orders and customized orders
///                          (distinguished by the `source` field, e.g.
///                          'custom-order')
///   contacts            — boutique + catering contact form submissions
///   notifications       — admin broadcast notifications
///   customer_requests   — data-export / grievance / deactivated /
///                          deleted-account requests, distinguished by
///                          a `type` field
///
/// Add to pubspec.yaml:
///   cloud_firestore: ^5.6.12
///   firebase_storage: ^12.3.2
///   image_picker: ^1.1.2
///   shared_preferences: ^2.5.5
///
/// Put this file at: lib/admin_page.dart

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const String adminEmail = 'admin@sumathisssstyles.com';
  static const String adminPass = 'sumathiaccount@1999';
  // ignore: unused_field
  static const String waNumber = '919876543210';

  final Color teal = const Color(0xFF00897B);
  final Color tealDark = const Color(0xFF00695C);
  final Color tealLight = const Color(0xFFE0F2F1);
  final Color copper = const Color(0xFFB87333);
  final Color copperLight = const Color(0xFFFFF8E1);
  final Color pageBg = const Color(0xFFF5F7FA);
  final Color sidebar = const Color(0xFF004D40);
  final Color danger = const Color(0xFFE53935);
  final Color success = const Color(0xFF43A047);
  final Color warning = const Color(0xFFFB8C00);
  final Color border = const Color(0xFFE0E0E0);
  final Color muted = const Color(0xFF757575);
  final Color loginBlue = const Color(0xFF2400F5);
  final Color loginBlueDark = const Color(0xFF1A00C9);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loggedIn = false;
  bool loading = false;
  bool mobilePageMode = false;
  String currentPage = 'dashboard';
  String loginError = '';
  String toastMessage = '';
  DateTime? toastUntil;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> dataRequests = [];
  List<Map<String, dynamic>> grievances = [];
  List<Map<String, dynamic>> deactivated = [];
  List<Map<String, dynamic>> deletedAccounts = [];

  String? selectedCustomerPhone;
  String? selectedCustomerName;

  final TextEditingController productSearch = TextEditingController();
  final TextEditingController orderSearch = TextEditingController();
  final TextEditingController customSearch = TextEditingController();
  final TextEditingController boutiqueSearch = TextEditingController();
  final TextEditingController cateringSearch = TextEditingController();
  final TextEditingController dataSearch = TextEditingController();
  final TextEditingController grievanceSearch = TextEditingController();
  final TextEditingController cancellationSearch = TextEditingController();

  String productCategory = '';
  String productStock = '';
  String orderStatus = '';
  String grievanceStatus = '';

  final TextEditingController pName = TextEditingController();
  final TextEditingController pPrice = TextEditingController();
  final TextEditingController pDesc = TextEditingController();
  String pCategory = '';
  String pStock = 'Available';
  String pVisible = 'yes';
    List<XFile> uploadedPhotos = [];
  final TextEditingController pImageUrl = TextEditingController();
  List<TextEditingController> highlightControllers = [TextEditingController()];
  List<TextEditingController> priceTagControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final TextEditingController notificationTitle = TextEditingController();
  final TextEditingController notificationMessage = TextEditingController();
  String notificationType = 'general';

  @override
  void initState() {
    super.initState();
    _restoreLogin();
  }

  @override
  void dispose() {
    for (final c in [
      emailController,
      passwordController,
      productSearch,
      orderSearch,
      customSearch,
      boutiqueSearch,
      cateringSearch,
      dataSearch,
      grievanceSearch,
      cancellationSearch,
      pName,
      pPrice,
      pDesc,
      pImageUrl,
      notificationTitle,
      notificationMessage,
    ]) {
      c.dispose();
    }
    for (final c in highlightControllers) c.dispose();
    for (final c in priceTagControllers) c.dispose();
    super.dispose();
  }

  Future<void> _restoreLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ss_admin_logged') == true) {
      setState(() => loggedIn = true);
      await initDashboard();
    }
  }

  Future<void> doLogin() async {
    final e = emailController.text.trim();
    final p = passwordController.text.trim();

    if (e == adminEmail && p == adminPass) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ss_admin_logged', true);
      setState(() {
        loggedIn = true;
        loginError = '';
      });
      await initDashboard();
    } else {
      setState(() => loginError = '❌ Wrong email or password');
    }
  }

  Future<void> doLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ss_admin_logged');
    setState(() {
      loggedIn = false;
      currentPage = 'dashboard';
      mobilePageMode = false;
      emailController.clear();
      passwordController.clear();
    });
  }

  Future<void> initDashboard() async {
    await refreshDashboard();
    await loadContacts();
    await loadNotifications();
    await loadCustomerRequests();
  }

  Future<void> refreshDashboard() async {
    final loadedProducts = await loadProductsFromServer();
    final loadedOrders = await loadOrdersFromServer();
    if (!mounted) return;
    setState(() {
      products = loadedProducts;
      orders = loadedOrders;
    });
  }

  // ---------------- FIRESTORE READS ----------------

  Future<List<Map<String, dynamic>>> loadOrdersFromServer() async {
    try {
      final snap = await _db.collection('orders').get();
      final mapped = snap.docs.map<Map<String, dynamic>>((doc) {
        final m = doc.data();
        final createdAt = m['created_at'];
        DateTime? created;
        if (createdAt is Timestamp) created = createdAt.toDate();
        final shortId =
            doc.id.length > 6 ? doc.id.substring(0, 6) : doc.id;
        return {
          'id': doc.id,
          'orderId': '#${shortId.toUpperCase()}',
          'name': m['name'] ?? '',
          'mobile': m['mobile'] ?? '',
          'product': m['product'] ?? '',
          'amount': num.tryParse('${m['amount'] ?? 0}') ?? 0,
          'status': m['status'] ?? 'Ordered',
          'date': created != null
              ? formatDate(created.toIso8601String())
              : '',
          'source': m['source'] ?? 'website',
          'measurement': m['measurement'] ?? '',
          'voiceNote': m['voice_note'] ?? '',
          'notes': m['notes'] ?? '',
          'cancelReason': m['cancel_reason'] ?? '',
          'paymentMethod': m['payment_method'] ?? 'N/A',
          'paymentStatus': m['payment_status'] ?? 'Not Required',
        };
      }).toList();
      // Keep a stable order — newest last, so `.reversed` (used all over
      // this file) shows the newest first, matching the old behaviour.
      mapped.sort((a, b) => '${a['date']}'.compareTo('${b['date']}'));
      return mapped;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadProductsFromServer() async {
    try {
      final snap = await _db.collection('products').get();
      return snap.docs.map<Map<String, dynamic>>((doc) {
        final m = doc.data();
        final photos = m['photos'] is List
            ? List<dynamic>.from(m['photos'])
            : (m['image_url'] != null && '${m['image_url']}'.isNotEmpty
                ? [m['image_url']]
                : <dynamic>[]);
        return {
          'id': doc.id,
          'name': m['name'] ?? '',
          'cat': m['category'] ?? m['cat'] ?? 'Other',
          'category': m['category'] ?? m['cat'] ?? 'Other',
          'price': num.tryParse('${m['price'] ?? 0}') ?? 0,
          'desc': m['description'] ?? '',
          'description': m['description'] ?? '',
          'stock': m['stock'] ?? 'Available',
          'visible': (m['visible'] == 'yes' || m['visible'] == true)
              ? 'yes'
              : 'no',
          'photos': photos,
          'photo': photos.isNotEmpty ? photos.first : '',
          'highlights':
              m['highlights'] is List ? List<dynamic>.from(m['highlights']) : [],
          'priceTags': m['price_tags'] is List
              ? List<dynamic>.from(m['price_tags'])
              : [],
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> loadContacts() async {
    try {
      final snap = await _db.collection('contacts').get();
      contacts = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        final createdAt = m['created_at'];
        if (createdAt is Timestamp) {
          m['created_at'] = createdAt.toDate().toIso8601String();
        }
        return m;
      }).toList();
    } catch (_) {
      contacts = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> loadNotifications() async {
    try {
      final snap = await _db.collection('notifications').get();
      final list = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        final createdAt = m['created_at'];
        if (createdAt is Timestamp) {
          m['created_at'] = createdAt.toDate().toIso8601String();
        }
        return m;
      }).toList();
      list.sort((a, b) =>
          '${a['created_at']}'.compareTo('${b['created_at']}'));
      notifications = list;
    } catch (_) {
      notifications = [];
    }
    if (mounted) setState(() {});
  }

  Future<List<Map<String, dynamic>>> _customerRequestsByType(
    String type,
    String dateField,
  ) async {
    try {
      final snap = await _db
          .collection('customer_requests')
          .where('type', isEqualTo: type)
          .get();
      return snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        final ts = m[dateField];
        if (ts is Timestamp) m[dateField] = ts.toDate().toIso8601String();
        return m;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> loadCustomerRequests() async {
    dataRequests = await _customerRequestsByType('data_export', 'requested_at');
    grievances = await _customerRequestsByType('grievance', 'created_at');
    deactivated = await _customerRequestsByType('deactivated', 'deactivated_at');
    deletedAccounts =
        await _customerRequestsByType('deleted_account', 'deleted_at');
    if (mounted) setState(() {});
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    try {
      final d = DateTime.parse(value.toString()).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String formatDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    try {
      final d = DateTime.parse(value.toString()).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  void showToast(String msg) {
    setState(() {
      toastMessage = msg;
      toastUntil = DateTime.now().add(const Duration(seconds: 3));
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (toastUntil != null && DateTime.now().isAfter(toastUntil!)) {
        setState(() => toastMessage = '');
      }
    });
  }

  void showPage(String id) {
    setState(() {
      currentPage = id;
      if (id == 'contactform') {
        selectedCustomerPhone = null;
        selectedCustomerName = null;
      }
    });
    if (id == 'dashboard') refreshDashboard();
    if (id == 'products') loadProductsAndSet();
    if (id == 'ordersmgmt') loadOrdersAndSet();
    if (id == 'customorder') loadOrdersAndSet();
    if (id == 'contactform') {
      loadContacts();
      loadOrdersAndSet();
    }
    if (id == 'contactform2') loadContacts();
    if (id == 'notifications') loadNotifications();
    if (id == 'datarequests') loadCustomerRequests();
  }

  Future<void> loadProductsAndSet() async {
    final p = await loadProductsFromServer();
    if (mounted) setState(() => products = p);
  }

  Future<void> loadOrdersAndSet() async {
    final o = await loadOrdersFromServer();
    if (mounted) setState(() => orders = o);
  }

  bool isCatering(Map<String, dynamic> c) {
    final service = '${c['service'] ?? ''}'.toLowerCase();
    final formType =
        '${c['form_type'] ?? c['type'] ?? c['page'] ?? c['source'] ?? ''}'
            .toLowerCase();
    if (formType.contains('boutique') || service.contains('boutique')) return false;
    if (formType.contains('catering') || service.contains('catering')) return true;
    const keys = [
      'catering',
      'food',
      'meal',
      'lunch',
      'dinner',
      'breakfast',
      'tiffin',
      'party food',
      'wedding food'
    ];
    final combined = '$service $formType';
    return keys.any(combined.contains);
  }

  List<Map<String, dynamic>> get boutiqueContacts =>
      contacts.where((c) => !isCatering(c)).toList();

  List<Map<String, dynamic>> get cateringContacts =>
      contacts.where(isCatering).toList();

  List<Map<String, dynamic>> get pendingOrders => orders
      .where((o) =>
          o['status'] == 'Ordered' ||
          o['status'] == 'Processing' ||
          o['status'] == 'Pending')
      .toList();

  List<Map<String, dynamic>> get deliveredOrders =>
      orders.where((o) => o['status'] == 'Delivered').toList();

  num get revenue =>
      deliveredOrders.fold<num>(0, (s, o) => s + (o['amount'] ?? 0));

  String titleFor(String id) {
    const map = {
      'dashboard': 'Dashboard',
      'upload': 'Product Upload',
      'products': 'All Products',
      'ordersmgmt': 'Orders',
      'customorder': 'Customized Order',
      'contactform': 'Customers',
      'contactform2': 'Catering Contact Form',
      'notifications': 'Send Notification',
      'datarequests': 'Request My Data / Grievance / De-act & Delete Acc',
      'revenue': 'Revenue',
    };
    return map[id] ?? 'Dashboard';
  }

  // ---------------- PRODUCT UPLOAD (Firestore + Storage) ----------------

  Future<void> uploadProduct() async {
    final name = pName.text.trim();
    final price = pPrice.text.trim();
    if (name.isEmpty || pCategory.isEmpty || price.isEmpty) {
      showToast('⚠️ Name, Category & Price are required!');
      return;
    }

    final highlights = highlightControllers
        .map((c) => c.text.trim())
        .where((x) => x.isNotEmpty)
        .toList();

    final priceTags = <Map<String, dynamic>>[];
    for (int i = 0; i + 1 < priceTagControllers.length; i += 2) {
      final label = priceTagControllers[i].text.trim();
      final value = priceTagControllers[i + 1].text.trim();
      if (label.isNotEmpty && value.isNotEmpty) {
        priceTags.add({'label': label, 'price': value});
      }
    }

        setState(() => loading = true);
    try {
      // Collect photo URLs from TWO sources:
      // 1) Any photos picked via the file picker (uploaded to Firebase
      //    Storage) — kept for when Storage billing is enabled later.
      // 2) A pasted image link (free — no Storage/billing needed).
      final List<String> photoUrls = [];

      for (final photo in uploadedPhotos) {
        try {
          final bytes = await photo.readAsBytes();
          final ref = FirebaseStorage.instance.ref(
            'product_photos/${DateTime.now().millisecondsSinceEpoch}_${photo.name}',
          );
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          photoUrls.add(await ref.getDownloadURL());
        } catch (e) {
          // Storage may not be enabled (Spark/free plan) — skip silently
          // so a pasted link can still be used instead.
        }
      }

      final pastedUrl = pImageUrl.text.trim();
      if (pastedUrl.isNotEmpty) {
        photoUrls.add(pastedUrl);
      }

      await _db.collection('products').add({
        'name': name,
        'category': pCategory,
        'cat': pCategory,
        'price': num.tryParse(price) ?? 0,
        'description': pDesc.text.trim(),
        'stock': pStock,
        'visible': pVisible,
        'highlights': highlights,
        'price_tags': priceTags,
        'photos': photoUrls,
        'image_url': photoUrls.isNotEmpty ? photoUrls.first : '',
        'created_at': FieldValue.serverTimestamp(),
      });

      products = await loadProductsFromServer();
      resetUploadForm();
      showToast('✅ Product uploaded successfully!');
    } catch (e) {
      showToast('❌ Upload failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickPhotos() async {
    final files = await picker.pickMultiImage(imageQuality: 60, maxWidth: 600, maxHeight: 600);
    if (files.isNotEmpty) {
      setState(() => uploadedPhotos.addAll(files));
    }
  }

    void resetUploadForm() {
    pName.clear();
    pPrice.clear();
    pDesc.clear();
    pImageUrl.clear();
    setState(() {
      pCategory = '';
      pStock = 'Available';
      pVisible = 'yes';
      uploadedPhotos.clear();
      for (final c in highlightControllers) c.dispose();
      for (final c in priceTagControllers) c.dispose();
      highlightControllers = [TextEditingController()];
      priceTagControllers = [TextEditingController(), TextEditingController()];
    });
  }

  // ---------------- PRODUCT ACTIONS ----------------

  Future<void> toggleVisible(String id, String visible) async {
    try {
      await _db.collection('products').doc(id).update({'visible': visible});
      products = await loadProductsFromServer();
      setState(() {});
      showToast('✅ Visibility updated');
    } catch (_) {
      showToast('❌ Server error');
    }
  }

  Future<void> deleteProduct(String id) async {
    final ok = await confirmDialog('Delete this product?');
    if (!ok) return;
    try {
      await _db.collection('products').doc(id).delete();
      products = await loadProductsFromServer();
      setState(() {});
      showToast('🗑️ Product deleted');
    } catch (_) {
      showToast('❌ Server error');
    }
  }

  // ---------------- ORDER ACTIONS ----------------

  Future<void> updateStatus(String id, String status) async {
    try {
      showToast('⏳ Updating status...');
      await _db.collection('orders').doc(id).update({'status': status});
      orders = await loadOrdersFromServer();
      setState(() {});
      showToast('✅ Status → $status');
    } catch (_) {
      showToast('❌ Server error while updating status');
    }
  }

  // ---------------- NOTIFICATIONS ----------------

  Future<void> sendNotification() async {
    final title = notificationTitle.text.trim();
    final message = notificationMessage.text.trim();
    if (title.isEmpty || message.isEmpty) {
      showToast('⚠️ Title & Message are required!');
      return;
    }
    try {
      showToast('⏳ Sending...');
      await _db.collection('notifications').add({
        'title': title,
        'message': message,
        'type': notificationType,
        'created_at': FieldValue.serverTimestamp(),
      });
      notificationTitle.clear();
      notificationMessage.clear();
      notificationType = 'general';
      await loadNotifications();
      showToast('✅ Notification sent to all customers!');
    } catch (_) {
      showToast('❌ Server error while sending notification');
    }
  }

  Future<void> deleteNotification(dynamic id) async {
    final ok = await confirmDialog('Delete this notification?');
    if (!ok) return;
    try {
      await _db.collection('notifications').doc('$id').delete();
      await loadNotifications();
      showToast('🗑️ Notification deleted');
    } catch (_) {
      showToast('❌ Server error');
    }
  }

  // ---------------- GRIEVANCES ----------------

  Future<void> markGrievance(dynamic id, String status) async {
    try {
      await _db
          .collection('customer_requests')
          .doc('$id')
          .update({'status': status});
      await loadCustomerRequests();
      showToast('✅ Complaint status → $status');
    } catch (_) {
      showToast('❌ Server error while updating complaint');
    }
  }

  // ---------------- CLEAR DATA (batched Firestore deletes) ----------------

  Future<void> _deleteAllInQuery(Query<Map<String, dynamic>> query) async {
    final snap = await query.get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> clearData(String target, String message) async {
    final ok = await confirmDialog(message);
    if (!ok) return;
    try {
      showToast('⏳ Clearing...');
      switch (target) {
        case 'all_demo_data':
          await _deleteAllInQuery(_db.collection('orders'));
          await _deleteAllInQuery(_db.collection('contacts'));
          break;
        case 'orders_all':
          await _deleteAllInQuery(_db.collection('orders'));
          break;
        case 'orders_custom':
          await _deleteAllInQuery(
            _db.collection('orders').where('source', isEqualTo: 'custom-order'),
          );
          break;
        case 'contacts_boutique':
          {
            final snap = await _db.collection('contacts').get();
            final batch = _db.batch();
            for (final doc in snap.docs) {
              if (!isCatering(doc.data())) batch.delete(doc.reference);
            }
            await batch.commit();
          }
          break;
        case 'contacts_catering':
          {
            final snap = await _db.collection('contacts').get();
            final batch = _db.batch();
            for (final doc in snap.docs) {
              if (isCatering(doc.data())) batch.delete(doc.reference);
            }
            await batch.commit();
          }
          break;
        case 'notifications_all':
          await _deleteAllInQuery(_db.collection('notifications'));
          break;
        case 'data_requests_all':
          await _deleteAllInQuery(
            _db.collection('customer_requests').where('type', isEqualTo: 'data_export'),
          );
          break;
        case 'grievances_all':
          await _deleteAllInQuery(
            _db.collection('customer_requests').where('type', isEqualTo: 'grievance'),
          );
          break;
        case 'deactivated_all':
          await _deleteAllInQuery(
            _db.collection('customer_requests').where('type', isEqualTo: 'deactivated'),
          );
          break;
        case 'deleted_accounts_all':
          await _deleteAllInQuery(
            _db.collection('customer_requests').where('type', isEqualTo: 'deleted_account'),
          );
          break;
      }
      await refreshDashboard();
      await loadContacts();
      await loadNotifications();
      await loadCustomerRequests();
      showToast('🗑️ Cleared successfully');
    } catch (e) {
      showToast('❌ Server error while clearing data: $e');
    }
  }

  Future<bool> confirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result == true;
  }

  List<Map<String, dynamic>> filteredProducts() {
    final s = productSearch.text.trim().toLowerCase();
    return products.where((p) {
      final okSearch = s.isEmpty ||
          '${p['name']}'.toLowerCase().contains(s) ||
          '${p['cat']}'.toLowerCase().contains(s);
      final okCat = productCategory.isEmpty || p['cat'] == productCategory;
      final okStock = productStock.isEmpty || p['stock'] == productStock;
      return okSearch && okCat && okStock;
    }).toList();
  }

  List<Map<String, dynamic>> filteredOrders() {
    final s = orderSearch.text.trim().toLowerCase().replaceFirst('#', '');
    return orders.where((o) {
      final okSearch = s.isEmpty ||
          '${o['name']}'.toLowerCase().contains(s) ||
          '${o['mobile']}'.contains(s) ||
          '${o['product']}'.toLowerCase().contains(s) ||
          '${o['orderId']}'.toLowerCase().replaceFirst('#', '').contains(s);
      final okStatus = orderStatus.isEmpty || o['status'] == orderStatus;
      return okSearch && okStatus;
    }).toList();
  }

  List<Map<String, dynamic>> customOrders() {
    final s = customSearch.text.trim().toLowerCase();
    return orders.where((o) {
      final source = '${o['source']}'.toLowerCase();
      final matchSource = source == 'custom-order';
      final matchSearch = s.isEmpty ||
          '${o['name']}'.toLowerCase().contains(s) ||
          '${o['mobile']}'.contains(s);
      return matchSource && matchSearch;
    }).toList();
  }

  List<Map<String, dynamic>> filteredContacts(bool catering) {
    final s = (catering ? cateringSearch.text : boutiqueSearch.text).trim().toLowerCase();
    final source = catering ? cateringContacts : boutiqueContacts;
    return source.where((c) {
      return s.isEmpty ||
          '${c['name'] ?? ''}'.toLowerCase().contains(s) ||
          '${c['phone'] ?? ''}'.contains(s) ||
          '${c['email'] ?? ''}'.toLowerCase().contains(s);
    }).toList();
  }

  Widget statCard(String value, String label, IconData icon, Color iconBg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: iconBg,
            child: Icon(icon, color: tealDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                Text(label, style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget mobileStatCard(String value, String label, String emoji, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: bg,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Full-width version of the stat card, used for the Pending Orders card
  /// so it doesn't sit alone as an odd, half-empty row in the 2-column grid.
  Widget mobileWideStatCard(String value, String label, String emoji, Color bg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: bg,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                Text(label, style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionCard(String title, Widget child, {Widget? action}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tealDark,
                    )),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget actionButton(String text, VoidCallback onPressed,
      {Color? color, Color? textColor, bool outline = false}) {
    return SizedBox(
      height: 40,
      child: outline
          ? OutlinedButton(onPressed: onPressed, child: Text(text))
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? teal,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onPressed,
              child: Text(text),
            ),
    );
  }

  Widget field(String label, TextEditingController controller,
      {String? hint, TextInputType? keyboard, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted)),
          const SizedBox(height: 5),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: teal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget dropdownField(String label, String value, List<String> values,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: values.contains(value) ? value : null,
          isExpanded: true,
          items: values
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget dashboardPage(bool mobile) {
    final pending = pendingOrders.length;
    final rev = revenue.toStringAsFixed(0);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: actionButton(
            '🗑️ Clear All Demo Data',
            () => clearData(
              'all_demo_data',
              '⚠️ This will delete ALL Orders + Boutique + Catering contact submissions '
              '(Products will not be touched). Do you want to continue?',
            ),
            color: danger,
          ),
        ),
        const SizedBox(height: 14),
        if (mobile) ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.0,
            children: [
              mobileStatCard('${orders.length}', 'Orders', '🛒', const Color(0xFFFFF3E0)),
              mobileStatCard('₹${num.tryParse(rev)?.toStringAsFixed(0) ?? rev}', 'Revenue', '₹', const Color(0xFFE8F5E9)),
              mobileStatCard('${products.length}', 'Products', '📦', tealLight),
              mobileStatCard('${deliveredOrders.length}', 'Delivered', '👥', const Color(0xFFE3F2FD)),
            ],
          ),
          const SizedBox(height: 14),
          mobileWideStatCard('$pending', 'Pending Orders', '⏳', const Color(0xFFFFEBEE)),
          const SizedBox(height: 14),
        ],
        if (!mobile) ...[
          LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth > 1100 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.8,
              children: [
                statCard('${orders.length}', 'Orders', Icons.shopping_cart, const Color(0xFFFFF3E0)),
                statCard('₹${revenue.toStringAsFixed(0)}', 'Revenue', Icons.currency_rupee, const Color(0xFFE8F5E9)),
                statCard('${products.length}', 'Products', Icons.inventory_2, tealLight),
                statCard('$pending', 'Pending', Icons.hourglass_empty, const Color(0xFFFFEBEE)),
              ],
            );
          }),
          const SizedBox(height: 22),
        ],
        if (mobile) ...[
          sectionCard('📈 Monthly Orders Chart', SizedBox(height: 200, child: SimpleChart(data: monthlyCounts(orders), bar: true, color: teal))),
          sectionCard('🍩 Order Status', SizedBox(height: 220, child: StatusChart(orders: orders))),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: sectionCard('📈 Monthly Orders Chart', SizedBox(height: 260, child: SimpleChart(data: monthlyCounts(orders), bar: true, color: teal)))),
              const SizedBox(width: 20),
              Expanded(child: sectionCard('🍩 Order Status', SizedBox(height: 260, child: StatusChart(orders: orders)))),
            ],
          ),
        sectionCard(
          '📋 Recent Orders',
          orderTable(orders.reversed.take(8).toList(), compact: true),
        ),
      ],
    );
  }

  List<int> monthlyCounts(List<Map<String, dynamic>> source) {
    final counts = List<int>.filled(12, 0);
    for (final o in source) {
      final d = '${o['date'] ?? ''}'.split('/');
      if (d.length >= 2) {
        final m = int.tryParse(d[1]);
        if (m != null && m >= 1 && m <= 12) counts[m - 1]++;
      }
    }
    return counts;
  }

  Widget uploadPage() {
    return sectionCard(
      '📤 Upload New Product',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRODUCT PHOTOS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
          const SizedBox(height: 8),
          InkWell(
            onTap: pickPhotos,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                border: Border.all(color: teal, width: 2),
                borderRadius: BorderRadius.circular(10),
                color: tealLight,
              ),
              child: Column(
                children: [
                  const Text('🖼️', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text('Click to Upload Photos',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: teal)),
                  Text('JPG, PNG, WEBP – Multiple files allowed',
                      style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            ),
          ),
                    if (uploadedPhotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(uploadedPhotos.length, (i) {
                return Stack(
                  children: [
                    FutureBuilder<Uint8List>(
                      future: uploadedPhotos[i].readAsBytes(),
                      builder: (_, snap) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: snap.hasData
                            ? Image.memory(snap.data!, fit: BoxFit.cover)
                            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: InkWell(
                        onTap: () => setState(() => uploadedPhotos.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.black54,
                          child: Text('✕', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('OR', style: TextStyle(fontSize: 11, color: Color(0xFF757575), fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 10),
          field(
            '🔗 Paste Image Link (e.g. from Imgur, Google Drive share link)',
            pImageUrl,
            hint: 'https://i.imgur.com/example.jpg',
          ),
          if (pImageUrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                pImageUrl.text.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: tealLight,
                  child: const Center(child: Text('❌ Invalid link', style: TextStyle(fontSize: 10))),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          LayoutBuilder(builder: (_, c) {
            final two = c.maxWidth > 650;
            final nameField = field('Product Name *', pName, hint: 'e.g. Bridal Blouse Stitching');
            final categoryField = dropdownField(
              'Category *',
              pCategory,
              ['All', 'Kids', 'Uniform', 'Modern', 'Salwar', 'Blouse', 'Aari', 'Saree', 'Frock', 'Lehenga', 'Kurthi'],
              (v) => setState(() => pCategory = v ?? ''),
            );
            final priceField = field('Price (₹) *', pPrice, hint: 'e.g. 1500', keyboard: TextInputType.number);
            final descField = field('Description', pDesc, hint: 'Short product description...', maxLines: 3);

            if (!two) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nameField,
                  const SizedBox(height: 14),
                  categoryField,
                  const SizedBox(height: 14),
                  priceField,
                  const SizedBox(height: 14),
                  descField,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 14),
                    Expanded(child: categoryField),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: priceField),
                    const SizedBox(width: 14),
                    Expanded(child: descField),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 18),
          Text('✨ PRODUCT HIGHLIGHTS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
          const SizedBox(height: 8),
          ...List.generate(highlightControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: field('', highlightControllers[i], hint: 'e.g. Premium quality fabric')),
                  IconButton(
                    color: danger,
                    onPressed: () {
                      if (highlightControllers.length > 1) {
                        setState(() {
                          highlightControllers[i].dispose();
                          highlightControllers.removeAt(i);
                        });
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
          OutlinedButton(
            onPressed: () => setState(() => highlightControllers.add(TextEditingController())),
            child: const Text('+ Add Highlight'),
          ),
          const SizedBox(height: 18),
          Text('🏷️ PRICE TAGS (size/type variations)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
          const SizedBox(height: 8),
          ...List.generate(priceTagControllers.length ~/ 2, (i) {
            final a = priceTagControllers[i * 2];
            final b = priceTagControllers[i * 2 + 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: field('', a, hint: 'Tag (e.g. Simple)')),
                  const SizedBox(width: 10),
                  Expanded(child: field('', b, hint: 'Price ₹', keyboard: TextInputType.number)),
                  IconButton(
                    color: danger,
                    onPressed: () {
                      if (priceTagControllers.length > 2) {
                        setState(() {
                          a.dispose();
                          b.dispose();
                          priceTagControllers.removeRange(i * 2, i * 2 + 2);
                        });
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
          OutlinedButton(
            onPressed: () => setState(() {
              priceTagControllers.add(TextEditingController());
              priceTagControllers.add(TextEditingController());
            }),
            child: const Text('+ Add Price Tag'),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (_, c) {
            final two = c.maxWidth > 650;
            final stockField = dropdownField('Stock Status', pStock, ['Available', 'Limited', 'Out of Stock'],
                (v) => setState(() => pStock = v ?? 'Available'));
            final visibleField = dropdownField('Visible on Website', pVisible,
                ['yes', 'no'], (v) => setState(() => pVisible = v ?? 'yes'));

            if (!two) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stockField,
                  const SizedBox(height: 14),
                  visibleField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: stockField),
                const SizedBox(width: 14),
                Expanded(child: visibleField),
              ],
            );
          }),
          const SizedBox(height: 22),
          Row(
            children: [
              actionButton(loading ? '⏳ Uploading...' : '✅ Upload Product', loading ? () {} : uploadProduct),
              const SizedBox(width: 12),
              actionButton('🔄 Reset', resetUploadForm, outline: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget productsPage() {
    final list = filteredProducts();
    return sectionCard(
      '👗 All Products',
      Column(
        children: [
          LayoutBuilder(builder: (_, c) {
            final narrow = c.maxWidth < 560;
            final searchField = field('', productSearch, hint: '🔍 Search products...');
            final categoryField = dropdownField('Category', productCategory,
                ['', 'All', 'Kids', 'Uniform', 'Modern', 'Salwar', 'Blouse', 'Aari', 'Saree', 'Frock', 'Lehenga', 'Kurthi'],
                (v) => setState(() => productCategory = v ?? ''));
            final stockField = dropdownField('Stock', productStock, ['', 'Available', 'Limited', 'Out of Stock'],
                (v) => setState(() => productStock = v ?? ''));

            if (narrow) {
              return Column(
                children: [
                  searchField,
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: categoryField),
                      const SizedBox(width: 10),
                      Expanded(child: stockField),
                    ],
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 10),
                SizedBox(width: 180, child: categoryField),
                const SizedBox(width: 10),
                SizedBox(width: 160, child: stockField),
              ],
            );
          }),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const EmptyState(icon: '📦', text: 'No products found')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width > 950 ? 4 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: .72,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                final photos = p['photos'] is List ? List.from(p['photos']) : <dynamic>[];
                final image = photos.isNotEmpty ? '${photos.first}' : '${p['photo'] ?? ''}';
                final stockColor = p['stock'] == 'Available'
                    ? success
                    : p['stock'] == 'Limited'
                        ? warning
                        : danger;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                    boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: image.isNotEmpty
                            ? Image.network(image, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: tealLight, child: const Center(child: Text('👗', style: TextStyle(fontSize: 36)))))
                            : Container(color: tealLight, child: const Center(child: Text('👗', style: TextStyle(fontSize: 36)))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${p['cat']}', style: TextStyle(fontSize: 11, color: tealDark, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text('${p['name']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('₹${p['price']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tealDark)),
                          const SizedBox(height: 4),
                          Text('${p['stock']}', style: TextStyle(fontSize: 11, color: stockColor, fontWeight: FontWeight.w600)),
                          Text('Website: ${p['visible'] == 'yes' ? '✅ Visible' : '❌ Hidden'}',
                              style: TextStyle(fontSize: 11, color: muted)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => toggleVisible(
                                      p['id'] as String, p['visible'] == 'yes' ? 'no' : 'yes'),
                                  child: Text(p['visible'] == 'yes' ? '🙈 Hide' : '👁 Show',
                                      style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(foregroundColor: danger),
                                  onPressed: () => deleteProduct(p['id'] as String),
                                  child: const Text('🗑️ Delete', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget orderTable(List<Map<String, dynamic>> list, {bool compact = false}) {
    if (list.isEmpty) return const EmptyState(icon: '📭', text: 'No orders yet');

    final columns = compact
        ? ['Order ID', 'Customer', 'Mobile', 'Product', 'Amount', 'Status', 'Date', 'WhatsApp']
        : ['Order ID', 'Customer', 'Mobile', 'Product', 'Amount', 'Payment', 'Measurement', 'Message', 'Voice Note', 'Status', 'Date', 'Update', 'WhatsApp'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(tealLight),
        columns: columns.map((c) => DataColumn(label: Text(c, style: TextStyle(fontSize: 11, color: tealDark, fontWeight: FontWeight.w700)))).toList(),
        rows: list.map((o) {
          final cells = compact
              ? [
                  DataCell(Text('${o['orderId']}')),
                  DataCell(Text('${o['name']}')),
                  DataCell(Text('📞 ${o['mobile']}')),
                  DataCell(Text('${o['product']}')),
                  DataCell(Text('₹${o['amount']}')),
                  DataCell(StatusBadge(status: '${o['status']}')),
                  DataCell(Text('${o['date']}')),
                  DataCell(TextButton(onPressed: () => openWhatsApp('${o['mobile']}', '${o['name']}'), child: const Text('💬'))),
                ]
              : [
                  DataCell(Text('${o['orderId']}')),
                  DataCell(Text('${o['name']}')),
                  DataCell(Text('${o['mobile']}')),
                  DataCell(Text('${o['product']}')),
                  DataCell(Text('₹${o['amount']}')),
                  DataCell(Text('${o['paymentMethod']}\n${o['paymentStatus']}')),
                  DataCell(Text('${o['measurement'] ?? '—'}')),
                  DataCell(Text('${o['notes'] ?? '—'}')),
                  DataCell(Text('${o['voiceNote'] ?? '—'}')),
                  DataCell(StatusBadge(status: '${o['status']}')),
                  DataCell(Text('${o['date']}')),
                  DataCell(
                    DropdownButton<String>(
                      value: '${o['status']}',
                      items: ['Ordered', 'Processing', 'Delivered', 'Cancelled', 'Pending']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) updateStatus('${o['id']}', v);
                      },
                    ),
                  ),
                  DataCell(TextButton(onPressed: () => openWhatsApp('${o['mobile']}', '${o['name']}'), child: const Text('💬'))),
                ];
          return DataRow(cells: cells);
        }).toList(),
      ),
    );
  }

  Widget ordersPage() {
    final list = filteredOrders().reversed.toList();
    return sectionCard(
      '🧾 Orders Management',
      Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: actionButton(
              '🗑️ Clear All Orders',
              () => clearData(
                'orders_all',
                '⚠️ This will delete ALL Orders (Customized Orders will also be deleted, since they are in the same table). Do you want to continue?',
              ),
              color: danger,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: tealLight, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('➕ Add New Order', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tealDark)),
                const SizedBox(height: 10),
                const Text('Orders are normally created from the customer website.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: field('', orderSearch, hint: '🔍 Search by Order ID / name / mobile / product...')),
              const SizedBox(width: 10),
              SizedBox(
                width: 170,
                child: dropdownField('Status', orderStatus,
                    ['', 'Ordered', 'Processing', 'Delivered', 'Cancelled', 'Pending'],
                    (v) => setState(() => orderStatus = v ?? '')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          orderTable(list),
        ],
      ),
    );
  }

  Widget customOrdersPage() {
    final list = customOrders().reversed.toList();
    return sectionCard(
      '✂️ Customized Order Requests',
      Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: actionButton(
              '🗑️ Clear Custom Orders',
              () => clearData('orders_custom',
                  '⚠️ This will delete ALL Customized Orders. Do you want to continue?'),
              color: danger,
            ),
          ),
          const SizedBox(height: 16),
          field('', customSearch, hint: '🔍 Search by name / mobile...'),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const EmptyState(icon: '✂️', text: 'No customized orders yet')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(tealLight),
                columns: const [
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Mobile')),
                  DataColumn(label: Text('Order Type')),
                  DataColumn(label: Text('Measurements')),
                  DataColumn(label: Text('Notes')),
                  DataColumn(label: Text('Voice Note')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('WhatsApp')),
                ],
                rows: list.map((o) => DataRow(cells: [
                  DataCell(Text('${o['name']}')),
                  DataCell(Text('📞 ${o['mobile']}')),
                  DataCell(Text('${o['product']}')),
                  DataCell(Text('${o['measurement'] ?? '—'}')),
                  DataCell(Text('${o['notes'] ?? '—'}')),
                  DataCell(Text('${o['voiceNote'] ?? '—'}')),
                  DataCell(Text('${o['date']}')),
                  DataCell(TextButton(onPressed: () => openWhatsApp('${o['mobile']}', '${o['name']}'), child: const Text('💬'))),
                ])).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  List<Map<String, String>> get uniqueCustomers {
    final seen = <String, Map<String, String>>{};
    for (final c in boutiqueContacts) {
      final phone = normalizePhone('${c['phone'] ?? ''}');
      if (phone.isEmpty) continue;
      seen[phone] = {
        'name': '${c['name'] ?? 'Guest'}',
        'phone': '${c['phone'] ?? ''}',
      };
    }
    return seen.values.toList();
  }

  List<Map<String, dynamic>> ordersForPhone(String phone) {
    final norm = normalizePhone(phone);
    if (norm.isEmpty) return [];
    return orders.where((o) => normalizePhone('${o['mobile'] ?? ''}') == norm).toList();
  }

  /// "Boutique Contact" is now shown to the admin as a Customers list.
  /// Tapping a customer opens their own order history (customerDetailPage).
  Widget customersPage() {
    if (selectedCustomerPhone != null) return customerDetailPage();

    final list = uniqueCustomers;
    return sectionCard(
      '👤 Customers',
      Column(
        children: [
          if (list.isEmpty)
            const EmptyState(icon: '👤', text: 'No customers yet')
          else
            ...list.map((c) {
              final count = ordersForPhone(c['phone']!).length;
              return InkWell(
                onTap: () => setState(() {
                  selectedCustomerPhone = c['phone'];
                  selectedCustomerName = c['name'];
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pageBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: tealLight,
                        child: Text(
                          c['name']!.isNotEmpty ? c['name']![0].toUpperCase() : '?',
                          style: TextStyle(color: tealDark, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('📞 ${c['phone']}', style: TextStyle(fontSize: 12, color: muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: tealLight, borderRadius: BorderRadius.circular(20)),
                        child: Text('$count orders',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tealDark)),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, color: muted),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Shows only the orders belonging to the tapped customer — e.g. tapping
  /// "Divya" shows just her orders (matched by mobile number), not everyone's.
  Widget customerDetailPage() {
    final phone = selectedCustomerPhone!;
    final name = selectedCustomerName ?? 'Customer';
    final custOrders = ordersForPhone(phone).reversed.toList();
    return sectionCard(
      '👤 $name — ${custOrders.length} orders',
      Column(
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: () => setState(() {
                  selectedCustomerPhone = null;
                  selectedCustomerName = null;
                }),
                child: const Text('← Back to Customers'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => openWhatsApp(phone, name),
                child: const Text('💬 WhatsApp'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          orderTable(custOrders, compact: true),
        ],
      ),
    );
  }

  Widget contactPage(bool catering) {
    final list = filteredContacts(catering).reversed.toList();
    final controller = catering ? cateringSearch : boutiqueSearch;
    return sectionCard(
      catering ? '🍽️ Catering Contact Form Submissions' : '📨 Boutique Contact Form Submissions',
      Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: actionButton(
              catering ? '🗑️ Clear Catering Contacts' : '🗑️ Clear Boutique Contacts',
              () => clearData(
                catering ? 'contacts_catering' : 'contacts_boutique',
                catering
                    ? '⚠️ This will delete ALL Catering contact submissions. Do you want to continue?'
                    : '⚠️ This will delete ALL Boutique contact submissions. Do you want to continue?',
              ),
              color: danger,
            ),
          ),
          const SizedBox(height: 16),
          field('', controller, hint: '🔍 Search by name / phone / email...'),
          const SizedBox(height: 16),
          if (list.isEmpty)
            EmptyState(icon: catering ? '🍽️' : '📨', text: catering ? 'No catering contact form submissions yet' : 'No contact form submissions yet')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(tealLight),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Service')),
                  DataColumn(label: Text('Message')),
                  DataColumn(label: Text('Date')),
                ],
                rows: list.map((c) => DataRow(cells: [
                  DataCell(Text('${c['name'] ?? ''}')),
                  DataCell(Text('${c['phone'] ?? '—'}')),
                  DataCell(Text('${c['email'] ?? '—'}')),
                  DataCell(Text('${c['service'] ?? '—'}')),
                  DataCell(Text('${c['message'] ?? ''}')),
                  DataCell(Text(formatDate(c['created_at']))),
                ])).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget notificationsPage() {
    return Column(
      children: [
        sectionCard(
          '🔔 Send Notification to All Customers',
          Column(
            children: [
              field('Title *', notificationTitle, hint: 'e.g. New Arrivals in Store!'),
              const SizedBox(height: 14),
              field('Message *', notificationMessage,
                  hint: 'e.g. Check out our latest saree collection now available...', maxLines: 3),
              const SizedBox(height: 14),
              dropdownField('Type', notificationType,
                  ['general', 'order', 'promotion', 'class'],
                  (v) => setState(() => notificationType = v ?? 'general')),
              const SizedBox(height: 18),
              Align(alignment: Alignment.centerLeft, child: actionButton('📢 Send Notification', sendNotification)),
            ],
          ),
        ),
        sectionCard(
          '📋 Sent Notifications',
          Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: actionButton(
                  '🗑️ Clear All Notifications',
                  () => clearData('notifications_all',
                      '⚠️ This will delete ALL sent notifications. Customers will no longer see them. Do you want to continue?'),
                  color: danger,
                ),
              ),
              const SizedBox(height: 14),
              if (notifications.isEmpty)
                const EmptyState(icon: '🔔', text: 'No notifications sent yet')
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(tealLight),
                    columns: const [
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Message')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Sent On')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: notifications.reversed.map((n) => DataRow(cells: [
                      DataCell(Text('${n['title'] ?? ''}')),
                      DataCell(Text('${n['message'] ?? ''}')),
                      DataCell(Text('${n['type'] ?? ''}')),
                      DataCell(Text(formatDateTime(n['created_at']))),
                      DataCell(TextButton(
                        onPressed: () => deleteNotification(n['id']),
                        child: Text('🗑️ Delete', style: TextStyle(color: danger)),
                      )),
                    ])).toList(),
                  ),
                ),
            ],
          ),
        ),
        sectionCard(
          '❌ Recent Cancellations',
          Column(
            children: [
              field('', cancellationSearch, hint: '🔍 Search by Order ID / name / mobile / product...'),
              const SizedBox(height: 14),
              Builder(builder: (_) {
                final s = cancellationSearch.text.trim().toLowerCase();
                final cancelled = orders.where((o) {
                  if (o['status'] != 'Cancelled') return false;
                  return s.isEmpty ||
                      '${o['name']}'.toLowerCase().contains(s) ||
                      '${o['mobile']}'.contains(s) ||
                      '${o['product']}'.toLowerCase().contains(s) ||
                      '${o['orderId']}'.toLowerCase().contains(s);
                }).toList();
                if (cancelled.isEmpty) return const EmptyState(icon: '❌', text: 'No cancellations yet');
                return orderTable(cancelled.reversed.toList(), compact: true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget dataRequestsPage() {
    return Column(
      children: [
        sectionCard(
          '📥 Request My Data Submissions',
          Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: actionButton(
                '🗑️ Clear Data Requests',
                () => clearData('data_requests_all',
                    '⚠️ This will delete ALL "Request My Data" submissions. Do you want to continue?'),
                color: danger,
              ),
            ),
            const SizedBox(height: 14),
            field('', dataSearch, hint: '🔍 Search by name / phone / email...'),
            const SizedBox(height: 14),
            _simpleDataTable(
              dataRequests.where((r) {
                final s = dataSearch.text.toLowerCase();
                return s.isEmpty ||
                    '${r['name'] ?? ''}'.toLowerCase().contains(s) ||
                    '${r['phone'] ?? ''}'.contains(s) ||
                    '${r['email'] ?? ''}'.toLowerCase().contains(s);
              }).toList(),
              ['Name', 'Phone', 'Email', 'Requested On'],
              (r) => [
                '${r['name'] ?? 'Guest'}',
                '${r['phone'] ?? '—'}',
                '${r['email'] ?? '—'}',
                formatDateTime(r['requested_at']),
              ],
              '📥',
              'No data export requests yet',
            ),
          ]),
        ),
        sectionCard(
          '⚖️ Grievance Redressal Complaints',
          Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: actionButton(
                '🗑️ Clear Grievances',
                () => clearData('grievances_all',
                    '⚠️ This will delete ALL Grievance complaints. Do you want to continue?'),
                color: danger,
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: field('', grievanceSearch, hint: '🔍 Search by name / phone / subject...')),
              const SizedBox(width: 10),
              SizedBox(
                width: 150,
                child: dropdownField('Status', grievanceStatus, ['', 'Open', 'Resolved'],
                    (v) => setState(() => grievanceStatus = v ?? '')),
              ),
            ]),
            const SizedBox(height: 14),
            _grievanceTable(),
          ]),
        ),
        sectionCard(
          '👤 De-activated Accounts',
          Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: actionButton(
                '🗑️ Clear De-activated',
                () => clearData('deactivated_all',
                    '⚠️ This will delete ALL De-activated account records. Do you want to continue?'),
                color: danger,
              ),
            ),
            const SizedBox(height: 14),
            _simpleDataTable(
              deactivated,
              ['Phone', 'Reason', 'De-activated On', 'WhatsApp'],
              (r) => [
                '${r['phone'] ?? ''}',
                '${r['reason'] ?? '—'}',
                formatDateTime(r['deactivated_at']),
                '💬',
              ],
              '👤',
              'No de-activated accounts',
            ),
          ]),
        ),
        sectionCard(
          '🗑️ Deleted Accounts',
          Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: actionButton(
                '🗑️ Clear Deleted',
                () => clearData('deleted_accounts_all',
                    '⚠️ This will delete ALL Deleted account records. Do you want to continue?'),
                color: danger,
              ),
            ),
            const SizedBox(height: 14),
            _simpleDataTable(
              deletedAccounts,
              ['Phone', 'Deleted On'],
              (r) => ['${r['phone'] ?? ''}', formatDateTime(r['deleted_at'])],
              '🗑️',
              'No deleted accounts',
            ),
          ]),
        ),
      ],
    );
  }

  Widget _simpleDataTable(
    List<Map<String, dynamic>> list,
    List<String> columns,
    List<String> Function(Map<String, dynamic>) values,
    String emptyIcon,
    String emptyText,
  ) {
    if (list.isEmpty) return EmptyState(icon: emptyIcon, text: emptyText);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(tealLight),
        columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
        rows: list.reversed.map((r) {
          final vals = values(r);
          return DataRow(cells: vals.map((v) => DataCell(Text(v))).toList());
        }).toList(),
      ),
    );
  }

  Widget _grievanceTable() {
    final s = grievanceSearch.text.trim().toLowerCase();
    final list = grievances.where((g) {
      final matchSearch = s.isEmpty ||
          '${g['name'] ?? ''}'.toLowerCase().contains(s) ||
          '${g['phone'] ?? ''}'.contains(s) ||
          '${g['subject'] ?? ''}'.toLowerCase().contains(s);
      final matchStatus = grievanceStatus.isEmpty || g['status'] == grievanceStatus;
      return matchSearch && matchStatus;
    }).toList();

    if (list.isEmpty) return const EmptyState(icon: '⚖️', text: 'No complaints yet');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(tealLight),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Subject')),
          DataColumn(label: Text('Order ID')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Action')),
          DataColumn(label: Text('WhatsApp')),
        ],
        rows: list.reversed.map((g) {
          final resolved = '${g['status']}' == 'Resolved';
          return DataRow(cells: [
            DataCell(Text('${g['name'] ?? 'Guest'}')),
            DataCell(Text('${g['phone'] ?? '—'}')),
            DataCell(Text('${g['subject'] ?? ''}')),
            DataCell(Text('${g['order_id'] ?? '—'}')),
            DataCell(Text('${g['description'] ?? ''}')),
            DataCell(StatusBadge(status: '${g['status'] ?? 'Open'}')),
            DataCell(Text(formatDateTime(g['created_at']))),
            DataCell(
              TextButton(
                onPressed: () => markGrievance(g['id'], resolved ? 'Open' : 'Resolved'),
                child: Text(resolved ? '↩️ Reopen' : '✅ Mark Resolved'),
              ),
            ),
            DataCell(TextButton(onPressed: () => openWhatsApp('${g['phone']}', '${g['name'] ?? 'Customer'}'), child: const Text('💬'))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget revenuePage() {
    final delivered = deliveredOrders;
    final total = revenue;
    final avg = delivered.isEmpty ? 0 : total / delivered.length;
    final now = DateTime.now();
    final month = delivered.where((o) {
      final parts = '${o['date']}'.split('/');
      return parts.length >= 3 &&
          int.tryParse(parts[1]) == now.month &&
          int.tryParse(parts[2]) == now.year;
    }).fold<num>(0, (s, o) => s + (o['amount'] ?? 0));

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: actionButton(
            '🗑️ Clear Orders (resets Revenue)',
            () => clearData('orders_all',
                '⚠️ This will delete ALL Orders, and Revenue will reset to ₹0. Do you want to continue?'),
            color: danger,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 700 ? 3 : 1;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.8,
            children: [
              RevenueCard(label: 'TOTAL REVENUE', value: '₹${total.toStringAsFixed(0)}', sub: 'All delivered orders', color1: tealDark, color2: teal),
              RevenueCard(label: 'THIS MONTH', value: '₹${month.toStringAsFixed(0)}', sub: '${now.month}/${now.year}', color1: const Color(0xFF9C6024), color2: copper),
              RevenueCard(label: 'AVG ORDER VALUE', value: '₹${avg.toStringAsFixed(0)}', sub: 'Per delivered order', color1: const Color(0xFF2E7D32), color2: success),
            ],
          );
        }),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sectionCard('📊 Monthly Revenue Chart', SizedBox(height: 260, child: SimpleChart(data: monthlyRevenue(delivered), bar: false, color: teal)))),
            const SizedBox(width: 20),
            Expanded(child: sectionCard('🏆 Top Products by Revenue', topProducts(delivered))),
          ],
        ),
        sectionCard(
          '📋 Delivered Orders',
          orderTable(delivered.reversed.toList(), compact: true),
        ),
      ],
    );
  }

  List<num> monthlyRevenue(List<Map<String, dynamic>> source) {
    final data = List<num>.filled(12, 0);
    for (final o in source) {
      final d = '${o['date']}'.split('/');
      if (d.length >= 2) {
        final m = int.tryParse(d[1]);
        if (m != null && m >= 1 && m <= 12) data[m - 1] += (o['amount'] ?? 0);
      }
    }
    return data;
  }

  Widget topProducts(List<Map<String, dynamic>> delivered) {
    final map = <String, num>{};
    for (final o in delivered) {
      final name = '${o['product'] ?? ''}';
      map[name] = (map[name] ?? 0) + (o['amount'] ?? 0);
    }
    final list = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = list.take(5).toList();
    if (top.isEmpty) return const EmptyState(icon: '📊', text: 'No delivered orders yet');
    final maxValue = top.first.value == 0 ? 1 : top.first.value;
    return Column(
      children: List.generate(top.length, (i) {
        final e = top[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              Row(children: [
                Expanded(child: Text('${i + 1}. ${e.key}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                Text('₹${e.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: e.value / maxValue,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation(teal),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

    Future<void> openWhatsApp(String mobile, String name) async {
    final numText = mobile.replaceAll(RegExp(r'\D'), '');
    final msg = Uri.encodeComponent(
        "Hi $name! 👗 Thank you for choosing Sumathi's Styles, Injambakkam. How can we help you today?");
    final uri = Uri.parse('https://wa.me/91$numText?text=$msg');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) showToast('❌ Could not open WhatsApp');
    } catch (e) {
      showToast('❌ WhatsApp error: $e');
    }
  }

  Widget currentContent(bool mobile) {
    switch (currentPage) {
      case 'upload':
        return uploadPage();
      case 'products':
        return productsPage();
      case 'ordersmgmt':
        return ordersPage();
      case 'customorder':
        return customOrdersPage();
      case 'contactform':
        return customersPage();
      case 'contactform2':
        return contactPage(true);
      case 'notifications':
        return notificationsPage();
      case 'datarequests':
        return dataRequestsPage();
      case 'revenue':
        return revenuePage();
      case 'dashboard':
      default:
        return dashboardPage(mobile);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loggedIn) return loginScreen();

    final width = MediaQuery.sizeOf(context).width;
    final mobile = width <= 700;

    if (mobile && !mobilePageMode) {
      return mobileMenu();
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Row(
          children: [
            if (!mobile) sidebarWidget(),
            Expanded(
              child: Column(
                children: [
                  topbarWidget(mobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(mobile ? 12 : 28),
                      child: currentContent(mobile),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: toastMessage.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: tealDark,
              onPressed: () {},
              label: Text(toastMessage, style: const TextStyle(fontSize: 12)),
            )
          : null,
    );
  }

  /// Login screen — matches admin.html: black top bar with "Admin Login",
  /// blue shield icon with person badge, "Admin Panel" title, plain
  /// bordered Email/Password fields, full-width blue pill LOGIN button.
  Widget loginScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Back',
                    ),
                  ),
                  const Text(
                    'Admin Login',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CustomPaint(
                                size: const Size(88, 88),
                                painter: ShieldPainter(color: loginBlue),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -6,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: loginBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 6)],
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Admin Panel',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 28),
                        loginField(
                          icon: Icons.mail_outline,
                          controller: emailController,
                          hint: 'Email',
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        loginField(
                          icon: Icons.lock_outline,
                          controller: passwordController,
                          hint: 'Password',
                          obscure: true,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: loginBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 0,
                            ),
                            onPressed: doLogin,
                            child: const Text(
                              'LOGIN',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: .6),
                            ),
                          ),
                        ),
                        if (loginError.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(loginError, style: TextStyle(color: danger, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget loginField({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8D8D8), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black.withOpacity(.55)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              obscureText: obscure,
              style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF999999)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget mobileMenu() {
    final items = [
      ('dashboard', '📊', 'Dashboard'),
      ('ordersmgmt', '🧾', 'Orders'),
      ('upload', '📦', 'Product Upload'),
      ('products', '👗', 'All Products'),
      ('customorder', '✂️', 'Customized Order'),
      ('contactform', '👤', 'Customers'),
      ('contactform2', '🍽️', 'Catering Contact'),
      ('notifications', '🔔', 'Notifications'),
      ('datarequests', '📥', 'Data Requests'),
      ('revenue', '💰', 'Revenue'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [sidebar, const Color(0xFF00796B)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 18)],
              ),
              child: Column(
                children: [
                  const Text("👗 Sumathi's Styles",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text('Admin Panel', style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 12)),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      currentPage = item.$1;
                      mobilePageMode = true;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD7E5E3)),
                      boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.$2, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(item.$3, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tealDark)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: doLogout,
                child: const Text('🚪 Logout',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sidebarWidget() {
    final groups = [
      ('Overview', [('dashboard', '📊', 'Dashboard')]),
      ('Catalogue', [('upload', '📦', 'Product Upload'), ('products', '👗', 'All Products')]),
      ('Sales', [
        ('ordersmgmt', '🧾', 'Orders'),
        ('customorder', '✂️', 'Customized Order'),
        ('contactform', '👤', 'Customers'),
        ('contactform2', '🍽️', 'Catering Contact Form'),
      ]),
      ('Engagement', [
        ('notifications', '🔔', 'Notification / Cancellation msg'),
        ('datarequests', '📥', 'Request My Data / Grievance / De-act & Delete Acc'),
      ]),
      ('Finance', [('revenue', '💰', 'Revenue')]),
    ];

    return Container(
      width: 240,
      height: double.infinity,
      color: sidebar,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                const Text('👗', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Sumathi's Styles",
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('Admin Dashboard',
                          style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final group in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Text(group.$1.toUpperCase(),
                        style: TextStyle(color: Colors.white.withOpacity(.35), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  ),
                  for (final item in group.$2)
                    InkWell(
                      onTap: () => showPage(item.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: currentPage == item.$1 ? const Color(0xFF00695C) : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: currentPage == item.$1 ? copper : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(item.$2, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(item.$3,
                                  style: TextStyle(
                                    color: currentPage == item.$1 ? Colors.white : Colors.white.withOpacity(.75),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          InkWell(
            onTap: doLogout,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(.1)))),
              child: Row(children: [
                const Text('🚪', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 14)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget topbarWidget(bool mobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 28, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 8)],
      ),
      child: Row(
        children: [
          if (mobile)
            OutlinedButton(
              onPressed: () => setState(() => mobilePageMode = false),
              child: const Text('← Back to Menu', style: TextStyle(fontSize: 12)),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('← Back', style: TextStyle(fontSize: 12)),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(titleFor(currentPage),
                style: TextStyle(fontSize: mobile ? 16 : 18, fontWeight: FontWeight.w700, color: tealDark)),
          ),
          if (!mobile) ...[
            Text(
              '${DateTime.now().weekday.weekdayName()}, ${DateTime.now().day} ${monthName(DateTime.now().month)} ${DateTime.now().year}',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(width: 14),
            OutlinedButton(onPressed: () {}, child: const Text('🔔')),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
              onPressed: () => showPage('ordersmgmt'),
              child: const Text('🧾 Go to Orders', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  String monthName(int month) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'];
    return names[month - 1];
  }
}

extension on int {
  String weekdayName() {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[this - 1];
  }
}

/// Draws the shield used on the login screen — a direct port of the
/// admin.html SVG path: M50 4 L92 18 V48 C92 74 74 92 50 98 C26 92 8 74 8 48 V18 Z
class ShieldPainter extends CustomPainter {
  ShieldPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 100;
    final path = Path()
      ..moveTo(50 * sx, 4 * sy)
      ..lineTo(92 * sx, 18 * sy)
      ..lineTo(92 * sx, 48 * sy)
      ..cubicTo(92 * sx, 74 * sy, 74 * sx, 92 * sy, 50 * sx, 98 * sy)
      ..cubicTo(26 * sx, 92 * sy, 8 * sx, 74 * sy, 8 * sx, 48 * sy)
      ..lineTo(8 * sx, 18 * sy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ShieldPainter oldDelegate) => oldDelegate.color != color;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Ordered':
        bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1565C0); break;
      case 'Processing':
        bg = const Color(0xFFEDE7F6); fg = const Color(0xFF4527A0); break;
      case 'Delivered':
        bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32); break;
      case 'Cancelled':
        bg = const Color(0xFFFFEBEE); fg = const Color(0xFFE53935); break;
      default:
        bg = const Color(0xFFFFF3E0); fg = const Color(0xFFE65100);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class RevenueCard extends StatelessWidget {
  const RevenueCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.color1,
    required this.color2,
  });
  final String label;
  final String value;
  final String sub;
  final Color color1;
  final Color color2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}

class SimpleChart extends StatelessWidget {
  const SimpleChart({
    super.key,
    required this.data,
    required this.bar,
    required this.color,
  });
  final List<num> data;
  final bool bar;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(data: data, bar: bar, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.data, required this.bar, required this.color});
  final List<num> data;
  final bool bar;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final maxValue = math.max(1, data.fold<num>(0, (a, b) => math.max(a, b)));
    final bottom = size.height - 28;
    final top = 12.0;
    final chartHeight = bottom - top;

    if (bar) {
      final gap = size.width / data.length;
      for (int i = 0; i < data.length; i++) {
        final h = (data[i] / maxValue) * chartHeight;
        final rect = Rect.fromLTWH(
          i * gap + gap * .18,
          bottom - h,
          gap * .64,
          h,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()..color = color.withOpacity(.7),
        );
      }
    } else {
      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = data.length == 1 ? size.width / 2 : i * size.width / (data.length - 1);
        final y = bottom - (data[i] / maxValue) * chartHeight;
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
      for (int i = 0; i < data.length; i++) {
        final x = data.length == 1 ? size.width / 2 : i * size.width / (data.length - 1);
        final y = bottom - (data[i] / maxValue) * chartHeight;
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.bar != bar || oldDelegate.color != color;
}

class StatusChart extends StatelessWidget {
  const StatusChart({super.key, required this.orders});
  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      'Ordered': 0,
      'Processing': 0,
      'Delivered': 0,
      'Cancelled': 0,
      'Pending': 0,
    };
    for (final o in orders) {
      final s = '${o['status']}';
      if (counts.containsKey(s)) counts[s] = counts[s]! + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return Center(
      child: SizedBox(
        width: 190,
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(190, 190),
              painter: _DonutPainter(values: counts.values.toList()),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$total', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                const Text('Orders', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values});
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF1565C0),
      const Color(0xFF4527A0),
      const Color(0xFF2E7D32),
      const Color(0xFFE53935),
      const Color(0xFFE65100),
    ];
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      canvas.drawCircle(
        size.center(Offset.zero),
        size.width / 2 - 12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..color = const Color(0xFFE0E0E0),
      );
      return;
    }
    var start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 12),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.values != values;
}