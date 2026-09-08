import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_colors.dart';

/// ===============================================================
/// CONTACT PAGE
/// ===============================================================

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  /// ---------------------------------------------------------------
  /// CONTACT DETAILS
  /// (matches website.html Contact Us section)
  /// ---------------------------------------------------------------

  static const String phoneNumber = '8610703658';
  static const String whatsappNumber = '918610703658';
  static const String email = 'sumathisstyle@gmail.com';
  static const String address = 'Injambakkam, Chennai';
  static const String instagramUrl =
      'https://www.instagram.com/_bridal__designer_/';
  static const String youtubeUrl =
      'https://www.youtube.com/@sumathicateringserviceoffi4046/featured';
  static const String mapsUrl =
      'https://maps.app.goo.gl/RYJZnmMLKigTTSd47';

  /// ---------------------------------------------------------------
  /// LAUNCH HELPERS
  /// ---------------------------------------------------------------

  Future<void> _launch(
    BuildContext context,
    Uri uri,
  ) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open this link'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open this link'),
          ),
        );
      }
    }
  }

  void _callPhone(BuildContext context) {
    _launch(context, Uri.parse('tel:$phoneNumber'));
  }

  void _openWhatsApp(BuildContext context) {
    final message =
        'Hi Sumathi, I would like to know more about your services.';

    _launch(
      context,
      Uri.parse(
        'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}',
      ),
    );
  }

  void _sendEmail(BuildContext context) {
    _launch(context, Uri.parse('mailto:$email'));
  }

  void _openInstagram(BuildContext context) {
    _launch(context, Uri.parse(instagramUrl));
  }

  void _openYoutube(BuildContext context) {
    _launch(context, Uri.parse(youtubeUrl));
  }

  void _openMaps(BuildContext context) {
    _launch(context, Uri.parse(mapsUrl));
  }

  /// ---------------------------------------------------------------
  /// BUILD
  /// ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,

      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(
            title: 'Contact Us',
            subtitle: 'Get in touch — 30 years of trust',
          ),

          const SizedBox(height: 22),

          // -----------------------------------------------------
          // CONTACT INFO CARD
          // -----------------------------------------------------

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.content_cut,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Sumathi's Style Boutique",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ContactItem(
                  icon: Icons.location_on,
                  title: 'Address',
                  subtitle: address,
                  onTap: () => _openMaps(context),
                ),

                _ContactItem(
                  icon: Icons.call,
                  title: 'Phone',
                  subtitle: '86107 03658',
                  onTap: () => _callPhone(context),
                ),

                _ContactItem(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: email,
                  onTap: () => _sendEmail(context),
                ),

                _ContactItem(
                  icon: Icons.restaurant_menu,
                  title: 'Catering',
                  subtitle: '86107 03658',
                  onTap: () => _callPhone(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -----------------------------------------------------
          // SOCIAL BUTTONS
          // FIXED: buttons were reported as too big — reduced
          // childAspectRatio (shorter boxes), tighter spacing,
          // and smaller icon/text sizes.
          // -----------------------------------------------------

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.3,
            children: [
              _SocialButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                colors: const [
                  Color(0xFF25D366),
                  Color(0xFF128C7E),
                ],
                onTap: () => _openWhatsApp(context),
              ),

              _SocialButton(
                icon: Icons.camera_alt,
                label: 'Instagram',
                colors: const [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                ],
                onTap: () => _openInstagram(context),
              ),

              _SocialButton(
                icon: Icons.play_circle_fill,
                label: 'YouTube',
                colors: const [
                  Color(0xFFFF0000),
                  Color(0xFFCC0000),
                ],
                onTap: () => _openYoutube(context),
              ),

              _SocialButton(
                icon: Icons.phone,
                label: 'Call Now',
                colors: const [
                  AppColors.secondary,
                  AppColors.secondaryLight,
                ],
                onTap: () => _callPhone(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // -----------------------------------------------------
          // MAP (tap to open live location in Google Maps)
          // -----------------------------------------------------

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                InkWell(
                  onTap: () => _openMaps(context),
                  child: Container(
                    height: 170,
                    width: double.infinity,
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
                                color: AppColors.primary,
                                size: 44,
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Sumathi's Style",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Injambakkam, Chennai',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.my_location, size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'View live map',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMaps(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.directions, size: 17),
                      label: const Text(
                        'Get Directions',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// ===============================================================
/// SECTION HEADER
/// ===============================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontFamily: 'PlayfairDisplay',
          ),
        ),

        const SizedBox(height: 6),

        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

/// ===============================================================
/// CONTACT ITEM ROW
/// ===============================================================

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// SOCIAL BUTTON
/// ===============================================================

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 15,
            ),

            const SizedBox(width: 6),

            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}