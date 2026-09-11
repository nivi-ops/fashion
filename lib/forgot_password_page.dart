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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: cream),
        title: const Text(
          "Forgot Password",
          style: TextStyle(color: cream, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // ------------------------------------------------
                // APP LOGO (medium size)
                // ------------------------------------------------
                Image.asset(
                  'assets/app.png',
                  height: 110,
                  width: 110,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 25),

                const Text(
                  "Enter your registered Email or Mobile Number.\n"
                  "We'll send you an OTP to reset your password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: greyText, height: 1.5),
                ),

                const SizedBox(height: 25),

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

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    contactController.dispose();
    super.dispose();
  }
}