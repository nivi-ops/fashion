// simple_pages.dart
// A collection of lightweight, mostly-static pages for Sumahti Styles:
// About Us, Contact Us, Terms & Conditions, and Order History.

import 'package:flutter/material.dart';
import 'api_service.dart';

// ---------------- ABOUT US ----------------

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                child: Icon(Icons.checkroom, size: 36),
              ),
              SizedBox(height: 16),
              Text(
                'Sumahti Styles',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Sumahti Styles is a custom tailoring and stitching service. '
                'From blouses and sarees to full suits and custom designs, '
                'we bring your ideas to life with precise, made-to-measure '
                'stitching and quick turnaround.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Why choose us?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _AboutPoint(text: 'Experienced tailors with an eye for detail'),
              _AboutPoint(text: 'Doorstep measurement pickup available'),
              _AboutPoint(text: 'Affordable, transparent pricing'),
              _AboutPoint(text: 'On-time delivery, every time'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutPoint extends StatelessWidget {
  final String text;
  const _AboutPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// ---------------- CONTACT US ----------------

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ContactTile(
            icon: Icons.phone_outlined,
            title: 'Phone',
            subtitle: '+91 98765 43210',
          ),
          _ContactTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'hello@sumahtistyles.com',
          ),
          _ContactTile(
            icon: Icons.location_on_outlined,
            title: 'Shop Address',
            subtitle: '12, Gandhi Street, Chennai - 600001',
          ),
          _ContactTile(
            icon: Icons.access_time_outlined,
            title: 'Working Hours',
            subtitle: 'Mon - Sat, 10:00 AM - 8:00 PM',
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

// ---------------- TERMS & CONDITIONS ----------------

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            '1. Orders once confirmed cannot be cancelled after stitching begins.\n\n'
            '2. Delivery timelines are estimates and may vary based on order load.\n\n'
            '3. Please verify measurements carefully before confirming an order.\n\n'
            '4. Alteration charges may apply for changes requested after stitching.\n\n'
            '5. Payment is due in full at the time of order pickup/delivery.\n\n'
            '6. Sumahti Styles is not responsible for fabric provided by the customer '
            'that is found to be defective after stitching.',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
      ),
    );
  }
}

// ---------------- ORDER HISTORY ----------------

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<TailoringOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.instance.getOrders();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Ready':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: FutureBuilder<List<TailoringOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: ListTile(
                  title: Text(order.serviceName),
                  subtitle: Text(
                    '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}  •  ₹${order.amount.toStringAsFixed(0)}',
                  ),
                  trailing: Chip(
                    label: Text(
                      order.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _statusColor(order.status),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------- CUSTOM ORDER ----------------

class CustomOrderPage extends StatefulWidget {
  const CustomOrderPage({super.key});

  @override
  State<CustomOrderPage> createState() => _CustomOrderPageState();
}

class _CustomOrderPageState extends State<CustomOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _designController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _designController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Custom Order Submitted Successfully"),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Order"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Customer Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Mobile Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter mobile number" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _designController,
                decoration: const InputDecoration(
                  labelText: "Dress / Design",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Additional Notes",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  child: const Text("Submit Order"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}