import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CarOwnerPage(),
    );
  }
}

class CarOwnerPage extends StatefulWidget {
  const CarOwnerPage({super.key});

  @override
  _CarOwnerScreenState createState() => _CarOwnerScreenState();
}

class _CarOwnerScreenState extends State<CarOwnerPage> {
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
  const HomePage({super.key});

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

class RepairsPage extends StatefulWidget {
  const RepairsPage({super.key});

  @override
  _RepairsPageState createState() => _RepairsPageState();
}

class _RepairsPageState extends State<RepairsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isFabClicked = false;

final ValueNotifier<double> _urgencyLevel = ValueNotifier<double>(3.0); // Default urgency level

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method to show the form in a modal bottom sheet
  void _showProblemForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          children: [
            const Text(
              'Report a Car Problem',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            _buildProblemForm(),
          ],
        ),
      ),
    );
  }

  // Building the form
  Widget _buildProblemForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown for problem type
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Problem Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Engine', child: Text('Engine Problem')),
              DropdownMenuItem(value: 'Brakes', child: Text('Brake Issue')),
              DropdownMenuItem(value: 'Tire', child: Text('Tire Problem')),
              DropdownMenuItem(value: 'Electrical', child: Text('Electrical Issue')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 20),

          // Urgency level slider
          // Urgency level slider
          const Text(
            'Urgency Level',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _urgencyLevel,
            builder: (context, value, child) {
              return Column(
                children: [
                  Slider(
                    value: value,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _getUrgencyLabel(value),
                    onChanged: (newValue) {
                      _urgencyLevel.value = newValue; // Update urgency level
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),


          // Text field for additional details
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Additional Details',
              hintText: 'Describe the problem in detail...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

// Upload image button
ElevatedButton.icon(
  onPressed: () {
    // Handle image upload logic
  },
  icon: const Icon(Icons.camera_alt, color: Colors.white), // Icon color for better contrast
  label: const Text(
    'Upload Image of the Problem',
    style: TextStyle(color: Colors.white), // Text color for better contrast
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple, // Background color
    foregroundColor: Colors.white, // Text and icon color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Padding for better touch area
    elevation: 5, // Add some elevation for depth
  ),
),
const SizedBox(height: 20),




// Submit button with gradient background and single button
Container(
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Colors.deepPurple, Colors.purpleAccent], // Gradient colors
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(10), // Rounded corners
  ),
  child: ElevatedButton.icon(
    onPressed: () {
      // Handle form submission logic
    },
    icon: const Icon(Icons.send, color: Colors.white), // Add an icon to the button
    label: const Text(
      'Submit Problem Report',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), // Text color
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent, // Make button background transparent to show gradient
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      shadowColor: Colors.transparent, // Disable shadow to keep it flat
    ),
  ),
),
const SizedBox(height: 20),


        ],
      ),
    );
  }
  String _getUrgencyLabel(double value) {
    switch (value.toInt()) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return '';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Repairs History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
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
      ),

      // Floating Action Button with animation
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: AnimatedIcon(
          icon: AnimatedIcons.add_event,
          progress: _animationController,
        ),
        onPressed: () {
          setState(() {
            _isFabClicked = !_isFabClicked;
            if (_isFabClicked) {
              _animationController.forward();
              _showProblemForm();
            } else {
              _animationController.reverse();
            }
          });
        },
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
  const FindMechanicPage({super.key});

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
  const ExplorePage({super.key});

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
  const AccountPage({super.key});

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
