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

class _OtpVerifyPageState extends State<OtpVerifyPage>
    with TickerProviderStateMixin {
  final TextEditingController otpController = TextEditingController();

  String? errorText;

  final Color teal = const Color(0xff0F766E);
  final Color gold = const Color(0xffD4AF37);

  // ------------------------------------------------------------
  // PAGE ANIMATION
  // ------------------------------------------------------------

  late final AnimationController _pageController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _boxScale;

  // ------------------------------------------------------------
  // SUCCESS ANIMATION
  // ------------------------------------------------------------

  late final AnimationController _successController;
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;
  late final Animation<double> _checkProgress;

  bool _isVerifying = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // PAGE ENTRY ANIMATION
    // ----------------------------------------------------------

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeIn,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: Curves.easeOutCubic,
      ),
    );

    _boxScale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: Curves.elasticOut,
      ),
    );

    _pageController.forward();

    // ----------------------------------------------------------
    // SUCCESS ANIMATION
    // ----------------------------------------------------------

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _successScale = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.elasticOut,
      ),
    );

    _successFade = CurvedAnimation(
      parent: _successController,
      curve: const Interval(
        0.0,
        0.45,
        curve: Curves.easeIn,
      ),
    );

    _checkProgress = CurvedAnimation(
      parent: _successController,
      curve: const Interval(
        0.25,
        0.90,
        curve: Curves.easeOutCubic,
      ),
    );

    // ----------------------------------------------------------
    // DEMO OTP POPUP
    // ----------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            "Demo OTP",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Your OTP is: ${widget.correctOtp}\n\n"
            "(This is shown only in demo mode. In production this "
            "will be sent via SMS/Email instead.)",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  // ------------------------------------------------------------
  // VERIFY
  // ------------------------------------------------------------

  Future<void> _verify() async {
    if (_isVerifying) return;

    final String enteredOtp = otpController.text.trim();

    // Empty OTP
    if (enteredOtp.isEmpty) {
      setState(() {
        errorText = "Please enter the OTP.";
      });
      return;
    }

    // Less than 4 digits
    if (enteredOtp.length != 4) {
      setState(() {
        errorText = "Please enter the 4-digit OTP.";
      });
      return;
    }

    // ----------------------------------------------------------
    // CORRECT OTP
    // ----------------------------------------------------------

    if (enteredOtp == widget.correctOtp) {
      setState(() {
        _isVerifying = true;
        errorText = null;
      });

      // Hide keyboard
      FocusScope.of(context).unfocus();

      // Loading effect
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      // Show success screen
      setState(() {
        _isVerified = true;
      });

      // Play success animation
      await _successController.forward(from: 0);

      if (!mounted) return;

      // Keep success visible
      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      // Continue to next page
      widget.onVerified();
    }

    // ----------------------------------------------------------
    // WRONG OTP
    // ----------------------------------------------------------

    else {
      setState(() {
        errorText = "Incorrect OTP. Please try again.";
      });

      // Small animation replay
      await _pageController.forward(
        from: 0.7,
      );

      if (!mounted) return;

      otpController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: otpController.text.length,
      );
    }
  }

  // ------------------------------------------------------------
  // OTP INPUT
  // ------------------------------------------------------------

  Widget _otpInput() {
    return ScaleTransition(
      scale: _boxScale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: teal.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (_) {
            if (errorText != null) {
              setState(() {
                errorText = null;
              });
            }
          },
          decoration: InputDecoration(
            counterText: "",
            errorText: errorText,
            filled: true,
            fillColor: Colors.white,
            hintText: "••••",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 25,
              letterSpacing: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: teal,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // VERIFY BUTTON
  // ------------------------------------------------------------

  Widget _verifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          disabledBackgroundColor: teal.withValues(alpha: 0.75),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isVerifying ? null : _verify,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isVerifying
              ? const SizedBox(
                  key: ValueKey("loading"),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : Text(
                  "VERIFY",
                  key: const ValueKey("verify"),
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUCCESS SCREEN
  // ------------------------------------------------------------

  Widget _successView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _successScale,
          child: FadeTransition(
            opacity: _successFade,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teal,
                boxShadow: [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.28),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _checkProgress,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _AnimatedCheckPainter(
                      progress: _checkProgress.value,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 25),

        FadeTransition(
          opacity: _successFade,
          child: const Text(
            "OTP Verified!",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xff0F766E),
            ),
          ),
        ),

        const SizedBox(height: 8),

        FadeTransition(
          opacity: _successFade,
          child: const Text(
            "Verification successful",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F4EC),

      appBar: AppBar(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: Stack(
        children: [
          // ------------------------------------------------------
          // BACKGROUND IMAGE
          // ------------------------------------------------------

          Positioned.fill(
            child: Image.asset(
              "assets/images/lgn_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // ------------------------------------------------------
          // WHITE OVERLAY
          // ------------------------------------------------------

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ),

          // ------------------------------------------------------
          // CONTENT
          // ------------------------------------------------------

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,

                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },

                      child: _isVerified
                          ? _successView()
                          : Column(
                              key: const ValueKey("otpContent"),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // SMS ICON
                                Icon(
                                  Icons.sms_outlined,
                                  size: 60,
                                  color: gold,
                                ),

                                const SizedBox(height: 20),

                                // TITLE
                                const Text(
                                  "Enter the 4-digit OTP sent to you",
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 25),

                                // OTP
                                _otpInput(),

                                const SizedBox(height: 20),

                                // VERIFY
                                _verifyButton(),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    otpController.dispose();
    _pageController.dispose();
    _successController.dispose();
    super.dispose();
  }
}

// =================================================================
// ANIMATED CHECK MARK
// =================================================================

class _AnimatedCheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AnimatedCheckPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final double startX = size.width * 0.27;
    final double startY = size.height * 0.52;

    final double midX = size.width * 0.44;
    final double midY = size.height * 0.68;

    final double endX = size.width * 0.76;
    final double endY = size.height * 0.34;

    // ------------------------------------------------------------
    // First part of check
    // ------------------------------------------------------------

    if (progress <= 0) {
      return;
    }

    if (progress < 0.5) {
      final double firstProgress = progress / 0.5;

      final double currentX =
          startX + (midX - startX) * firstProgress;

      final double currentY =
          startY + (midY - startY) * firstProgress;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(currentX, currentY),
        paint,
      );
    }

    // ------------------------------------------------------------
    // Second part of check
    // ------------------------------------------------------------

    else {
      // Draw first half completely
      canvas.drawLine(
        Offset(startX, startY),
        Offset(midX, midY),
        paint,
      );

      final double secondProgress =
          (progress - 0.5) / 0.5;

      final double currentX =
          midX + (endX - midX) * secondProgress;

      final double currentY =
          midY + (endY - midY) * secondProgress;

      canvas.drawLine(
        Offset(midX, midY),
        Offset(currentX, currentY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _AnimatedCheckPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}