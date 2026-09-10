import 'dart:math' as math;
import 'package:flutter/material.dart';

class OtpVerifyPage extends StatefulWidget {
  final String phoneNumber;
  final String correctOtp;
  final VoidCallback onVerified;

  const OtpVerifyPage({
    super.key,
    required this.phoneNumber,
    required this.correctOtp,
    required this.onVerified,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage>
    with TickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? errorText;
  bool isVerifying = false;
  bool isVerified = false;

  late AnimationController _mainAnimationController;
  late AnimationController _scissorController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _successController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ------------------------------------------------------------
  // SUMATHI STYLES COLORS
  // ------------------------------------------------------------

  static const Color background = Color(0xFF07080C);
  static const Color cardColor = Color(0xFF151722);
  static const Color gold = Color(0xFFFFC44D);
  static const Color cream = Color(0xFFF7F3EA);
  static const Color greyText = Color(0xFFA9AAB8);

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // MAIN PAGE ANIMATION
    // ----------------------------------------------------------

    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // ----------------------------------------------------------
    // SCISSOR ANIMATION
    // ----------------------------------------------------------

    _scissorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // ----------------------------------------------------------
    // GOLD GLOW
    // ----------------------------------------------------------

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // ----------------------------------------------------------
    // BACKGROUND PARTICLES
    // ----------------------------------------------------------

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    // ----------------------------------------------------------
    // SUCCESS ANIMATION
    // ----------------------------------------------------------

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _mainAnimationController.forward();

    // ----------------------------------------------------------
    // DEMO OTP POPUP
    // ----------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (_) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: gold.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.15),
                    blurRadius: 35,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scissor icon
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withValues(alpha: 0.12),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      color: gold,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "DEMO OTP",
                    style: TextStyle(
                      color: gold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.correctOtp,
                    style: const TextStyle(
                      color: cream,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 7,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "This OTP is shown only\nfor demo/testing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: greyText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "CONTINUE",
                        style: TextStyle(
                          color: background,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // ------------------------------------------------------------
  // VERIFY OTP
  // ------------------------------------------------------------

  Future<void> _verifyOtp() async {
    if (isVerifying) return;

    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() {
        errorText = "Please enter the 6-digit OTP";
      });
      return;
    }

    if (otp != widget.correctOtp) {
      setState(() {
        errorText = "Incorrect OTP. Please try again.";
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isVerifying = true;
      errorText = null;
    });

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    setState(() {
      isVerified = true;
    });

    _successController.forward();

    await Future.delayed(
      const Duration(milliseconds: 1200),
    );

    if (!mounted) return;

    widget.onVerified();
  }

  // ------------------------------------------------------------
  // FASHION BACKGROUND
  // ------------------------------------------------------------

  Widget _fashionBackground(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scissorController,
            _particleController,
            _glowController,
          ]),
          builder: (context, child) {
            return CustomPaint(
              painter: _FashionBackgroundPainter(
                scissorProgress: _scissorController.value,
                particleProgress: _particleController.value,
                glowProgress: _glowController.value,
              ),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ANIMATED SCISSOR
  // ------------------------------------------------------------

  Widget _animatedScissors() {
    return AnimatedBuilder(
      animation: _scissorController,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(
          _scissorController.value,
        );

        final rotation = math.sin(value * math.pi * 2) * 0.10;
        final moveX = math.sin(value * math.pi * 2) * 8;

        return Transform.translate(
          offset: Offset(moveX, 0),
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.09),
                border: Border.all(
                  color: gold.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.08),
                    blurRadius: 25,
                  ),
                ],
              ),
              child: const Icon(
                Icons.content_cut_rounded,
                color: gold,
                size: 36,
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // OTP BOXES
  // ------------------------------------------------------------

  Widget _otpBoxes() {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Stack(
            children: [
              SizedBox(
                height: 1,
                width: 1,
                child: TextField(
                  controller: _otpController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: false,
                  style: const TextStyle(
                    color: Colors.transparent,
                  ),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setState(() {
                        errorText = null;
                      });
                    }

                    setState(() {});
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) {
                    final text = _otpController.text;
                    final filled = index < text.length;

                    final active =
                        index == text.length &&
                        _focusNode.hasFocus;

                    final glow = 0.10 +
                        (_glowController.value * 0.12);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 47,
                      height: 58,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: errorText != null
                              ? Colors.redAccent
                              : active
                                  ? gold
                                  : filled
                                      ? gold.withValues(
                                          alpha: 0.45,
                                        )
                                      : const Color(0xFF3D4050),
                          width: active ? 2 : 1,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: gold.withValues(
                                    alpha: glow,
                                  ),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ]
                            : filled
                                ? [
                                    BoxShadow(
                                      color: gold.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 180,
                          ),
                          child: filled
                              ? const Text(
                                  "●",
                                  key: ValueKey("filled"),
                                  style: TextStyle(
                                    color: gold,
                                    fontSize: 17,
                                  ),
                                )
                              : const SizedBox(
                                  key: ValueKey("empty"),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // VERIFY BUTTON
  // ------------------------------------------------------------

  Widget _verifyButton() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: isVerifying ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              disabledBackgroundColor: gold.withValues(
                alpha: 0.55,
              ),
              elevation: 4,
              shadowColor: gold.withValues(
                alpha: 0.18 + (_glowController.value * 0.15),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: isVerifying
                ? const SizedBox(
                    height: 23,
                    width: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: background,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "VERIFY",
                        style: TextStyle(
                          color: background,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedBuilder(
                        animation: _scissorController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              math.sin(
                                    _scissorController.value *
                                        math.pi *
                                        2,
                                  ) *
                                  4,
                              0,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: background,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SUCCESS VIEW
  // ------------------------------------------------------------

  Widget _successView() {
    return AnimatedBuilder(
      animation: _successController,
      builder: (context, child) {
        final scale = Curves.elasticOut.transform(
          _successController.value,
        );

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  height: 115,
                  width: 115,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold,
                    boxShadow: [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.30),
                        blurRadius: 35,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 68,
                    color: background,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                "OTP Verified!",
                style: TextStyle(
                  color: cream,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Your account has been verified",
                style: TextStyle(
                  color: greyText,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 25),

              _animatedScissors(),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final horizontalPadding =
        size.width < 380 ? 18.0 : 28.0;

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,

      body: Stack(
        children: [
          // ------------------------------------------------------
          // FASHION BACKGROUND
          // ------------------------------------------------------

          _fashionBackground(size),

          // ------------------------------------------------------
          // TOP RIGHT GLOW
          // ------------------------------------------------------

          Positioned(
            top: -160,
            right: -130,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 370,
                  height: 370,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(
                      alpha:
                          0.025 +
                          (_glowController.value * 0.025),
                    ),
                  ),
                );
              },
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
                color: const Color(0xFF151722)
                    .withValues(alpha: 0.85),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ------------------------------------------------
                // TOP BAR
                // ------------------------------------------------

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: cardColor.withValues(
                              alpha: 0.88,
                            ),
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
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior
                                .onDrag,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 500,
                          ),
                          child: isVerified
                              ? SizedBox(
                                  height: size.height * 0.78,
                                  child: _successView(),
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: size.height < 700
                                          ? 25
                                          : 48,
                                    ),

                                    // ------------------------------------------------
                                    // SCISSOR ANIMATION
                                    // ------------------------------------------------

                                    _animatedScissors(),

                                    const SizedBox(height: 18),

                                    // ------------------------------------------------
                                    // FASHION LINE
                                    // ------------------------------------------------

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: gold.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Icon(
                                            Icons
                                                .checkroom_rounded,
                                            color: gold.withValues(
                                              alpha: 0.45,
                                            ),
                                            size: 20,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: gold.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 25),

                                    // ------------------------------------------------
                                    // TITLE
                                    // ------------------------------------------------

                                    const Text(
                                      "Verify Your Account",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: cream,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    const Text(
                                      "We've sent a 6-digit OTP to",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: greyText,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      widget.phoneNumber,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: gold,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),

                                    const SizedBox(height: 35),

                                    // ------------------------------------------------
                                    // OTP LABEL
                                    // ------------------------------------------------

                                    const Align(
                                      alignment:
                                          Alignment.centerLeft,
                                      child: Text(
                                        "ENTER 6-DIGIT OTP",
                                        style: TextStyle(
                                          color: greyText,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    _otpBoxes(),

                                    if (errorText != null) ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment:
                                            Alignment.centerLeft,
                                        child: Text(
                                          errorText!,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.redAccent,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 30),

                                    // ------------------------------------------------
                                    // VERIFY BUTTON
                                    // ------------------------------------------------

                                    _verifyButton(),

                                    const SizedBox(height: 23),

                                    // ------------------------------------------------
                                    // RESEND
                                    // ------------------------------------------------

                                    TextButton(
                                      onPressed: () {
                                        _otpController.clear();

                                        setState(() {
                                          errorText = null;
                                        });

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                cardColor,
                                            behavior:
                                                SnackBarBehavior
                                                    .floating,
                                            shape:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                14,
                                              ),
                                            ),
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .check_circle_outline,
                                                  color: gold,
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  "OTP sent again",
                                                  style: TextStyle(
                                                    color: cream,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Didn't receive the OTP?  Resend",
                                        style: TextStyle(
                                          color: gold,
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 35),

                                    // ------------------------------------------------
                                    // FOOTER
                                    // ------------------------------------------------

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons
                                              .content_cut_rounded,
                                          color: gold.withValues(
                                            alpha: 0.45,
                                          ),
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
                                          Icons
                                              .content_cut_rounded,
                                          color: gold.withValues(
                                            alpha: 0.45,
                                          ),
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
                ),
              ],
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
    _otpController.dispose();
    _focusNode.dispose();

    _mainAnimationController.dispose();
    _scissorController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _successController.dispose();

    super.dispose();
  }
}

// ================================================================
// FASHION BACKGROUND PAINTER
// ================================================================

class _FashionBackgroundPainter extends CustomPainter {
  final double scissorProgress;
  final double particleProgress;
  final double glowProgress;

  _FashionBackgroundPainter({
    required this.scissorProgress,
    required this.particleProgress,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // ------------------------------------------------------------
    // SOFT FASHION CIRCLE
    // ------------------------------------------------------------

    paint.color = const Color(0xFF12141C);

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.34),
      size.width * 0.42,
      paint,
    );

    // ------------------------------------------------------------
    // DRESS SILHOUETTE
    // ------------------------------------------------------------

    final dressPaint = Paint()
      ..color = const Color(0xFF1B1D28).withValues(alpha: 0.62)
      ..style = PaintingStyle.fill;

    final dressPath = Path();

    final cx = size.width * 0.82;
    final top = size.height * 0.24;

    // Neck
    dressPath.moveTo(cx - 12, top);

    // Left shoulder
    dressPath.lineTo(cx - 38, top + 20);

    // Left arm
    dressPath.lineTo(cx - 55, top + 45);

    // Waist
    dressPath.lineTo(cx - 25, top + 105);

    // Skirt
    dressPath.lineTo(cx - 90, top + 255);

    dressPath.quadraticBezierTo(
      cx,
      top + 290,
      cx + 90,
      top + 255,
    );

    dressPath.lineTo(cx + 25, top + 105);

    // Right shoulder
    dressPath.lineTo(cx + 55, top + 45);

    dressPath.lineTo(cx + 38, top + 20);

    dressPath.lineTo(cx + 12, top);

    dressPath.close();

    canvas.drawPath(dressPath, dressPaint);

    // ------------------------------------------------------------
    // DRESS GOLD OUTLINE
    // ------------------------------------------------------------

    final outlinePaint = Paint()
      ..color = const Color(0xFFFFC44D)
          .withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(dressPath, outlinePaint);

    // ------------------------------------------------------------
    // SCISSOR CUTTING LINE
    // ------------------------------------------------------------

    final cutPaint = Paint()
      ..color = const Color(0xFFFFC44D)
          .withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final cutPath = Path();

    for (int i = 0; i < 6; i++) {
      final x1 = cx - 65 + (i * 22);
      final y = top + 170 + math.sin(i * 1.5) * 4;

      if (i == 0) {
        cutPath.moveTo(x1, y);
      } else {
        cutPath.lineTo(x1, y);
      }
    }

    canvas.drawPath(cutPath, cutPaint);

    // ------------------------------------------------------------
    // FLOATING GOLD PARTICLES
    // ------------------------------------------------------------

    final particlePaint = Paint()
      ..color = const Color(0xFFFFC44D)
          .withValues(alpha: 0.20);

    for (int i = 0; i < 18; i++) {
      final baseX =
          (i * 71.0) % size.width;

      final baseY =
          (i * 97.0) % size.height;

      final movement =
          math.sin(
                particleProgress * math.pi * 2 +
                    i,
              ) *
              12;

      final y =
          (baseY +
                  particleProgress * size.height +
                  movement) %
              size.height;

      final radius = 1.0 + (i % 3) * 0.5;

      canvas.drawCircle(
        Offset(baseX, y),
        radius,
        particlePaint,
      );
    }

    // ------------------------------------------------------------
    // SMALL SCISSOR WATERMARK
    // ------------------------------------------------------------

    final scissorPaint = Paint()
      ..color = const Color(0xFFFFC44D)
          .withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final sx =
        size.width * 0.16 +
        math.sin(
              scissorProgress * math.pi * 2,
            ) *
            8;

    final sy = size.height * 0.70;

    canvas.drawCircle(
      Offset(sx - 8, sy),
      8,
      scissorPaint,
    );

    canvas.drawCircle(
      Offset(sx + 8, sy),
      8,
      scissorPaint,
    );

    canvas.drawLine(
      Offset(sx - 2, sy - 2),
      Offset(sx + 30, sy - 24),
      scissorPaint,
    );

    canvas.drawLine(
      Offset(sx + 2, sy + 2),
      Offset(sx + 30, sy + 24),
      scissorPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FashionBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.scissorProgress !=
            scissorProgress ||
        oldDelegate.particleProgress !=
            particleProgress ||
        oldDelegate.glowProgress != glowProgress;
  }
}