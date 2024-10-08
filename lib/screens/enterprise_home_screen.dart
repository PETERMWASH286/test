import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class EnterpriseCarScreen extends StatefulWidget {
  const EnterpriseCarScreen({super.key});

  @override
  _EnterpriseCarOwnerScreenState createState() =>
      _EnterpriseCarOwnerScreenState();
}

class _EnterpriseCarOwnerScreenState extends State<EnterpriseCarScreen> {
  List<dynamic> cars = [];
  int _selectedIndex = 0; // For bottom navbar
  String _userLocationName = '';
  String? userEmail; // Variable to hold user email
  Position? _previousPosition; // Variable to hold the previous location

@override
void initState() {
  super.initState();

  // Fetch cars immediately
  fetchCars();

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
          'To show mechanics near you, please allow location access.',
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

  Future<void> fetchCars() async {
    try {
      final response = await http.get(Uri.parse('http://your_api_url/cars'));

      if (response.statusCode == 200) {
        setState(() {
          cars = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load cars: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cars: $e');
    }
  }

  static final List<Widget> _bottomNavPages = <Widget>[
    const CarListScreenBody(cars: []), // Cars list page
    const RepairsPage(), // Repairs management page
    const MechanicsPage(), // Find mechanics
    const ProfilePage(), // Owner's profile
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
        title: const Text('Enterprise Car Owner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality for cars or mechanics
            },
            tooltip: 'Search',
          ),
        ],
      ),
      body: _bottomNavPages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick action for adding new repair records or cars
        },
        backgroundColor: Colors.blueAccent,
        tooltip: 'Add Repair Record',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.car_repair),
            label: 'Cars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Repairs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_taxi),
            label: 'Find Mechanics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class CarListScreenBody extends StatelessWidget {
  final List<dynamic> cars;

  const CarListScreenBody({super.key, required this.cars});

  @override
  Widget build(BuildContext context) {
    return cars.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(cars[index]['model']),
                  subtitle: Text('Plate: ${cars[index]['plate_number']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Edit car details
                    },
                  ),
                ),
              );
            },
          );
  }
}

// Page for managing repairs
class RepairsPage extends StatelessWidget {
  const RepairsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Repairs Management Page'),
    );
  }
}

// Page for finding mechanics
class MechanicsPage extends StatelessWidget {
  const MechanicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Find Mechanics Page'),
    );
  }
}

// Page for the owner's profile
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Page'),
    );
  }
}
