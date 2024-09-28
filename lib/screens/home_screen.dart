import 'package:flutter/material.dart';
import 'mechanic_list_screen.dart';
import 'car_owner_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // FontAwesome

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

              // Enterprise Button (New Option)
              CrazyButton(
                icon: FontAwesomeIcons.building, // FontAwesome icon
                label: 'Enterprise',
                onPressed: () {
                  // Navigate to Enterprise screen (placeholder)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EnterpriseScreen()),
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
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

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

// Placeholder for Enterprise Screen
class EnterpriseScreen extends StatelessWidget {
  const EnterpriseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Options'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: const Text('Enterprise Functionality Coming Soon!'),
      ),
    );
  }
}
