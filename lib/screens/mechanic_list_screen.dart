import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/mechanic_card.dart';

class MechanicListScreen extends StatefulWidget {
  const MechanicListScreen({Key? key}) : super(key: key);

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
  }

Future<void> fetchMechanics() async {
    try {
        final response = await http.get(Uri.parse('http://10.0.2.2:5000/mechanics'));
        
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


static final List<Widget> _bottomNavPages = <Widget>[
  MechanicListScreenBody(mechanics: []), // Mechanics list page
  JobsPage(),                // Jobs assigned to mechanic
  MessagesPage(),            // Mechanic's messages
  ProfilePage(),             // Mechanic's profile
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
        child: const Icon(Icons.add),
        tooltip: 'Add Job or Task',
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
  MechanicListScreenBody({required this.mechanics});

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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Jobs Page'),
    );
  }
}

// Page for Mechanic's Messages
class MessagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Messages Page'),
    );
  }
}

// Page for Mechanic's Profile
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Profile Page'),
    );
  }
}
