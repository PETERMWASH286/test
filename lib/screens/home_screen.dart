import 'package:flutter/material.dart';
import 'mechanic_list_screen.dart';
import 'car_owner_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // FontAwesome
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // For shared preferences

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
    _fetchUserFullName(); // Fetch user's full name when the screen loads
  }

Future<void> _fetchUserFullName() async {
  // Get email from shared preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? email = prefs.getString('email'); // Adjust based on your shared preference key

  // Debugging: Print the email to verify it's retrieved correctly
  print('Retrieved email from SharedPreferences: $email');

  if (email != null) {
    // Make an HTTP GET request to fetch the user's full name from the server
    final response = await http.get(Uri.parse('http://10.88.0.4:5000/get_full_name?email=$email'));

    // Debugging: Print the response status code
    print('Response status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      var data = json.decode(response.body);

      // Debugging: Print the data received from the API
      print('Data received from API: $data');

      setState(() {
        _fullName = data['full_name'] ?? "User"; // Use null-aware operator to fall back to default
      });
    } else {
      // If the server did not return a 200 OK response, handle the error
      print('Failed to load user full name: ${response.statusCode}');
      print('Response body: ${response.body}'); // Log the response body for debugging
    }
  } else {
    print('Email not found in shared preferences.');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Car Service App'),
        backgroundColor: Colors.deepPurple,
        elevation: 10,
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
            mainAxisAlignment: MainAxisAlignment.start, // Aligns the message at the top
            children: [
              // Welcome message at the top
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20), // Padding around the message
                child: Text(
                  'Hello, $_fullName! Please select your role to proceed.',
                  style: const TextStyle(
                    fontSize: 18, // Smaller font size
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

              // Add margin before the buttons
              const SizedBox(height: 40), // Space between the message and buttons

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
                    MaterialPageRoute(builder: (context) => const MechanicListScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Enterprise Car Owner Button
              CrazyButton(
                icon: FontAwesomeIcons.building, // FontAwesome icon
                label: 'Enterprise Car Owner',
                onPressed: () {
                  // Navigate to Enterprise Car Owner screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EnterpriseCarOwnerScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Enterprise Mechanic Button
              CrazyButton(
                icon: FontAwesomeIcons.building, // FontAwesome icon
                label: 'Enterprise Mechanic',
                onPressed: () {
                  // Navigate to Enterprise Mechanic screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EnterpriseMechanicScreen()),
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

// Custom CrazyButton Widget for consistency and crazy style
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
        backgroundColor: Colors.deepPurple, // Background color
        foregroundColor: Colors.white, // Text color
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

// Placeholder for Enterprise Car Owner Screen
class EnterpriseCarOwnerScreen extends StatelessWidget {
  const EnterpriseCarOwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Car Owner Options'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text('Enterprise Car Owner Functionality Coming Soon!'),
      ),
    );
  }
}

// Placeholder for Enterprise Mechanic Screen
class EnterpriseMechanicScreen extends StatelessWidget {
  const EnterpriseMechanicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Mechanic Options'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text('Enterprise Mechanic Functionality Coming Soon!'),
      ),
    );
  }
}
