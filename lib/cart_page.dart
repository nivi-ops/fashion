import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_colors.dart';
import 'app_state.dart';
import 'models.dart';
import 'checkout.dart';
import 'location_picker_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;

        // Make a safe copy so navigation to checkout does not depend
        // on the live list reference.
        final List<Product> items = List<Product>.from(
          state.cartItems,
        );

        final bool isEmpty = items.isEmpty;

        return Scaffold(
          backgroundColor: AppColors.light,

          appBar: AppBar(
            title: const Text(
              'My Cart',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),

          body: SafeArea(
            top: false,
            child: Column(
              children: [
                // ======================================================
                // CART CONTENT
                // ======================================================

                Expanded(
                  child: isEmpty
                      ? _emptyState(context)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            12,
                            12,
                            12,
                            20,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = items[index];

                            return _cartTile(
                              context,
                              state,
                              product,
                            );
                          },
                        ),
                ),

                // ======================================================
                // FIXED BOTTOM TOTAL + CHECKOUT
                // ======================================================

                _bottomBar(
                  context,
                  state,
                  items,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================================================================
  // EMPTY CART
  // ===================================================================

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: AppColors.textLight,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add some products to your cart and they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Continue Shopping',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // BOTTOM BAR
  // ===================================================================

  Widget _bottomBar(
    BuildContext context,
    AppState state,
    List<Product> items,
  ) {
    final bool isEmpty = items.isEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            14,
          ),
          child: Row(
            children: [
              // -------------------------------------------------------
              // TOTAL
              // -------------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '₹${state.cartTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // -------------------------------------------------------
              // CHECKOUT
              // -------------------------------------------------------

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(
                                items: List<Product>.from(
                                  items,
                                ),
                                fromCart: true,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmpty
                        ? AppColors.gray
                        : AppColors.gold,
                    foregroundColor: AppColors.dark,
                    disabledForegroundColor:
                        AppColors.textLight,
                    disabledBackgroundColor:
                        AppColors.gray,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // CART TILE
  // ===================================================================

  Widget _cartTile(
    BuildContext context,
    AppState state,
    Product product,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.07,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // -----------------------------------------------------
                // PRODUCT IMAGE
                // -----------------------------------------------------

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.isNetworkImage
                      ? Image.network(
                          product.image,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                          loadingBuilder:
                              (
                                context,
                                child,
                                loadingProgress,
                              ) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return _imagePlaceholder();
                          },
                          errorBuilder:
                              (_, __, ___) {
                            return _imagePlaceholder();
                          },
                        )
                      : Image.asset(
                          product.image,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return _imagePlaceholder();
                          },
                        ),
                ),

                const SizedBox(width: 12),

                // -----------------------------------------------------
                // PRODUCT DETAILS
                // -----------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Product name + Flipkart-style details arrow
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(20),
                              onTap: () =>
                                  _openProductDetails(
                                context,
                                product,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 24,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ------------------------------------------------
                      // QUANTITY
                      // ------------------------------------------------

                      Row(
                        children: [
                          _qtyBtn(
                            Icons.remove,
                            () {
                              if (product.qty > 1) {
                                state.updateQty(
                                  product.id,
                                  product.qty - 1,
                                );
                              } else {
                                state.removeFromCart(
                                  product.id,
                                );
                              }
                            },
                          ),

                          Container(
                            constraints:
                                const BoxConstraints(
                              minWidth: 36,
                            ),
                            alignment:
                                Alignment.center,
                            child: Text(
                              '${product.qty}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),

                          _qtyBtn(
                            Icons.add,
                            () {
                              state.updateQty(
                                product.id,
                                product.qty + 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===========================================================
          // ACTION ROW
          // ===========================================================

          const Divider(
            height: 1,
            thickness: 1,
          ),

          Row(
            children: [
              // REMOVE
              Expanded(
                child: _actionBtn(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  color: AppColors.danger,
                  onTap: () {
                    state.removeFromCart(product.id);
                  },
                ),
              ),

              Container(
                width: 1,
                height: 42,
                color: AppColors.gray,
              ),

              // MOVE TO WISHLIST
              Expanded(
                child: _actionBtn(
                  icon: Icons.favorite_border,
                  label: 'Move to Wishlist',
                  color: AppColors.text,
                                   onTap: () {
                    state.addToWishlist(product);
                    state.removeFromCart(product.id);

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            '${product.name} moved to Wishlist',
                          ),
                          duration:
                              const Duration(seconds: 2),
                        ),
                      );
                  },
                ),
              ),

              Container(
                width: 1,
                height: 42,
                color: AppColors.gray,
              ),

              // BUY NOW
              Expanded(
                child: _actionBtn(
                  icon: Icons.flash_on,
                  label: 'Buy Now',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          items: [product],
                          fromCart: true,
                          quantities: {
                            product.id:
                                product.qty > 0
                                    ? product.qty
                                    : 1,
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // PRODUCT DETAILS NAVIGATION
  // ===================================================================

  void _openProductDetails(
    BuildContext context,
    Product product,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartProductDetailsPage(
          product: product,
        ),
      ),
    );
  }



  // ===================================================================
  // IMAGE PLACEHOLDER
  // ===================================================================

  Widget _imagePlaceholder() {
    return Container(
      width: 82,
      height: 82,
      color: AppColors.gray,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 30,
        color: AppColors.textLight,
      ),
    );
  }

  // ===================================================================
  // ACTION BUTTON
  // ===================================================================

    Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 4,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),

            const SizedBox(width: 4),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // QUANTITY BUTTON
  // ===================================================================

  Widget _qtyBtn(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.gray,
            borderRadius:
                BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}


// =======================================================================
// CART PRODUCT DETAILS PAGE
// =======================================================================
//
// Opened when the user taps the > arrow beside a cart product.
// The page reads the latest product data from Firestore so the user can
// see the complete image gallery, description, highlights and price tags.
// If the Firestore document cannot be loaded, the cart product data is
// still displayed as a safe fallback.
// =======================================================================

 class CartProductDetailsPage extends StatefulWidget {
  final Product product;

  const CartProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<CartProductDetailsPage> createState() => _CartProductDetailsPageState();
}

class _CartProductDetailsPageState extends State<CartProductDetailsPage> {
  int _qty = 1;

  Product get product => widget.product;

  double get _rating {
    final seed = '${product.id}'.codeUnits.fold<int>(0, (a, b) => a + b);
    return 4.3 + (seed % 3) * 0.2;
  }

  bool get _isWishlisted => AppState.instance.wishlistIds.contains(product.id);
  bool get _isInCart => AppState.instance.cartItems.any((p) => p.id == product.id);

  void _goToCart() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
  }

  Future<Map<String, dynamic>> _loadProductDetails() async {
    try {
             final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc('${product.id}')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);

        final photos = data['photos'] is List
            ? List<dynamic>.from(data['photos'])
            : <dynamic>[];

        if (photos.isEmpty &&
            data['image_url'] != null &&
            '${data['image_url']}'.trim().isNotEmpty) {
          photos.add(data['image_url']);
        }

        if (photos.isEmpty) {
          photos.add(product.image);
        }

        return {
          'name': data['name'] ?? product.name,
          'category':
              data['category'] ?? data['cat'] ?? 'Other',
          'price': num.tryParse(
                '${data['price'] ?? product.price}',
              ) ??
              product.price,
          'description':
              data['description'] ?? data['desc'] ?? '',
          'stock': data['stock'] ?? 'Available',
          'highlights': data['highlights'] is List
              ? List<dynamic>.from(data['highlights'])
              : <dynamic>[],
          'priceTags': data['price_tags'] is List
              ? List<dynamic>.from(data['price_tags'])
              : (data['priceTags'] is List
                  ? List<dynamic>.from(data['priceTags'])
                  : <dynamic>[]),
          'photos': photos,
        };
      }
    } catch (_) {
      // Use cart data below if Firestore is unavailable.
    }

    return {
      'name': product.name,
      'category': 'Product',
      'price': product.price,
      'description': '',
      'stock': 'Available',
      'highlights': <dynamic>[],
      'priceTags': <dynamic>[],
      'photos': <dynamic>[product.image],
    };
  }

    @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) => Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () => AppState.instance.toggleWishlist(product),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: _goToCart,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadProductDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          final data = snapshot.data ??
              <String, dynamic>{
                'name': product.name,
                'category': 'Product',
                'price': product.price,
                'description': '',
                'stock': 'Available',
                'highlights': <dynamic>[],
                'priceTags': <dynamic>[],
                'photos': <dynamic>[product.image],
              };

          final name = '${data['name'] ?? product.name}';
         
          final price = num.tryParse(
                '${data['price'] ?? product.price}',
              ) ??
              product.price;
          final description =
              '${data['description'] ?? ''}'.trim();
          final stock = '${data['stock'] ?? 'Available'}';

          final highlights = data['highlights'] is List
              ? List<dynamic>.from(data['highlights'])
              : <dynamic>[];

          final priceTags = data['priceTags'] is List
              ? List<dynamic>.from(data['priceTags'])
              : <dynamic>[];

          final rawPhotos = data['photos'] is List
              ? List<dynamic>.from(data['photos'])
              : <dynamic>[];

          final photos = rawPhotos
              .map((e) => '$e'.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          if (photos.isEmpty) {
            photos.add(product.image);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------
                // FULL PRODUCT IMAGE / GALLERY
                // -------------------------------------------------------

                Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: SizedBox(
                    height: 360,
                    child: PageView.builder(
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return _detailImage(
                          photos[index],
                        );
                      },
                    ),
                  ),
                ),

                if (photos.length > 1)
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      0,
                    ),
                    child: Text(
                      '${photos.length} product images • Swipe to view',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),

                // -------------------------------------------------------
                // PRODUCT INFORMATION
                // -------------------------------------------------------

                       Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    18,
                  ),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF388E3C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.star, color: Colors.white, size: 11),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Free Delivery',
                            style: TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                        ],
                      ),

                      const Divider(height: 26),

                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Inclusive of all taxes',
                        style: TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),

                      const SizedBox(height: 10),

                                     Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: stock
                                  .toLowerCase()
                                  .contains('available')
                              ? Colors.green.withValues(
                                  alpha: 0.10,
                                )
                              : Colors.orange.withValues(
                                  alpha: 0.10,
                                ),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          stock,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: stock
                                    .toLowerCase()
                                    .contains('available')
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gray),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final picked = await LocationPickerSheet.show(context);
                                if (picked != null) {
                                  final display = picked.addressLine.trim().isNotEmpty
                                      ? picked.addressLine
                                      : (picked.label.isNotEmpty
                                          ? picked.label
                                          : 'Selected location');
                                                                    await AppState.instance.setDeliveryLocation(
                                    display,
                                    lat: picked.latitude,
                                    lng: picked.longitude,
                                    pincode: picked.pincode,
                                  );
                                  setState(() {});
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.home_outlined, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppState.instance.deliveryLocation.trim().isNotEmpty
                                            ? AppState.instance.deliveryLocation
                                            : 'Add a delivery address',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1, indent: 12, endIndent: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.primary),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Custom stitched — delivered within 10–15 days',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Text('Qty:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (_qty > 1) setState(() => _qty--);
                                  },
                                  icon: const Icon(Icons.remove, size: 16),
                                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                  padding: EdgeInsets.zero,
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '$_qty',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (_qty < 10) setState(() => _qty++);
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // -------------------------------------------------------
                // DESCRIPTION
                // -------------------------------------------------------

                if (description.isNotEmpty)
                  _detailSection(
                    title: 'Description',
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.text,
                      ),
                    ),
                  ),

                // -------------------------------------------------------
                // HIGHLIGHTS
                // -------------------------------------------------------

                         // -------------------------------------------------------
                // PRICE TAGS / VARIATIONS
                // -------------------------------------------------------

                if (priceTags.isNotEmpty)
                  _detailSection(
                    title: 'Available Options',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: priceTags.map((tag) {
                        if (tag is Map) {
                          final label =
                              '${tag['label'] ?? tag['tag'] ?? ''}';
                          final tagPrice =
                              '${tag['price'] ?? tag['amount'] ?? ''}';

                          return Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              '$label  ₹$tagPrice',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          );
                        }

                        return Text(
                          '$tag',
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // -------------------------------------------------------
                // BUY NOW
                // -------------------------------------------------------

                   Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (_isInCart) {
                                _goToCart();
                              } else {
                                AppState.instance.addToCart(product.copyWith(qty: _qty));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to cart! 🛒'),
                                    action: SnackBarAction(label: 'VIEW CART', onPressed: _goToCart),
                                  ),
                                );
                              }
                              setState(() {});
                            },
                            icon: Icon(_isInCart ? Icons.shopping_cart_checkout : Icons.shopping_cart, size: 18),
                            label: Text(_isInCart ? 'View Cart' : 'Add to Cart'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutPage(
                                    items: [product],
                                    fromCart: true,
                                    quantities: {product.id: _qty},
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.flash_on,
                              size: 20,
                            ),
                            label: const Text(
                              'Buy Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor:
                                  AppColors.dark,
                              elevation: 2,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (highlights.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Highlights',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          highlights.map((h) => '• $h').join('\n'),
                          style: const TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _detailSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        18,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailImage(String path) {
    final isNetwork = path.startsWith('http://') ||
        path.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        path,
        width: double.infinity,
        height: 360,
        fit: BoxFit.contain,
        loadingBuilder:
            (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 60,
              color: AppColors.textLight,
            ),
          );
        },
      );
    }

    return Image.asset(
      path,
      width: double.infinity,
      height: 360,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: AppColors.textLight,
          ),
        );
      },
    );
  }
}
