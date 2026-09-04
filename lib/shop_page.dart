// shop_page.dart
// Flutter version of shop.html's Flipkart-style shop UI:
// vertical category sidebar (small icons), horizontal-scroll product
// cards (image, rating badge, wishlist heart), and a product-detail
// bottom sheet (image, price, qty stepper, Add to Cart / Buy Now,
// delivery + description + highlights) — same look as the website.
//
// NOTE: sidebar categories match shop.html's list (Kids, Uniform,
// Modern, Salwar, Blouse, Aari, Saree, Frock, Lehenga, Kurthi), but the
// underlying mock data in api_service.dart only has services tagged
// Blouse/Saree/Suit/Alteration/Custom — categories outside that set
// will show "No services found" until mock data / a real backend is
// updated to match.

import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_colors.dart';

class ShopPage extends StatefulWidget {
  final String? initialFilter;

  const ShopPage({super.key, this.initialFilter});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _CategoryDef {
  final String label;

  // Image shown in the sidebar (from assets/images/). Null for
  // categories without a dedicated photo (e.g. "All"), which fall
  // back to [icon] instead.
  final String? imagePath;
  final IconData icon;

  const _CategoryDef(
    this.label, {
    this.imagePath,
    required this.icon,
  });
}

class _ShopPageState extends State<ShopPage> {
  final ApiService _api = ApiService.instance;

  late Future<List<StitchingService>> _servicesFuture;
  late String _selectedCategory;

  // Wishlist kept in-memory for this session (mirrors shop.html's
  // localStorage-backed wishlist, minus persistence).
  final Set<String> _wishlist = {};

  // Matches the shop.html sidebar list/order. Image paths point at
  // the actual files in assets/images/ (case-sensitive filenames,
  // matched exactly as they exist on disk).
  static const List<_CategoryDef> _categories = [
    _CategoryDef('All', icon: Icons.grid_view_rounded),
    _CategoryDef(
      'Kids',
      imagePath: 'assets/images/kids.png',
      icon: Icons.child_care,
    ),
    _CategoryDef(
      'Uniform',
      imagePath: 'assets/images/unifrom.png',
      icon: Icons.school,
    ),
    _CategoryDef(
      'Modern',
      imagePath: 'assets/images/modern.png',
      icon: Icons.checkroom,
    ),
    _CategoryDef(
      'Salwar',
      imagePath: 'assets/images/salwar.png',
      icon: Icons.checkroom,
    ),
    _CategoryDef(
      'Blouse',
      imagePath: 'assets/images/Blouse.png',
      icon: Icons.dry_cleaning,
    ),
    _CategoryDef(
      'Aari',
      imagePath: 'assets/images/Aari wrk.png',
      icon: Icons.brush,
    ),
    _CategoryDef(
      'Saree',
      imagePath: 'assets/images/ss.jpg',
      icon: Icons.woman,
    ),
    _CategoryDef(
      'Frock',
      imagePath: 'assets/images/Frocks.png',
      icon: Icons.girl,
    ),
    _CategoryDef(
      'Lehenga',
      imagePath: 'assets/images/leng.jpg',
      icon: Icons.diamond,
    ),
    _CategoryDef(
      'Kurthi',
      imagePath: 'assets/images/kurthi.png',
      icon: Icons.checkroom,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilter ?? 'All';
    _servicesFuture = _api.getServices(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _servicesFuture = _api.getServices(
        category: category == 'All' ? null : category,
      );
    });
  }

  void _toggleWishlist(String id) {
    setState(() {
      if (_wishlist.contains(id)) {
        _wishlist.remove(id);
      } else {
        _wishlist.add(id);
      }
    });
  }

  double _ratingFor(String id) {
    // Deterministic pseudo-rating per item, same spirit as
    // ApiService.fetchProducts()'s 4.3 + (i % 3) * 0.2 pattern.
    final seed = id.codeUnits.fold<int>(0, (a, b) => a + b);
    return 4.3 + (seed % 3) * 0.2;
  }

  Future<void> _openProductDetail(StitchingService service) async {
    int qty = 1;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isWishlisted = _wishlist.contains(service.id);
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.zero,
                          children: [
                            // ---- Image + wishlist heart (pd-left) ----
                            Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: Image.network(
                                    service.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.light,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.checkroom, size: 50),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: InkWell(
                                    onTap: () {
                                      _toggleWishlist(service.id);
                                      setSheetState(() {});
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isWishlisted
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isWishlisted
                                            ? const Color(0xFFE53935)
                                            : Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ---- Right panel (pd-right) ----
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "SUMATHI'S STYLE",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    service.name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                                              _ratingFor(service.id)
                                                  .toStringAsFixed(1),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            const Icon(Icons.star,
                                                color: Colors.white, size: 11),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'New Listing',
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 26),
                                  Text(
                                    '₹${service.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Free delivery above ₹500',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Qty stepper
                                  Row(
                                    children: [
                                      const Text('Qty:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xFFE0E0E0)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                if (qty > 1) {
                                                  setSheetState(() => qty--);
                                                }
                                              },
                                              icon: const Icon(Icons.remove, size: 16),
                                              constraints: const BoxConstraints(
                                                  minWidth: 34, minHeight: 34),
                                              padding: EdgeInsets.zero,
                                            ),
                                            SizedBox(
                                              width: 28,
                                              child: Text(
                                                '$qty',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                if (qty < 10) {
                                                  setSheetState(() => qty++);
                                                }
                                              },
                                              icon: const Icon(Icons.add, size: 16),
                                              constraints: const BoxConstraints(
                                                  minWidth: 34, minHeight: 34),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // Add to Cart / Buy Now
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 46,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _addToCartAndConfirm(service, qty);
                                            },
                                            icon: const Icon(
                                                Icons.shopping_cart, size: 16),
                                            label: const Text('Add to Cart'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SizedBox(
                                          height: 46,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.secondary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _bookService(service, qty: qty);
                                            },
                                            icon: const Icon(Icons.bolt, size: 16),
                                            label: const Text('Buy Now'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Delivery section (static, matches pd-delivery)
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color(0xFFE0E0E0)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Delivery details',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: const [
                                            Icon(Icons.local_shipping_outlined,
                                                size: 18),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Custom stitched — delivered within 10–15 days',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    service.description,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textLight,
                                        height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _addToCartAndConfirm(StitchingService service, int qty) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service.name} added to cart! 🛒')),
    );
  }

  Future<void> _bookService(StitchingService service, {int qty = 1}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service.name),
        content: Text(
          '${service.description}\n\nQty: $qty\nTotal: ₹${(service.price * qty).toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _api.placeOrder(
      serviceName: service.name,
      amount: service.price * qty,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service.name} booked successfully! 🎉')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Shop Collection'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySidebar(),
          Expanded(child: _buildProductArea()),
        ],
      ),
    );
  }

  // ---------------- SIDEBAR (matches .shop-cat-sidebar) ----------------

  Widget _buildCategorySidebar() {
    return Container(
      width: 78,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = cat.label == _selectedCategory;
          return InkWell(
            onTap: () => _onCategorySelected(cat.label),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.light : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isActive ? AppColors.secondary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: cat.imagePath != null
                        ? Image.asset(
                            cat.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              cat.icon,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            cat.icon,
                            size: 18,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.secondary
                          : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- PRODUCT GRID (matches .products-grid / .product-card) ----------------

  Widget _buildProductArea() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<List<StitchingService>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return const Center(child: Text('No products found in this category.'));
          }
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return _ProductCard(
                service: services[index],
                rating: _ratingFor(services[index].id),
                isWishlisted: _wishlist.contains(services[index].id),
                onTap: () => _openProductDetail(services[index]),
                onWishlistTap: () => _toggleWishlist(services[index].id),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final StitchingService service;
  final double rating;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;

  const _ProductCard({
    required this.service,
    required this.rating,
    required this.isWishlisted,
    required this.onTap,
    required this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Image.network(
                    service.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.light,
                      alignment: Alignment.center,
                      child: const Icon(Icons.checkroom, size: 34),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: onWishlistTap,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isWishlisted
                            ? const Color(0xFFE53935)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star, size: 10, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}