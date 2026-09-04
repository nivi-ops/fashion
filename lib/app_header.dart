import 'package:flutter/material.dart';


class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      height: isDesktop ? 80 : 65,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [

          /// Logo
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  "assets/images/app.png",
                  width: isDesktop ? 55 : 45,
                  height: isDesktop ? 55 : 45,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              Text(
                "Fashion",
                style: TextStyle(
                  fontSize: isDesktop ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0F766E),
                ),
              ),
            ],
          ),

          const SizedBox(width: 30),

          /// Search
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search products...",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),

          const SizedBox(width: 25),

          if (isDesktop) ...[
            TextButton(
              onPressed: () {},
              child: const Text("Home"),
            ),
            TextButton(
              onPressed: () {},
              child: const Text("Shop"),
            ),
            TextButton(
              onPressed: () {},
              child: const Text("Categories"),
            ),
            TextButton(
              onPressed: () {},
              child: const Text("About"),
            ),
            TextButton(
              onPressed: () {},
              child: const Text("Contact"),
            ),
          ],

          const SizedBox(width: 10),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
    );
  }
}