import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_state.dart';
import '../models.dart';
import 'product_details_page.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final items = state.wishlistItems;

        return Scaffold(
          backgroundColor: AppColors.light,

          // ----------------------------------------------------------
          // APP BAR
          // ----------------------------------------------------------
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'My Wishlist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ----------------------------------------------------------
          // BODY
          // ----------------------------------------------------------
          body: items.isEmpty
              ? _buildEmptyWishlist()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    // Responsive:
                    // Small mobile  -> 2 columns
                    // Tablet/Desktop -> 4 columns
                    final crossAxisCount = width >= 700 ? 4 : 2;

                    final horizontalPadding =
                        width >= 700 ? 20.0 : 10.0;

                    final spacing = width >= 700 ? 14.0 : 10.0;

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        20,
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio:
                            width >= 700 ? 0.78 : 0.62,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _WishlistProductCard(
                          product: items[index],
                          onTap: () {
                            _openProductDetails(
                              context,
                              items[index],
                            );
                          },
                          onWishlistTap: () {
                            state.toggleWishlist(items[index]);
                          },
                          onCartTap: () {
                            _addToCart(
                              context,
                              state,
                              items[index],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // EMPTY WISHLIST
  // ----------------------------------------------------------
  Widget _buildEmptyWishlist() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your Wishlist is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Save your favourite styles here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // OPEN FULL PRODUCT DETAILS
  // ----------------------------------------------------------
  void _openProductDetails(
    BuildContext context,
    Product product,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: product,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // ADD TO CART
  // ----------------------------------------------------------
  void _addToCart(
    BuildContext context,
    AppState state,
    Product product,
  ) {
    state.addToCart(product);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} added to cart 🛒',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ==================================================================
// WISHLIST PRODUCT CARD
// Same visual style as Home page product card
// ==================================================================

class _WishlistProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onCartTap;

  const _WishlistProductCard({
    required this.product,
    required this.onTap,
    required this.onWishlistTap,
    required this.onCartTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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

              // ----------------------------------------------------
              // IMAGE + WISHLIST + RATING
              // ----------------------------------------------------
              Expanded(
                flex: 7,
                child: Stack(
                  children: [

                    // PRODUCT IMAGE
                    Positioned.fill(
                      child: _ProductImage(
                        product: product,
                      ),
                    ),

                    // ------------------------------------------------
                    // HEART BUTTON
                    // ------------------------------------------------
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onWishlistTap,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: AppColors.danger,
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ------------------------------------------------
                    // RATING BADGE
                    // ------------------------------------------------
                    Positioned(
                      bottom: 9,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ----------------------------------------------------
              // PRODUCT INFORMATION
              // ----------------------------------------------------
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    8,
                    6,
                    8,
                    6,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      // NAME + PRICE
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // FIXED PRODUCT PRICE
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      // ------------------------------------------------
                      // CART ICON
                      // Same compact style as Home page
                      // ------------------------------------------------
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCartTap,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_checkout,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// PRODUCT IMAGE
// ==================================================================

class _ProductImage extends StatelessWidget {
  final Product product;

  const _ProductImage({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    if (product.image.trim().isEmpty) {
      return _placeholder();
    }

    if (product.isNetworkImage) {
      return Image.network(
        product.image,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _placeholder();
        },
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            color: AppColors.light,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      product.image,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.light,
      alignment: Alignment.center,
      child: const Icon(
        Icons.checkroom,
        size: 38,
        color: AppColors.primary,
      ),
    );
  }
}