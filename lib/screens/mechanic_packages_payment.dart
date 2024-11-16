import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mechanic_list_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';  // For crazy icons
import 'package:animated_text_kit/animated_text_kit.dart';  // For animated text
class MechanicScreen extends StatelessWidget {
  const MechanicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double monthlyPrice = 100.0; // Monthly price for mechanics
    const double annualPrice = 1000.0; // Annual price for mechanics

    const double monthlyTotal = monthlyPrice * 12;
    const double discount = monthlyTotal - annualPrice;
    const double discountPercentage = (discount / monthlyTotal) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanic Packages'),
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
                    price: 'Ksh 1000 / Year',
                    description:
                        '• Connect with car owners.\n• Track jobs and services.\n• Reminders for service.\n'
                        '• Save Ksh ${discount.toStringAsFixed(2)} annually (${discountPercentage.toStringAsFixed(1)}% off)!',
                    buttonLabel: 'Subscribe Now',
                    buttonIcon: Icons.subscriptions,
                    onPressed: () {
                      _showPaymentPopup(context, 'Ksh 1000 / Year', 'Annual');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Monthly Package
                  buildPackageCard(
                    context,
                    icon: Icons.calendar_view_month,
                    title: 'Monthly Package',
                    price: 'Ksh 100 / Month',
                    description:
                        '• All services of the annual package, but with monthly payments.',
                    buttonLabel: 'Subscribe Now',
                    buttonIcon: Icons.subscriptions,
                    onPressed: () {
                      _showPaymentPopup(context, 'Ksh 100 / Month', 'Monthly');
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

                  if (phoneController.text.isNotEmpty) {
                    // Call the function to submit payment data
                    await _submitPaymentData(email ?? '', price, subscriptionType, phoneController.text, context);
                    Navigator.of(context).pop(); // Close the dialog (optional since you'll navigate)
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
        'role': 'Mechanic',  // Assume this is the role you're assigning
      }),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print('Payment initiated: ${responseData['message']}');

      // Store role in SharedPreferences if payment is successful
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'Mechanic');  // Save the role

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
                      MaterialPageRoute(builder: (context) => const MechanicListScreen()), // Ensure this points to the correct screen
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
