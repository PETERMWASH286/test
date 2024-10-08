import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'dart:convert';
import 'package:http/http.dart' as http;


class EnterpriseHomeScreen extends StatefulWidget {
  const EnterpriseHomeScreen({super.key});

  @override
  _EnterpriseHomeScreenState createState() => _EnterpriseHomeScreenState();
}

class _EnterpriseHomeScreenState extends State<EnterpriseHomeScreen> {
  // Define a list of pages for the bottom navigation bar


  String _userLocationName = '';
  String? userEmail; // Variable to hold user email
  Position? _previousPosition; // Variable to hold the previous location

@override
void initState() {
  super.initState();

  // Fetch cars immediately

  // Check location permission after the widget is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkLocationPermission();
  });

  // Load user email from SharedPreferences
  _loadUserEmail();
}


  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail'); // Retrieve user email
    });
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      _showLocationPermissionDialog();
    } else {
      _getUserLocation(); // Fetch location if permission is already granted
    }
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      _userLocationName = '${place.locality}, ${place.country}';

      print('User Location: $_userLocationName');

      // Check if the location has changed more than 2 kilometers
      if (_previousPosition == null || Geolocator.distanceBetween(
          _previousPosition!.latitude, 
          _previousPosition!.longitude, 
          position.latitude, 
          position.longitude) > 2000) {
        _previousPosition = position; // Update previous position
        _postUserLocation(position); // Post the new location
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location: $_userLocationName')),
        );
      }
    } catch (e) {
      print('Error fetching location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching location!')),
        );
      }
    }
  }

Future<void> _postUserLocation(Position position) async {
  if (userEmail == null) return; // Ensure email is available

  final url = Uri.parse('https://expertstrials.xyz/Garifix_app/post_location'); // Your backend URL
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json', // Specify that you're sending JSON
    },
    body: jsonEncode({
      'email': userEmail,
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
    }),
  );

  if (response.statusCode == 201) {
    print('Location posted successfully');
  } else {
    print('Failed to post location: ${response.statusCode}');
  }
}

void _showLocationPermissionDialog() {
  if (!mounted) return; // Prevents showing dialog if the widget is not mounted

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
title: const Row(
  children: [
    Icon(Icons.location_on, color: Colors.deepPurple),
    SizedBox(width: 10),
    Text(
      'Location Permission Needed',
      style: TextStyle(
        fontSize: 16, // Font size in logical pixels, not exact px but equivalent
        color: Colors.blue, // Text color changed to blue
      ),
    ),
  ],
),
        content: const Text(
          'To show carowners near you, please allow location access.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              await Permission.location.request(); // Request permission
              if (mounted) {
                if (await Permission.location.isGranted) {
                  _getUserLocation(); // Fetch location if granted
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location permission denied!')),
                    );
                  }
                }
              }
            },
            child: const Text('Allow'),
          ),
        ],
      );
    },
  );
}
  final List<Widget> _pages = [
    const DashboardPage(),
    const ServiceHistoryPage(),
    const PerformanceAnalyticsPage(),
    const ExplorePage(),
    const AccountPage(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Mechanic Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications here
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle user logout here
            },
          ),
        ],
      ),
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Service History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected page index
          });
        },
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// Dashboard Page Widget
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Your Dashboard!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Manage your fleet effectively and efficiently',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),

                // Cards for Services
                buildServiceCard(
                  context,
                  icon: Icons.car_repair,
                  title: 'Vehicle Management',
                  description: 'Track and manage all your vehicles in one place.',
                  onTap: () {
                    // Navigate to Vehicle Management screen
                  },
                ),
                const SizedBox(height: 20),

                buildServiceCard(
                  context,
                  icon: Icons.history,
                  title: 'Service History',
                  description: 'View detailed service history for each vehicle.',
                  onTap: () {
                    // Navigate to Service History screen
                  },
                ),
                const SizedBox(height: 20),

                buildServiceCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Performance Analytics',
                  description: 'Analyze the performance of your fleet.',
                  onTap: () {
                    // Navigate to Performance Analytics screen
                  },
                ),
                const SizedBox(height: 30),

                // Notifications Section
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                buildNotificationCard(
                  title: 'Service Due!',
                  message: 'Your vehicle ABC123 is due for service next week.',
                ),
                const SizedBox(height: 10),
                buildNotificationCard(
                  title: 'New Update!',
                  message: 'Check out the latest features added to your account.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget to build each service card
  Widget buildServiceCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.deepPurple),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build notification card
  Widget buildNotificationCard({required String title, required String message}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder widget for Service History Page
class ServiceHistoryPage extends StatelessWidget {
  const ServiceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Service History Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// Placeholder widget for Performance Analytics Page
class PerformanceAnalyticsPage extends StatelessWidget {
  const PerformanceAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Performance Analytics Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// Placeholder widget for Explore Page
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Explore Page - Discover New Services and Offers',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// Placeholder widget for Account Page
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Account Page - Manage Your Profile and Settings',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
