import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PosterPage extends StatefulWidget {
  const PosterPage({super.key});

  @override
  State<PosterPage> createState() => _PosterPageState();
}

class _PosterPageState extends State<PosterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  bool _showModal = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _glowAnimation = Tween<double>(
      begin: 0.8,
      end: 1.6,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // OPEN WHATSAPP
  // ----------------------------------------------------------
  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse(
      'https://wa.me/918610703658?text=Hi%2C%20I%27m%20interested%20in%20the%20Bridal%20Package',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ----------------------------------------------------------
  // OPEN INSTAGRAM
  // ----------------------------------------------------------
  Future<void> _openInstagram() async {
    final Uri url = Uri.parse(
      'https://www.instagram.com/_bridal__designer_/',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ----------------------------------------------------------
  // CALL
  // ----------------------------------------------------------
  Future<void> _makeCall() async {
    final Uri url = Uri.parse('tel:+918610703658');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // ----------------------------------------------------------
  // BRIDAL PACKAGE CLICK
  // ----------------------------------------------------------
  void _showBridal() {
    _glowController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _showModal = true;
        });
      }
    });
  }



  // ----------------------------------------------------------
  // FEATURE ITEM
  // ----------------------------------------------------------
  Widget _feature(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFFB87333),
                Color(0xFFD4A574),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text(
              '✓',
              style: TextStyle(
                color: Color(0xFF1A2A3A),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFF0FFF4),
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // LEFT SECTION
  // ----------------------------------------------------------
  Widget _buildLeftSection() {
    return Container(
      color: const Color(0xFF008080),
      padding: const EdgeInsets.symmetric(
        horizontal: 50,
        vertical: 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Bridal Package',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Turn Your Wedding Day Dream Into Reality! '
                  'Complete bridal stitching & styling — crafted with '
                  '30 years of trusted experience.',
                  style: TextStyle(
                    color: Color(0xFFF0FFF4),
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),

                const SizedBox(height: 26),

                Column(
                  children: [
                    _feature(
                      'Saree Falls — Proper fall stitching for heavy bridal sarees.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Saree Hemming — Clean finishing for saree edges.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Saree Tassels — Decorative tassels for pallu.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Saree Pre-Pleating — Ready-to-wear pleats for wedding day convenience.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Blouse Normal — Standard blouse stitching with lining.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Aari Blouse — Heavy bridal embroidery with beads, zardosi, stones.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Lehenga — Bridal lehenga stitching with lining and can-can support.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Blouse Padding — Perfect fit with bridal comfort.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Dupatta Edging — Lace or pico finish for dupatta borders.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Boutique Finishing Touches — Piping, hooks, dori, tassels for elegance.',
                    ),
                    const SizedBox(height: 15),

                    _feature(
                      'Trial Fitting Sessions — Ensures comfort and flawless bridal look.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // POSTER SECTION
  // ----------------------------------------------------------
  Widget _buildPosterSection() {
    return Container(
      color: const Color(0xFFF0FFF4),
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 40,
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double posterWidth = constraints.maxWidth;

            if (posterWidth > 460) {
              posterWidth = 460;
            }

            return SizedBox(
              width: posterWidth,
              child: AspectRatio(
                aspectRatio: 460 / 650,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // --------------------------------------------------
                      // POSTER IMAGE
                      // --------------------------------------------------
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/sumathi.png',
                          fit: BoxFit.cover,
                        ),
                      ),

                      // --------------------------------------------------
                      // BRIDAL PACKAGE HOTSPOT
                      // --------------------------------------------------
                      Positioned(
                        left: posterWidth * 0.73,
                        top: posterWidth * 0.73 * (650 / 460),
                        width: posterWidth * 0.22,
                        height: posterWidth * 0.22 * (650 / 460),
                        child: GestureDetector(
                          onTap: _showBridal,
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              double scale =
                                  _glowController.isAnimating
                                      ? _glowAnimation.value
                                      : 1.0;

                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF008080)
                                            .withOpacity(
                                          _glowController.isAnimating
                                              ? 0.55
                                              : 0.25,
                                        ),
                                        blurRadius:
                                            _glowController.isAnimating
                                                ? 22
                                                : 12,
                                        spreadRadius:
                                            _glowController.isAnimating
                                                ? 6
                                                : 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // --------------------------------------------------
                      // INSTAGRAM HOTSPOT
                      // --------------------------------------------------
                      Positioned(
                        left: posterWidth * 0.875,
                        bottom: posterWidth * 0.046,
                        width: posterWidth * 0.08,
                        height: posterWidth * 0.046,
                        child: GestureDetector(
                          onTap: _openInstagram,
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),

                      // --------------------------------------------------
                      // PHONE HOTSPOT
                      // --------------------------------------------------
                      Positioned(
                        left: posterWidth * 0.36,
                        bottom: posterWidth * 0.065,
                        width: posterWidth * 0.44,
                        height: posterWidth * 0.065,
                        child: GestureDetector(
                          onTap: _makeCall,
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // BOOKING MODAL
  // ----------------------------------------------------------
  Widget _buildModal() {
    if (!_showModal) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.70),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: TweenAnimationBuilder<double>(
          tween: Tween(
            begin: 0.90,
            end: 1.0,
          ),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 360,
            ),
            padding: const EdgeInsets.fromLTRB(
              26,
              34,
              26,
              34,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF008080),
                  Color(0xFF1A2A3A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF008080).withOpacity(0.40),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Interested in the Bridal Package?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD4A574),
                        fontFamily: 'Playfair Display',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'Message us on WhatsApp for booking details, '
                      'pricing & available dates. Our team will get '
                      'back to you shortly!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF0FFF4),
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // WhatsApp button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: const Icon(
                          Icons.chat,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Message on WhatsApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Close button
                Positioned(
                  top: -12,
                  right: -10,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _showModal = false;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFFD4A574),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // MAIN BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ------------------------------------------------------
          // RESPONSIVE PAGE
          // ------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isMobile = constraints.maxWidth <= 900;

              if (isMobile) {
                // MOBILE:
                // Poster first
                // Details second
                return Container(
                  color: const Color(0xFF008080),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildPosterSection(),
                          _buildLeftSection(),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // DESKTOP:
              // Left details | Right poster
              return SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildLeftSection(),
                    ),
                    Expanded(
                      child: _buildPosterSection(),
                    ),
                  ],
                ),
              );
            },
          ),

          

          // ------------------------------------------------------
          // MODAL
          // ------------------------------------------------------
          _buildModal(),
        ],
      ),
    );
  }
}