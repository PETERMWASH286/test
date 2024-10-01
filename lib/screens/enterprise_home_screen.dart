import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EnterpriseCarScreen extends StatefulWidget {
  const EnterpriseCarScreen({super.key});

  @override
  _EnterpriseCarOwnerScreenState createState() =>
      _EnterpriseCarOwnerScreenState();
}

class _EnterpriseCarOwnerScreenState extends State<EnterpriseCarScreen> {
  List<dynamic> cars = [];
  int _selectedIndex = 0; // For bottom navbar

  @override
  void initState() {
    super.initState();
    fetchCars();
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
