import 'package:flutter/material.dart';
import 'mechanic_packages_payment.dart';
import 'car_owner_packages_payment.dart';
import 'enterprise_packages_payment.dart';
import 'enterprise_mechanic_packages_payment.dart';
import 'auto_supply_store_package_screen.dart'; // Import the new Auto Supply Store screen

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = "User"; // Default full name

  @override
  void initState() {
    super.initState();
    _fetchUserFullName();
  }

  Future<void> _fetchUserFullName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    final response = await http.get(Uri.parse('https://expertstrials.xyz/Garifix_app/get_full_name?email=$email'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        _fullName = data['full_name'] ?? "User";
      });
    } else {
      print('Failed to load user full name: ${response.statusCode}');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text('If you need assistance, please contact our support team at support@mecarapp.com.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Mecar App'),
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                child: Text(
                  'Hello, $_fullName! Please select your role to proceed.',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Car Owner Button
              CrazyButton(
                icon: Icons.directions_car,
                label: 'I am a Car Owner',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CarOwnerScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Mechanic Button
              CrazyButton(
                icon: Icons.build,
                label: 'I am a Mechanic',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MechanicScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Enterprise Car Owner Button
              CrazyButton(
                icon: FontAwesomeIcons.building,
                label: 'Enterprise Car Owner',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EnterpriseCarOwnerScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Enterprise Mechanic Button
              CrazyButton(
                icon: FontAwesomeIcons.building,
                label: 'Enterprise Mechanic',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EnterpriseMechanicScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Auto Supply Store Button
              CrazyButton(
                icon: FontAwesomeIcons.store, // Use a different icon for Auto Supply Store
                label: 'Auto Supply Store',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AutoStorePaymentScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom CrazyButton Widget for consistency and style
class CrazyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const CrazyButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      icon: Icon(icon, size: 28, color: Colors.white),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
