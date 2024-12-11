import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mechanic_list_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:animated_text_kit/animated_text_kit.dart';  // For text animation
import 'package:lottie/lottie.dart';
// For crazy icons
// For animated text

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
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    );
                  },
                );

                // Retrieve email from SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? email = prefs.getString('userEmail');

                if (phoneController.text.isNotEmpty) {
                  // Call the function to submit payment data
                  await _submitPaymentData(
                    email ?? '',
                    price,
                    subscriptionType,
                    phoneController.text,
                    context,
                  );

                  // Dismiss the loading dialog

                } else {
                  // Dismiss the loading dialog if phone is not entered
                  Navigator.of(context).pop();
                  
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


Future<void> _submitPaymentData(
  String email,
  String amount,
  String subscriptionType,
  String phoneNumber,
  BuildContext context,
) async {
  const String url = 'https://expertstrials.xyz/Garifix_app/api/payment';

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

if (token == null || token.isEmpty) {
  print("Error: Token is missing.");
  return;
}


    final payload = {
      'email': email,
      'amount': '2', // Test amount
      'subscriptionType': subscriptionType,
      'phoneNumber': phoneNumber,
      'role': 'Mechanic',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print("${data['message']}");

      if (data['success'] == true) {
        // Payment successful, show a success SnackBar
        showAnimatedSnackBar(context);

        // Start listening for the callback
        _listenForCallback(phoneNumber, context);
      } else {
        // Show failure message if the backend returns an error
        print("Error from backend: ${data['error']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${data['error']}")),
        );
      }
    } else {
      print("Backend responded with status code: ${response.statusCode}");
      print("Response body: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment request failed. Please try again.")),
      );
    }
  } catch (error) {
    print("Error submitting payment data: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("An error occurred. Please try again later.")),
    );
  }
}

void showAnimatedSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  "STK Push initiated successfully!",
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
              pause: const Duration(milliseconds: 500),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black87,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
  );
}
Future<void> _listenForCallback(String phoneNumber, BuildContext context) async {
  const String callbackUrl = 'https://expertstrials.xyz/Garifix_app/api/transaction-status';
  int pollingDuration = 0;

  try {
    while (pollingDuration < 180) { // Poll for up to 3 minutes
      final response = await http.get(
        Uri.parse('$callbackUrl?phoneNumber=$phoneNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Polling response data: ${response.body}');

        if (data['success'] == true && data['resultCode'] == 0) {
          print("Payment successful: ${data['message']}");

          // Notify user of successful payment using a toast
          Fluttertoast.showToast(
            msg: "🎉 Payment completed successfully! 🎉",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Save user role to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', 'Mechanic');

// Show dialog after a delay to ensure context is valid
if (context.mounted) {
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // Ensures dialog cannot be dismissed by tapping outside
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lottie animation for visual appeal
                    Lottie.asset(
                      'assets/lotti/Animation - 1730958529727.json', // Ensure this is in your assets directory
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 20),
                    // Title with an icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Successful',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Content with a brief message
                    const Text(
                      'Your payment was successful. Would you like to continue to your dashboard?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const MechanicListScreen()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Yes', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.white),
                              SizedBox(width: 4),
                              Text('No', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    });
}

          break; // Exit the loop as the payment is confirmed
        } else {
          print("Payment still pending or failed: ${data['message']}");
        }
      } else {
        print("Polling error: ${response.body}");
      }

      await Future.delayed(const Duration(seconds: 5)); // Wait before next poll
      pollingDuration += 5;
    }

    if (pollingDuration >= 180 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment verification timeout.")),
      );
    }
  } catch (e) {
    print("Error during polling: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred while checking payment status.")),
      );
    }
  }
}
}
