// product_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_state.dart';
import 'models.dart';
import 'checkout.dart';
import 'cart_page.dart';
import 'login_page.dart';

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

  bool _loadingReviews = true;
  List<Map<String, dynamic>> _productReviews = [];
  bool _checkingEligibility = true;
  bool _eligibleToReview = false;
  Map<String, dynamic>? _myReview;
  final _reviewCommentCtrl = TextEditingController();
  int _reviewRating = 0;

  static const Color teal = Color(0xFF008C8C);
  static const Color tealDark = Color(0xFF007777);
  static const Color tealLight = Color(0xFFF1FFFB);
  static const Color gold = Color(0xFFD9B11E);

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
    _loadProductReviews();
    _checkReviewEligibility();
  }

  @override
  void dispose() {
    _reviewCommentCtrl.dispose();
    super.dispose();
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
      QuerySnapshot<Map<String, dynamic>> snap =
          await FirebaseFirestore.instance
              .collection('saved_addresses')
              .doc(phone)
              .collection('addresses')
              .get();

      // Backward-compatible fallback for addresses saved by the ApiService
      // address flow under users/{userId}/addresses.
      if (snap.docs.isEmpty) {
        snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(phone)
            .collection('addresses')
            .get();
      }

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
  // REVIEWS
  // -------------------------------------------------------------------

  Future<void> _loadProductReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('product', isEqualTo: widget.product.name)
          .get();
      final loaded = snap.docs.map((doc) {
        final m = doc.data();
        return {
          'id': doc.id,
          'mobile': '${m['mobile'] ?? ''}',
          'name': '${m['name'] ?? ''}',
          'rating': (num.tryParse('${m['rating'] ?? 5}') ?? 5).toInt(),
          'comment': '${m['comment'] ?? ''}',
        };
      }).toList();
      if (!mounted) return;
      setState(() => _productReviews = loaded);
    } catch (_) {
      // reviews are supplementary — fail silently
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _checkReviewEligibility() async {
    final phone = (AppState.instance.userId ?? '').trim();
    if (phone.isEmpty) {
      if (mounted) setState(() => _checkingEligibility = false);
      return;
    }
    try {
      final orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('mobile', isEqualTo: phone)
          .where('product', isEqualTo: widget.product.name)
          .where('status', isEqualTo: 'Delivered')
          .limit(1)
          .get();
      final reviewSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('mobile', isEqualTo: phone)
          .where('product', isEqualTo: widget.product.name)
          .limit(1)
          .get();
      if (!mounted) return;
      setState(() {
        _eligibleToReview = orderSnap.docs.isNotEmpty;
        _myReview = reviewSnap.docs.isNotEmpty
            ? {'id': reviewSnap.docs.first.id, ...reviewSnap.docs.first.data()}
            : null;
      });
    } catch (_) {
      // ignore — treat as not eligible
    } finally {
      if (mounted) setState(() => _checkingEligibility = false);
    }
  }

  double get _averageRating {
    if (_productReviews.isEmpty) return widget.product.rating;
    final total = _productReviews.fold<int>(0, (s, r) => s + ((r['rating'] as num?)?.toInt() ?? 0));
    return total / _productReviews.length;
  }

  Future<void> _submitProductReview() async {
    final phone = (AppState.instance.userId ?? '').trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to write a review!')),
      );
      return;
    }
    try {
      final data = {
        'mobile': phone,
        'name': AppState.instance.userName ?? '',
        'product': widget.product.name,
        'productImage': widget.product.image,
        'rating': _reviewRating,
        'comment': _reviewCommentCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final existingId = _myReview?['id']?.toString() ?? '';
      if (existingId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('reviews').doc(existingId).update(data);
      } else {
        await FirebaseFirestore.instance.collection('reviews').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review!')),
      );
      await _loadProductReviews();
      await _checkReviewEligibility();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit review: $e')),
        );
      }
    }
  }

  void _openWriteReviewSheet() {
    _reviewCommentCtrl.text = _myReview?['comment']?.toString() ?? '';
    _reviewRating = (_myReview?['rating'] as num?)?.toInt() ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: tealLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _myReview != null ? 'Edit Your Review' : 'Rate this Product',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tealDark),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        final selected = star <= _reviewRating;
                        return IconButton(
                          onPressed: () => setSheet(() => _reviewRating = star),
                          iconSize: 34,
                          icon: Icon(
                            selected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: selected ? gold : Colors.grey.shade400,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reviewCommentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tell others about this product...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_reviewRating == 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please select a star rating!')),
                            );
                            return;
                          }
                          _submitProductReview();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.white),
                        child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
      description: p.description,
      highlights: List<String>.from(p.highlights),
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
                      _averageRating.toStringAsFixed(1),
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
              Text(
                '${_productReviews.length} review${_productReviews.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
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
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // RATINGS & REVIEWS
          _buildReviewsSection(product),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _isInCart ? tealDark : teal,
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
    final description = product.description.trim();
    final highlights = product.highlights
        .map((h) => h.trim())
        .where((h) => h.isNotEmpty)
        .toList();

    final hasDescription = description.isNotEmpty;
    final hasHighlights = highlights.isNotEmpty;

    // Do not show a Description/Highlights area at all when the admin
    // has not entered either field.
    if (!hasDescription && !hasHighlights) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDescription) ...[
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
        if (hasDescription && hasHighlights)
          const SizedBox(height: 18),
        if (hasHighlights) ...[
          const Text(
            'Product Highlights',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            highlights.map((h) => '• $h').join('\n'),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  // -------------------------------------------------------------------
  // RATINGS & REVIEWS SECTION
  // -------------------------------------------------------------------

  Widget _buildReviewsSection(Product product) {
    final avg = _averageRating;
    final phone = (AppState.instance.userId ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Ratings & Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (!_checkingEligibility)
              TextButton.icon(
                onPressed: phone.isEmpty
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()))
                    : (_eligibleToReview ? _openWriteReviewSheet : null),
                icon: Icon(_myReview != null ? Icons.edit_outlined : Icons.star_border_rounded, size: 17),
                label: Text(
                  phone.isEmpty ? 'Login to Review' : (_myReview != null ? 'Edit Review' : 'Write a Review'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(foregroundColor: teal),
              ),
          ],
        ),
        if (phone.isNotEmpty && !_checkingEligibility && !_eligibleToReview && _myReview == null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Text(
              'Buy this product and once it is delivered, you can write a review.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: gold, size: 20),
            const SizedBox(width: 4),
            Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              '(${_productReviews.length} review${_productReviews.length == 1 ? '' : 's'})',
              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: teal)),
          )
        else if (_productReviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No reviews yet. Be the first to review this product!',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          )
        else
          ..._productReviews.map((r) => _productReviewCard(r, phone)),
      ],
    );
  }

  Widget _productReviewCard(Map<String, dynamic> review, String myPhone) {
    final rating = (review['rating'] as num?)?.toInt() ?? 5;
    final comment = review['comment']?.toString() ?? '';
    final rawName = review['name']?.toString().trim() ?? '';
    final name = rawName.isNotEmpty ? rawName : 'Customer';
    final isMine = myPhone.isNotEmpty && review['mobile'] == myPhone;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tealLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EEE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: teal,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMine ? '$name (You)' : name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Text('★' * rating + '☆' * (5 - rating), style: const TextStyle(color: gold, fontSize: 13)),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: const TextStyle(fontSize: 12.5, color: Color(0xFF30363B), height: 1.5)),
          ],
        ],
      ),
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