import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CarOwnerScreen(),
    );
  }
}

class CarOwnerScreen extends StatefulWidget {
  const CarOwnerScreen({Key? key}) : super(key: key);

  @override
  _CarOwnerScreenState createState() => _CarOwnerScreenState();
}

class _CarOwnerScreenState extends State<CarOwnerScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const RepairsPage(),
    const FindMechanicPage(),
    const ExplorePage(),
    const AccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Owner App'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Repairs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find Mechanic',
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Home Page
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back, Car Owner!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 20),
          const Text(
            'Here’s a quick overview of your car’s recent activities and updates:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.deepPurple[50],
            child: ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.deepPurple),
              title: const Text('Upcoming Service: Oil Change'),
              subtitle: const Text('Date: 28th September, 2024'),
              trailing: const Icon(Icons.arrow_forward, color: Colors.deepPurple),
              onTap: () {
                // Implement navigation or more details
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: Colors.deepPurple[50],
            child: ListTile(
              leading: const Icon(Icons.build, color: Colors.deepPurple),
              title: const Text('New Repairs Request'),
              subtitle: const Text('Requested on: 23rd September, 2024'),
              trailing: const Icon(Icons.arrow_forward, color: Colors.deepPurple),
              onTap: () {
                // Implement navigation or more details
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Need assistance with your vehicle?',
            style: TextStyle(fontSize: 16),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Implement help logic
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('Request Help'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// Repairs Page
class RepairsPage extends StatelessWidget {
  const RepairsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Repairs History',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildRepairCard(
                  date: '12th September, 2024',
                  description: 'Brake Pad Replacement',
                  cost: '\$150',
                ),
                _buildRepairCard(
                  date: '2nd August, 2024',
                  description: 'Engine Tune-up',
                  cost: '\$320',
                ),
                _buildRepairCard(
                  date: '15th July, 2024',
                  description: 'Tire Replacement',
                  cost: '\$400',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairCard({
    required String date,
    required String description,
    required String cost,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.build, color: Colors.deepPurple),
        title: Text(description),
        subtitle: Text('Date: $date'),
        trailing: Text(cost, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Find Mechanic Page
class FindMechanicPage extends StatelessWidget {
  const FindMechanicPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mechanics Near You',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildMechanicCard(
                  name: 'John Doe Mechanics',
                  rating: '4.8',
                  distance: '1.2 km',
                  phone: '123-456-7890',
                ),
                _buildMechanicCard(
                  name: 'Auto Fix Solutions',
                  rating: '4.5',
                  distance: '2.5 km',
                  phone: '098-765-4321',
                ),
                _buildMechanicCard(
                  name: 'Quick Fix Garage',
                  rating: '4.7',
                  distance: '3.0 km',
                  phone: '111-222-3333',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicCard({
    required String name,
    required String rating,
    required String distance,
    required String phone,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.person_pin_circle, color: Colors.deepPurple),
        title: Text(name),
        subtitle: Text('Rating: $rating ★\nDistance: $distance'),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.deepPurple),
          onPressed: () {
            // Implement call mechanic feature
          },
        ),
      ),
    );
  }
}

// Explore Page
class ExplorePage extends StatelessWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Top Mechanics',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildExplorePost(
                  mechanicName: 'Expert Auto Repairs',
                  description: 'Completed a full engine overhaul on a BMW M3. Professional service guaranteed!',
                  datePosted: '2 days ago',
                ),
                _buildExplorePost(
                  mechanicName: 'Quick Tune Garage',
                  description: 'Specialized in brake systems and suspension upgrades. Book a service today!',
                  datePosted: '5 days ago',
                ),
                _buildExplorePost(
                  mechanicName: 'Luxury Car Repair',
                  description: 'Premium car detailing and interior refurbishment. Transform your ride!',
                  datePosted: '1 week ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplorePost({
    required String mechanicName,
    required String description,
    required String datePosted,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: ListTile(
        title: Text(mechanicName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Text(datePosted),
      ),
    );
  }
}

// Account Page
class AccountPage extends StatelessWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Account',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 20),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.deepPurple),
              title: const Text('John Doe'),
              subtitle: const Text('john.doe@email.com'),
              trailing: const Icon(Icons.edit, color: Colors.deepPurple),
              onTap: () {
                // Implement edit account details
              },
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              // Implement logout
            },
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }
}
