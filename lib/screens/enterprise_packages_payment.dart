import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'enterprise_home_screen.dart';

class EnterpriseCarOwnerScreen extends StatelessWidget {
  const EnterpriseCarOwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double annualPrice = 50000.0; // Annual price for enterprise
    const double monthlyPrice = 6000.0; // Monthly price for enterprise

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Car Owner Dashboard'),
        backgroundColor: Colors.deepPurple,
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
                  const Text(
                    'Manage Your Fleet',
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
                    icon: Icons.business,
                    title: 'Annual Package',
                    price: 'Ksh $annualPrice / Year',
                    description:
                        '• Manage all vehicles.\n• Track expenses and income.\n• Schedule maintenance.\n'
                        '• Monthly reports on fleet usage.\n'
                        '• Access to 24/7 support.',
                    buttonLabel: 'Subscribe Now',
                    buttonIcon: Icons.subscriptions,
                    onPressed: () {
                      _showPaymentPopup(context, annualPrice.toString(), 'Annual');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Monthly Package
                  buildPackageCard(
                    context,
                    icon: Icons.business_center,
                    title: 'Monthly Package',
                    price: 'Ksh $monthlyPrice / Month',
                    description:
                        '• All features of the annual package, billed monthly.\n'
                        '• No long-term commitment.',
                    buttonLabel: 'Subscribe Now',
                    buttonIcon: Icons.subscriptions,
                    onPressed: () {
                      _showPaymentPopup(context, monthlyPrice.toString(), 'Monthly');
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
                  'Ksh $price',
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
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String? email = prefs.getString('userEmail');

                  if (phoneController.text.isNotEmpty) {
                    await _submitPaymentData(email ?? '', price, subscriptionType, phoneController.text, context);
                    Navigator.of(context).pop();
                  } else {
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

Future<void> _submitPaymentData(String email, String amount, String subscriptionType, String phoneNumber, BuildContext context) async {
  const String url = 'https://expertstrials.xyz/Garifix_app/api/payment'; // Replace with your backend URL

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'amount': 'Ksh $amount',  // Ensure it's formatted correctly
        'subscriptionType': subscriptionType,
        'phoneNumber': phoneNumber,
        'role': 'enterprise_car_owner',
      }),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print('Payment initiated: ${responseData['message']}');
      // Store the role in SharedPreferences after successful payment
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'enterprise_car_owner');  // Save the role as 'car_owner'
      // Use Future.delayed to ensure the dialog is shown after the dialog context is valid
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Payment Successful'),
              content: Text(responseData['message']),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const EnterpriseCarScreen()), // Ensure this points to the correct screen
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception('Failed to initiate payment: ${errorData['error']}');
    }
  } catch (e) {
    print('Exception caught during payment submission: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
}
