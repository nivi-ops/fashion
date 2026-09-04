import 'package:flutter/material.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool desktop = MediaQuery.of(context).size.width > 900;

    final List<Map<String, dynamic>> categories = [
      {"icon": Icons.checkroom, "title": "Women"},
      {"icon": Icons.man, "title": "Men"},
      {"icon": Icons.child_care, "title": "Kids"},
      {"icon": Icons.shopping_bag, "title": "Bags"},
      {"icon": Icons.watch, "title": "Watches"},
      {"icon": Icons.face, "title": "Beauty"},
      {"icon": Icons.sports_soccer, "title": "Sports"},
      {"icon": Icons.diamond, "title": "Jewellery"},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 40 : 16,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shop by Category",
            style: TextStyle(
              fontSize: desktop ? 28 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {},
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor:
                              const Color(0xff0F766E).withValues(alpha: .1),
                          child: Icon(
                            categories[index]["icon"],
                            size: 34,
                            color: const Color(0xff0F766E),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          categories[index]["title"],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}