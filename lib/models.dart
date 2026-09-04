import 'package:flutter/material.dart';
import 'app_colors.dart';

class QuickCategory {
  final String label;
  final String imageUrl;
  const QuickCategory(this.label, this.imageUrl);
}

class Product {
  final int id;
  final String name;
  final double price;
  final String image; // can be asset path OR network url (see isNetworkImage)
  final double rating;
  final int qty; // used inside cart only
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.rating = 4.5,
    this.qty = 1,
  });

  bool get isNetworkImage => image.startsWith('http');

  Product copyWith({int? qty}) => Product(
        id: id,
        name: name,
        price: price,
        image: image,
        rating: rating,
        qty: qty ?? this.qty,
      );
}

/// One hero slide = its own image, text AND its own CTA button
/// (label + destination + color) — matches Divya's 3-slide requirement:
/// Slide 1 -> Shop Now, Slide 2 -> Bridal Package, Slide 3 -> Custom Order
class HeroSlide {
  final String title;
  final String subtitle;
  final String tagline;
  final String imageUrl;
  final String buttonLabel;
  final Color buttonColor;
  final Color buttonTextColor;
  final VoidCallback? onTap;
  const HeroSlide({
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.imageUrl,
    required this.buttonLabel,
    this.buttonColor = AppColors.gold,
    this.buttonTextColor = AppColors.dark,
    this.onTap,
  });
}

class AppNotification {
  final int id;
  final String title;
  final String message;
  final DateTime time;
  bool read;
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });
}