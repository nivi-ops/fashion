import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';
import 'api_service.dart' show baseUrl;

// ---------------------------------------------------------------------
// CATERING PAGE
// ---------------------------------------------------------------------

class CateringPage extends StatefulWidget {
  final String? userName;
  final String? userEmail;

  const CateringPage({
    super.key,
    this.userName,
    this.userEmail,
  });

  @override
  State<CateringPage> createState() => _CateringPageState();
}

class _CateringPageState extends State<CateringPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Sumathi Catering',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.home_outlined, size: 18),
              text: 'Home',
            ),
            Tab(
              icon: Icon(Icons.info_outline, size: 18),
              text: 'About',
            ),
            Tab(
              icon: Icon(Icons.room_service_outlined, size: 18),
              text: 'Services',
            ),
            Tab(
              icon: Icon(Icons.photo_library_outlined, size: 18),
              text: 'Gallery',
            ),
            Tab(
              icon: Icon(Icons.mail_outline, size: 18),
              text: 'Contact',
            ),
            Tab(
              icon: Icon(Icons.star_outline, size: 18),
              text: 'Reviews',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _CateringHomeTab(),
          const _CateringAboutTab(),
          const _CateringServicesTab(),
          const _CateringGalleryTab(),
          const _CateringContactTab(),
          _CateringReviewsTab(
            userName: widget.userName,
            userEmail: widget.userEmail,
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// SHARED HELPERS
// =======================================================================

Future<void> _launch(String url) async {
  final uri = Uri.parse(url);

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      debugPrint('Could not launch: $url');
    }
  } catch (e) {
    debugPrint('Launch error: $e');
  }
}

class _ResponsiveContent extends StatelessWidget {
  final Widget child;

  const _ResponsiveContent({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
        ),
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradientHeaderBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;

  const _GradientHeaderBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 36,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 21,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.white70,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.secondary,
                    AppColors.secondaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =======================================================================
// HOME TAB
// =======================================================================

class _CateringHomeTab extends StatefulWidget {
  const _CateringHomeTab();

  @override
  State<_CateringHomeTab> createState() => _CateringHomeTabState();
}

class _CateringHomeTabState extends State<_CateringHomeTab> {
  final PageController _heroController = PageController();

  Timer? _heroTimer;

  int _heroIndex = 0;

  final List<Map<String, String>> _heroSlides = const [
    {
      'image': 'assets/catering/uploads/home1.jpeg',
      'title': 'Authentic Tamil Wedding Feasts',
      'subtitle': 'Traditional flavors for your most special day',
    },
    {
      'image': 'assets/catering/uploads/home2.jpeg',
      'title': 'Grand Reception Dinners',
      'subtitle': 'Lavish spreads that leave lasting memories',
    },
    {
      'image': 'assets/catering/uploads/home3.jpeg',
      'title': 'Full Sadhya Meals',
      'subtitle': 'Complete traditional meals with all accompaniments',
    },
    {
      'image': 'assets/catering/uploads/home4.jpeg',
      'title': 'Morning Tiffin Specials',
      'subtitle': 'Start celebrations with our signature tiffin items',
    },
    {
      'image': 'assets/catering/uploads/home5.jpeg',
      'title': 'Sumathi Catering Services',
      'subtitle': 'Everything you need under one roof',
    },
  ];

  final List<Map<String, String>> _menuCards = const [
    {
      'key': 'morning',
      'label': 'Morning Tiffin',
      'image': 'assets/catering/uploads/morning.jpg',
    },
    {
      'key': 'reception',
      'label': 'Reception Dinner',
      'image': 'assets/catering/uploads/reception.jpeg',
    },
    {
      'key': 'lunch',
      'label': 'Lunch Sadhya',
      'image': 'assets/catering/uploads/lunch.jpeg',
    },
    {
      'key': 'evening',
      'label': 'Evening Tiffin',
      'image': 'assets/catering/uploads/even.jpeg',
    },
    {
      'key': 'marriage',
      'label': 'Marriage Package',
      'image': 'assets/catering/uploads/marriage.jpeg',
    },
    {
      'key': 'general',
      'label': 'General Package',
      'image': 'assets/catering/uploads/gen.jpeg',
    },
  ];

  @override
  void initState() {
    super.initState();

    _heroTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!mounted || !_heroController.hasClients) return;

        final next = (_heroIndex + 1) % _heroSlides.length;

        _heroController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  void _openMenuModal(String key) {
    final entry = cateringMenuData[key];

    if (entry == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MenuModalSheet(
          entry: entry,
          whatsappNumber: '918610703658',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 210,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: PageView.builder(
                      controller: _heroController,
                      itemCount: _heroSlides.length,
                      onPageChanged: (i) {
                        setState(() {
                          _heroIndex = i;
                        });
                      },
                      itemBuilder: (context, i) {
                        final slide = _heroSlides[i];

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              slide['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  color: AppColors.primaryDark,
                                );
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.15),
                                    AppColors.primaryDark.withValues(
                                      alpha: 0.75,
                                    ),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slide['title']!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'PlayfairDisplay',
                                      fontSize: 19,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    slide['subtitle']!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _heroSlides.length,
                        (i) {
                          final active = i == _heroIndex;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.gold
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const _SectionHeader(
              title: 'Our Menu',
              subtitle:
                  'Traditional recipes crafted with care for every occasion',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _menuCards.length,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, i) {
                  final card = _menuCards[i];

                  return GestureDetector(
                    onTap: () {
                      _openMenuModal(card['key']!);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(
                          bottom: BorderSide(
                            color: AppColors.secondary,
                            width: 3,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                card['image']!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: AppColors.gray,
                                    child: const Icon(
                                      Icons.restaurant_menu,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            card['label']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why Choose Sumathi Catering?',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: const [
                      _WhyItem(
                        icon: Icons.emoji_events_outlined,
                        label: '30+ Years Experience',
                      ),
                      _WhyItem(
                        icon: Icons.people_outline,
                        label: '5000+ Weddings Catered',
                      ),
                      _WhyItem(
                        icon: Icons.eco_outlined,
                        label: 'Fresh Ingredients Daily',
                      ),
                      _WhyItem(
                        icon: Icons.local_shipping_outlined,
                        label: 'On-Time Delivery',
                      ),
                      _WhyItem(
                        icon: Icons.star_outline,
                        label: 'Top Rated in Chennai',
                      ),
                      _WhyItem(
                        icon: Icons.restaurant_outlined,
                        label: 'Customized Menus',
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

class _WhyItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WhyItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.secondaryLight,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// MENU MODAL
// =======================================================================

class _MenuModalSheet extends StatelessWidget {
  final CateringMenuEntry entry;
  final String whatsappNumber;

  const _MenuModalSheet({
    required this.entry,
    required this.whatsappNumber,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    20,
                  ),
                  children: [
                    ...entry.columns.map(
                      (col) => _MenuColumnCard(column: col),
                    ),
                    if (entry.particulars.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.secondary,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Additional Particulars Included:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.particulars
                                  .map(
                                    (r) => r.value.isNotEmpty
                                        ? '${r.label} — ${r.value}'
                                        : r.label,
                                  )
                                  .join('  |  '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (entry.price != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.secondary,
                              AppColors.secondaryLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Package Price: ${entry.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => _launch(
                        'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(
                          "Hi Sumathi Catering, I want to enquire about ${entry.title}.",
                        )}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.chat),
                      label: const Text(
                        'Enquire on WhatsApp',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuColumnCard extends StatelessWidget {
  final CateringMenuColumn column;

  const _MenuColumnCard({
    required this.column,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5A5A5A),
                  Color(0xFF3D3D3D),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  column.name,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'CATALOGUE',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: column.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// ABOUT TAB
// =======================================================================

class _CateringAboutTab extends StatelessWidget {
  const _CateringAboutTab();

  static const String _exactAddress =
      'No7, 444, Medavakkam Main Rd, nearby Dr.Senthil Clinic, '
      'Kamarajar Salai, Lakshmi Nagar, Kovilambakkam, Chennai, '
      'Nanmangalam, Tamil Nadu 600 129';

  static const String _mapsUrl =
      'https://maps.app.goo.gl/xbCoLE9w2yMayGX56';

  void _openMaps() {
    _launch(_mapsUrl);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GradientHeaderBanner(
              icon: Icons.restaurant,
              title: 'About Sumathi Catering',
              subtitle:
                  'Delicious authentic South Indian food for all occasions',
              badgeText: '30 Years of Catering Excellence',
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(
                    icon: Icons.info_outline,
                    title: 'Company Profile',
                    child: const Text(
                      "Founded in the 19th century as Sumathi Catering Service, "
                      "we're proud pure vegetarian caterers with a legacy spanning "
                      "generations. With over 25 years under our branded name, "
                      "quality and excellence have made us one of the top names "
                      "in the profession. From intimate home parties to grand "
                      "events, we blend experience with creativity to make every "
                      "occasion special. We also undertake labour charge and "
                      "contract basis catering at budget-friendly rates — every "
                      "detail planned around your needs, taste, and budget.\n\n"
                      "Team: Murali (Director) | 50 Cooks | 50 Hospitality Staff | "
                      "50 Reception | 50 Supervisors.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Director
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/catering/uploads/dir.jpg',
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                height: 180,
                                color: AppColors.gray,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.textLight,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'DIRECTOR PROFILE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "The entire business processes are proficiently managed "
                          "under the dexterous administration of our company director "
                          "Doctor. Mr. Murali, who has relevant industry experience "
                          "of more than fifteen years. The ability of our director "
                          "to resolve problems at site and his innovative ideas have "
                          "perfected the blend of creativity and services in taking "
                          "Sumathi Catering Service to greater heights.",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textLight,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'AWARDS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment:
                              WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2FA8A0),
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Arusuvai Nayagan (2009 - 2010)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            const Text(
                              'Issued By: Film Director Mr. S.P. Muthuraman, '
                              'Tamil Nadu Cinema Kalai Mandram.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =====================================================
                  // CONTACT
                  // =====================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.headset_mic_outlined,
                              color: AppColors.secondaryLight,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Contact Us',
                              style: TextStyle(
                                color: AppColors.secondaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Reach out to us for your next event 💛 "
                          "We're just a message away! Share your event "
                          "details and we'll help you plan a menu your "
                          "guests will remember.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // EMAIL
                        _ContactLinkTile(
                          icon: Icons.email_outlined,
                          iconColor:
                              AppColors.secondaryLight,
                          label: 'Email',
                          value:
                              'murali@sumathicatering.com',
                          onTap: () {
                            _launch(
                              'mailto:murali@sumathicatering.com',
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 15,
                                color:
                                    AppColors.secondaryLight,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Monday - Sunday',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                '8:00 AM - 10:00 PM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.secondaryLight,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =====================================================
                  // EXACT LOCATION
                  // =====================================================

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(16),
                          decoration:
                              const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                color:
                                    AppColors.secondaryLight,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Our Location',
                                      style: TextStyle(
                                        color: AppColors
                                            .secondaryLight,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      _exactAddress,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // MAP AREA
                        Container(
                          width: double.infinity,
                          height: 280,
                          color: const Color(0xFFE8E3D9),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.location_on,
                                      color:
                                          AppColors.primary,
                                      size: 54,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Sumathi Catering',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.bold,
                                        color: AppColors
                                            .primaryDark,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(
                                        horizontal: 30,
                                      ),
                                      child: Text(
                                        'Kovilambakkam, '
                                        'Chennai - 600 129',
                                        textAlign:
                                            TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors
                                              .textLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Positioned(
                                left: 14,
                                right: 14,
                                bottom: 14,
                                child:
                                    ElevatedButton.icon(
                                  onPressed: _openMaps,
                                  style: ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                        AppColors.primary,
                                    foregroundColor:
                                        Colors.white,
                                    minimumSize:
                                        const Size(
                                      double.infinity,
                                      46,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.directions,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'Get Directions',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// =======================================================================
// INFO CARD
// =======================================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// =======================================================================
// CONTACT TILE
// =======================================================================

class _ContactLinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactLinkTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// SERVICES TAB
// =======================================================================

class _CateringServicesTab extends StatelessWidget {
  const _CateringServicesTab();

  static const List<Map<String, String>> _services = [
    {'label': 'Mandapam Kolam', 'image': 'kolam.jpeg'},
    {
      'label': 'Seer Varieties',
      'image': 'seer.jpeg'
    },
    {
      'label': 'Reception Items',
      'image': 'rec.jpeg'
    },
    {'label': 'All Session Water Bottle', 'image': 'water.jpeg'},
    {
      'label': 'Uniformed Services',
      'image': 'services.jpeg'
    },
    {'label': 'Video & Photo', 'image': 'camera.jpeg'},
    {'label': 'Seer Patshanangal', 'image': 'thing.jpeg'},
    {'label': 'Nadaswaram', 'image': 'nadaswaram.jpeg'},
    {'label': 'Janavasa Car with Lights', 'image': 'car.jpeg'},
    {'label': 'Band Set', 'image': 'band.jpeg'},
    {'label': 'Light Music / Karnatic', 'image': 'music.jpeg'},
    {
      'label':
          'Reception Backdrop,',
      'image': 'arch.jpeg'
    },
    {
      'label': 'Manamedai Alangaram',
      'image': 'flowers.jpeg'
    },
    {'label': 'Mickey Mouse', 'image': 'mickey.jpeg'},
    {
      'label': "Children's Jumping",
      'image': 'jumping.jpeg'
    },
    {'label': 'Fruit Stall', 'image': 'fruit.jpeg'},
    {'label': 'Ice Cream Stall', 'image': 'icecream.jpeg'},
    {'label': 'Beeda Stall', 'image': 'beeda.jpeg'},
    {'label': 'Mehendi Stall', 'image': 'mehendi.jpeg'},
    {'label': 'Bangle Stall', 'image': 'bangle.jpeg'},
    {'label': 'Balloon Decoration', 'image': 'balloon.jpeg'},
    {
      'label': 'Pop Corn & Cotton Candy',
      'image': 'popcorn.jpeg'
    },
    {'label': 'Chocolate Fountain', 'image': 'chocolate.jpeg'},
    {'label': 'Customized Services', 'image': 'tag.jpeg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: _ResponsiveContent(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _GradientHeaderBanner(
                icon: Icons.room_service_outlined,
                title: 'Our Services',
                subtitle:
                    'Complete event solutions beyond catering — '
                    'decor, entertainment & more',
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: _InfoCard(
                  icon: Icons.info_outline,
                  title: 'Beyond Catering',
                  child: const Text(
                    'From Weddings to Corporate Events and other '
                    'Special Occasions, our professional staff makes '
                    'sure your event is "one of its kind". Our broad '
                    'range of services covers everything from decor '
                    'to entertainment, so your event is flawless '
                    'from start to finish.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textLight,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: _services.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, i) {
                    final s = _services[i];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/catering/uploads/${s['image']}',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) {
                                return Container(
                                  width: 56,
                                  height: 56,
                                  decoration:
                                      BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          AppColors.secondary,
                                      width: 2,
                                    ),
                                    color:
                                        AppColors.gray,
                                  ),
                                  child: const Icon(
                                    Icons
                                        .celebration_outlined,
                                    color:
                                        AppColors.primary,
                                    size: 22,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s['label']!,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondaryLight,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Want any of these services for your event? '
                      'Get in touch with us today.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.dark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _launch(
                        'https://wa.me/918610703658?text=${Uri.encodeComponent(
                          "Hi Sumathi Catering, I want to enquire about your services.",
                        )}',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.dark,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.chat,
                        size: 16,
                      ),
                      label: const Text(
                        'Enquire Now',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// GALLERY TAB
// =======================================================================

class _CateringGalleryTab extends StatelessWidget {
  const _CateringGalleryTab();

  static final List<String> _images =
      List.generate(
    16,
    (i) => 'assets/catering/uploads/Gal${i + 1}.jpg',
  );

  void _openLightbox(
    BuildContext context,
    int index,
  ) {
    showDialog(
      context: context,
      barrierColor:
          Colors.black.withValues(alpha: 0.92),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: InteractiveViewer(
                child: Image.asset(
                  _images[index],
                  errorBuilder:
                      (_, __, ___) {
                    return Container(
                      height: 300,
                      color: AppColors.gray,
                      alignment:
                          Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported,
                        color:
                            AppColors.textLight,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () =>
                    Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _ResponsiveContent(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const _GradientHeaderBanner(
              icon:
                  Icons.photo_library_outlined,
              title: 'Our Gallery',
              subtitle:
                  'Moments captured from our events and celebrations',
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: _images.length,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () =>
                        _openLightbox(context, i),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(14),
                      child: Image.asset(
                        _images[i],
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) {
                          return Container(
                            color: AppColors.gray,
                            alignment:
                                Alignment.center,
                            child: const Icon(
                              Icons
                                  .image_not_supported,
                              color: AppColors
                                  .textLight,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// CONTACT TAB
// =======================================================================

class _CateringContactTab
    extends StatefulWidget {
  const _CateringContactTab();

  @override
  State<_CateringContactTab> createState() =>
      _CateringContactTabState();
}

class _CateringContactTabState
    extends State<_CateringContactTab> {
  final _formKey =
      GlobalKey<FormState>();

  final _nameCtrl =
      TextEditingController();

  final _phoneCtrl =
      TextEditingController();

  final _emailCtrl =
      TextEditingController();

  final _messageCtrl =
      TextEditingController();

  String? _service;

  bool _isSubmitting = false;

  static const _serviceOptions = [
    'Marriage Package (A to Z)',
    'Reception Dinner',
    'Morning Tiffin',
    'Lunch',
    'Evening Tiffin',
    'General Package',
    'Corporate Event',
    'Birthday Party',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Sends the enquiry to submit_forms.php (contacts table) on the
  // Railway/PHP backend. NOTE: the field names below (form_type,
  // name, phone, email, service, message) are what this form sends —
  // they must match what submit_forms.php reads from $_POST. If the
  // real submit_forms.php uses different keys, update the body map
  // below to match.
  // ---------------------------------------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
       final response = await http.post(
  Uri.parse('$baseUrl/submit_forms.php'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'type': 'contact',
    'name': _nameCtrl.text.trim(),
    'phone': _phoneCtrl.text.trim(),
    'email': _emailCtrl.text.trim(),
    'service': _service ?? '',
    'message': _messageCtrl.text.trim(),
  }),
);

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data is Map && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Enquiry sent! We will contact you soon.',
            ),
          ),
        );
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _emailCtrl.clear();
        _messageCtrl.clear();
        setState(() => _service = null);
      } else {
        final msg = data is Map
            ? (data['message']?.toString() ?? 'Failed to send enquiry')
            : 'Failed to send enquiry';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Server error, please try again'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _ResponsiveContent(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const _GradientHeaderBanner(
              icon: Icons.mail_outline,
              title: 'Contact Us',
              subtitle:
                  "We'd love to cater your next event!",
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset:
                              const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .send_outlined,
                                color:
                                    AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Get in Touch',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors
                                      .primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel(
                            'Your Name',
                          ),
                          TextFormField(
                            controller:
                                _nameCtrl,
                            decoration:
                                _inputDecoration(
                              'Enter your name',
                            ),
                            validator: (v) =>
                                (v == null ||
                                        v.trim()
                                            .isEmpty)
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(
                              height: 12),
                          const _FieldLabel(
                            'Mobile Number',
                          ),
                          TextFormField(
                            controller:
                                _phoneCtrl,
                            keyboardType:
                                TextInputType.phone,
                            decoration:
                                _inputDecoration(
                              '+91 XXXXX XXXXX',
                            ),
                          ),
                          const SizedBox(
                              height: 12),
                          const _FieldLabel(
                            'Email',
                          ),
                          TextFormField(
                            controller:
                                _emailCtrl,
                            keyboardType:
                                TextInputType
                                    .emailAddress,
                            decoration:
                                _inputDecoration(
                              'your@email.com',
                            ),
                          ),
                          const SizedBox(
                              height: 12),
                          const _FieldLabel(
                            'Service Required',
                          ),
                          DropdownButtonFormField<
                              String>(
                            initialValue:
                                _service,
                            decoration:
                                _inputDecoration(
                              'Select a service',
                            ),
                            items:
                                _serviceOptions
                                    .map(
                              (s) =>
                                  DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        13,
                                  ),
                                ),
                              ),
                            ).toList(),
                            onChanged: (v) {
                              setState(() {
                                _service = v;
                              });
                            },
                          ),
                          const SizedBox(
                              height: 12),
                          const _FieldLabel(
                            'Message',
                          ),
                          TextFormField(
                            controller:
                                _messageCtrl,
                            maxLines: 4,
                            decoration:
                                _inputDecoration(
                              'Tell us about your event...',
                            ),
                            validator: (v) =>
                                (v == null ||
                                        v.trim()
                                            .isEmpty)
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(
                              height: 16),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : _submit,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors
                                      .primary,
                              foregroundColor:
                                  Colors.white,
                              minimumSize:
                                  const Size(
                                double.infinity,
                                46,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    size: 16,
                                  ),
                            label: Text(
                              _isSubmitting
                                  ? 'Sending...'
                                  : 'Send Enquiry',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _InfoCard(
                    icon:
                        Icons.headset_mic_outlined,
                    title: 'Reach Us Directly',
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available every day from 8 AM to 10 PM '
                          'for bookings and enquiries.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color:
                                AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  ElevatedButton
                                      .icon(
                                onPressed: () =>
                                    _launch(
                                  'https://wa.me/918610703658?text=${Uri.encodeComponent(
                                    "Hi Sumathi Catering, I want to book catering.",
                                  )}',
                                ),
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      AppColors
                                          .secondary,
                                  foregroundColor:
                                      AppColors
                                          .dark,
                                  minimumSize:
                                      const Size(
                                    double.infinity,
                                    44,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      10,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.chat,
                                  size: 15,
                                ),
                                label: const Text(
                                  'WhatsApp',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 10),
                            Expanded(
                              child:
                                  OutlinedButton
                                      .icon(
                                onPressed: () =>
                                    _launch(
                                  'tel:8610703658',
                                ),
                                style:
                                    OutlinedButton
                                        .styleFrom(
                                  foregroundColor:
                                      AppColors
                                          .primary,
                                  side:
                                      const BorderSide(
                                    color:
                                        AppColors
                                            .primary,
                                  ),
                                  minimumSize:
                                      const Size(
                                    double.infinity,
                                    44,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      10,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.call,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Call Us',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      20,
                      18,
                      18,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          AppColors.secondary,
                          AppColors.secondaryLight,
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'For full menu, photos & more details visit our official website',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color:
                                AppColors.dark,
                          ),
                        ),
                        const SizedBox(
                            height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child:
                              ElevatedButton.icon(
                            onPressed: () =>
                                _launch(
                              'https://www.sumathicatering.com/',
                            ),
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  AppColors
                                      .dark,
                              foregroundColor:
                                  Colors.white,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.open_in_new,
                              size: 17,
                            ),
                            label: const Text(
                              'Visit Our Website',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// =======================================================================
// FIELD HELPERS
// =======================================================================

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  String hint,
) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 12.5,
      color: AppColors.textLight,
    ),
    isDense: true,
    contentPadding:
        const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
    border: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(10),
      borderSide: BorderSide(
        color: AppColors.primary
            .withValues(alpha: 0.2),
      ),
    ),
    enabledBorder:
        OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(10),
      borderSide: BorderSide(
        color: AppColors.primary
            .withValues(alpha: 0.2),
      ),
    ),
    focusedBorder:
        OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 1.5,
      ),
    ),
  );
}

// =======================================================================
// REVIEWS TAB
// =======================================================================

class _CateringReviewsTab extends StatefulWidget {
  final String? userName;
  final String? userEmail;

  const _CateringReviewsTab({
    this.userName,
    this.userEmail,
  });

  @override
  State<_CateringReviewsTab> createState() =>
      _CateringReviewsTabState();
}

class _CateringReviewsTabState extends State<_CateringReviewsTab> {
  final _reviewCtrl = TextEditingController();

  int _rating = 0;
  String _loggedInName = '';
  String _loggedInEmail = '';
  bool _loadingProfile = true;

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Priya & Rajesh',
      'email': '',
      'event': 'Wedding Event',
      'stars': 5,
      'text':
          'Amazing food quality! Sumathi Catering made our wedding truly special. '
              'The briyani was outstanding and everyone loved the full meals.',
    },
    {
      'name': 'Lakshmi Family',
      'email': '',
      'event': 'T. Nagar, Chennai',
      'stars': 5,
      'text':
          'Best catering in Chennai. We have been using their service for 10 years now. '
              'Consistent quality, timely delivery, and amazing taste every single time.',
    },
    {
      'name': 'Karthik',
      'email': '',
      'event': 'House Warming',
      'stars': 4,
      'text':
          'The full meals at our house warming was absolutely delicious. '
              'Authentic South Indian taste with perfect spice levels. Highly recommended',
    },
    {
      'name': 'Anand',
      'email': '',
      'event': 'Corporate Event',
      'stars': 5,
      'text':
          'Professional service, timely delivery, and the food was absolutely divine '
              'Our corporate event was a huge success thanks to Sumathi Catering.',
    },
    {
      'name': 'Sundar & Meena',
      'email': '',
      'event': 'Engagement Ceremony',
      'stars': 5,
      'text':
          'From the morning tiffin to the evening snacks, everything was perfect. '
              'The staff were professional and the service was top-notch. Will definitely use again.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileAndReviews();
  }

  Future<void> _loadProfileAndReviews() async {
    String name = widget.userName?.trim() ?? '';
    String email = widget.userEmail?.trim() ?? '';

    try {
      final prefs = await SharedPreferences.getInstance();

      if (name.isEmpty) {
        name = prefs.getString('user_name') ??
            prefs.getString('name') ??
            prefs.getString('username') ??
            '';
      }

      if (email.isEmpty) {
        email = prefs.getString('user_email') ??
            prefs.getString('email') ??
            '';
      }

      final savedReviews = prefs.getString('sumathi_catering_reviews');

      if (savedReviews != null && savedReviews.isNotEmpty) {
        final decoded = jsonDecode(savedReviews);

        if (decoded is List) {
          _reviews
            ..removeWhere((review) => review['local'] == true)
            ..insertAll(
              0,
              decoded
                  .whereType<Map>()
                  .map(
                    (review) => Map<String, dynamic>.from(review),
                  )
                  .map((review) {
                    review['local'] = true;
                    return review;
                  }),
            );
        }
      }
    } catch (e) {
      debugPrint('Review/profile load error: $e');
    }

    if (!mounted) return;

    setState(() {
      _loggedInName = name;
      _loggedInEmail = email;
      _loadingProfile = false;
    });
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final localReviews = _reviews
          .where((review) => review['local'] == true)
          .map(
            (review) => {
              'name': review['name'],
              'email': review['email'],
              'event': review['event'],
              'stars': review['stars'],
              'text': review['text'],
            },
          )
          .toList();

      await prefs.setString(
        'sumathi_catering_reviews',
        jsonEncode(localReviews),
      );
    } catch (e) {
      debugPrint('Review save error: $e');
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please login with your name and email to post a review.',
        ),
      ),
    );
  }

  void _openWriteReview() {
    if (_loadingProfile) return;

    if (_loggedInName.isEmpty || _loggedInEmail.isEmpty) {
      _showLoginRequired();
      return;
    }

    _rating = 0;
    _reviewCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Write a review',
                              style: TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Share your experience with Sumathi Catering',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                _loggedInName.isNotEmpty
                                    ? _loggedInName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _loggedInName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _loggedInEmail,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const _FieldLabel('Your Rating'),

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starNumber = index + 1;
                          final selected = starNumber <= _rating;

                          return IconButton(
                            tooltip: '$starNumber star',
                            onPressed: () {
                              setSheetState(() {
                                _rating = starNumber;
                              });
                            },
                            iconSize: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            icon: Icon(
                              selected
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: selected
                                  ? AppColors.secondary
                                  : Colors.grey.shade500,
                            ),
                          );
                        }),
                      ),

                      Center(
                        child: Text(
                          _rating == 0
                              ? 'Tap a star to rate'
                              : '$_rating out of 5 stars',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      const _FieldLabel('Your Review'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _reviewCtrl,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: _inputDecoration(
                          'Tell us about your experience...',
                        ),
                      ),

                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final reviewText = _reviewCtrl.text.trim();

                            if (_rating == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a star rating.',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (reviewText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please write your review.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final newReview = <String, dynamic>{
                              'name': _loggedInName,
                              'email': _loggedInEmail,
                              'event': 'Catering Review',
                              'stars': _rating,
                              'text': reviewText,
                              'local': true,
                            };

                            setState(() {
                              _reviews.insert(0, newReview);
                            });

                            await _saveReviews();

                            if (!mounted) return;

                            Navigator.pop(sheetContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Review posted successfully! ⭐',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 17),
                          label: const Text(
                            'Post',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;

    final total = _reviews.fold<int>(
      0,
      (sum, review) => sum + ((review['stars'] as num?)?.toInt() ?? 0),
    );

    return total / _reviews.length;
  }

  int _countForRating(int stars) {
    return _reviews.where((review) => review['stars'] == stars).length;
  }

  @override
  Widget build(BuildContext context) {
    final average = _averageRating;
    final ratingText = average == 0 ? '0.0' : average.toStringAsFixed(1);

    return SingleChildScrollView(
      child: _ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GradientHeaderBanner(
              icon: Icons.star_outline,
              title: 'Customer Reviews',
              subtitle: 'What our happy customers say about us',
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              ratingText,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '★★★★★',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_reviews.length} reviews',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [5, 4, 3, 2, 1].map((stars) {
                              final count = _countForRating(stars);
                              final percent = _reviews.isEmpty
                                  ? 0.0
                                  : count / _reviews.length;

                              return _RatingBar(
                                label: '$stars★',
                                percent: percent,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                _loggedInName.isNotEmpty
                                    ? _loggedInName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _loadingProfile
                                        ? 'Checking your account...'
                                        : _loggedInName.isNotEmpty
                                            ? 'Hi, $_loggedInName'
                                            : 'Sign in to write a review',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _loggedInEmail.isNotEmpty
                                        ? _loggedInEmail
                                        : 'Login required',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        const Text(
                          'How was your experience?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => const Icon(
                              Icons.star_border_rounded,
                              color: AppColors.secondary,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed:
                                _loadingProfile ? null : _openWriteReview,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 17,
                            ),
                            label: const Text(
                              'Write a review',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  ..._reviews.map(
                    (r) => _ReviewCard(
                      name: r['name']?.toString() ?? 'Customer',
                      email: r['email']?.toString() ?? '',
                      event: r['event']?.toString() ?? 'Catering Review',
                      stars: (r['stars'] as num?)?.toInt() ?? 5,
                      text: r['text']?.toString() ?? '',
                    ),
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// RATING BAR
// =======================================================================

class _RatingBar extends StatelessWidget {
  final String label;
  final double percent;

  const _RatingBar({
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(4),
              child:
                  LinearProgressIndicator(
                value: percent,
                minHeight: 7,
                backgroundColor:
                    AppColors.gray,
                valueColor:
                    const AlwaysStoppedAnimation(
                  AppColors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '${(percent * 100).round()}%',
              style: const TextStyle(
                fontSize: 10.5,
                color:
                    AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// REVIEW CARD
// =======================================================================

class _ReviewCard extends StatelessWidget {
  final String name;
  final String email;
  final String event;
  final int stars;
  final String text;

  const _ReviewCard({
    required this.name,
    required this.email,
    required this.event,
    required this.stars,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(
            color: AppColors.secondary,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.primary,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 11,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      event,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '★' * stars + '☆' * (5 - stars),
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// MENU DATA MODELS
// =======================================================================

class CateringMenuColumn {
  final String name;
  final List<String> items;

  const CateringMenuColumn(
    this.name,
    this.items,
  );
}

class CateringMenuParticular {
  final String label;
  final String value;

  const CateringMenuParticular(
    this.label,
    this.value,
  );
}

class CateringMenuEntry {
  final String title;
  final List<CateringMenuColumn> columns;
  final List<CateringMenuParticular>
      particulars;
  final String? price;

  const CateringMenuEntry(
    this.title,
    this.columns, {
    this.particulars = const [],
    this.price,
  });
}

// =======================================================================
// MENU DATA
// =======================================================================

final Map<String, CateringMenuEntry>
    cateringMenuData = {
  'morning': const CateringMenuEntry(
    'Morning Tiffin',
    [
      CateringMenuColumn(
        'Tiffen',
        [
          'Kesari / Pineapple Pudding',
          'Idli',
          'Pongal',
          'Poori',
          'Chenna Masala',
          'Vadai',
          'Sambhar',
          'Coconut Chutney',
          'Kara Chutney',
          'Filter Coffee',
          'Mineral Water',
          'Leaves Cups',
          'Paper roll',
        ],
      ),
      CateringMenuColumn(
        'Tiffen II',
        [
          'Kasi Halwa / Carrot Halwa',
          'Mini Idly / Kushboo Idly',
          'Pongal / Rava Pongal',
          'Mini Othappam',
          'Vadai Curry',
          'Vadai',
          'Sambhar',
          'Coconut Chutney',
          'Kara Chutney',
          'Special Coffee / Special Tea',
          'Leaves',
          'Cups Paper Roll',
          'Mineral Water',
        ],
      ),
      CateringMenuColumn(
        'Tiffin III',
        [
          'Kasi Halwa / Ashoka',
          'Idly / Kushboo Idly',
          'Kuzhi Paniharam',
          'Idiyappam',
          'Poori',
          'Veg othappam / Dosai',
          'Medu Vadai / Parppu Vadai',
          'Vadai Curry',
          'Channa Masala',
          'Sambhar',
          'Coconut Chutney',
          'Pudina Chutney, Kara Chutney',
          'Filter Coffee / Tea, Leaves',
          'Cups',
          'Paper roll',
          'Mineral Water',
        ],
      ),
    ],
  ),

  'lunch': const CateringMenuEntry(
    'Lunch Sadhya',
    [
      CateringMenuColumn(
        'Lunch I',
        [
          'Sweet (Gulab Jamun Cup)',
          'Aval Payasam',
          'Madu Vadai',
          'Ice Cream',
          'Potato Poriyal Roast',
          'Beans Carrot Poriyal',
          'Chow Chow Kottu',
          'Rice',
          'Paruppu Ghee',
          'Sambhar',
          'Vathal Kuzhumbu',
          'Tomato Rasam',
          'Curd',
          'Appalam',
          'Mango Thokku',
          'Banana',
          'Sweet Beeda',
          'Mineral Water Bottle',
          'Leaves',
          'Paper roll',
        ],
      ),
      CateringMenuColumn(
        'Lunch II',
        [
          'Sweet (Jangiri / Badusha)',
          'Cauliflower Pakoda',
          'Paruppu Payasam',
          'Ice Cream',
          'Malabar Aviyal / Kottu',
          'Urulai Patani Roast',
          'Brinjal Karamani Chops',
          'Beans Uzhili',
          'Veg Pulav / Ghee Rice',
          'Onion Raita',
          'Chapathi / Poli',
          'Kurma',
          'Rice',
          'Sambhar',
          'Rasam',
          'Curd',
          'Appalam',
          'Mango Thokku',
          'Sweet Beeda',
          'Banana',
          'Mineral Water',
          'Leaves',
          'Cups',
          'Paper roll',
          'Banana Leaf',
        ],
      ),
      CateringMenuColumn(
        'Lunch III',
        [
          'Sweet (Rasamalai / Kaju Kathali)',
          'Veg Cutlet',
          'Badam Gheer',
          'Ice Cream',
          'Senai Mochi Chops',
          'National Poriyal',
          'Malabar Aviyal / Kottu',
          'Chapathi / Butter Naan',
          'Kurma / Panner Butter Masala',
          'Veg Pulav / Noodles',
          'Onion Raita',
          'Bisebelabath',
          'Curd Rice',
          'Lemon Sevai',
          'Cocount Sevai',
          'Rice',
          'Nendrum / Potato Chips',
          'Appalam',
          'Mango Thokku',
          'Sweet Beeda',
          'Banana',
          'Mineral Water',
          'Leaves',
          'Cups',
          'Paper Roll',
        ],
      ),
    ],
  ),

  'evening': const CateringMenuEntry(
    'Evening Tiffin',
    [
      CateringMenuColumn(
        'Evening Tiffen',
        [
          'Wheat Halwa / Carrot Halwa',
          'Lemon Sevai',
          'Cocount Sevai',
          'Rava Dosai',
          'Mysore Bonda / Thavalavadai',
          'Kosthu / Sambar',
          'Chutney',
          'Coffee / Tea',
        ],
      ),
      CateringMenuColumn(
        'Evening Tiffen II',
        [
          'Milk Cake / Jangiri / Poli',
          'Cashew Pakoda / Samosa',
          'Cutlet / Karam Pakoda',
          'Ice Cream',
          'Kitchadi / Lemon Sevai',
          'Chutney',
          'Coffee / Tea',
        ],
      ),
    ],
  ),

  'reception': const CateringMenuEntry(
    'Reception Dinner',
    [
      CateringMenuColumn(
        'Catalogue I',
        [
          'Basundi',
          'Gulabjamun',
          'Potato Chips',
          'Cutlet / Gopi 65',
          'Bisi Bela Bath',
          'Veg Pulav',
          'White Rice',
          'Rasam',
          'Kothamalli Sadam',
          'Cocount Sevai',
          'Chappathy',
          'Naan / Butter Naan',
          'Panner Butter Masala',
          'Navarathna Kurma',
          'Rumani Roti',
          'Potato Fry',
          'Potato Orange Fry',
          'Pickles',
          'Leaves',
          'Chow Chow Kottu',
          'Onion Uthappam / Dosai',
          'Puthina Chutney',
          'Fruits',
          'Ice Cream',
          'Water Bottle',
          'Beeda',
        ],
      ),
      CateringMenuColumn(
        'Catalogue II',
        [
          'Rasamalai',
          'Makkan Beda',
          'Neantharan Chips',
          'Sembu 65',
          'Veg Biriyani',
          'Pine Apple Rasam',
          'Curry Leaves Rice',
          'Lemon Sevai',
          'Parota',
          'Pulka',
          'Malai Koftha',
          'Veg. Kurma',
          'Spring Roll',
          'National Poriyal',
          'Senai Chops',
          'Mix. Veg. Pickles',
          'Cabagge Kottu',
          'Kothamalli Chutney',
          'Fruit Salad',
          '3 Varietys / Kulfi',
        ],
      ),
      CateringMenuColumn(
        'Catalogue III',
        [
          'Kajuroll',
          'Jangiri',
          'Finger Chips',
          'Spring Roll / Lalipup',
          'Kashmiri Pulav',
          'Paruppu Rasam',
          'Lemon Rice',
          'Chapathi / Butter Naan',
          'Chola Puri',
          'Romali Roti',
          'Palak Panner',
          'Panner Kurma',
          'Punjab Curry',
          'Lemon Sevai',
          'Brinjal Chops',
          'Mango Thokku',
          'Veg. Kottu / Avaiyal',
          'Masala Dosai',
          'Tomato Chutney',
          'Kesar Kulfi',
        ],
      ),
    ],
  ),

  'marriage': const CateringMenuEntry(
    'Marriage Package',
    [
      CateringMenuColumn(
        'Evening Tiffen (100 Nos)',
        [
          'Kesari',
          'Mysore Bonda / Medu Pakoda',
          'Cocount Chutney',
          'Filter Coffee',
          'Evening Drinks (400 Nos)',
          'Grape Juice / Badam Kher',
          'Filter Coffee',
        ],
      ),
      CateringMenuColumn(
        'Reception Meals (400 Nos)',
        [
          'Rasamalai / Mundiri Cake',
          'Veg Cutlet',
          'Paruppu Payasam',
          'Ice Cream',
          'Chappathi / Naan',
          'Kurma / Panner Masala',
          'Veg Pulav',
          'Onion Raitha',
          'Sambhar Rice',
          'Curd Rice',
          'Chapathi / Poli',
          'Rice',
          'Rasam',
          'Potato Chips',
          'Malabar Aviyal',
          'Appalam',
          'Mango Thokku',
          'Banana',
          'Beeda',
          'Water Bottle',
          'Table Paper',
        ],
      ),
      CateringMenuColumn(
        'Morning Tiffen (300 Nos)',
        [
          'Sweet (Rasamalai / Kaju Kathali)',
          'Veg Cutlet',
          'Badam Gheer',
          'Ice Cream',
          'Senai Mochi Chops',
          'National Poriyal',
          'Malabar Aviyal / Kottu',
          'Chapathi / Butter Naan',
          'Kurma / Panner Butter Masala',
          'Veg Pulav / Noodles',
          'Onion Raita',
          'Bisebelabath',
          'Curd Rice',
          'Lemon Sevai',
          'Cocount Sevai',
          'Rice',
          'Nendrum / Potato Chips',
          'Appalam',
          'Mango Thokku',
          'Sweet Beeda',
          'Banana',
          'Mineral Water',
          'Leaves',
          'Cups',
          'Paper Roll',
        ],
      ),
    ],
    particulars: [
      CateringMenuParticular(
        'Tambulam Bag with name Printing',
        '500',
      ),
      CateringMenuParticular(
        'Tambulam Tenga',
        '500',
      ),
      CateringMenuParticular(
        'Laddu',
        '300',
      ),
      CateringMenuParticular(
        'Mixture',
        '10 kg',
      ),
      CateringMenuParticular(
        'Water Bottle',
        '',
      ),
      CateringMenuParticular(
        'Gas Cylinder',
        '',
      ),
      CateringMenuParticular(
        'Service with Uniform',
        '',
      ),
      CateringMenuParticular(
        'Service with Supervisors',
        '',
      ),
      CateringMenuParticular(
        'Reception Sandanam, Panner with Reception Ladies',
        '',
      ),
    ],
    price: 'Rs. 2,25,000 (Total Package)',
  ),

  'general': const CateringMenuEntry(
    'General Package',
    [
      CateringMenuColumn(
        'Sweets',
        [
          'Badam Boat',
          'Badam Biscuit',
          'Badam Singoda',
          'Badam Mysore Pak',
          'Bisi Bela Bath',
          'Rajbogh',
          'Kaserbhati',
          'Madhur Milan',
          'Gunj Uthi Shanai',
          'Malai Gulla',
          'Malai ChamCham',
          'Angur Rabadi',
          'Mallai Sandwich',
          'Rasagoola Toast',
          'Milk Brown',
          'Bengali Rakhi',
          'Badam Pista Roll',
          'Badam Mango',
          'Malai Pan',
          'Ras Madam',
          'Pista Sandwich',
          'Malai Roll',
          'Kesar Kali',
          'Water Bottle',
          'Pista Mysore Pak',
        ],
      ),
      CateringMenuColumn(
        'South Indian',
        [
          'Idly',
          'Rava Idly',
          'Khusbu Idly',
          'Fry Idly',
          'Fry Sameiy',
          'Idiyapam Plain',
          'Plain Dosa',
          'Masala Dosa',
          'Mysore Masala Dosa',
          'Panner Silda',
          'Veg. Uttapam',
          'Onion Uttapam',
          'Veg Pulav',
          'Semaiya Bakala Bat',
          'Coconut Rices',
          'Bismala Rice',
          'Podina Rice',
          'Vadai Kari',
          'Navratan Kurma',
          'Tomato Rasam',
          'Pineapple Rasam',
          'Imlai Rasam',
          'Masala Vadai',
          'Mysore Bonda',
          'Medu Vada',
          'Kerai Vada',
          'Onion Pakoda',
          'Beans Poriyal',
          'Carrot Poriyal',
          'Veg. Poriyal',
          'Batata Poriyal',
        ],
      ),
      CateringMenuColumn(
        'Chinese',
        [
          'Green Maxican Rice',
          'Cauli Flower Rice',
          'Chinese Corandal Rice',
          'Ginger Black Mushroom',
          'Fried Rice',
          'Capsicum Cheese Pepper Rice',
          'Cauliflower Agartin',
          'Chilly Cheese Roll',
          'Vegetable Dumplings',
          'Governor Vegetables',
          'Barvan Panner',
          'Napalithaine',
          'Gobi Manchurian',
          'Baby Corn Vegetable',
          'American Chopsey',
          'Panner Shasalik',
          'Backed Beans',
          'Veg. Cheese Ling',
          'Veg. Spring Roll',
          'Veg. Hong Kong',
          'Noodles',
          'American Noddles',
          'Veg. Cabbage Roll',
          'Fry Mushroom Roll',
          'Chatni Varieties '
              '(Green / Onion / Coconut / Tomato / Sweet / Red / '
              'Phudina / Navratna)',
        ],
      ),
      CateringMenuColumn(
        'Cool Drinks / More',
        [
          'Kajuroll',
          'Jangiri',
          'Finger Chips',
          'Spring Roll / Lalipup',
          'Kashmiri Pulav',
          'Paruppu Rasam',
          'Lemon Rice',
          'Chapathi / Butter Naan',
          'Chola Puri',
          'Romali Roti',
          'Palak Panner',
          'Panner Kurma',
          'Punjab Curry',
          'Lemon Sevai',
          'Brinjal Chops',
          'Mango Thokku',
          'Veg. Kottu / Avaiyal',
          'Masala Dosai',
          'Tomato Chutney',
          'Kesar Kulfi',
        ],
      ),
    ],
  ),
};