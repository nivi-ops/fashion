import 'dart:async';
import 'package:flutter/material.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _controller = PageController();

  int _currentPage = 0;

  final List<String> banners = [
    "assets/images/model.png",
    "assets/images/model.png",
    "assets/images/model.png",
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;

      _currentPage++;

      if (_currentPage >= banners.length) {
        _currentPage = 0;
      }

      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool desktop = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [

        SizedBox(
          height: desktop ? 420 : 200,

          child: PageView.builder(
            controller: _controller,

            itemCount: banners.length,

            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },

            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  image: DecorationImage(
                    image: AssetImage(banners[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),

              margin: const EdgeInsets.symmetric(horizontal: 4),

              width: _currentPage == index ? 25 : 8,
              height: 8,

              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xff0F766E)
                    : Colors.grey.shade400,

                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}