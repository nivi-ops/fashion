import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'app_colors.dart';
import 'app_state.dart';
import 'models.dart';

/// ---------------------------------------------------------------------
/// PAYMENT METHOD
/// ---------------------------------------------------------------------

enum PaymentMethod {
  upi,
  card,
  cod,
}

/// ---------------------------------------------------------------------
/// CHECKOUT PAGE
/// ---------------------------------------------------------------------

class CheckoutPage extends StatefulWidget {
  final List<Product> items;
  final bool fromCart;

  final Map<int, int>? quantities;

  const CheckoutPage({
    super.key,
    required this.items,
    this.fromCart = false,
    this.quantities,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // 0 = Address
  // 1 = Summary
  // 2 = Payment
  int _step = 0;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameCtrl =
      TextEditingController();

  final TextEditingController _phoneCtrl =
      TextEditingController();

  final TextEditingController _addressCtrl =
      TextEditingController();

  final TextEditingController _pincodeCtrl =
      TextEditingController();

  PaymentMethod _payment = PaymentMethod.upi;

  bool _placingOrder = false;

  // -------------------------------------------------------------------
  // RAZORPAY
  // -------------------------------------------------------------------

  late Razorpay _razorpay;

  String? _razorpayOrderId;
  String? _razorpayPaymentId;

  String? _razorpaySignature;

  // -------------------------------------------------------------------
  // IMPORTANT
  // -------------------------------------------------------------------
  //
  // Replace these with your actual PHP backend URLs.
  //
    static const String createOrderUrl =
      'http://192.168.1.5/fashion/api/create_order.php';

  static const String verifyPaymentUrl =
      'http://192.168.1.5/fashion/api/verify_payment.php';

  // Replace this with Razorpay KEY ID.
  //
  // DO NOT put Razorpay SECRET KEY here.
  static const String razorpayKeyId =
      'rzp_test_xxxxxxxxxxxxx';

  // -------------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    final state = AppState.instance;

    if (state.isLoggedIn) {
      _nameCtrl.text = state.userName ?? '';
      _phoneCtrl.text = state.userId ?? '';
    }

    // Razorpay setup
    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );
  }

  // -------------------------------------------------------------------
  // DISPOSE
  // -------------------------------------------------------------------

  @override
  void dispose() {
    _razorpay.clear();

    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();

    super.dispose();
  }

  // -------------------------------------------------------------------
  // QUANTITY
  // -------------------------------------------------------------------

  int _qtyOf(Product product) {
    final overrideQty =
        widget.quantities?[product.id];

    if (overrideQty != null && overrideQty > 0) {
      return overrideQty;
    }

    if (product.qty > 0) {
      return product.qty;
    }

    return 1;
  }

  // -------------------------------------------------------------------
  // TOTAL
  // -------------------------------------------------------------------

  double get _total {
    double total = 0;

    for (final product in widget.items) {
      final qty = _qtyOf(product);
      total += product.price * qty;
    }

    return total;
  }

  // -------------------------------------------------------------------
  // NEXT
  // -------------------------------------------------------------------

  void _goNext() {
    // ADDRESS
    if (_step == 0) {
      final isValid =
          _formKey.currentState?.validate() ?? false;

      if (!isValid) {
        return;
      }

      setState(() {
        _step = 1;
      });

      return;
    }

    // SUMMARY
    if (_step == 1) {
      setState(() {
        _step = 2;
      });

      return;
    }

    // PAYMENT
    if (_step == 2) {
      if (_payment == PaymentMethod.cod) {
        _placeCodOrder();
      } else {
        _startRazorpayPayment();
      }
    }
  }

  // -------------------------------------------------------------------
  // BACK
  // -------------------------------------------------------------------

  void _goBack() {
    if (_placingOrder) {
      return;
    }

    if (_step == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _step--;
    });
  }

  // ===================================================================
  // RAZORPAY PAYMENT
  // ===================================================================

  Future<void> _startRazorpayPayment() async {
    if (_placingOrder) {
      return;
    }

    if (widget.items.isEmpty) {
      _showMessage(
        'No items available for checkout.',
      );
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    try {
      // Razorpay expects paise.
      // ₹470 = 47000 paise.
      final int amountInPaise =
          (_total * 100).round();

      final response = await http.post(
        Uri.parse(createOrderUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountInPaise,
          'currency': 'INR',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(
          data['message'] ??
              'Unable to create payment order',
        );
      }

      _razorpayOrderId =
          data['order_id']?.toString();

      if (_razorpayOrderId == null ||
          _razorpayOrderId!.isEmpty) {
        throw Exception(
          'Razorpay order ID missing',
        );
      }

      final options = {
        'key': razorpayKeyId,

        'amount': amountInPaise,

        'currency': 'INR',

        'name': 'Sumathi',

        'description':
            'Dress / Tailoring Order',

        'order_id': _razorpayOrderId,

        'prefill': {
          'name': _nameCtrl.text.trim(),
          'contact': _phoneCtrl.text.trim(),
        },

        'theme': {
          'color':
              '#${AppColors.primary.value.toRadixString(16).substring(2)}',
        },

        'retry': {
          'enabled': true,
          'max_count': 2,
        },

        'send_sms_hash': true,
      };

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _placingOrder = false;
      });

      _showMessage(
        'Unable to start payment.',
      );
    }
  }

  // ===================================================================
  // PAYMENT SUCCESS
  // ===================================================================

  void _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    _razorpayPaymentId =
        response.paymentId;

    _razorpayOrderId =
        response.orderId ?? _razorpayOrderId;

    _razorpaySignature =
        response.signature;

    await _verifyPaymentOnServer();
  }

  // ===================================================================
  // VERIFY PAYMENT
  // ===================================================================

  Future<void> _verifyPaymentOnServer() async {
    try {
      final response = await http.post(
        Uri.parse(verifyPaymentUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'razorpay_payment_id':
              _razorpayPaymentId,

          'razorpay_order_id':
              _razorpayOrderId,

          'razorpay_signature':
              _razorpaySignature,

          'name':
              _nameCtrl.text.trim(),

          'mobile':
              _phoneCtrl.text.trim(),

          'address':
              _addressCtrl.text.trim(),

          'pincode':
              _pincodeCtrl.text.trim(),

          'amount':
              _total,

          'product': widget.items
              .map((p) => p.name)
              .join(', '),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Payment verification server error',
        );
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        await _finishPaidOrder();
      } else {
        throw Exception(
          data['message'] ??
              'Payment verification failed',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _placingOrder = false;
      });

      _showMessage(
        'Payment verification failed.',
      );
    }
  }

  // ===================================================================
  // PAYMENT ERROR
  // ===================================================================

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _placingOrder = false;
    });

    _showMessage(
      'Payment failed. Please try again.',
    );
  }

  // ===================================================================
  // EXTERNAL WALLET
  // ===================================================================

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _placingOrder = false;
    });

    _showMessage(
      'External wallet selected.',
    );
  }

  // ===================================================================
  // PAID ORDER
  // ===================================================================

  Future<void> _finishPaidOrder() async {
    if (widget.items.isEmpty) {
      return;
    }

    final db =
        FirebaseFirestore.instance;

    final double orderTotal = _total;

    final phone =
        _phoneCtrl.text.trim();

    final year =
        DateTime.now().year;

    final yearStart =
        DateTime(year, 1, 1);

    final snap = await db
        .collection('orders')
        .where(
          'created_at',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(yearStart),
        )
        .get();

    final sequence =
        (snap.docs.length + 1)
            .toString()
            .padLeft(3, '0');

    final last3 =
        phone.length >= 3
            ? phone.substring(
                phone.length - 3,
              )
            : phone;

    final orderId =
        'SS$year$sequence$last3';

    final productNames =
        widget.items
            .map((p) => p.name)
            .join(', ');

    await db.collection('orders').add({
      'order_id': orderId,

      'name':
          _nameCtrl.text.trim(),

      'mobile':
          phone,

      'address':
          _addressCtrl.text.trim(),

      'pincode':
          _pincodeCtrl.text.trim(),

      'product':
          productNames,

      'amount':
          orderTotal,

      'status':
          'Ordered',

      'source':
          'website',

      'payment_method':
          _payment == PaymentMethod.card
              ? 'Card'
              : 'UPI',

      'payment_status':
          'Paid',

      'razorpay_payment_id':
          _razorpayPaymentId,

      'razorpay_order_id':
          _razorpayOrderId,

      'created_at':
          FieldValue.serverTimestamp(),
    });

    await _completeLocalOrder(
      orderTotal,
      _payment,
    );
  }

  // ===================================================================
  // COD ORDER
  // ===================================================================

  Future<void> _placeCodOrder() async {
    if (_placingOrder) {
      return;
    }

    if (widget.items.isEmpty) {
      _showMessage(
        'No items available for checkout.',
      );
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    try {
      final db =
          FirebaseFirestore.instance;

      final double orderTotal = _total;

      final phone =
          _phoneCtrl.text.trim();

      final year =
          DateTime.now().year;

      final yearStart =
          DateTime(year, 1, 1);

      final snap = await db
          .collection('orders')
          .where(
            'created_at',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(yearStart),
          )
          .get();

      final sequence =
          (snap.docs.length + 1)
              .toString()
              .padLeft(3, '0');

      final last3 =
          phone.length >= 3
              ? phone.substring(
                  phone.length - 3,
                )
              : phone;

      final orderId =
          'SS$year$sequence$last3';

      final productNames =
          widget.items
              .map((p) => p.name)
              .join(', ');

      await db.collection('orders').add({
        'order_id': orderId,

        'name':
            _nameCtrl.text.trim(),

        'mobile':
            phone,

        'address':
            _addressCtrl.text.trim(),

        'pincode':
            _pincodeCtrl.text.trim(),

        'product':
            productNames,

        'amount':
            orderTotal,

        'status':
            'Ordered',

        'source':
            'website',

        'payment_method':
            'COD',

        'payment_status':
            'Not Required',

        'created_at':
            FieldValue.serverTimestamp(),
      });

      await _completeLocalOrder(
        orderTotal,
        PaymentMethod.cod,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _placingOrder = false;
      });

      _showMessage(
        'Something went wrong.',
      );
    }
  }

  // ===================================================================
  // COMPLETE LOCAL ORDER
  // ===================================================================

  Future<void> _completeLocalOrder(
    double orderTotal,
    PaymentMethod paymentMethod,
  ) async {
    final state =
        AppState.instance;

    // Remove ordered products from cart.
    if (widget.fromCart) {
      for (final item in widget.items) {
        state.removeFromCart(item.id);
      }
    }

    state.addNotification(
      'Order Placed',
      'Your order of ₹${orderTotal.toStringAsFixed(0)} has been placed successfully.',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _placingOrder = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _OrderSuccessPage(
          total: orderTotal,
          paymentMethod:
              paymentMethod,
        ),
      ),
    );
  }

  // ===================================================================
  // MESSAGE
  // ===================================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ===================================================================
  // BUILD
  // ===================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.light,

      appBar: AppBar(
        title:
            Text(_titleForStep()),

        backgroundColor:
            AppColors.primary,

        foregroundColor:
            Colors.white,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed:
              _placingOrder
                  ? null
                  : _goBack,
        ),
      ),

      body: Column(
        children: [
          _buildStepIndicator(),

          Expanded(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),
              child:
                  _buildCurrentStep(),
            ),
          ),
        ],
      ),

      // ---------------------------------------------------------------
      // BOTTOM BUTTON
      // ---------------------------------------------------------------

      bottomNavigationBar:
          SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          child:
              ElevatedButton(
            onPressed:
                _placingOrder
                    ? null
                    : _goNext,

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.gold,

              foregroundColor:
                  AppColors.dark,

              minimumSize:
                  const Size(
                double.infinity,
                50,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
            ),

            child:
                _placingOrder
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _step < 2
                            ? 'Continue'
                            : _payment ==
                                    PaymentMethod.cod
                                ? 'Place Order  •  ₹${_total.toStringAsFixed(0)}'
                                : 'Pay  •  ₹${_total.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // CURRENT STEP
  // ===================================================================

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildAddressStep();

      case 1:
        return _buildSummaryStep();

      case 2:
        return _buildPaymentStep();

      default:
        return _buildAddressStep();
    }
  }

  // ===================================================================
  // TITLE
  // ===================================================================

  String _titleForStep() {
    switch (_step) {
      case 0:
        return 'Delivery Address';

      case 1:
        return 'Order Summary';

      case 2:
        return 'Payments';

      default:
        return 'Checkout';
    }
  }

  // ===================================================================
  // STEP INDICATOR
  // ===================================================================

  Widget _buildStepIndicator() {
    const labels = [
      'Address',
      'Summary',
      'Payment',
    ];

    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: List.generate(
          labels.length * 2 - 1,
          (index) {
            if (index.isOdd) {
              final passed =
                  (index ~/ 2) < _step;

              return Container(
                width: 30,
                height: 2,
                color: passed
                    ? AppColors.primary
                    : AppColors.gray,
              );
            }

            final stepIndex =
                index ~/ 2;

            final active =
                stepIndex <= _step;

            return Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      active
                          ? AppColors.primary
                          : AppColors.gray,
                  child: Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : AppColors.textLight,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  labels[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: active
                        ? AppColors.primary
                        : AppColors.textLight,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===================================================================
  // ADDRESS
  // ===================================================================

  Widget _buildAddressStep() {
    return Form(
      key: _formKey,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your delivery details',
            style: TextStyle(
              fontWeight:
                  FontWeight.w600,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Please enter the address where you want your order delivered.',
            style: TextStyle(
              color:
                  AppColors.textLight,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 18),

          _field(
            controller:
                _nameCtrl,
            label:
                'Full Name',
            icon:
                Icons.person_outline,
          ),

          const SizedBox(height: 12),

          _field(
            controller:
                _phoneCtrl,
            label:
                'Phone Number',
            icon:
                Icons.phone_outlined,
            keyboardType:
                TextInputType.phone,
            maxLength: 10,
            validator:
                _validatePhone,
          ),

          const SizedBox(height: 12),

          _field(
            controller:
                _addressCtrl,
            label:
                'Full Address',
            icon:
                Icons.home_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 12),

          _field(
            controller:
                _pincodeCtrl,
            label:
                'Pincode',
            icon:
                Icons.pin_drop_outlined,
            keyboardType:
                TextInputType.number,
            maxLength: 6,
            validator:
                _validatePincode,
          ),

          const SizedBox(height: 16),

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(12),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color:
                      AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Make sure your phone number and delivery address are correct before continuing.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          AppColors.textLight,
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

  // ===================================================================
  // FIELD
  // ===================================================================

  Widget _field({
    required
        TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)?
        validator,
  }) {
    return TextFormField(
      controller:
          controller,
      keyboardType:
          keyboardType,
      maxLines:
          maxLines,
      maxLength:
          maxLength,

      decoration:
          InputDecoration(
        labelText:
            label,

        prefixIcon:
            Icon(
          icon,
          color:
              AppColors.primary,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              BorderSide(
            color:
                AppColors.gray,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              BorderSide(
            color:
                AppColors.primary,
            width: 1.5,
          ),
        ),

        counterText:
            '',
      ),

      validator:
          validator ??
              (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Required';
        }

        return null;
      },
    );
  }

  // ===================================================================
  // PHONE VALIDATION
  // ===================================================================

  String? _validatePhone(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    final phone =
        value.trim();

    if (phone.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }

    if (!RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(phone)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  // ===================================================================
  // PINCODE VALIDATION
  // ===================================================================

  String? _validatePincode(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    final pincode =
        value.trim();

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(pincode)) {
      return 'Enter a valid 6-digit pincode';
    }

    return null;
  }

  // ===================================================================
  // SUMMARY
  // ===================================================================

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(14),
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                color:
                    AppColors.primary,
                size: 20,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deliver To',
                      style:
                          TextStyle(
                        fontSize: 11,
                        color:
                            AppColors.textLight,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      _nameCtrl.text,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      _addressCtrl.text,
                      style:
                          const TextStyle(
                        color:
                            AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),

                    Text(
                      'Pincode: ${_pincodeCtrl.text}',
                      style:
                          const TextStyle(
                        color:
                            AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),

                    Text(
                      _phoneCtrl.text,
                      style:
                          const TextStyle(
                        color:
                            AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Items',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 10),

        ...widget.items.map(
          (product) {
            final qty =
                _qtyOf(product);

            final itemTotal =
                product.price * qty;

            return Container(
              width:
                  double.infinity,
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              padding:
                  const EdgeInsets.all(
                10,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    child:
                        product.isNetworkImage
                            ? Image.network(
                                product.image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) {
                                  return _imageErrorBox();
                                },
                              )
                            : Image.asset(
                                product.image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) {
                                  return _imageErrorBox();
                                },
                              ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          '₹${product.price.toStringAsFixed(0)} × $qty',
                          style:
                              const TextStyle(
                            color:
                                AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '₹${itemTotal.toStringAsFixed(0)}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(14),
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Column(
            children: [
              _priceRow(
                'Subtotal',
                '₹${_total.toStringAsFixed(0)}',
              ),

              const SizedBox(
                height: 8,
              ),

              _priceRow(
                'Delivery',
                'FREE',
                valueColor:
                    Colors.green,
              ),

              const Divider(
                height: 22,
              ),

              _priceRow(
                'Total Amount',
                '₹${_total.toStringAsFixed(0)}',
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // IMAGE ERROR
  // ===================================================================

  Widget _imageErrorBox() {
    return Container(
      width: 60,
      height: 60,
      color:
          AppColors.gray,
      child:
          const Icon(
        Icons.image_not_supported_outlined,
        color:
            AppColors.textLight,
      ),
    );
  }

  // ===================================================================
  // PRICE ROW
  // ===================================================================

  Widget _priceRow(
    String title,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              TextStyle(
            fontWeight:
                bold
                    ? FontWeight.w600
                    : FontWeight.normal,
            fontSize:
                bold ? 15 : 13,
          ),
        ),

        Text(
          value,
          style:
              TextStyle(
            fontWeight:
                bold
                    ? FontWeight.bold
                    : FontWeight.w500,
            fontSize:
                bold ? 17 : 13,
            color:
                valueColor ??
                    (bold
                        ? AppColors.primary
                        : AppColors.text),
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // PAYMENT SCREEN
  // ===================================================================

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // -------------------------------------------------------------
        // PAYMENT HEADER
        // -------------------------------------------------------------

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payments',
              style:
                  TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),
              child: const Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                  ),
                  SizedBox(width: 5),
                  Text(
                    '100% Secure',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // -------------------------------------------------------------
        // TOTAL
        // -------------------------------------------------------------

        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.primary.withValues(
              alpha: 0.08,
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Total Amount',
                    style:
                        TextStyle(
                      color:
                          AppColors.primary,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Icon(
                    Icons.keyboard_arrow_down,
                    color:
                        AppColors.primary,
                  ),
                ],
              ),

              Text(
                '₹${_total.toStringAsFixed(0)}',
                style:
                    TextStyle(
                  color:
                      AppColors.primary,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // -------------------------------------------------------------
        // UPI
        // -------------------------------------------------------------

        _buildUpiCard(),

        const SizedBox(height: 12),

        // -------------------------------------------------------------
        // CARD
        // -------------------------------------------------------------

        _buildCardOption(),

        const SizedBox(height: 12),

        // -------------------------------------------------------------
        // COD
        // -------------------------------------------------------------

        _buildCodOption(),

        const SizedBox(height: 20),

        // -------------------------------------------------------------
        // SECURITY MESSAGE
        // -------------------------------------------------------------

        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(12),
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.security_outlined,
                color:
                    AppColors.primary,
                size: 18,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Your payment information is processed securely.',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // UPI CARD
  // ===================================================================

  Widget _buildUpiCard() {
    final selected =
        _payment ==
            PaymentMethod.upi;

    return Container(
      width:
          double.infinity,
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color: selected
              ? AppColors.primary
              : Colors.grey.shade300,
          width:
              selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap:
                _placingOrder
                    ? null
                    : () {
                        setState(() {
                          _payment =
                              PaymentMethod.upi;
                        });
                      },
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 28,
                    color:
                        AppColors.primary,
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  const Expanded(
                    child: Text(
                      'UPI',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  Icon(
                    selected
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),

          if (selected)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ),
              child:
                  Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    Column(
                  children: [
                    // ------------------------------------------------
                    // GOOGLE PAY
                    // ------------------------------------------------

                    Row(
                      children: [
                        Radio<PaymentMethod>(
                          value:
                              PaymentMethod.upi,
                          groupValue:
                              _payment,
                          onChanged:
                              (_) {
                            setState(() {
                              _payment =
                                  PaymentMethod.upi;
                            });
                          },
                        ),

                        const Expanded(
                          child: Text(
                            'Google Pay',
                            style:
                                TextStyle(
                              fontSize:
                                  17,
                            ),
                          ),
                        ),

                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 30,
                          color:
                              AppColors.primary,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ------------------------------------------------
                    // PAY BUTTON
                    // ------------------------------------------------

                    SizedBox(
                      width:
                          double.infinity,
                      height: 54,
                      child:
                          ElevatedButton(
                        onPressed:
                            _placingOrder
                                ? null
                                : _startRazorpayPayment,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.gold,
                          foregroundColor:
                              Colors.black,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child:
                            _placingOrder
                                ? const SizedBox(
                                    width:
                                        22,
                                    height:
                                        22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : Text(
                                    'Pay ₹${_total.toStringAsFixed(0)}',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ------------------------------------------------
                    // OTHER UPI APPS
                    // ------------------------------------------------

                    InkWell(
                      onTap:
                          _placingOrder
                              ? null
                              : _startRazorpayPayment,
                      child:
                          Row(
                        children: [
                          const Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pay with other UPI Apps',
                                  style:
                                      TextStyle(
                                    color:
                                        AppColors.primary,
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),

                                SizedBox(
                                  height:
                                      4,
                                ),

                                Text(
                                  'PhonePe, Paytm and more',
                                  style:
                                      TextStyle(
                                    color:
                                        AppColors.textLight,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right,
                            color:
                                AppColors.primary,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===================================================================
  // CARD OPTION
  // ===================================================================

  Widget _buildCardOption() {
    final selected =
        _payment ==
            PaymentMethod.card;

    return InkWell(
      onTap:
          _placingOrder
              ? null
              : () {
                  setState(() {
                    _payment =
                        PaymentMethod.card;
                  });
                },
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child:
          Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets.all(
          18,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          border:
              Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.shade300,
            width:
                selected ? 1.5 : 1,
          ),
        ),
        child:
            Row(
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 28,
              color:
                  selected
                      ? AppColors.primary
                      : Colors.grey.shade800,
            ),

            const SizedBox(
              width: 14,
            ),

            const Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credit / Debit / ATM Card',
                    style:
                        TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Secure card payment',
                    style:
                        TextStyle(
                      color:
                          AppColors.textLight,
                      fontSize:
                          12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.keyboard_arrow_down,
              color:
                  selected
                      ? AppColors.primary
                      : Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // COD OPTION
  // ===================================================================

  Widget _buildCodOption() {
    final selected =
        _payment ==
            PaymentMethod.cod;

    return InkWell(
      onTap:
          _placingOrder
              ? null
              : () {
                  setState(() {
                    _payment =
                        PaymentMethod.cod;
                  });
                },
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child:
          Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets.all(
          18,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          border:
              Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.shade300,
            width:
                selected ? 1.5 : 1,
          ),
        ),
        child:
            Row(
          children: [
            Icon(
              Icons.payments_outlined,
              size: 28,
              color:
                  selected
                      ? AppColors.primary
                      : Colors.grey.shade700,
            ),

            const SizedBox(
              width: 14,
            ),

            const Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash on Delivery',
                    style:
                        TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Pay when your order arrives',
                    style:
                        TextStyle(
                      color:
                          AppColors.textLight,
                      fontSize:
                          12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  selected
                      ? AppColors.primary
                      : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// ORDER SUCCESS PAGE
// =======================================================================

class _OrderSuccessPage
    extends StatelessWidget {
  final double total;

  final PaymentMethod paymentMethod;

  const _OrderSuccessPage({
    required this.total,
    required this.paymentMethod,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final String paymentText =
        paymentMethod ==
                PaymentMethod.cod
            ? 'Cash on Delivery'
            : paymentMethod ==
                    PaymentMethod.card
                ? 'Card'
                : 'UPI';

    return Scaffold(
      backgroundColor:
          AppColors.light,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration:
                      BoxDecoration(
                    color: Colors.green
                        .withValues(
                      alpha: 0.10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons.check_circle,
                    color:
                        Colors.green,
                    size: 80,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Order Placed!',
                  style:
                      TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Your order has been placed successfully.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        AppColors.textLight,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      Column(
                    children: [
                      const Text(
                        'Order Total',
                        style:
                            TextStyle(
                          color:
                              AppColors.textLight,
                          fontSize:
                              12,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontSize:
                              24,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors.primary,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Payment: $paymentText',
                        style:
                            const TextStyle(
                          fontSize:
                              12,
                          color:
                              AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).popUntil(
                        (route) =>
                            route.isFirst,
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      minimumSize:
                          const Size(
                        double.infinity,
                        50,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'Continue Shopping',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w600,
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
}