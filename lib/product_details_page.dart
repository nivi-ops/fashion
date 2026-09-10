import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_state.dart';
import 'models.dart';
import 'checkout.dart';
import 'cart_page.dart';

/// ---------------------------------------------------------------------
/// PRODUCT DETAILS PAGE — Sumathi's Styles
/// ---------------------------------------------------------------------
///
/// Features:
/// - Product image shown fully using BoxFit.contain
/// - Saved delivery address loaded from Firestore
/// - Custom stitching delivery promise shown
/// - Delivery details shown ABOVE View Cart / Buy Now
/// - Wishlist button
/// - Cart button
/// - Quantity selector
/// - Buy Now passes selected quantity to CheckoutPage
/// - Mobile responsive layout
/// ---------------------------------------------------------------------

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _qty = 1;

  bool _loadingAddress = true;
  String _address = '';
  String _recipient = '';
  String _addressPhone = '';

  static const Color teal = Color(0xFF008C8C);
  static const Color tealDark = Color(0xFF007777);
  static const Color tealLight = Color(0xFFF1FFFB);
  static const Color gold = Color(0xFFD9B11E);

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  // -------------------------------------------------------------------
  // LOAD SAVED ADDRESS
  // -------------------------------------------------------------------

  Future<void> _loadSavedAddress() async {
    final phone = (AppState.instance.userId ?? '').trim();

    if (phone.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingAddress = false;
        });
      }
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('saved_addresses')
          .doc(phone)
          .collection('addresses')
          .get();

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        setState(() {
          _address = '';
          _recipient = '';
          _addressPhone = '';
          _loadingAddress = false;
        });
        return;
      }

      // First saved address is treated as the default address.
      final data = snap.docs.first.data();

      final parts = <String>[
        '${data['door'] ?? ''}'.trim(),
        '${data['street'] ?? ''}'.trim(),
        '${data['area'] ?? ''}'.trim(),
        '${data['city'] ?? ''}'.trim(),
        '${data['state'] ?? ''}'.trim(),
        '${data['pin'] ?? ''}'.trim(),
      ].where((e) => e.isNotEmpty).toList();

      setState(() {
        _recipient = '${data['recipient'] ?? ''}'.trim();
        _addressPhone = '${data['phone'] ?? ''}'.trim();
        _address = parts.join(', ');
        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingAddress = false;
      });
    }
  }

  // -------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final product = widget.product;

        final isWishlisted =
            state.wishlistIds.contains(product.id);

        return Scaffold(
          backgroundColor: tealLight,

          appBar: AppBar(
            backgroundColor: teal,
            foregroundColor: Colors.white,
            elevation: 0,

            title: const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),

            actions: [
              // Wishlist
              IconButton(
                tooltip: 'Wishlist',
                icon: Icon(
                  isWishlisted
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 29,
                ),
                onPressed: () {
                  state.toggleWishlist(product);
                },
              ),

              // Cart
              IconButton(
                tooltip: 'Cart',
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 29,
                ),
                onPressed: _goToCart,
              ),

              const SizedBox(width: 4),
            ],
          ),

          body: RefreshIndicator(
            color: teal,

            onRefresh: _loadSavedAddress,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(product),
                  _buildProductInfo(product),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // PRODUCT IMAGE
  // -------------------------------------------------------------------

  Widget _buildProductImage(Product product) {
    return Container(
      width: double.infinity,
      height: 360,
      color: Colors.white,

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      child: Hero(
        tag: 'product_${product.id}',

        child: product.isNetworkImage
            ? Image.network(
                product.image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,

                errorBuilder: (_, __, ___) {
                  return _imagePlaceholder();
                },
              )
            : Image.asset(
                product.image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,

                errorBuilder: (_, __, ___) {
                  return _imagePlaceholder();
                },
              ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // IMAGE PLACEHOLDER
  // -------------------------------------------------------------------

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF6F8F7),
      alignment: Alignment.center,

      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 54,
        color: teal,
      ),
    );
  }

  // -------------------------------------------------------------------
  // PRODUCT INFORMATION
  // -------------------------------------------------------------------

  Widget _buildProductInfo(Product product) {
    return Container(
      width: double.infinity,
      color: Colors.white,

      padding: const EdgeInsets.fromLTRB(
        29,
        24,
        29,
        30,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          const Text(
            "SUMATHI'S STYLE",

            style: TextStyle(
              color: teal,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 6),

          // Product name
          Text(
            product.name,

            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF20252B),
            ),
          ),

          const SizedBox(height: 13),

          // Rating
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFF35A853),
                  borderRadius: BorderRadius.circular(6),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.rating.toStringAsFixed(1),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 3),

                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 13,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 11),

              const Text(
                'New Listing',

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(height: 1),

          const SizedBox(height: 24),

          // Price
          Text(
            '₹${product.price.toStringAsFixed(0)}',

            style: const TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.w500,
              color: tealDark,
            ),
          ),

          const SizedBox(height: 10),

          // Delivery price message
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F0),
              borderRadius: BorderRadius.circular(8),
            ),

            child: Text(
              product.price >= 500
                  ? 'Free delivery above ₹500'
                  : 'Delivery available',

              style: const TextStyle(
                color: Color(0xFF32935A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Delivery details ABOVE buttons
          _buildDeliveryCard(),

          const SizedBox(height: 22),

          // Quantity
          _buildQuantity(),

          const SizedBox(height: 22),

          // Cart + Buy Now
          _buildActionButtons(product),

          const SizedBox(height: 28),

          const Divider(height: 1),

          const SizedBox(height: 22),

          // Description
          _buildDescription(product),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // DELIVERY CARD
  // -------------------------------------------------------------------

  Widget _buildDeliveryCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(
        16,
        15,
        16,
        5,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFFAFFFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5EEE9),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery details',

            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20252B),
            ),
          ),

          const SizedBox(height: 12),

          // Address row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.home_outlined,
                color: teal,
                size: 24,
              ),

              const SizedBox(width: 13),

              Expanded(
                child: _buildAddressContent(),
              ),

              if (!_loadingAddress && _address.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 7),

                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                    size: 22,
                  ),
                ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),

            child: Divider(height: 1),
          ),

          // Custom stitching delivery
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: teal,
                size: 24,
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 2),

                  child: Text(
                    'Custom stitched — delivered within 10–15 days',

                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF30363B),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // ADDRESS CONTENT
  // -------------------------------------------------------------------

  Widget _buildAddressContent() {
    // Loading
    if (_loadingAddress) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 5),

        child: Row(
          children: [
            SizedBox(
              width: 17,
              height: 17,

              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: teal,
              ),
            ),

            SizedBox(width: 10),

            Text(
              'Loading saved address...',

              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // No address
    if (_address.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),

        child: Text(
          'Add a delivery address in your profile',

          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      );
    }

    // Saved address
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recipient.isNotEmpty)
          Text(
            _recipient,

            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20252B),
            ),
          ),

        const SizedBox(height: 3),

        Text(
          _address,

          style: const TextStyle(
            fontSize: 14,
            height: 1.35,
            color: Color(0xFF30363B),
          ),
        ),

        if (_addressPhone.isNotEmpty) ...[
          const SizedBox(height: 3),

          Text(
            'Phone: +91 $_addressPhone',

            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------
  // QUANTITY
  // -------------------------------------------------------------------

  Widget _buildQuantity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',

          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          height: 55,
          width: 235,

          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFD9DEDD),
            ),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Minus
              _quantityButton(
                Icons.remove,
                () {
                  if (_qty > 1) {
                    setState(() {
                      _qty--;
                    });
                  }
                },
              ),

              // Quantity number
              Text(
                '$_qty',

                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Plus
              _quantityButton(
                Icons.add,
                () {
                  setState(() {
                    _qty++;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // QUANTITY BUTTON
  // -------------------------------------------------------------------

  Widget _quantityButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,

      child: Padding(
        padding: const EdgeInsets.all(9),

        child: Icon(
          icon,
          size: 19,
          color: const Color(0xFF30363B),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // ACTION BUTTONS
  // -------------------------------------------------------------------

  Widget _buildActionButtons(Product product) {
    return Row(
      children: [
        // VIEW CART
        Expanded(
          child: SizedBox(
            height: 56,

            child: OutlinedButton.icon(
              onPressed: _goToCart,

              icon: const Icon(
                Icons.shopping_cart_checkout,
                size: 22,
              ),

              label: const Text(
                'View Cart',

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: tealDark,

                side: const BorderSide(
                  color: teal,
                  width: 1.5,
                ),

                backgroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // BUY NOW
        Expanded(
          child: SizedBox(
            height: 56,

            child: ElevatedButton.icon(
              onPressed: () {
                _buyNow(context, product);
              },

              icon: const Icon(
                Icons.flash_on_rounded,
                size: 22,
              ),

              label: const Text(
                'Buy Now',

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: gold,

                foregroundColor: const Color(0xFF20252B),

                elevation: 2,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // DESCRIPTION
  // -------------------------------------------------------------------

  Widget _buildDescription(Product product) {
    final hasDescription =
        product.description.trim().isNotEmpty;

    final hasHighlights =
        product.highlights.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',

          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          hasDescription
              ? product.description
              : 'Made to order, custom stitched with quality checked finishing.',

          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            height: 1.55,
          ),
        ),

        if (hasHighlights) ...[
          const SizedBox(height: 22),

          const Text(
            'Product Highlights',

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 9),

          ...product.highlights.map(
            (h) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 6,
                ),

                child: Text(
                  '• $h',

                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              );
            },
          ),
        ],

        const SizedBox(height: 28),
      ],
    );
  }

  // -------------------------------------------------------------------
  // GO TO CART
  // -------------------------------------------------------------------

  void _goToCart() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => const CartPage(),
      ),
    );
  }

  // -------------------------------------------------------------------
  // BUY NOW
  // -------------------------------------------------------------------

  void _buyNow(
    BuildContext context,
    Product product,
  ) {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          items: [product],
          fromCart: false,

          quantities: {
            product.id: _qty,
          },
        ),
      ),
    );
  }
}