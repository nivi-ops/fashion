import 'package:flutter/material.dart';
import 'dart:math';
import 'otp_verify_page.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final contactController = TextEditingController();

  // ------------------------------------------------------------
  // SUMATHI STYLES COLORS (same as OTP page)
  // ------------------------------------------------------------
  static const Color background = Color(0xFF061312);
  static const Color cardColor = Color(0xFF0F1D1C);
  static const Color teal = Color(0xFF18C7B7);
  static const Color gold = Color(0xFFFFC44D);
  static const Color cream = Color(0xFFF7F3EA);
  static const Color greyText = Color(0xFFA9B8B6);

  static const String logoAsset = 'assets/images/app.png';

  String _generateOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      final otp = _generateOtp();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyPage(
            phoneNumber: contactController.text.trim(),
            correctOtp: otp,
            onVerified: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResetPasswordPage(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: gold),
      hintText: hint,
      hintStyle: const TextStyle(color: greyText),
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: teal.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: teal.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  // ------------------------------------------------------------
  // ROUND LOGO BADGE — same style as OTP page
  // ------------------------------------------------------------
  Widget _logoBadge({double size = 92}) {
    return Container(
      height: size,
      width: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cardColor,
        border: Border.all(
          color: gold.withValues(alpha: 0.55),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: teal.withValues(alpha: 0.15),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          logoAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: cardColor,
              alignment: Alignment.center,
              child: Text(
                "S",
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.42,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width < 380 ? 18.0 : 28.0;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // ------------------------------------------------------
          // TOP RIGHT GLOW
          // ------------------------------------------------------
          Positioned(
            top: -160,
            right: -130,
            child: Container(
              width: 370,
              height: 370,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teal.withValues(alpha: 0.045),
              ),
            ),
          ),

          // ------------------------------------------------------
          // BOTTOM LEFT GLOW
          // ------------------------------------------------------
          Positioned(
            bottom: -190,
            left: -160,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B2926).withValues(alpha: 0.88),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ------------------------------------------------
                // TOP BAR — same as OTP page
                // ------------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.88),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF30323E),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: cream,
                            size: 19,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "SUMATHI",
                        style: TextStyle(
                          color: cream,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "STYLES",
                        style: TextStyle(
                          color: gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // ------------------------------------------------
                // MAIN CONTENT
                // ------------------------------------------------
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SizedBox(height: size.height < 700 ? 25 : 48),

                            // LOGO
                            _logoBadge(size: 92),

                            const SizedBox(height: 18),

                            // FASHION LINE
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: teal.withValues(alpha: 0.22),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    Icons.checkroom_rounded,
                                    color: gold.withValues(alpha: 0.70),
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: teal.withValues(alpha: 0.22),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),

                            const Text(
                              "Forgot Password",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: cream,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 14),

                            const Text(
                              "Enter your registered Email or Mobile Number.\n"
                              "We'll send you an OTP to reset your password.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: greyText,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            TextFormField(
                              controller: contactController,
                              style: const TextStyle(color: cream),
                              decoration: _fieldDecoration(
                                hint: "Email / Mobile Number",
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter your Email or Mobile Number";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gold,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _sendOtp,
                                child: const Text(
                                  "SEND OTP",
                                  style: TextStyle(
                                    color: background,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 35),

                            // FOOTER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.content_cut_rounded,
                                  color: teal.withValues(alpha: 0.65),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "SUMATHI STYLES",
                                  style: TextStyle(
                                    color: greyText,
                                    fontSize: 11,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.content_cut_rounded,
                                  color: teal.withValues(alpha: 0.65),
                                  size: 14,
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "Style that speaks for you ♡",
                              style: TextStyle(
                                color: greyText,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    contactController.dispose();
    super.dispose();
  }
}