import 'package:flutter/material.dart';

class EnterpriseHomeScreen extends StatefulWidget {
  const EnterpriseHomeScreen({super.key});

  @override
  _EnterpriseHomeScreenState createState() => _EnterpriseHomeScreenState();
}

class _EnterpriseHomeScreenState extends State<EnterpriseHomeScreen> {
  // Define a list of pages for the bottom navigation bar
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
    return Center(
      child: const Text(
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
    return Center(
      child: const Text(
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
    return Center(
      child: const Text(
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
    return Center(
      child: const Text(
        'Account Page - Manage Your Profile and Settings',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
