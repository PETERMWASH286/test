import 'package:flutter/material.dart';

class ConfirmationPinPage extends StatelessWidget {
  final String email;
  final String pin;

  const ConfirmationPinPage(
      {super.key, required this.email, required this.pin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirm Your PIN',
          style: TextStyle(fontSize: 18), // Smaller appBar title
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Please confirm your PIN',
                style: TextStyle(
                  fontSize: 18, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10), // Reduced space between elements
              Text(
                'PIN: $pin',
                style: const TextStyle(fontSize: 16), // Smaller PIN text
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  // Logic to verify and save the PIN in the database
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 20), // Reduced button padding
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text(
                  'Confirm PIN',
                  style: TextStyle(fontSize: 16), // Smaller button text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
