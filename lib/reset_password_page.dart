import 'package:flutter/material.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirm = true;

  // ------------------------------------------------------------
  // SUMATHI STYLES COLORS (same as OTP page)
  // ------------------------------------------------------------
  static const Color background = Color(0xFF061312);
  static const Color cardColor = Color(0xFF0F1D1C);
  static const Color teal = Color(0xFF18C7B7);
  static const Color gold = Color(0xFFFFC44D);
  static const Color cream = Color(0xFFF7F3EA);
  static const Color greyText = Color(0xFFA9B8B6);

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    required VoidCallback onToggle,
    required bool hidden,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: gold),
      suffixIcon: IconButton(
        icon: Icon(
          hidden ? Icons.visibility_off : Icons.visibility,
          color: greyText,
        ),
        onPressed: onToggle,
      ),
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
          "Reset Password",
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
                Icon(Icons.lock_outline, size: 60, color: gold),
                const SizedBox(height: 25),

                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  style: const TextStyle(color: cream),
                  decoration: _fieldDecoration(
                    hint: "New Password",
                    icon: Icons.lock,
                    hidden: hidePassword,
                    onToggle: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return "Minimum 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: confirmController,
                  obscureText: hideConfirm,
                  style: const TextStyle(color: cream),
                  decoration: _fieldDecoration(
                    hint: "Confirm New Password",
                    icon: Icons.lock_outline,
                    hidden: hideConfirm,
                    onToggle: () {
                      setState(() {
                        hideConfirm = !hideConfirm;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return "Passwords do not match";
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: cardColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: gold),
                                SizedBox(width: 10),
                                Text(
                                  "Password Reset Successful",
                                  style: TextStyle(color: cream),
                                ),
                              ],
                            ),
                          ),
                        );

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text(
                      "RESET PASSWORD",
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
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}