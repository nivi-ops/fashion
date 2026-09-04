
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_state.dart';
import 'models.dart';

/// ---------------------------------------------------------------------
/// CHECKOUT PAGE
/// ---------------------------------------------------------------------
///
/// Flows supported:
///
/// 1. Product Details -> Buy Now
///    items = [product]
///    fromCart = false
///
/// 2. Cart -> Buy this now
///    items = [product]
///    fromCart = true
///
/// 3. Cart -> Checkout
///    items = state.cartItems
///    fromCart = true
///
/// Steps:
///    Address -> Order Summary -> Payment -> Place Order
///
/// ---------------------------------------------------------------------

enum PaymentMethod {
  upi,
  cod,
}

class CheckoutPage extends StatefulWidget {
  final List<Product> items;
  final bool fromCart;

  /// Optional quantity override.
  ///
  /// Used when Buy Now is opened from Product Details and the selected
  /// quantity has not yet been stored inside Product.qty.
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  PaymentMethod _payment = PaymentMethod.upi;

  bool _placingOrder = false;

  @override
  void dispose() {
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
    final overrideQty = widget.quantities?[product.id];

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
  // NEXT BUTTON
  // -------------------------------------------------------------------

  void _goNext() {
    // ADDRESS
    if (_step == 0) {
      final isValid = _formKey.currentState?.validate() ?? false;

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
      _placeOrder();
    }
  }

  // -------------------------------------------------------------------
  // BACK BUTTON
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

  // -------------------------------------------------------------------
  // PLACE ORDER
  // -------------------------------------------------------------------

  Future<void> _placeOrder() async {
    if (_placingOrder) {
      return;
    }

    if (widget.items.isEmpty) {
      _showMessage('No items available for checkout.');
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    // Store total before changing cart state.
    final double orderTotal = _total;

    try {
      // ---------------------------------------------------------------
      // TODO:
      // Replace this delay with your real backend/API order request.
      //
      // Example:
      //
      // await ApiService.placeOrder(
      //   name: _nameCtrl.text.trim(),
      //   phone: _phoneCtrl.text.trim(),
      //   address: _addressCtrl.text.trim(),
      //   pincode: _pincodeCtrl.text.trim(),
      //   paymentMethod: _payment.name,
      //   items: widget.items,
      //   total: orderTotal,
      // );
      // ---------------------------------------------------------------

      await Future.delayed(
        const Duration(milliseconds: 900),
      );

      final state = AppState.instance;

      // ---------------------------------------------------------------
      // REMOVE FROM CART
      // ---------------------------------------------------------------
      //
      // If checkout came from cart:
      // remove exactly the products that were ordered.
      //
      // If normal Buy Now:
      // fromCart = false
      // nothing will be removed from cart.
      //
      if (widget.fromCart) {
        for (final item in widget.items) {
          state.removeFromCart(item.id);
        }
      }

      // ---------------------------------------------------------------
      // ADD NOTIFICATION
      // ---------------------------------------------------------------

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

      // ---------------------------------------------------------------
      // ORDER SUCCESS PAGE
      // ---------------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _OrderSuccessPage(
            total: orderTotal,
            paymentMethod: _payment,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _placingOrder = false;
      });

      _showMessage(
        'Something went wrong. Please try again.',
      );
    }
  }

  // -------------------------------------------------------------------
  // MESSAGE
  // -------------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,

      appBar: AppBar(
        title: Text(_titleForStep()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _placingOrder ? null : _goBack,
        ),
      ),

      body: Column(
        children: [
          _buildStepIndicator(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),

      // ---------------------------------------------------------------
      // BOTTOM BUTTON
      // ---------------------------------------------------------------

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          child: ElevatedButton(
            onPressed: _placingOrder ? null : _goNext,

            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.dark,

              minimumSize: const Size(
                double.infinity,
                50,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),

            child: _placingOrder
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _step < 2
                        ? 'Continue'
                        : 'Place Order  •  ₹${_total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // CURRENT STEP
  // -------------------------------------------------------------------

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

  // -------------------------------------------------------------------
  // TITLE
  // -------------------------------------------------------------------

  String _titleForStep() {
    switch (_step) {
      case 0:
        return 'Delivery Address';

      case 1:
        return 'Order Summary';

      case 2:
        return 'Payment';

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
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          labels.length * 2 - 1,
          (index) {
            // Connector
            if (index.isOdd) {
              final passed = (index ~/ 2) < _step;

              return Container(
                width: 30,
                height: 2,
                color: passed
                    ? AppColors.primary
                    : AppColors.gray,
              );
            }

            // Circle
            final stepIndex = index ~/ 2;
            final active = stepIndex <= _step;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: active
                      ? AppColors.primary
                      : AppColors.gray,
                  child: Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

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
  // STEP 1 - ADDRESS
  // ===================================================================

  Widget _buildAddressStep() {
    return Form(
      key: _formKey,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your delivery details',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Please enter the address where you want your order delivered.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 18),

          _field(
            controller: _nameCtrl,
            label: 'Full Name',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 12),

          _field(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: _validatePhone,
          ),

          const SizedBox(height: 12),

          _field(
            controller: _addressCtrl,
            label: 'Full Address',
            icon: Icons.home_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 12),

          _field(
            controller: _pincodeCtrl,
            label: 'Pincode',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: _validatePincode,
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Make sure your phone number and delivery address are correct before continuing.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
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

  // -------------------------------------------------------------------
  // FORM FIELD
  // -------------------------------------------------------------------

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gray,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),

        counterText: '',
      ),

      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Required';
            }

            return null;
          },
    );
  }

  // -------------------------------------------------------------------
  // PHONE VALIDATION
  // -------------------------------------------------------------------

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    final phone = value.trim();

    if (phone.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  // -------------------------------------------------------------------
  // PINCODE VALIDATION
  // -------------------------------------------------------------------

  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    final pincode = value.trim();

    if (!RegExp(r'^[0-9]{6}$').hasMatch(pincode)) {
      return 'Enter a valid 6-digit pincode';
    }

    return null;
  }

  // ===================================================================
  // STEP 2 - ORDER SUMMARY
  // ===================================================================

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------
        // DELIVERY ADDRESS CARD
        // ---------------------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.05,
                ),
                blurRadius: 6,
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.primary,
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
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _nameCtrl.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _addressCtrl.text,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),

                    Text(
                      'Pincode: ${_pincodeCtrl.text}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),

                    Text(
                      _phoneCtrl.text,
                      style: const TextStyle(
                        color: AppColors.textLight,
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
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 10),

        // ---------------------------------------------------------------
        // ITEMS
        // ---------------------------------------------------------------

        ...widget.items.map(
          (product) {
            final qty = _qtyOf(product);
            final itemTotal = product.price * qty;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: Row(
                children: [
                  // IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),

                    child: product.isNetworkImage
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

                  // NAME + QTY
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '₹${product.price.toStringAsFixed(0)} × $qty',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ITEM TOTAL
                  Text(
                    '₹${itemTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ---------------------------------------------------------------
        // PRICE SUMMARY
        // ---------------------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            children: [
              _priceRow(
                'Subtotal',
                '₹${_total.toStringAsFixed(0)}',
              ),

              const SizedBox(height: 8),

              _priceRow(
                'Delivery',
                'FREE',
                valueColor: Colors.green,
              ),

              const Divider(height: 22),

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

  // -------------------------------------------------------------------
  // IMAGE ERROR
  // -------------------------------------------------------------------

  Widget _imageErrorBox() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.gray,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textLight,
      ),
    );
  }

  // -------------------------------------------------------------------
  // PRICE ROW
  // -------------------------------------------------------------------

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
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.w600 : FontWeight.normal,
            fontSize: bold ? 15 : 13,
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.bold : FontWeight.w500,
            fontSize: bold ? 17 : 13,
            color: valueColor ??
                (bold
                    ? AppColors.primary
                    : AppColors.text),
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // STEP 3 - PAYMENT
  // ===================================================================

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Payment Method',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Select how you would like to pay for your order.',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 14),

        // UPI
        _paymentTile(
          method: PaymentMethod.upi,
          title: 'UPI',
          subtitle: 'Pay via GPay, PhonePe, Paytm, etc.',
          icon: Icons.qr_code,
        ),

        const SizedBox(height: 10),

        // COD
        _paymentTile(
          method: PaymentMethod.cod,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your order arrives',
          icon: Icons.payments_outlined,
        ),

        const SizedBox(height: 20),

        // ---------------------------------------------------------------
        // PAYMENT SUMMARY
        // ---------------------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            children: [
              _priceRow(
                'Items',
                '${widget.items.length}',
              ),

              const SizedBox(height: 8),

              _priceRow(
                'Payment',
                _payment == PaymentMethod.upi
                    ? 'UPI'
                    : 'Cash on Delivery',
              ),

              const Divider(height: 22),

              _priceRow(
                'Total Payable',
                '₹${_total.toStringAsFixed(0)}',
                bold: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),

          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.security_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your order details will be processed securely.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // PAYMENT TILE
  // -------------------------------------------------------------------

  Widget _paymentTile({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = _payment == method;

    return InkWell(
      onTap: _placingOrder
          ? null
          : () {
              setState(() {
                _payment = method;
              });
            },
      borderRadius: BorderRadius.circular(12),

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),

        width: double.infinity,

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.gray,
            width: selected ? 2 : 1,
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.primary
                  : AppColors.textLight,
              size: 24,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
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

class _OrderSuccessPage extends StatelessWidget {
  final double total;
  final PaymentMethod paymentMethod;

  const _OrderSuccessPage({
    required this.total,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final String paymentText =
        paymentMethod == PaymentMethod.upi
            ? 'UPI'
            : 'Cash on Delivery';

    return Scaffold(
      backgroundColor: AppColors.light,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SUCCESS ICON
                Container(
                  width: 100,
                  height: 100,

                  decoration: BoxDecoration(
                    color: Colors.green.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Order Placed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Your order has been placed successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLight,
                  ),
                ),

                const SizedBox(height: 18),

                // ORDER AMOUNT CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  child: Column(
                    children: [
                      const Text(
                        'Order Total',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Payment: $paymentText',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // CONTINUE SHOPPING
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .popUntil(
                        (route) => route.isFirst,
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor: Colors.white,

                      minimumSize:
                          const Size(double.infinity, 50),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(24),
                      ),
                    ),

                    child: const Text(
                      'Continue Shopping',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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