// custom_order_page.dart
// Flutter version of the "Customized Order" section from index.html
// (id="custom"). Mobile-first: feature strip + heading on top, form below —
// same content/behaviour as the website's .custom-order block.
//
// SETUP:
//   1. flutter pub add http record path_provider
//      (permission is handled internally by the `record` package on both
//      Android and iOS, so you do NOT need permission_handler separately —
//      but you DO need to declare the mic permission in your platform
//      manifests, see below.)
//   2. Set kSubmitFormsUrl below to your real submit_forms.php endpoint
//      (same one the website posts to), e.g.
//      'https://yourdomain.com/submit_forms.php'
//   3. Voice recording is now REAL — it uses the device microphone via the
//      `record` package, saves an .m4a file, and base64-encodes it into the
//      'voice_note' field on submit (same idea as the website's
//      getUserMedia -> base64 -> voice_note flow).
//
//   ANDROID: add this to android/app/src/main/AndroidManifest.xml,
//   inside the <manifest> tag (above <application>):
//     <uses-permission android:name="android.permission.RECORD_AUDIO" />
//
//   iOS: add this to ios/Runner/Info.plist:
//     <key>NSMicrophoneUsageDescription</key>
//     <string>We need microphone access so you can record a voice message
//     about your custom order.</string>

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'app_colors.dart';

/// TODO: point this to your real submit_forms.php URL.
const String kSubmitFormsUrl = 'https://YOUR_DOMAIN_HERE/submit_forms.php';

class CustomOrderPage extends StatefulWidget {
  const CustomOrderPage({super.key});

  @override
  State<CustomOrderPage> createState() => _CustomOrderPageState();
}

class _CustomOrderPageState extends State<CustomOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bustController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _lengthController = TextEditingController();
  final _notesController = TextEditingController();

  String? _orderType;
  bool _submitting = false;

  // ---------------- Voice recording state ----------------
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordedFilePath;
  Duration _recordDuration = Duration.zero;
  DateTime? _recordStartedAt;

  final List<String> _orderTypes = const [
    'All',
    'Kids',
    'Uniform',
    'Modern',
    'Salwar',
    'Blouse',
    'Aari',
    'Saree',
    'Frock',
    'Lehenga',
    'Kurthi',
  ];

  final List<_FeatureItem> _features = const [
    _FeatureItem(Icons.straighten, 'Personalized\nMeasurements'),
    _FeatureItem(Icons.checkroom, 'Any Design,\nAny Fabric'),
    _FeatureItem(Icons.support_agent, 'Voice Message\nSupport'),
    _FeatureItem(Icons.local_shipping, 'Home Delivery\nAvailable'),
    _FeatureItem(Icons.stars, '30 Years of\nTrusted Craft'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bustController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _lengthController.dispose();
    _notesController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ---------------- Real mic recording ----------------

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // record package requests mic permission internally on first call.
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showSnack(
        'Microphone permission is needed to record a voice message',
        isError: true,
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _hasRecording = false;
        _recordedFilePath = null;
        _recordDuration = Duration.zero;
        _recordStartedAt = DateTime.now();
      });
    } catch (e) {
      _showSnack('Could not start recording. Please try again.',
          isError: true);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      final started = _recordStartedAt;
      setState(() {
        _isRecording = false;
        _hasRecording = path != null;
        _recordedFilePath = path;
        _recordDuration = started != null
            ? DateTime.now().difference(started)
            : Duration.zero;
      });
    } catch (e) {
      _showSnack('Could not save the recording. Please try again.',
          isError: true);
      setState(() => _isRecording = false);
    }
  }

  void _discardRecording() {
    final path = _recordedFilePath;
    if (path != null) {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    }
    setState(() {
      _hasRecording = false;
      _recordedFilePath = null;
      _recordDuration = Duration.zero;
    });
  }

  Future<String> _voiceNoteAsBase64() async {
    final path = _recordedFilePath;
    if (path == null || !_hasRecording) return '';
    final file = File(path);
    if (!await file.exists()) return '';
    final bytes = await file.readAsBytes();
    // Prefixed like a data URI so your backend can tell what it is and
    // decode it straight into an .m4a file.
    return 'data:audio/m4a;base64,${base64Encode(bytes)}';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------------- Submit ----------------

  Future<void> _submitOrder() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_orderType == null) {
      _showSnack('Please select an order type', isError: true);
      return;
    }
    if (_isRecording) {
      _showSnack('Please stop the recording before submitting',
          isError: true);
      return;
    }

    setState(() => _submitting = true);

    final measurements =
        'Bust: ${_bustController.text.trim()} | '
        'Waist: ${_waistController.text.trim()} | '
        'Hip: ${_hipController.text.trim()} | '
        'Length: ${_lengthController.text.trim()}';

    final voiceNote = await _voiceNoteAsBase64();

    final payload = {
      'type': 'order',
      'name': _nameController.text.trim(),
      'mobile': _phoneController.text.trim(),
      'product': _orderType,
      'amount': 0,
      'notes': _notesController.text.trim().isEmpty
          ? 'None'
          : _notesController.text.trim(),
      'measurement': measurements,
      'voice_note': voiceNote,
      'source': 'custom-order',
    };

    try {
      final response = await http.post(
        Uri.parse(kSubmitFormsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);
      if (data is Map && data['status'] == 'success') {
        _showSnack(
          'Custom order submitted! We will contact you soon. 📞',
        );
        _formKey.currentState?.reset();
        _nameController.clear();
        _phoneController.clear();
        _bustController.clear();
        _waistController.clear();
        _hipController.clear();
        _lengthController.clear();
        _notesController.clear();
        _discardRecording();
        setState(() => _orderType = null);
      } else {
        _showSnack(
          (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Unable to save custom order',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Unable to save custom order right now', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Custom Order'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildIntroSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- INTRO (feature strip + heading + tagline) ----------------

  Widget _buildIntroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFeatureStrip(),
          const SizedBox(height: 24),
          const Text(
            'Customized Order',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 2,
                  color: AppColors.primary,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.content_cut,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ),
                Container(
                  width: 28,
                  height: 2,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Turn Your Dream Outfit Into Reality! ✂️ Got a special occasion, "
            "a wedding, or your own design idea in mind? Just tell us — "
            "we'll custom stitch it for you. Perfect fit, your style, "
            "your choice.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureStrip() {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.dark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _features.length,
        separatorBuilder: (_, __) => Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 18),
          color: Colors.white.withValues(alpha: 0.25),
        ),
        itemBuilder: (context, i) {
          final feature = _features[i];
          return SizedBox(
            width: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  feature.icon,
                  color: AppColors.secondary,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Text(
                  feature.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- FORM (matches .custom-form) ----------------

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Place Your Custom Order',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Your Name *'),
            _buildTextField(
              controller: _nameController,
              hint: 'Enter your name',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Phone Number *'),
            _buildTextField(
              controller: _phoneController,
              hint: 'Enter phone number',
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Order Type *'),
            _buildDropdown(),
            const SizedBox(height: 16),

            _buildLabel('Measurements (inches)'),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _bustController,
                    hint: 'Bust',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _waistController,
                    hint: 'Waist',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _hipController,
                    hint: 'Hip',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _lengthController,
                    hint: 'Length',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel('Requirements / Notes'),
            _buildTextField(
              controller: _notesController,
              hint: 'Describe your design, fabric, color, occasion...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildLabel('Voice Message (Optional)'),
            _buildVoiceRecordBox(),
            const SizedBox(height: 22),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(_submitting ? 'Submitting...' : 'Submit Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _orderType,
          isExpanded: true,
          hint: const Text(
            'Select type',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          decoration: const InputDecoration(border: InputBorder.none),
          items: _orderTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _orderType = v),
          validator: (v) => v == null ? 'Please select a type' : null,
        ),
      ),
    );
  }

  Widget _buildVoiceRecordBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggleVoiceRecording,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isRecording
                    ? const Color(0xFFFF4757)
                    : AppColors.primaryLight,
                width: 2,
                style: BorderStyle.solid,
              ),
              color: _isRecording
                  ? const Color(0xFFFF4757).withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  _isRecording
                      ? Icons.stop_circle
                      : (_hasRecording ? Icons.check_circle : Icons.mic_none),
                  color: _isRecording
                      ? const Color(0xFFFF4757)
                      : (_hasRecording
                          ? AppColors.success
                          : AppColors.primary),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isRecording
                        ? 'Recording... Tap to stop'
                        : (_hasRecording
                            ? 'Voice recorded (${_formatDuration(_recordDuration)}) — tap to re-record'
                            : 'Tap to record voice message'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_hasRecording && !_isRecording)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _discardRecording,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Remove recording'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
      ],
    );
  }
}

/// ===============================================================
/// FEATURE ITEM (icon + label for the horizontal strip)
/// ===============================================================

class _FeatureItem {
  final IconData icon;
  final String label;

  const _FeatureItem(this.icon, this.label);
}