import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app_colors.dart';
import 'app_state.dart';
import 'api_service.dart';
import 'models.dart';

import 'location_picker_page.dart';
import 'shop_page.dart';
import 'cart_page.dart';
import 'wishlist_page.dart';
import 'notifications_page.dart';
import 'settings_page.dart';
import 'catering_page.dart';
import 'custom_order_page.dart';
import 'login_page.dart';
import 'poster_page.dart';
import 'product_details_page.dart';

import 'class_page.dart';
import 'contact.dart';

/// ---------------------------------------------------------------------
/// HOME PAGE
/// ---------------------------------------------------------------------

class HomePage extends StatefulWidget {
  final ValueChanged<Product>? onProductTap;
  final ValueChanged<String>? onCategoryTap;

  const HomePage({
    super.key,
    this.onProductTap,
    this.onCategoryTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  final PageController _heroController = PageController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _heroTimer;

  int _heroIndex = 0;

  bool _loadingProducts = true;
  List<Product> _featuredProducts = [];

  // ---------------------------------------------------------------
  // QUICK CATEGORIES
  // ---------------------------------------------------------------

  final List<QuickCategory> _quickCategories = const [
    QuickCategory(
      'Kids Wear',
      'assets/images/kids.png',
    ),
    QuickCategory(
      'Uniform',
      'assets/images/unifrom.png',
    ),
    QuickCategory(
      'Modern Wear',
      'assets/images/modern.png',
    ),
    QuickCategory(
      'Salwar',
      'assets/images/salwar.png',
    ),
    QuickCategory(
      'Blouse',
      'assets/images/Blouse.png',
    ),
    QuickCategory(
      'Aari Work',
      'assets/images/Aari wrk.png',
    ),
    QuickCategory(
      'Saree Pre-pleating',
      'assets/images/ss.jpg',
    ),
    QuickCategory(
      'Frocks',
      'assets/images/Frocks.png',
    ),
    QuickCategory(
      'Lehenga',
      'assets/images/leng.jpg',
    ),
    QuickCategory(
      'Kurthi',
      'assets/images/kurthi.png',
    ),
  ];

  // ---------------------------------------------------------------
  // HERO SLIDES
  // ---------------------------------------------------------------

  late final List<HeroSlide> _heroSlides = [
    HeroSlide(
      title: 'Traditional Elegance',
      subtitle: 'Modern Style',
      tagline: 'Custom Stitching • Bridal Wear • Aari Work',
      imageUrl: 'assets/images/model.png',
      buttonLabel: 'Shop Now',
      buttonColor: AppColors.gold,
      buttonTextColor: AppColors.dark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ShopPage(),
          ),
        );
      },
    ),
    HeroSlide(
      title: 'Exclusive',
      subtitle: 'Bridal Package',
      tagline: 'Full Bridal Set • Aari Work • Custom Fit',
      imageUrl: 'assets/images/model.png',
      buttonLabel: 'Bridal Package',
      buttonColor: AppColors.gold,
      buttonTextColor: AppColors.dark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PosterPage(),
          ),
        );
      },
    ),

    HeroSlide(
      title: 'Design It',
      subtitle: 'Your Way',
      tagline: 'Any Design • Any Fabric • Perfect Fit',
      imageUrl: 'assets/images/model.png',
      buttonLabel: 'Custom Order',
      buttonColor: AppColors.gold,
      buttonTextColor: AppColors.dark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomOrderPage(),
          ),
        );
      },
    ),
  ];

  // ---------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _loadProducts();
    _startHeroAutoplay();

    // Load the previously-selected delivery location (persisted via
    // SharedPreferences in AppState) so it survives app restarts.
    AppState.instance.loadSavedDeliveryLocation();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    _scrollController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------
  // HERO AUTOPLAY
  // ---------------------------------------------------------------

  void _startHeroAutoplay() {
    _heroTimer?.cancel();

    _heroTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!mounted ||
            !_heroController.hasClients ||
            _heroSlides.isEmpty) {
          return;
        }

        final next =
            (_heroIndex + 1) % _heroSlides.length;

        _heroController.animateToPage(
          next,
          duration: const Duration(
            milliseconds: 500,
          ),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // LOAD PRODUCTS
  // ---------------------------------------------------------------

     Future<void> _loadProducts() async {
    try {
      final products = await ApiService.fetchProducts();

      if (!mounted) return;

      // ignore: avoid_print
      print('✅ Loaded ${products.length} products from Firestore');

      setState(() {
        _featuredProducts = products.isNotEmpty
            ? products
            : List.generate(
                8,
                (i) => Product(
                  id: i + 1,
                  name: 'Product ${i + 1}',
                  price: 400.0 + (i * 150),
                  image: 'assets/images/placeholder.png',
                  rating: 4.3 + (i % 3) * 0.2,
                ),
              );

        _loadingProducts = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ _loadProducts error: $e');

      if (!mounted) return;

      setState(() {
        _featuredProducts = List.generate(
          8,
          (i) => Product(
            id: i + 1,
            name: 'Product ${i + 1}',
            price: 400.0 + (i * 150),
            image: 'assets/images/placeholder.png',
            rating: 4.3 + (i % 3) * 0.2,
          ),
        );

        _loadingProducts = false;
      });
    }
  }

  // ---------------------------------------------------------------
  // SCROLL HOME
  // ---------------------------------------------------------------

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(
        milliseconds: 400,
      ),
      curve: Curves.easeInOut,
    );
  }

  // ---------------------------------------------------------------
  // SEARCH SUBMIT
  // ---------------------------------------------------------------

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopPage(
          initialFilter: trimmed,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.light,

          // LEFT DRAWER
          drawer: _buildDrawer(context),

          body: SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildAppHeader(
                    context,
                    state,
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildHeroSlider(),
                ),

                SliverToBoxAdapter(
                  child: _buildFeaturedSection(
                    state,
                  ),
                ),

                _buildSuggestedGridSection(
                  state,
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildAppHeader(
    BuildContext context,
    AppState state,
  ) {
    final hour = DateTime.now().hour;

    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        15,
        12,
        15,
        14,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------
          // TOP ROW
          // -------------------------------------------------------

          Row(
            children: [
              Image.asset(
                'assets/images/app.png',
                width: 34,
                height: 34,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.storefront,
                    color: AppColors.primary,
                    size: 34,
                  );
                },
              ),

              const SizedBox(width: 8),

              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily:
                          'PlayfairDisplay',
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight:
                          FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: "Sumathi's ",
                      ),
                      TextSpan(
                        text: 'Styles',
                        style: TextStyle(
                          color:
                              AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _headerIcon(
                Icons.notifications_none,
                state.unreadNotifCount,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationsPage(),
                    ),
                  );
                },
              ),

              _headerIcon(
                Icons.favorite_border,
                state.wishlistCount,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const WishlistPage(),
                    ),
                  );
                },
              ),

              _headerIcon(
                Icons.shopping_cart_outlined,
                state.cartCount,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CartPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------------
          // MENU + GREETING + LOGIN
          // -------------------------------------------------------

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      _scaffoldKey.currentState
                          ?.openDrawer();
                    },
                    borderRadius:
                        BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.only(
                        right: 8,
                      ),
                      child: Icon(
                        Icons.menu,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  Text(
                    '$greeting ✨',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),

              // LOGIN BUTTON
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginPage(),
                    ),
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // -------------------------------------------------------
          // LOCATION
          // -------------------------------------------------------

          InkWell(
            onTap: () async {
              final picked =
                  await LocationPickerSheet.show(context);

              if (picked != null) {
                final display = picked.label.isNotEmpty
                    ? picked.label
                    : picked.addressLine;

                // Persist the selection (SharedPreferences) so it
                // survives app restarts, and updates the header text
                // immediately via notifyListeners() inside AppState.
                await state.setDeliveryLocation(
                  display,
                  lat: picked.latitude,
                  lng: picked.longitude,
                );
              }
            },
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 15,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 4),

                Text(
                  'Deliver to ${state.deliveryLocation}',
                  style: const TextStyle(
                    fontSize: 13,
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 15,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // SEARCH
          _buildSearchBar(),

          const SizedBox(height: 14),

          // CATEGORIES
          _buildQuickCategories(),
        ],
      ),
    );
  }

  // ===============================================================
  // HEADER ICON
  // ===============================================================

  Widget _headerIcon(
    IconData icon,
    int count,
    VoidCallback onTap,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding:
                  const EdgeInsets.all(6),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.text,
              ),
            ),

            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding:
                      const EdgeInsets.all(3),
                  decoration:
                      const BoxDecoration(
                    color:
                        AppColors.secondary,
                    shape:
                        BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$count',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 9,
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // SEARCH BAR
  // ===============================================================

  Widget _buildSearchBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 18,
            color: AppColors.textLight,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch,
              decoration:
                  const InputDecoration(
                hintText:
                    'Search for sarees, blouses, aari work...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color:
                      AppColors.textLight,
                ),
                border:
                    InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          // Search action icon (tap to search current text)
          InkWell(
            onTap: () => _submitSearch(_searchController.text),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // QUICK CATEGORY ROW
  // ===============================================================

  Widget _buildQuickCategories() {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            _quickCategories.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final cat =
              _quickCategories[i];

          return GestureDetector(
            onTap: () {
              widget.onCategoryTap
                  ?.call(cat.label);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopPage(
                    initialFilter:
                        cat.label,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 62,

              // IMPORTANT:
              // Every category gets EXACT same
              // width + height.
              child: Column(
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      child: Container(
                        color:
                            const Color(
                          0xFFFDF1E7,
                        ),

                        // Top-center alignment
                        // so face/head won't
                        // disappear easily.
                        child: Image.asset(
                          cat.imageUrl,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          alignment:
                              Alignment.topCenter,
                          errorBuilder:
                              (_, __, ___) {
                            return const Icon(
                              Icons.checkroom,
                              color:
                                  AppColors.primary,
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    cat.label,
                    textAlign:
                        TextAlign.center,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppColors.text,
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

  // ===============================================================
  // DRAWER
  // ===============================================================

  Widget _buildDrawer(
    BuildContext context,
  ) {
    final drawerItems =
        <_NavItem>[
      _NavItem(
        'Home',
        Icons.home_outlined,
        () {
          Navigator.pop(context);
          _scrollToTop();
        },
      ),

      _NavItem(
        'Shop',
        Icons.shopping_bag_outlined,
        () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const ShopPage(),
            ),
          );
        },
      ),

      _NavItem(
        'Classes',
        Icons.school_outlined,
        () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                 const ClassPage(), 
            ),
          );
        },
      ),

      _NavItem(
        'Custom Order',
        Icons.design_services_outlined,
        () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const CustomOrderPage(),
            ),
          );
        },
      ),

      _NavItem(
        'Catering',
        Icons.restaurant_menu_outlined,
        () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const CateringPage(),
            ),
          );
        },
      ),

      _NavItem(
        'Contact',
        Icons.call_outlined,
        () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const ContactPage(),
            ),
          );
        },
      ),

      _NavItem(
        'Settings',
        Icons.settings_outlined,
        () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const SettingsPage(),
            ),
          );
        },
      ),
    ];

    return Drawer(
      backgroundColor:
          AppColors.light,
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------
            // DRAWER HEADER
            // -----------------------------------------------------

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(20),
              color:
                  AppColors.primary,
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/app.png',
                    width: 40,
                    height: 40,
                    errorBuilder:
                        (_, __, ___) {
                      return const Icon(
                        Icons.storefront,
                        color:
                            Colors.white,
                        size: 40,
                      );
                    },
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Expanded(
                    child: Text(
                      "Sumathi's Styles",
                      style:
                          TextStyle(
                        fontFamily:
                            'PlayfairDisplay',
                        fontSize: 18,
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -----------------------------------------------------
            // DRAWER ITEMS
            // -----------------------------------------------------

            Expanded(
              child:
                  ListView.separated(
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 8,
                ),
                itemCount:
                    drawerItems.length,
                separatorBuilder:
                    (_, __) =>
                        const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                itemBuilder:
                    (context, i) {
                  final item =
                      drawerItems[i];

                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color:
                          AppColors.primary,
                    ),
                    title: Text(
                      item.label,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        color:
                            AppColors.text,
                      ),
                    ),
                    trailing:
                        const Icon(
                      Icons
                          .arrow_forward_ios,
                      size: 13,
                      color:
                          AppColors.textLight,
                    ),
                    onTap:
                        item.onTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // HERO SLIDER
  // ===============================================================

  Widget _buildHeroSlider() {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(
              bottom:
                  Radius.circular(24),
            ),
            child:
                PageView.builder(
              controller:
                  _heroController,
              itemCount:
                  _heroSlides.length,
              onPageChanged: (i) {
                setState(
                  () => _heroIndex = i,
                );
              },
              itemBuilder:
                  (context, i) {
                return _buildHeroSlide(
                  _heroSlides[i],
                );
              },
            ),
          ),

          // DOTS
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children:
                  List.generate(
                _heroSlides.length,
                (i) {
                  final active =
                      i == _heroIndex;

                  return AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 300,
                    ),
                    margin:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 4,
                    ),
                    width:
                        active ? 22 : 8,
                    height: 8,
                    decoration:
                        BoxDecoration(
                      color: active
                          ? AppColors.gold
                          : Colors.white
                              .withValues(
                              alpha: 0.55,
                            ),
                      borderRadius:
                          BorderRadius
                              .circular(4),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // HERO SLIDE
  // ===============================================================

  Widget _buildHeroSlide(
    HeroSlide slide,
  ) {
    return GestureDetector(
      onTap: slide.onTap,
      child: Container(
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.dark,
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 60,
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      slide.title,
                      style:
                          const TextStyle(
                        fontFamily:
                            'PlayfairDisplay',
                        fontSize: 17,
                        height: 1.2,
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    Text(
                      slide.subtitle,
                      style:
                          const TextStyle(
                        fontFamily:
                            'PlayfairDisplay',
                        fontSize: 17,
                        height: 1.2,
                        color: AppColors
                            .secondaryLight,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      slide.tagline,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors
                            .white
                            .withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    ElevatedButton.icon(
                      onPressed:
                          slide.onTap,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            slide
                                .buttonColor,
                        foregroundColor:
                            slide
                                .buttonTextColor,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      icon:
                          const Icon(
                        Icons.arrow_forward,
                        size: 14,
                      ),
                      label: Text(
                        slide
                            .buttonLabel,
                        style:
                            const TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------
            // MODEL IMAGE
            // -----------------------------------------------------

            Expanded(
              flex: 40,
              child: ClipRect(
                child: Align(
                  alignment:
                      Alignment.topCenter,
                  heightFactor: 0.92,
                  child: Image.asset(
                    slide.imageUrl,
                    fit: BoxFit.cover,
                    alignment:
                        Alignment.topCenter,
                    height:
                        double.infinity,
                    errorBuilder:
                        (_, __, ___) {
                      return Container(
                        color:
                            AppColors
                                .primaryDark,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // FEATURED COLLECTION
  // ===============================================================

  Widget _buildFeaturedSection(
    AppState state,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 15,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .center,
              children: const [
                Text(
                  'Featured Collection',
                  style:
                      TextStyle(
                    fontFamily:
                        'PlayfairDisplay',
                    fontSize: 24,
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.w600,
                  ),
                  textAlign:
                      TextAlign.center,
                ),

                SizedBox(
                  height: 6,
                ),

                Text(
                  'Handpicked designs — 30 years of crafting perfection',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        AppColors
                            .textLight,
                  ),
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _loadingProducts
              ? const SizedBox(
                  height: 260,
                  child:
                      Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              : SizedBox(
                  height: 260,
                  child:
                      ListView.separated(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 15,
                    ),
                    scrollDirection:
                        Axis.horizontal,
                    itemCount:
                        _featuredProducts
                            .length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      width: 12,
                    ),
                    itemBuilder:
                        (context, i) {
                      final product =
                          _featuredProducts[
                              i];

                      return RevealOnScroll(
                        tag:
                            'featured_${product.id}_$i',
                        child:
                            _buildProductCard(
                          product,
                          state,
                        ),
                      );
                    },
                  ),
                ),

          // NO VIEW ALL PRODUCTS BUTTON
        ],
      ),
    );
  }

  // ===============================================================
  // PRODUCT CARD
  // ===============================================================

  Widget _buildProductCard(
    Product product,
    AppState state,
  ) {
    final isWishlisted =
        state.wishlistIds
            .contains(product.id);

    return GestureDetector(
      onTap: () {
        widget.onProductTap
            ?.call(product);

        // OPEN FLIPKART-STYLE PRODUCT DETAILS PAGE
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              product: product,
            ),
          ),
        );
      },
      child: Container(
        width: 165,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors
                  .primary
                  .withValues(
                alpha: 0.12,
              ),
              blurRadius: 12,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius
                          .vertical(
                    top:
                        Radius.circular(
                      16,
                    ),
                  ),
                  child:
                      _productImage(
                    product,
                    height: 165,
                  ),
                ),

                // RATING
                Positioned(
                  bottom: -10,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
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
                              .circular(
                        4,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      children: [
                        Text(
                          product.rating
                              .toStringAsFixed(
                            1,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        const Icon(
                          Icons.star,
                          size: 10,
                          color:
                              Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),

                // WISHLIST
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: () {
                      state.toggleWishlist(
                        product,
                      );
                    },
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                    child:
                        Container(
                      width: 30,
                      height: 30,
                      decoration:
                          const BoxDecoration(
                        color:
                            Colors.white,
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        isWishlisted
                            ? Icons.favorite
                            : Icons
                                .favorite_border,
                        size: 15,
                        color: isWishlisted
                            ? AppColors
                                .danger
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                12,
                16,
                12,
                12,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          AppColors.text,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              Color(
                            0xFF212121,
                          ),
                        ),
                      ),

                      InkWell(
                        onTap: () {
                          _addToCart(
                            product,
                            state,
                          );
                        },
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                        child:
                            Container(
                          padding:
                              const EdgeInsets
                                  .all(
                            6,
                          ),
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withValues(
                              alpha: 0.1,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .add_shopping_cart,
                            size: 15,
                            color:
                                AppColors
                                    .primary,
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

  // ===============================================================
  // PRODUCT IMAGE
  // ===============================================================

  Widget _productImage(
    Product product, {
    double? height,
  }) {
    if (product.isNetworkImage) {
      return Image.network(
        product.image,
        width:
            double.infinity,
        height: height,
        fit: BoxFit.cover,
        alignment:
            Alignment.topCenter,
        loadingBuilder:
            (
          context,
          child,
          progress,
        ) {
          if (progress == null) {
            return child;
          }

          return Container(
            height: height,
            color:
                AppColors.gray,
            child:
                const Center(
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder:
            (_, __, ___) {
          return _imageError(
            height,
          );
        },
      );
    }

    return Image.asset(
      product.image,
      width:
          double.infinity,
      height: height,
      fit: BoxFit.cover,
      alignment:
          Alignment.topCenter,
      errorBuilder:
          (_, __, ___) {
        return _imageError(
          height,
        );
      },
    );
  }

  Widget _imageError(
    double? height,
  ) {
    return Container(
      height: height,
      color: AppColors.gray,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color:
              AppColors.textLight,
        ),
      ),
    );
  }

  // ===============================================================
  // ADD TO CART
  // ===============================================================

  void _addToCart(
    Product product,
    AppState state,
  ) {
    state.addToCart(product);

    state.addNotification(
      'Added to cart',
      '${product.name} added to your cart.',
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} added to cart',
        ),
        duration:
            const Duration(
          seconds: 1,
        ),
        backgroundColor:
            AppColors.primary,
      ),
    );
  }

  // ===============================================================
  // SUGGESTED PRODUCTS GRID
  // ===============================================================

  SliverPadding
      _buildSuggestedGridSection(
    AppState state,
  ) {
    return SliverPadding(
      padding:
          const EdgeInsets.fromLTRB(
        15,
        8,
        15,
        8,
      ),
      sliver:
          SliverMainAxisGroup(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.only(
                bottom: 12,
              ),
              child: Text(
                'Suggested For You',
                style:
                    TextStyle(
                  fontFamily:
                      'PlayfairDisplay',
                  fontSize: 20,
                  color:
                      AppColors.primary,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          _loadingProducts
              ? const SliverToBoxAdapter(
                  child:
                      SizedBox(
                    height: 200,
                    child:
                        Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing:
                        14,
                    crossAxisSpacing:
                        12,
                    childAspectRatio:
                        0.62,
                  ),
                  delegate:
                      SliverChildBuilderDelegate(
                    (context, i) {
                      final product =
                          _featuredProducts[
                              i];

                      return RevealOnScroll(
                        tag:
                            'suggested_${product.id}_$i',
                        child:
                            _buildGridProductCard(
                          product,
                          state,
                        ),
                      );
                    },
                    childCount:
                        _featuredProducts
                            .length,
                  ),
                ),
        ],
      ),
    );
  }

  // ===============================================================
  // GRID PRODUCT CARD
  // ===============================================================

  Widget _buildGridProductCard(
    Product product,
    AppState state,
  ) {
    final isWishlisted =
        state.wishlistIds
            .contains(product.id);

    return GestureDetector(
      onTap: () {
        widget.onProductTap
            ?.call(product);

        // OPEN FLIPKART-STYLE PRODUCT DETAILS PAGE
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              product: product,
            ),
          ),
        );
      },
      child: Container(
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors
                  .primary
                  .withValues(
                alpha: 0.10,
              ),
              blurRadius: 10,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius
                            .vertical(
                      top:
                          Radius.circular(
                        16,
                      ),
                    ),
                    child:
                        _productImage(
                      product,
                    ),
                  ),

                  // RATING
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF388E3C,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          4,
                        ),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          Text(
                            product.rating
                                .toStringAsFixed(
                              1,
                            ),
                            style:
                                const TextStyle(
                              fontSize:
                                  10,
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

                  // WISHLIST
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () {
                        state.toggleWishlist(
                          product,
                        );
                      },
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                      child:
                          Container(
                        width: 26,
                        height: 26,
                        decoration:
                            const BoxDecoration(
                          color:
                              Colors.white,
                          shape:
                              BoxShape
                                  .circle,
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons
                                  .favorite
                              : Icons
                                  .favorite_border,
                          size: 13,
                          color: isWishlisted
                              ? AppColors
                                  .danger
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                10,
                10,
                10,
                10,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          AppColors.text,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              Color(
                            0xFF212121,
                          ),
                        ),
                      ),

                      InkWell(
                        onTap: () {
                          _addToCart(
                            product,
                            state,
                          );
                        },
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                        child:
                            Container(
                          padding:
                              const EdgeInsets
                                  .all(
                            5,
                          ),
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withValues(
                              alpha: 0.1,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .add_shopping_cart,
                            size: 13,
                            color:
                                AppColors
                                    .primary,
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

// ===============================================================
// NAV ITEM MODEL
// ===============================================================

class _NavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavItem(
    this.label,
    this.icon,
    this.onTap,
  );
}

// ===============================================================
// REVEAL ON SCROLL
// ===============================================================

class RevealOnScroll
    extends StatefulWidget {
  final Widget child;
  final String tag;

  const RevealOnScroll({
    super.key,
    required this.child,
    required this.tag,
  });

  @override
  State<RevealOnScroll>
      createState() =>
          _RevealOnScrollState();
}

class _RevealOnScrollState
    extends State<RevealOnScroll> {
  bool _visible = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return VisibilityDetector(
      key: Key(widget.tag),
      onVisibilityChanged:
          (info) {
        if (!_visible &&
            info.visibleFraction >
                0.15) {
          setState(() {
            _visible = true;
          });
        }
      },
      child: AnimatedOpacity(
        opacity:
            _visible ? 1 : 0,
        duration:
            const Duration(
          milliseconds: 450,
        ),
        curve:
            Curves.easeOut,
        child: AnimatedSlide(
          offset: _visible
              ? Offset.zero
              : const Offset(
                  0,
                  0.12,
                ),
          duration:
              const Duration(
            milliseconds: 450,
          ),
          curve:
              Curves.easeOut,
          child:
              widget.child,
        ),
      ),
    );
  }
}