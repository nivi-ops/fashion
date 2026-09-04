import 'package:flutter/material.dart';
import 'app_colors.dart';

/// =====================================================================
/// TEMPORARY PLACEHOLDER PAGES (Divya)
/// =====================================================================
/// These exist ONLY to unblock your build — home_page.dart's nav bar
/// and footer link to ClassesPage / CateringPage / ContactPage, and
/// those classes didn't exist yet in simple_pages.dart, which was
/// causing the "isn't a class" errors.
///
/// Each one below is a simple "Coming Soon" screen with your app's
/// theming. Replace the body of each with your real page whenever
/// you're ready — you already mentioned you built a WebView-based
/// catering page earlier, so you can swap _ComingSoonBody() out for
/// that in CateringPage once you wire it back in.
///
/// HOW TO USE:
/// 1. Save this file as placeholder_pages.dart in your lib folder.
/// 2. In home_page.dart, add:
///      import 'placeholder_pages.dart';
/// 3. Remove/don't duplicate these class names anywhere else
///    (e.g. if simple_pages.dart already has partial versions,
///    delete those first to avoid "duplicate class" errors).
/// =====================================================================

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonScaffold(
      title: 'Classes',
      icon: Icons.school_outlined,
      message: 'Tailoring & Aari Work classes info coming soon!',
    );
  }
}

class CateringPage extends StatelessWidget {
  const CateringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonScaffold(
      title: 'Catering',
      icon: Icons.restaurant_menu_outlined,
      message: 'Catering & event booking page coming soon!',
      // TODO(Divya): swap this body for your WebView-based catering
      // page once you're ready to wire it back in here.
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonScaffold(
      title: 'Contact Us',
      icon: Icons.call_outlined,
      message: 'Call, WhatsApp & location details coming soon!',
    );
  }
}

/// Shared "Coming Soon" layout so all 3 pages look consistent with
/// your app's teal/gold theme instead of a plain blank screen.
class _ComingSoonScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const _ComingSoonScaffold({
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}