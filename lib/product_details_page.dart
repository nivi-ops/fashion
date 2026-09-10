import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_state.dart';
import 'models.dart';
import 'checkout.dart';
import 'cart_page.dart';
import 'location_picker_page.dart';

/// ---------------------------------------------------------------------
/// PRODUCT DETAILS PAGE (Flipkart style)
/// ---------------------------------------------------------------------
///
/// Reached by tapping any product card on the Home page (or Shop page,
/// if you wire the same onTap there). Shows the product image, price,
/// rating and a quantity selector, with two bottom actions:
///
///   - Add to Cart  -> adds to the shared cart (AppState). Once added,
///                     the button turns into "View Cart" and takes you
///                     straight to the cart on tap.
///   - Buy Now      -> skips the cart entirely and goes straight to
///                     CheckoutPage with just this one product
/// ---------------------------------------------------------------------

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _qty = 1;

  // Tracks whether THIS product has already been added to the cart from
  // this screen, so the bottom button can flip from "Add to Cart" to
  // "View Cart" instead of staying static forever.
  bool _addedToCart = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final product = widget.product;
        final isWishlisted = state.wishlistIds.contains(product.id);

        return Scaffold(
          backgroundColor: AppColors.light,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Product Details'),
            actions: [
              IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: () => state.toggleWishlist(product),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------
                // IMAGE
                // ---------------------------------------------------
                Hero(
                  tag: 'product_${product.id}',
                  child: product.isNetworkImage
                      ? Image.network(
                          product.image,
                          width: double.infinity,
                          height: 320,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 320,
                            color: AppColors.gray,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Image.asset(
                          product.image,
                          width: double.infinity,
                          height: 320,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 320,
                            color: AppColors.gray,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // RATING + DELIVERY
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF388E3C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.star,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Free Delivery',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // PRICE
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Inclusive of all taxes',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // -----------------------------------------------
                      // DELIVERY DETAILS (saved address + estimated
                      // delivery date for custom-stitched orders)
                      // -----------------------------------------------
                      _buildDeliveryDetails(state),

                      const Divider(height: 32),

                      // QUANTITY
                      const Text(
                        'Quantity',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _qtyBtn(Icons.remove, () {
                            if (_qty > 1) setState(() => _qty--);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Text(
                              '$_qty',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _qtyBtn(Icons.add, () => setState(() => _qty++)),
                        ],
                      ),

                      const Divider(height: 32),

                      // -----------------------------------------------
                      // DESCRIPTION (own section, always shown when the
                      // product has one — separate from Highlights)
                      // -----------------------------------------------
                      if (product.description.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // -----------------------------------------------
                      // HIGHLIGHTS (own section, separate from
                      // Description — from admin panel highlights list)
                      // -----------------------------------------------
                      if (product.highlights.isNotEmpty) ...[
                        const Text(
                          'Product Highlights',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.highlights.map((h) => '• $h').join('\n'),
                          style: const TextStyle(
                            color: AppColors.textLight,
                            height: 1.6,
                          ),
                        ),
                      ],

                      // Fallback only if BOTH are empty.
                      if (product.description.isEmpty &&
                          product.highlights.isEmpty)
                        const Text(
                          'No additional details available for this product.',
                          style: TextStyle(
                            color: AppColors.textLight,
                            height: 1.6,
                          ),
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------
          // BOTTOM ACTION BAR
          // -------------------------------------------------------
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_addedToCart) {
                          // Already added from this screen -> jump straight
                          // to the cart instead of adding it again.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CartPage(),
                            ),
                          );
                        } else {
                          _addToCart(context, state, product);
                        }
                      },
                      icon: Icon(
                        _addedToCart
                            ? Icons.shopping_cart
                            : Icons.add_shopping_cart,
                        size: 18,
                      ),
                      label: Text(_addedToCart ? 'View Cart' : 'Add to Cart'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _buyNow(context, product),
                      icon: const Icon(Icons.flash_on, size: 18),
                      label: const Text('Buy Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.dark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===============================================================
  // DELIVERY DETAILS CARD
  // ===============================================================
  //
  // Shows the customer's SAVED delivery address (from AppState /
  // SharedPreferences — same source the Home page location picker
  // writes to) and an estimated delivery date, since these are custom
  // stitched orders (10-15 days), not next-day dispatch.
  Widget _buildDeliveryDetails(AppState state) {
    final hasAddress = state.deliveryLocation.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ADDRESS ROW
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
                await state.setDeliveryLocation(
                  display,
                  lat: picked.latitude,
                  lng: picked.longitude,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.home_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasAddress
                          ? state.deliveryLocation
                          : 'Add a delivery address',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasAddress
                            ? AppColors.text
                            : AppColors.textLight,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, indent: 12, endIndent: 12),

          // DELIVERY DATE ROW
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                      children: [
                        const TextSpan(text: 'Delivery by '),
                        TextSpan(
                          text: _estimatedDeliveryDate(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom-stitched orders take ~10-15 days. Shows a single target
  // date (midpoint, 12 days out) formatted like "Tuesday, 15 Sep" —
  // no `intl` package dependency needed.
  String _estimatedDeliveryDate() {
    final date = DateTime.now().add(const Duration(days: 12));

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, ${date.day} $month';
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  // ADD TO CART: adds the product then bumps its qty to match the
  // selector on this page. Stays on this screen (Flipkart behavior),
  // and flips the button into "View Cart" so tapping again jumps to
  // the cart instead of re-adding.
  void _addToCart(BuildContext context, AppState state, Product product) {
    state.addToCart(product);

    if (_qty > 1) {
      state.updateQty(product.id, _qty);
    }

    state.addNotification(
      'Added to cart',
      '${product.name} added to your cart.',
    );

    setState(() => _addedToCart = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // BUY NOW: does NOT touch the cart. Sends only this product straight to
  // the checkout flow. `qty` is final on Product, so instead of mutating
  // product.qty (not allowed) we pass the chosen quantity separately via
  // CheckoutPage's `quantities` map.
  void _buyNow(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          items: [product],
          fromCart: false,
          quantities: {product.id: _qty},
        ),
      ),
    );
  }
}