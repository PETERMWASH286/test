import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CarOwnerScreen extends StatelessWidget {
  const CarOwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double monthlyPrice = 250.0;
    const double annualPrice = 2000.0;

    const double monthlyTotal = monthlyPrice * 12;
    const double discount = monthlyTotal - annualPrice;
    const double discountPercentage = (discount / monthlyTotal) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Owner Packages'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  const Text(
                    'Choose Your Payment Plan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Annual Package
                  buildPackageCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Annual Package',
                    price: 'Ksh 2000 / Year',
                    description:
                        '• Connect with mechanics.\n• Track repairs and services.\n• Reminders for next service.\n'
                        '• Save Ksh ${discount.toStringAsFixed(2)} annually (${discountPercentage.toStringAsFixed(1)}% off)!',
                    buttonLabel: 'Subscribe Now',
                    buttonIcon: Icons.subscriptions,
                    onPressed: () {
                      _showPaymentPopup(context, 'Ksh 2000 / Year', 'Annual'); // Corrected
                    },
                  ),
                  const SizedBox(height: 20),

                  // Monthly Package
                  buildPackageCard(
                    context,
                    icon: Icons.calendar_view_month,
                    title: 'Monthly Package',
                    price: 'Ksh 250 / Month',
                    description:
                        '• All services of the annual package, but with monthly payments.',
                    buttonLabel: 'Subscribe Now',
                    buttonIcon: Icons.subscriptions,
                    onPressed: () {
                      _showPaymentPopup(context, 'Ksh 250 / Month', 'Monthly'); // Corrected
                    },
                  ),
                  const SizedBox(height: 30), // Add spacing for layout
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build each package card
  Widget buildPackageCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String price,
      required String description,
      required String buttonLabel,
      required IconData buttonIcon,
      required VoidCallback onPressed}) {
    return Card(
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              price,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              description,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 25),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                onPressed: onPressed,
                icon: Icon(buttonIcon, color: Colors.white),
                label: Text(
                  buttonLabel,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


// Function to show payment popup
void _showPaymentPopup(BuildContext context, String price, String subscriptionType) {
  final TextEditingController phoneController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Complete Your Payment',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'You are about to pay:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Enter Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  prefixIcon: const Icon(Icons.phone, color: Colors.deepPurple),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                // Retrieve email from SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? email = prefs.getString('userEmail');

                if (email != null && phoneController.text.isNotEmpty) {
                  // Call the function to submit payment data
                  await _submitPaymentData(email, price, subscriptionType, phoneController.text);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Show a message if email or phone number is not provided
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid phone number and ensure you are logged in.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// Function to submit payment data to the backend
Future<void> _submitPaymentData(String email, String amount, String subscriptionType, String phoneNumber) async {
  const String url = 'http://10.88.0.4:5000/api/payment'; // Replace with your backend URL

  final response = await http.post(
    Uri.parse(url),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'email': email,
      'amount': amount,
      'subscriptionType': subscriptionType,
      'phoneNumber': phoneNumber,
      'role': 'car_owner', // Specify the user role
    }),
  );

  if (response.statusCode == 200) {
    // Payment initialization successful
    final responseData = jsonDecode(response.body);
    // Handle the response from the backend as needed
    print('Payment initiated: ${responseData['message']}');
  } else {
    // Handle error response
    throw Exception('Failed to initiate payment: ${response.body}');
  }
}


}
