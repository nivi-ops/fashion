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
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? errorText;
  bool isVerifying = false;
  bool isVerified = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ------------------------------------------------------------
  // SUMATHI STYLES COLORS
  // ------------------------------------------------------------

  static const Color background = Color(0xFF08090D);
  static const Color cardColor = Color(0xFF151722);
  static const Color gold = Color(0xFFFFC44D);
  static const Color cream = Color(0xFFF7F3EA);
  static const Color greyText = Color(0xFFA9AAB8);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
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

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    widget.onVerified();
  }

  // ------------------------------------------------------------
  // OTP BOX
  // ------------------------------------------------------------

  Widget _otpBoxes() {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Stack(
        children: [
          // Hidden TextField
          SizedBox(
            height: 1,
            width: 1,
            child: TextField(
              controller: _otpController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
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

                final bool filled = index < text.length;

                final bool active =
                    index == text.length && _focusNode.hasFocus;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 47,
                  height: 58,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: errorText != null
                          ? Colors.redAccent
                          : active
                              ? gold
                              : const Color(0xFF3D4050),
                      width: active ? 2 : 1,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: gold.withValues(alpha: 0.18),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      filled ? "●" : "",
                      style: const TextStyle(
                        color: cream,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // VERIFY BUTTON
  // ------------------------------------------------------------

  Widget _verifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isVerifying ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          disabledBackgroundColor: gold.withValues(alpha: 0.55),
          elevation: 0,
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
                children: const [
                  Text(
                    "VERIFY",
                    style: TextStyle(
                      color: background,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: background,
                    size: 24,
                  ),
                ],
              ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUCCESS VIEW
  // ------------------------------------------------------------

  Widget _successView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold,
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 65,
              color: background,
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            "OTP Verified!",
            style: TextStyle(
              color: cream,
              fontSize: 27,
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
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // ------------------------------------------------------
          // BACKGROUND CIRCLES
          // ------------------------------------------------------

          Positioned(
            top: -150,
            right: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF11131D),
              ),
            ),
          ),

          Positioned(
            bottom: -180,
            left: -150,
            child: Container(
              width: 390,
              height: 390,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF11131D),
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
                            color: cardColor,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width < 380 ? 20 : 28,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 500,
                          ),
                          child: isVerified
                              ? SizedBox(
                                  height: size.height * 0.75,
                                  child: _successView(),
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: size.height < 700
                                          ? 30
                                          : 70,
                                    ),

                                    // ------------------------------------------------
                                    // OTP ICON
                                    // ------------------------------------------------

                                    Container(
                                      height: 92,
                                      width: 92,
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha: 0.10),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: gold.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: gold,
                                        size: 42,
                                      ),
                                    ),

                                    const SizedBox(height: 28),

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

                                    const SizedBox(height: 38),

                                    // ------------------------------------------------
                                    // OTP LABEL
                                    // ------------------------------------------------

                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "ENTER 6-DIGIT OTP",
                                        style: TextStyle(
                                          color: greyText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    _otpBoxes(),

                                    if (errorText != null) ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          errorText!,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 30),

                                    // ------------------------------------------------
                                    // VERIFY
                                    // ------------------------------------------------

                                    _verifyButton(),

                                    const SizedBox(height: 25),

                                    // ------------------------------------------------
                                    // RESEND
                                    // ------------------------------------------------

                                    TextButton(
                                      onPressed: () {
                                        _otpController.clear();

                                        setState(() {
                                          errorText = null;
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "OTP sent again",
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Didn't receive the OTP?  Resend",
                                        style: TextStyle(
                                          color: gold,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 45),

                                    // ------------------------------------------------
                                    // FOOTER
                                    // ------------------------------------------------

                                    const Text(
                                      "SUMATHI STYLES",
                                      style: TextStyle(
                                        color: greyText,
                                        fontSize: 11,
                                        letterSpacing: 3,
                                      ),
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

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}