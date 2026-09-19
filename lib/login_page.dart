import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_nav_page.dart';
import 'otp_verify_page.dart';
import 'app_state.dart';
import 'admin_page.dart';

/// Country with its dial code and allowed mobile number length.
class Country {
  final String name;
  final String flag;
  final String code;
  final int minLen;
  final int maxLen;

  const Country(this.name, this.flag, this.code, this.minLen, this.maxLen);
}

// Lengths are for the number WITHOUT the country code.
const List<Country> kCountries = [
  Country('India', '🇮🇳', '+91', 10, 10),
  Country('United States / Canada', '🇺🇸', '+1', 10, 10),
  Country('United Kingdom', '🇬🇧', '+44', 10, 10),
  Country('United Arab Emirates', '🇦🇪', '+971', 9, 9),
  Country('Saudi Arabia', '🇸🇦', '+966', 9, 9),
  Country('Qatar', '🇶🇦', '+974', 8, 8),
  Country('Kuwait', '🇰🇼', '+965', 8, 8),
  Country('Oman', '🇴🇲', '+968', 8, 8),
  Country('Bahrain', '🇧🇭', '+973', 8, 8),
  Country('Singapore', '🇸🇬', '+65', 8, 8),
  Country('Malaysia', '🇲🇾', '+60', 9, 10),
  Country('Sri Lanka', '🇱🇰', '+94', 9, 9),
  Country('Maldives', '🇲🇻', '+960', 7, 7),
  Country('Nepal', '🇳🇵', '+977', 10, 10),
  Country('Bangladesh', '🇧🇩', '+880', 10, 10),
  Country('Pakistan', '🇵🇰', '+92', 10, 10),
  Country('Australia', '🇦🇺', '+61', 9, 9),
  Country('New Zealand', '🇳🇿', '+64', 8, 10),
  Country('Germany', '🇩🇪', '+49', 10, 11),
  Country('France', '🇫🇷', '+33', 9, 9),
  Country('Italy', '🇮🇹', '+39', 9, 10),
  Country('Spain', '🇪🇸', '+34', 9, 9),
  Country('Netherlands', '🇳🇱', '+31', 9, 9),
  Country('Ireland', '🇮🇪', '+353', 9, 9),
  Country('Switzerland', '🇨🇭', '+41', 9, 9),
  Country('Sweden', '🇸🇪', '+46', 9, 9),
  Country('Russia', '🇷🇺', '+7', 10, 10),
  Country('Turkey', '🇹🇷', '+90', 10, 10),
  Country('Israel', '🇮🇱', '+972', 9, 9),
  Country('Japan', '🇯🇵', '+81', 10, 10),
  Country('South Korea', '🇰🇷', '+82', 9, 10),
  Country('China', '🇨🇳', '+86', 11, 11),
  Country('Hong Kong', '🇭🇰', '+852', 8, 8),
  Country('Thailand', '🇹🇭', '+66', 9, 9),
  Country('Indonesia', '🇮🇩', '+62', 9, 12),
  Country('Philippines', '🇵🇭', '+63', 10, 10),
  Country('Vietnam', '🇻🇳', '+84', 9, 9),
  Country('Mauritius', '🇲🇺', '+230', 8, 8),
  Country('South Africa', '🇿🇦', '+27', 9, 9),
  Country('Kenya', '🇰🇪', '+254', 9, 9),
  Country('Nigeria', '🇳🇬', '+234', 10, 10),
  Country('Egypt', '🇪🇬', '+20', 10, 10),
  Country('Brazil', '🇧🇷', '+55', 10, 11),
  Country('Mexico', '🇲🇽', '+52', 10, 10),
  Country('Argentina', '🇦🇷', '+54', 10, 10),
];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();

  final Color teal = const Color(0xff0F766E);
  final Color lightTeal = const Color(0xff4FC3B0);
  final Color gold = const Color(0xffD4AF37);

  // Default country = India (+91)
  Country _country = kCountries.first;

  String _generateOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  String get _lengthText => _country.minLen == _country.maxLen
      ? '${_country.maxLen}-digit'
      : '${_country.minLen}-${_country.maxLen} digit';

  void _onCountryChanged(Country? c) {
    if (c == null) return;
    setState(() {
      _country = c;
      // Trim already typed digits if the new country allows fewer digits
      final text = mobileController.text;
      if (text.length > c.maxLen) {
        mobileController.text = text.substring(0, c.maxLen);
        mobileController.selection = TextSelection.fromPosition(
          TextPosition(offset: mobileController.text.length),
        );
      }
    });
  }

  Future<void> _completeLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    final name = nameController.text.trim();
    final mobile = mobileController.text.trim();
    await prefs.setString('userName', name);
    await prefs.setString('userMobile', mobile);
    await prefs.setString('userCountryCode', _country.code);

    // Indian numbers keep the same id as before (10 digits).
    // Other countries get the country code prefix so ids never clash.
    final userId = _country.code == '+91' ? mobile : '${_country.code}$mobile';
    AppState.instance.login(userId: userId, userName: name);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavPage()),
      (route) => false,
    );
  }

  void _startLogin() {
    if (_formKey.currentState!.validate()) {
      final otp = _generateOtp();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyPage(
            phoneNumber: '${_country.code} ${mobileController.text.trim()}',
            correctOtp: otp,
            onVerified: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Login Successful"),
                  backgroundColor: Colors.green,
                ),
              );
              _completeLogin();
            },
          ),
        ),
      );
    }
  }

  void _continueAsGuest() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavPage()),
      (route) => false,
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
  }) {
    return InputDecoration(
      counterText: "",
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70, fontSize: 15),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      enabledBorder: _border(Colors.white.withValues(alpha: 0.30)),
      focusedBorder: _border(lightTeal, width: 2),
      errorBorder: _border(Colors.redAccent),
      focusedErrorBorder: _border(Colors.redAccent, width: 2),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  Widget _countryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Country>(
              value: _country,
              isDense: true,
              dropdownColor: const Color(0xff1E1E1E),
              iconEnabledColor: gold,
              menuWidth: 290,
              menuMaxHeight: 360,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              // Closed state: only flag + code
              selectedItemBuilder: (context) => kCountries
                  .map(
                    (c) => Center(
                      child: Text(
                        '${c.flag} ${c.code}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              // Open menu: flag + country name + code
              items: kCountries
                  .map(
                    (c) => DropdownMenuItem<Country>(
                      value: c,
                      child: Text(
                        '${c.flag}  ${c.name} (${c.code})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _onCountryChanged,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/lgn_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // Light overlay only for text readability
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Very light admin-access icon (kept faint on purpose)
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: Opacity(
                opacity: 0.25,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminPage()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------- LOGO ----------
                      Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/app.png", // <-- your logo path
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.checkroom, color: teal, size: 48),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ---------- BRAND NAME (smaller font) ----------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "SUMATHI",
                            style: TextStyle(
                              color: lightTeal,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "STYLES",
                            style: TextStyle(
                              color: gold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // ---------- TAGLINE ----------
                      const Text(
                        "Fashion Designing Boutique",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ---------- LOGIN CONTAINER ----------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Customer Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Enter your details to continue",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Full Name
                              TextFormField(
                                controller: nameController,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z ]')),
                                ],
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldDecoration(
                                  hint: "Full Name",
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: gold),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter your name";
                                  }
                                  if (!RegExp(r'^[a-zA-Z ]+$')
                                      .hasMatch(value.trim())) {
                                    return "Only alphabets are allowed";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Mobile Number with country code dropdown
                              TextFormField(
                                controller: mobileController,
                                keyboardType: TextInputType.phone,
                                maxLength: _country.maxLen,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: const TextStyle(color: Colors.white),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: _fieldDecoration(
                                  hint: "Mobile Number",
                                  prefixIcon: _countryDropdown(),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) {
                                    return "Please enter your Mobile Number";
                                  }
                                  if (v.length < _country.minLen ||
                                      v.length > _country.maxLen) {
                                    return "Enter a valid $_lengthText mobile number";
                                  }
                                  // Indian mobile numbers start with 6-9
                                  if (_country.code == '+91' &&
                                      !RegExp(r'^[6-9]').hasMatch(v)) {
                                    return "Indian mobile numbers start with 6, 7, 8 or 9";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 8),

                              // Dynamic hint below the mobile field
                              Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      size: 16, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Enter a valid $_lengthText mobile number for ${_country.name}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // LOGIN button (inside container)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lightTeal,
                                  foregroundColor: Colors.white,
                                  overlayColor: gold.withValues(alpha: 0.35),
                                  elevation: 4,
                                  shadowColor: teal.withValues(alpha: 0.6),
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _startLogin,
                                icon: const Icon(Icons.sms_outlined),
                                label: const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------- WELCOME TEXT (below container) ----------
                      const Text(
                        "Welcome to Sumathi's Styles ✨",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 4),

                      TextButton(
                        onPressed: _continueAsGuest,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Continue as ",
                                style: TextStyle(
                                  color: lightTeal,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(
                                text: "Guest",
                                style: TextStyle(
                                  color: gold,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    super.dispose();
  }
}