import 'package:flutter/material.dart';

class OtpVerifyPage extends StatefulWidget {
  final String correctOtp;
  final String title;
  final VoidCallback onVerified;

  const OtpVerifyPage({
    super.key,
    required this.correctOtp,
    required this.onVerified,
    this.title = "Verify OTP",
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final otpController = TextEditingController();
  String? errorText;

  final Color teal = const Color(0xff0F766E);
  final Color gold = const Color(0xffD4AF37);

  @override
  void initState() {
    super.initState();
    // DEMO MODE: show the generated OTP on screen since there is no
    // real SMS/Email service connected yet. Remove this once a real
    // OTP provider (Firebase / Twilio / PHP mail) is wired up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Demo OTP"),
          content: Text(
            "Your OTP is: ${widget.correctOtp}\n\n"
            "(This is shown only in demo mode. In production this "
            "will be sent via SMS/Email instead.)",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  void _verify() {
    if (otpController.text.trim() == widget.correctOtp) {
      widget.onVerified();
    } else {
      setState(() {
        errorText = "Incorrect OTP. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F4EC),
      appBar: AppBar(
        backgroundColor: teal,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sms_outlined, size: 60, color: gold),
            const SizedBox(height: 20),
            const Text(
              "Enter the 4-digit OTP sent to you",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: "",
                errorText: errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _verify,
              child: Text(
                "VERIFY",
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}