import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_state.dart';
import 'home_page.dart';
import 'shop_page.dart';
import 'catering_page.dart';
import 'settings_page.dart';

/// ---------------------------------------------------------------------
/// MAIN NAV PAGE — the app shell with the bottom nav bar.
/// 4 tabs: Home, Shop, Service (Catering), Profile (Settings).
/// This is the widget you set as `home:` in main.dart instead of
/// HomePage directly.
///
/// NOTE: Cart is intentionally NOT a bottom-nav tab — it's reachable via
/// the cart icon in HomePage's header. If you want it back as a tab,
/// just add a 5th _navItem + page below.
/// ---------------------------------------------------------------------
class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int _currentIndex = 0;

  // IndexedStack so each tab keeps its scroll position / state
  // when you switch away and come back.
  final List<Widget> _pages = const [
    HomePage(),
    ShopPage(),
    CateringPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _navItem(
                1,
                Icons.storefront_outlined,
                Icons.storefront,
                'Shop',
              ),
              _navItem(
                2,
                Icons.design_services_outlined,
                Icons.design_services,
                'Service',
              ),
              _navItem(
                3,
                Icons.person_outline,
                Icons.person,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final bool active = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 23,
              color: active ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}