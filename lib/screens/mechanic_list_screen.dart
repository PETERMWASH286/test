import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/mechanic_card.dart';

class MechanicListScreen extends StatefulWidget {
  const MechanicListScreen({super.key});

  @override
  _MechanicListScreenState createState() => _MechanicListScreenState();
}

class _MechanicListScreenState extends State<MechanicListScreen> {
  List<dynamic> mechanics = [];
  int _selectedIndex = 0; // For bottom navbar

  @override
  void initState() {
    super.initState();
    fetchMechanics();
    _checkLocationPermission(); // Check permission when the screen is loaded
  }

  Future<void> fetchMechanics() async {
    try {
      final response = await http.get(Uri.parse('http://10.88.0.4:5000/mechanics'));
      if (response.statusCode == 200) {
        setState(() {
          mechanics = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load mechanics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching mechanics: $e');
    }
  }

  // Method to check location permission and show dialog
  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      _showLocationPermissionDialog();
    }
  }

void _showLocationPermissionDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.deepPurple),
            const SizedBox(width: 10),
            const Text('Location Permission Needed'),
          ],
        ),
        content: const Text(
          'To show mechanics near you, please allow location access.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Dismiss the dialog
              // Request permission
              await Permission.location.request();
              // Check the status again
              if (mounted) { // Check if the widget is still mounted
                if (await Permission.location.isGranted) {
                  // Permission granted
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location permission granted!')),
                  );
                } else {
                  // Permission denied
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location permission denied!')),
                  );
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

  static final List<Widget> _bottomNavPages = <Widget>[
    const MechanicListScreenBody(mechanics: []), // Mechanics list page
    const JobsPage(), // Jobs assigned to mechanic
    const MessagesPage(), // Mechanic's messages
    const ProfilePage(), // Mechanic's profile
  ];

  // Handling navbar tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Mechanics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality for mechanics
            },
            tooltip: 'Search Mechanics',
          ),
        ],
      ),
      body: _bottomNavPages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick action for creating new jobs or tasks
        },
        backgroundColor: Colors.deepPurple,
        tooltip: 'Add Job or Task',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Mechanics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class MechanicListScreenBody extends StatelessWidget {
  final List<dynamic> mechanics;

  // Constructor to receive mechanics data
  const MechanicListScreenBody({super.key, required this.mechanics});

  @override
  Widget build(BuildContext context) {
    return mechanics.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: mechanics.length,
            itemBuilder: (context, index) {
              return MechanicCard(
                name: mechanics[index]['name'],
                location: mechanics[index]['location'],
                specialty: mechanics[index]['specialty'],
              );
            },
          );
  }
}

// Page for Mechanic's Jobs
class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Jobs Page'),
    );
  }
}

// Page for Mechanic's Messages
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Messages Page'),
    );
  }
}

// Page for Mechanic's Profile
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Page'),
    );
  }
}
