// product_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_state.dart';
import 'models.dart';
import 'checkout.dart';
import 'cart_page.dart';

/// ---------------------------------------------------------------------
/// PRODUCT DETAILS PAGE — Sumathi's Styles
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
      if (mounted) setState(() => _loadingAddress = false);
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
      setState(() => _loadingAddress = false);
    }
  }

  // -------------------------------------------------------------------
  // CART HELPERS
  // -------------------------------------------------------------------

  bool get _isInCart =>
      AppState.instance.cartItems.any((p) => p.id == widget.product.id);

  Product _productWithQty(int qty) {
    final p = widget.product;
    return Product(
      id: p.id,
      name: p.name,
      price: p.price,
      image: p.image,
      rating: p.rating,
      qty: qty,
    );
  }

  void _addToCart() {
    AppState.instance.addToCart(_productWithQty(_qty));
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart! 🛒'),
        action: SnackBarAction(label: 'VIEW CART', onPressed: _goToCart),
      ),
    );
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
        final isWishlisted = state.wishlistIds.contains(product.id);

        return Scaffold(
          backgroundColor: tealLight,
          appBar: AppBar(
            backgroundColor: teal,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Product Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
            actions: [
                           IconButton(
                tooltip: 'Wishlist',
                icon: Icon(
                  isWishlisted
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 24,
                  color: isWishlisted ? Colors.red : Colors.white,
                ),
                onPressed: () => state.toggleWishlist(_productWithQty(1)),
              ),
              IconButton(
                tooltip: 'Cart',
                icon: const Icon(Icons.shopping_cart_outlined, size: 24),
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
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Hero(
        tag: 'product_${product.id}',
        child: product.isNetworkImage
            ? Image.network(
                product.image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              )
            : Image.asset(
                product.image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF6F8F7),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 44,
        color: teal,
      ),
    );
  }

  // -------------------------------------------------------------------
  // PRODUCT INFORMATION
  // Order: name -> rating -> price -> delivery card -> quantity ->
  //        add to cart/buy now -> description -> highlights
  // -------------------------------------------------------------------

  Widget _buildProductInfo(Product product) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SUMATHI'S STYLE",
            style: TextStyle(
              color: teal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Color(0xFF20252B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF35A853),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.rating.toStringAsFixed(1),
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
              const Text('', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Divider(height: 26),
          Text(
            '₹${product.price.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: tealDark),
          ),
          const SizedBox(height: 4),
          const Text(
            '',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // DELIVERY CARD
          _buildDeliveryCard(),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // QUANTITY
          _buildQuantity(),
          const SizedBox(height: 18),

          // ADD TO CART / BUY NOW — right below Quantity
          _buildActionButtons(),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // DESCRIPTION + HIGHLIGHTS — at the very end
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFFFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5EEE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.home_outlined, size: 18, color: teal),
              const SizedBox(width: 10),
              Expanded(child: _buildAddressContent()),
              if (!_loadingAddress && _address.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ),
            ],
          ),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.local_shipping_outlined, size: 18, color: teal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Custom stitched — delivered within 10–15 days',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF30363B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // ADDRESS CONTENT
  // -------------------------------------------------------------------

  Widget _buildAddressContent() {
    if (_loadingAddress) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: teal),
          ),
          SizedBox(width: 10),
          Text('Loading saved address...', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
        ],
      );
    }

    if (_address.isEmpty) {
      return const Text(
        'Add a delivery address in your profile',
        style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.35),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recipient.isNotEmpty)
          Text(
            _recipient,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20252B),
            ),
          ),
        const SizedBox(height: 3),
        Text(_address, style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF30363B))),
        if (_addressPhone.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text('Phone: +91 $_addressPhone', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
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
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9DEDD)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
    );
  }

  // -------------------------------------------------------------------
  // ACTION BUTTONS — Add to Cart / View Cart toggle + Buy Now
  // -------------------------------------------------------------------

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                if (_isInCart) {
                  _goToCart();
                } else {
                  _addToCart();
                }
              },
              icon: Icon(
                _isInCart ? Icons.shopping_cart_checkout : Icons.shopping_cart,
                size: 16,
              ),
              label: Text(
                _isInCart ? 'View Cart' : 'Add to Cart',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: tealDark,
                side: const BorderSide(color: teal, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _buyNow,
              icon: const Icon(Icons.flash_on_rounded, size: 16),
              label: const Text('Buy Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: const Color(0xFF20252B),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    final hasDescription = product.description.trim().isNotEmpty;
    final hasHighlights = product.highlights.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Text(
          hasDescription
              ? product.description
              : 'Made to order, custom stitched with quality checked finishing.',
          style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
        ),
        if (hasHighlights) ...[
          const SizedBox(height: 18),
          const Text('Product Highlights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(
            product.highlights.map((h) => '• $h').join('\n'),
            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  // -------------------------------------------------------------------
  // NAVIGATION
  // -------------------------------------------------------------------

  void _goToCart() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
  }

  void _buyNow() {
    final product = _productWithQty(_qty);
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