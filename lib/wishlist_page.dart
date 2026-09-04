import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_state.dart';
import '../models.dart';

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
          appBar: AppBar(
            title: const Text('My Wishlist'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_border, size: 64, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      const Text('No items in wishlist yet', style: TextStyle(color: AppColors.textLight)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _wishlistCard(context, state, items[i]),
                ),
        );
      },
    );
  }

  Widget _wishlistCard(BuildContext context, AppState state, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: product.isNetworkImage
                    ? Image.network(product.image, width: double.infinity, height: 130, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 130, color: AppColors.gray))
                    : Image.asset(product.image, width: double.infinity, height: 130, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 130, color: AppColors.gray)),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => state.toggleWishlist(product),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite, size: 14, color: AppColors.danger),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      state.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.name} moved to cart'), duration: const Duration(seconds: 1)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}