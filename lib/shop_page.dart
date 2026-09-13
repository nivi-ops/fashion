// shop_page.dart
//
// Sumathi's Styles - Shop Collection
// ------------------------------------------------------------
// Features:
// • Category sidebar
// • Product grid
// • Home-page style product cards
// • Wishlist button
// • Rating badge
// • Add to Cart / View Cart button
// • Buy Now button
// • Product details page (shared with Home)
// • Delivery location
// • Product description
// • Product highlights
// ------------------------------------------------------------

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_colors.dart';
import 'app_state.dart';
import 'models.dart';
import 'checkout.dart';
import 'cart_page.dart';
import 'product_details_page.dart';

class ShopPage extends StatefulWidget {
  final String? initialFilter;

  const ShopPage({
    super.key,
    this.initialFilter,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

// ============================================================
// CATEGORY MODEL
// ============================================================

class _CategoryDef {
  final String label;
  final String? imagePath;
  final IconData icon;

  const _CategoryDef(
    this.label, {
    this.imagePath,
    required this.icon,
  });
}

// ============================================================
// SHOP PAGE STATE
// ============================================================

class _ShopPageState extends State<ShopPage> {
  final ApiService _api = ApiService.instance;

  late Future<List<StitchingService>> _servicesFuture;
  late String _selectedCategory;

  // ============================================================
  // CATEGORIES
  // ============================================================

  static const List<_CategoryDef> _categories = [
    _CategoryDef(
      'All',
      icon: Icons.grid_view_rounded,
    ),
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

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _selectedCategory = widget.initialFilter ?? 'All';

    _servicesFuture = _api.getServices(
      category: _selectedCategory == 'All'
          ? null
          : _selectedCategory,
    );
  }

  // ============================================================
  // CATEGORY SELECT
  // ============================================================

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;

      _servicesFuture = _api.getServices(
        category: category == 'All' ? null : category,
      );
    });
  }

  // ============================================================
  // RATING
  // ============================================================

  double _ratingFor(String id) {
    final seed = id.codeUnits.fold<int>(
      0,
      (a, b) => a + b,
    );

    return 4.3 + (seed % 3) * 0.2;
  }

  // ============================================================
  // PRODUCT ID
  // ============================================================

  int _productIdFor(StitchingService service) {
    return service.id.hashCode;
  }

  // ============================================================
  // CHECK CART
  // ============================================================

  bool _isInCart(StitchingService service) {
    final pid = _productIdFor(service);

    return AppState.instance.cartItems.any(
      (p) => p.id == pid,
    );
  }

  // ============================================================
  // CONVERT SERVICE → PRODUCT
  // ============================================================

  Product _productFrom(
    StitchingService service,
    int qty,
  ) {
    return Product(
      id: _productIdFor(service),
      name: service.name,
      price: service.price,
      image: service.imageUrl,
      rating: _ratingFor(service.id),
      qty: qty,
      description: service.description.trim(),
      highlights: List<String>.from(
        service.highlights,
      ),
    );
  }

  // ============================================================
  // GO TO CART
  // ============================================================

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartPage(),
      ),
    );
  }

  // ============================================================
  // OPEN PRODUCT DETAIL
  // ============================================================

  void _openProductDetail(
    StitchingService service,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: _productFrom(
            service,
            1,
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  void _addToCart(
    StitchingService service,
    int qty,
  ) {
    AppState.instance.addToCart(
      _productFrom(
        service,
        qty,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${service.name} added to cart! 🛒',
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: _goToCart,
        ),
      ),
    );
  }

  // ============================================================
  // BUY NOW
  // ============================================================

  Future<void> _bookService(
    StitchingService service, {
    int qty = 1,
  }) async {
    if (!mounted) return;

    final product = _productFrom(
      service,
      qty,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          items: [product],
          fromCart: false,
          quantities: {
            product.id: qty,
          },
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (
        context,
        _,
      ) {
        return Scaffold(
          backgroundColor: AppColors.light,

          // ======================================================
          // APP BAR
          // ======================================================

          appBar: AppBar(
            title: const Text(
              'Shop Collection',
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),

          // ======================================================
          // BODY
          // ======================================================

          body: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildCategorySidebar(),

              Expanded(
                child: _buildProductArea(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CATEGORY SIDEBAR
  // ============================================================

  Widget _buildCategorySidebar() {
    return Container(
      width: 78,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        itemCount: _categories.length,
        itemBuilder: (
          context,
          index,
        ) {
          final cat = _categories[index];

          final isActive =
              cat.label == _selectedCategory;

          return InkWell(
            onTap: () {
              _onCategorySelected(
                cat.label,
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.light
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isActive
                        ? AppColors.secondary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // ==================================================
                  // CATEGORY IMAGE
                  // ==================================================

                  Container(
                    width: 40,
                    height: 40,
                    clipBehavior:
                        Clip.antiAlias,
                    decoration:
                        BoxDecoration(
                      color: AppColors.light,
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    child:
                        cat.imagePath != null
                            ? Image.asset(
                                cat.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                  _,
                                  __,
                                  ___,
                                ) {
                                  return Icon(
                                    cat.icon,
                                    size: 18,
                                    color: AppColors
                                        .primary,
                                  );
                                },
                              )
                            : Icon(
                                cat.icon,
                                size: 18,
                                color: AppColors
                                    .primary,
                              ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    cat.label,
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
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

  // ============================================================
  // PRODUCT AREA
  // ============================================================

  Widget _buildProductArea() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: FutureBuilder<
          List<StitchingService>>(
        future: _servicesFuture,
        builder: (
          context,
          snapshot,
        ) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  'Something went wrong:\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }

          final services =
              snapshot.data ?? [];

          // ======================================================
          // EMPTY
          // ======================================================

          if (services.isEmpty) {
            return const Center(
              child: Text(
                'No products found in this category.',
                style: TextStyle(
                  color:
                      AppColors.textLight,
                  fontSize: 14,
                ),
              ),
            );
          }

          // ======================================================
          // PRODUCT GRID
          // ======================================================
                   return GridView.builder(
            padding: const EdgeInsets.only(
              bottom: 20,
            ),
            physics:
                const BouncingScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemCount: services.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  final service =
                      services[index];

                  final productId =
                      _productIdFor(
                    service,
                  );

                  return _ProductCard(
                    service: service,

                    rating:
                        _ratingFor(
                      service.id,
                    ),

                    isWishlisted: AppState
                        .instance
                        .wishlistIds
                        .contains(productId),

                    // Card tap
                    onTap: () {
                      _openProductDetail(
                        service,
                      );
                    },

                    // Wishlist
                    onWishlistTap: () {
                      AppState.instance
                          .toggleWishlist(
                        _productFrom(
                          service,
                          1,
                        ),
                      );

                      setState(() {});
                    },

                    // Cart
                    onCartTap: () {
                      if (_isInCart(
                        service,
                      )) {
                        _goToCart();
                      } else {
                        _addToCart(
                          service,
                          1,
                        );

                        setState(() {});
                      }
                    },

                   // Buy Now
                    onBuyNowTap: () {
                      _bookService(
                        service,
                        qty: 1,
                      );
                    },
                  );
                },
              );
        },
      ),
    );
  }
}

// ================================================================
// PRODUCT CARD
// ================================================================

class _ProductCard extends StatelessWidget {
  final StitchingService service;
  final double rating;
  final bool isWishlisted;

  final VoidCallback onTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onCartTap;
  final VoidCallback onBuyNowTap;

  const _ProductCard({
    required this.service,
    required this.rating,
    required this.isWishlisted,
    required this.onTap,
    required this.onWishlistTap,
    required this.onCartTap,
    required this.onBuyNowTap,
  });

  // ============================================================
  // CART CHECK
  // ============================================================

  bool _isAlreadyInCart() {
    final productId =
        service.id.hashCode;

    return AppState.instance.cartItems.any(
      (item) => item.id == productId,
    );
  }

  // ============================================================
  // BUILD CARD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final isInCart =
        _isAlreadyInCart();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color:
                const Color(0xFFE8E8E8),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                alpha: 0.055,
              ),
              blurRadius: 7,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior:
            Clip.antiAlias,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PRODUCT IMAGE
            // ==================================================

            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(
                      top:
                          Radius.circular(10),
                    ),
                    child: Image.network(
                      service.imageUrl,
                      fit: BoxFit.cover,
                      alignment:
                          Alignment.topCenter,
                      errorBuilder:
                          (
                        _,
                        __,
                        ___,
                      ) {
                        return Container(
                          color:
                              AppColors.gray,
                          alignment:
                              Alignment.center,
                          child:
                              const Icon(
                            Icons
                                .image_not_supported,
                            color:
                                AppColors
                                    .textLight,
                          ),
                        );
                      },
                    ),
                  ),

                  // ------------------------------------------------
                  // WISHLIST HEART
                  // ------------------------------------------------

                  Positioned(
                    top: 7,
                    right: 7,
                    child: Material(
                      color: Colors.white,
                      shape:
                          const CircleBorder(),
                      elevation: 1.5,
                      child: InkWell(
                        onTap:
                            onWishlistTap,
                        customBorder:
                            const CircleBorder(),
                        child: SizedBox(
                          width: 29,
                          height: 29,
                          child: Icon(
                            isWishlisted
                                ? Icons
                                    .favorite
                                : Icons
                                    .favorite_border,
                            size: 16,
                            color: isWishlisted
                                ? AppColors
                                    .danger
                                : Colors
                                    .grey
                                    .shade700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // RATING
                  // ------------------------------------------------

                  Positioned(
                    left: 7,
                    bottom: 7,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF388E3C,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(4),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Text(
                            rating
                                .toStringAsFixed(
                              1,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 9.5,
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          const Icon(
                            Icons.star,
                            size: 9,
                            color:
                                Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // PRODUCT INFO
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                8,
                8,
                7,
                8,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  // ------------------------------------------------
                  // PRODUCT NAME + PRICE
                  // ------------------------------------------------

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              service.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 11.5,
                                fontWeight:
                                    FontWeight
                                        .w500,
                                color:
                                    AppColors
                                        .text,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '₹${service.price.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    Color(
                                  0xFF212121,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      // ------------------------------------------------
                      // CART BUTTON
                      // ------------------------------------------------

                      Material(
                        color: isInCart
                            ? AppColors
                                .primaryDark
                            : AppColors
                                .primary
                                .withValues(
                                alpha: 0.10,
                              ),
                        borderRadius:
                            BorderRadius
                                .circular(7),
                        child: InkWell(
                          onTap:
                              onCartTap,
                          borderRadius:
                              BorderRadius
                                  .circular(7),
                          child: SizedBox(
                            width: 31,
                            height: 31,
                            child: Icon(
                              isInCart
                                  ? Icons
                                      .shopping_cart_checkout
                                  : Icons
                                      .add_shopping_cart,
                              size: 16,
                              color: isInCart
                                  ? Colors
                                      .white
                                  : AppColors
                                      .primary,
                            ),
                          ),
                        ),
                      ),
                    ],
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