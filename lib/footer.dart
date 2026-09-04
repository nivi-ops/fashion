import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 35,
      ),
      color: const Color(0xff0F766E),
      child: Column(
        children: [

          /// Logo
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                "assets/images/app.png",
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            "Fashion",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Style • Fashion • Trends",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 25),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 10,
            children: const [
              Text(
                "Home",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                "Shop",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                "Categories",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                "About",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                "Contact",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.facebook,
                  color: Colors.white,
                ),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                ),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                ),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.email,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          const Divider(color: Colors.white38),

          const SizedBox(height: 15),

          const Text(
            "© 2026 Fashion. All Rights Reserved.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}