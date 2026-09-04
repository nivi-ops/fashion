import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_colors.dart';

/// ===============================================================
/// CLASS MODEL
/// ===============================================================

class ClassItem {
  final String title;
  final String imagePath;
  final String description;
  final String duration;
  final String students;
  final String price;

  const ClassItem({
    required this.title,
    required this.imagePath,
    required this.description,
    required this.duration,
    required this.students,
    required this.price,
  });
}

/// ===============================================================
/// CLASSES PAGE
/// ===============================================================

class ClassPage extends StatelessWidget {
  const ClassPage({super.key});

  /// ---------------------------------------------------------------
  /// CLASS LIST
  /// ---------------------------------------------------------------

  static const List<ClassItem> classes = [
    ClassItem(
      title: 'Aari Work Class',
      imagePath: 'assets/images/image.png',
      description:
          'Learn traditional South Indian aari embroidery. Master chain stitch, bead work, and zardosi patterns.',
      duration: '1 Month',
      students: '2000 Students',
      price: '₹10,000',
    ),

    ClassItem(
      title: 'Tailoring Class',
      imagePath: 'assets/images/tailocls.jpg',
      description:
          'Complete course from basics to advanced. Measurements, cutting, stitching for all garments.',
      duration: '6 Months',
      students: '1500 Students',
      price: '₹2,000',
    ),

    ClassItem(
      title: 'Saree Pre-pleating Class',
      imagePath: 'assets/images/Saree.jpg',
      description:
          'Master perfect saree pleating. Different styles, petticoat stitching, draping techniques.',
      duration: '1 Week',
      students: '500 Students',
      price: '₹2,000',
    ),
  ];

  /// ---------------------------------------------------------------
  /// WHATSAPP NUMBER
  /// ---------------------------------------------------------------

  static const String whatsappNumber = '918610703658';

  /// ---------------------------------------------------------------
  /// ENROLL CLASS
  /// ---------------------------------------------------------------

  Future<void> _enrollClass(
    BuildContext context,
    String className,
  ) async {
    final message =
        'Hi Sumathi, I am interested in enrolling for $className. Please provide more details.';

    final Uri uri = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp',
            ),
          ),
        );
      }
    }
  }

  /// ---------------------------------------------------------------
  /// BUILD
  /// ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,

      /// -----------------------------------------------------------
      /// APP BAR
      /// -----------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'Our Classes',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      /// -----------------------------------------------------------
      /// BODY
      /// -----------------------------------------------------------

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(
            title: 'Our Classes',
            subtitle:
                'Learn from 30 years experienced experts',
          ),

          const SizedBox(height: 22),

          ...classes.map(
            (item) => Padding(
              padding: const EdgeInsets.only(
                bottom: 16,
              ),
              child: _ClassCard(
                item: item,
                onEnroll: () {
                  _enrollClass(
                    context,
                    item.title,
                  );
                },
              ),
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
            borderRadius:
                BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

/// ===============================================================
/// CLASS CARD
/// ===============================================================

class _ClassCard extends StatelessWidget {
  final ClassItem item;
  final VoidCallback onEnroll;

  const _ClassCard({
    required this.item,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    // FIXED: the previous version used a fixed SizedBox(height: 160)
    // around the Row(crossAxisAlignment: stretch), but the actual
    // content (title + 3-line description + meta chips + button)
    // needed more than 160px, which caused the
    // "BOTTOM OVERFLOWED BY ~20 PIXELS" yellow/black stripe.
    //
    // IntrinsicHeight measures the tallest child (the text column)
    // and gives the image column that same bounded height, instead
    // of a hardcoded number — so the card grows to fit its content
    // and never overflows, no matter the font/device.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              /// -------------------------------------------------------
              /// IMAGE
              /// -------------------------------------------------------

              SizedBox(
                width: 110,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      color: AppColors.light,
                      child: const Icon(
                        Icons.checkroom,
                        color:
                            AppColors.primary,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),

              /// -------------------------------------------------------
              /// CONTENT
              /// -------------------------------------------------------

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      /// TITLE

                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// DESCRIPTION

                      Text(
                        item.description,
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color:
                              AppColors.textLight,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// META INFORMATION

                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _MetaChip(
                            icon:
                                Icons.access_time,
                            label:
                                item.duration,
                          ),

                          _MetaChip(
                            icon: Icons.people,
                            label:
                                item.students,
                          ),

                          _MetaChip(
                            icon:
                                Icons.currency_rupee,
                            label:
                                item.price.replaceAll(
                              '₹',
                              '',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// ENROLL BUTTON

                      SizedBox(
                        width: double.infinity,
                        child:
                            ElevatedButton.icon(
                          onPressed: onEnroll,

                          icon: const Icon(
                            Icons.chat,
                            size: 16,
                          ),

                          label: const Text(
                            'Enroll Now',
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.primary,
                            foregroundColor:
                                Colors.white,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 10,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                          ),
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
    );
  }
}

/// ===============================================================
/// META CHIP
/// ===============================================================

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: AppColors.secondary,
        ),

        const SizedBox(width: 3),

        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}