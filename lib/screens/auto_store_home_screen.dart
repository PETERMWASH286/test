import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// Import shared_preferences
import 'post.dart'; // Make sure to import the Post model
import 'dart:async';
// Ensure you have this package in your pubspec.yaml
// Add flutter_rating_bar package for star rating bar
// Import the newly created file
// Import the newly created file
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'switch_signup.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // For text animation


class AutoStoreHomeScreen extends StatefulWidget {
  const AutoStoreHomeScreen({super.key});

  @override
  _AutoStoreHomeScreenState createState() => _AutoStoreHomeScreenState();
}

class _AutoStoreHomeScreenState extends State<AutoStoreHomeScreen> {
  int _currentIndex = 0;
  String _userLocationName = '';
  String? userEmail; // Variable to hold user email
  Position? _previousPosition; // Variable to hold the previous location

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
    _loadUserEmail(); // Load user email from SharedPreferences
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

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      _userLocationName = '${place.locality}, ${place.country}';

      print('User Location: $_userLocationName');

      // Check if the location has changed more than 2 kilometers
      if (_previousPosition == null ||
          Geolocator.distanceBetween(
                  _previousPosition!.latitude,
                  _previousPosition!.longitude,
                  position.latitude,
                  position.longitude) >
              2000) {
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

    final url = Uri.parse(
        'https://expertstrials.xyz/Garifix_app/post_location'); // Your backend URL
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
                  fontSize:
                      16, // Font size in logical pixels, not exact px but equivalent
                  color: Colors.blue, // Text color changed to blue
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            // Added to avoid overflow issues
            child: Text(
              'To show mechanics near you, please allow location access.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Deny'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Permission.location.request();
                if (mounted) {
                  if (await Permission.location.isGranted) {
                    _getUserLocation();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Location permission denied!')),
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
  // List of pages to navigate between
  final List<Widget> _pages = [
    const HomePageScreen(), // Home Page
    const ExplorePage(), // Explore Page
    const OrdersScreen(), // Orders Page
    const AccountsScreen(), // Accounts Page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color.fromRGBO(191, 187, 197, 1)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore, color: Color.fromRGBO(191, 187, 197, 1)),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt, color: Color.fromRGBO(191, 187, 197, 1)),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle,
                color: Color.fromRGBO(191, 187, 197, 1)),
            label: 'Accounts',
          ),
        ],
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
      ),
    );
  }
}

class HomePageScreen extends StatelessWidget {
  const HomePageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/app_logo.png',
                height: 50,
                width: 50,
              ),
            ),
            const SizedBox(width: 15),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color.fromARGB(255, 255, 171, 64), Colors.yellow],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'Mecar',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            iconSize: 28,
            color: Colors.white,
            splashRadius: 25,
            onPressed: () {
              // Notification action
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            const Text(
              'Welcome to Auto Supply Store!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(103, 58, 183, 1),
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Section
            _buildStatisticsSection(),

            const SizedBox(height: 30),

            // Recent Posts Overview Section
            const Text(
              'Recent Posts Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            _buildRecentPosts(),

            const SizedBox(height: 30),

            // Featured Categories Section
            const Text(
              'Featured Categories',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            _buildCategoryList(),

            const SizedBox(height: 30),

            // Popular Products Section
            const Text(
              'Popular Products',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            _buildProductList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return SizedBox(
      height: 140, // Adjusts height of the stat card section
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: [
          _buildStatCard(
            icon: Icons.post_add,
            label: 'Posts Today',
            value: '5',
            color: Colors.purple.shade100,
          ),
          _buildStatCard(
            icon: Icons.calendar_today,
            label: 'Monthly Posts',
            value: '120',
            color: Colors.blue.shade100,
          ),
          _buildStatCard(
            icon: Icons.remove_red_eye,
            label: '24h Engagement',
            value: '300',
            color: Colors.green.shade100,
          ),
          _buildStatCard(
            icon: Icons.timeline,
            label: 'Monthly Engagement',
            value: '5K',
            color: Colors.orange.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPosts() {
    return Column(
      children: [
        _buildPostStatCard(
          title: 'Brake Pads - 20% Off!',
          views: '150 views',
          engagements: '80 engagements',
        ),
        const SizedBox(height: 15),
        _buildPostStatCard(
          title: 'Spark Plugs Bundle',
          views: '90 views',
          engagements: '45 engagements',
        ),
      ],
    );
  }

  Widget _buildPostStatCard(
      {required String title,
      required String views,
      required String engagements}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(FontAwesomeIcons.cogs,
                color: Colors.deepPurpleAccent, size: 28),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(views,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black54)),
                Text(engagements,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final List<Map<String, String>> categories = [
      {'name': 'Engine Parts', 'image': 'assets/engine_parts.png'},
      {'name': 'Tires & Wheels', 'image': 'assets/tires.png'},
      {'name': 'Interior Accessories', 'image': 'assets/interior.png'},
      {'name': 'Lighting', 'image': 'assets/lighting.png'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(category['image']!),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name']!,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductList() {
    final List<Map<String, String>> products = [
      {
        'name': 'Brake Pads',
        'image': 'assets/brake_pads.png',
        'price': 'Ksh 2500'
      },
      {
        'name': 'Air Filters',
        'image': 'assets/air_filters.png',
        'price': 'Ksh 1200'
      },
      {
        'name': 'Spark Plugs',
        'image': 'assets/spark_plugs.png',
        'price': 'Ksh 800'
      },
      {
        'name': 'Car Battery',
        'image': 'assets/car_battery.png',
        'price': 'Ksh 9000'
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: products.map((product) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(product['image']!),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['name']!,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Text(
                  product['price']!,
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int _selectedNavIndex = 0;

// List of widgets for different sections
final List<Widget> _navPages = [
  const HomeSection(),
  const ProductScreen(),
  const MessagesSection(),
  const OrdersSection(), // Add the Orders section here
  const ExploreSection(),
];
  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back arrow
        backgroundColor: Colors.deepPurple,
        elevation: 10, // Adds shadow for a more dynamic look
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.start, // Aligns content to the far left
          children: [
            // Logo with a subtle glow effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/app_logo.png', // Path to the Mecar logo
                height: 50,
                width: 50,
              ),
            ),
            const SizedBox(width: 15), // Space between logo and name
            // Gradient text for the company name
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color.fromARGB(255, 255, 171, 64), Colors.yellow],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'Mecar',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings, color: Colors.white),
          onSelected: (String value) async {
            switch (value) {
              case 'Switch Account':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SwitchAccountScreen()),
                );
                break;
              case 'Privacy Policy':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
                break;
              case 'Help':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
                break;
              case 'Logout':
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem(value: 'Switch Account', child: Text('Switch Account')),
              const PopupMenuItem(value: 'Privacy Policy', child: Text('Privacy Policy')),
              const PopupMenuItem(value: 'Help', child: Text('Help')),
              const PopupMenuItem(value: 'Logout', child: Text('Logout')),
            ];
          },
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
          onPressed: () async {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
              60.0), // Set height for the bottom navigation
child: BottomNavigationBar(
  items: const <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.store),
      label: 'Products',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.message),
      label: 'Messages',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart), // Icon for Orders
      label: 'Orders',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.explore),
      label: 'Explore',
    ),
  ],
  currentIndex: _selectedNavIndex,
  selectedItemColor: const Color.fromARGB(255, 255, 171, 64), // Single color
  unselectedItemColor: Colors.grey,
  onTap: _onNavItemTapped,
  type: BottomNavigationBarType.fixed,
),

        ),
      ),
      body: IndexedStack(
        index: _selectedNavIndex, // Show the selected page
        children: _navPages,
      ),
    );
  }
}



class OrdersSection extends StatelessWidget {
  const OrdersSection({super.key});

  Future<List<dynamic>> fetchOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      print("Debug: JWT token is null. User is not authenticated.");
      throw Exception('User is not authenticated.');
    }

    try {
      final response = await http.get(
        Uri.parse('https://expertstrials.xyz/Garifix_app/api/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final orders = jsonDecode(response.body);
        return orders;
      } else {
        throw Exception('Failed to fetch orders.');
      }
    } catch (e) {
      print("Error: Exception occurred while fetching orders: $e");
      throw Exception('An error occurred while fetching orders.');
    }
  }

  Future<void> _checkImageLoaded(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        print('Image URL is valid and returned status 200.');
      } else {
        print('Error: Image returned status ${response.statusCode}.');
      }
    } catch (e) {
      print('Failed to fetch image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text(
    'My Orders',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22,
      color: Colors.white,
      letterSpacing: 1.2,
    ),
  ),
  backgroundColor: Colors.blueAccent,
  elevation: 4.0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(30),
    ),
  ),
  actions: [
    IconButton(
      icon: const Icon(
        Icons.shopping_cart,
        color: Colors.white,
      ),
      onPressed: () {
        // Add your action here
      },
    ),
  ],
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blueAccent, Colors.purpleAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
),

body: FutureBuilder<List<dynamic>>(
  future: fetchOrders(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.blueAccent,
                size: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'No orders yet!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start shopping now to see your orders here.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      // Display a beautiful "No orders yet" message with an icon
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.blueAccent,
                size: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'No orders yet!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start shopping now to see your orders here.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }


          final orders = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order ID: #${order['id']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Ksh ${order['total_amount'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
const SizedBox(height: 8),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        'Product: ${order['product_name']}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    Text(
      'Quantity: ${order['quantity']}',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.blueAccent, // Optional: change color to highlight
      ),
    ),
  ],
),

                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Order Date: ${order['created_at']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            order['product_image_path'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      'https://expertstrials.xyz/Garifix_app/' + order['product_image_path'],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        } else {
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                                  : null,
                                            ),
                                          );
                                        }
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.error, size: 50);
                                      },
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    width: 100,
                                    height: 100,
                                    child: const Icon(Icons.image, color: Colors.grey, size: 50),
                                  ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      'Paid',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Company: ${order['company_full_name']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${order['status']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                                                        const SizedBox(height: 4),

                                                        Row(
                          children: [
                            if (order['company_phone_number'] != null)
                              const Icon(Icons.phone, color: Colors.blue),
                            if (order['company_phone_number'] != null)
                              const SizedBox(width: 4),
                            if (order['company_phone_number'] != null)
                              Text(
                                order['company_phone_number'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                          ],
                        ),
                              ],
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class HomeSection extends StatefulWidget {
  const HomeSection({super.key});

  @override
  _HomeSectionState createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  List<Post> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  List<Post> removeDuplicatesById(List<Post> posts) {
    final seenIds = <int>{};
    return posts.where((post) => seenIds.add(post.id)).toList();
  }

  Future<void> fetchPosts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    const String url = 'https://expertstrials.xyz/Garifix_app/api/posts';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        List<Post> fetchedPosts =
            jsonData.map((json) => Post.fromJson(json)).toList();
        fetchedPosts = removeDuplicatesById(fetchedPosts);

        setState(() {
          posts = fetchedPosts;
          isLoading = false;
        });
      } else {
        print('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.grey[200],
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: fetchPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];

                          return FutureBuilder<String>(
                            future: _getAddressFromLatLng(
                                post.latitude!, post.longitude!),
                            builder: (context, snapshot) {
                              String locationText = 'Location not available';
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                locationText = 'Fetching location...';
                              } else if (snapshot.hasData) {
                                locationText = snapshot.data!;
                              } else if (snapshot.hasError) {
                                locationText = 'Error fetching location';
                              }

return _buildExplorePost(
  postId: post.id, // Pass the post ID here
  mechanicName: post.fullName,
  description: post.description,
  datePosted: post.createdAt.toString(),
  imagePath: 'https://expertstrials.xyz/Garifix_app/${post.imagePath}',
  userProfilePic: post.profileImage != null
      ? 'https://expertstrials.xyz/Garifix_app/${post.profileImage}'
      : 'assets/default_user.png',
  location: locationText,
  isLiked: post.isLiked, // Pass the isLiked status
  isSaved: post.isSaved, // Pass the isSaved status
  totalLikes: post.totalLikes, // Pass the totalLikes count
);


                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).size.height / 8,
          child: FloatingActionButton(
            onPressed: () {
              _showPostDialog(context);
            },
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<String> _getAddressFromLatLng(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      return '${place.street}, ${place.locality}, ${place.country}';
    } catch (e) {
      print(e);
      return 'Location not available';
    }
  }

  void _showPostDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    String? imagePath;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Create a New Post',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
              fontSize: 24,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? pickedFile =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            imagePath = pickedFile.path;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          image: imagePath != null
                              ? DecorationImage(
                                  image: FileImage(File(imagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: imagePath == null
                            ? const Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter post description...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    elevation: 8,
                    shadowColor: Colors.red.withOpacity(0.5),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Check if fields are filled
                    if (descriptionController.text.isNotEmpty &&
                        imagePath != null) {
                      // Call the function to create the post
                      await _createPost(
                          descriptionController.text, imagePath, context);
                      Navigator.of(context).pop(); // Close the dialog
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please fill in all fields!')));
                    }
                  },
                  icon: const Icon(Icons.post_add, color: Colors.white),
                  label:
                      const Text('Post', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    elevation: 8,
                    shadowColor: Colors.deepPurple.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

Future<void> _createPost(
  String description, String? imagePath, BuildContext context) async {
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    },
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token'); // Get the JWT token

  // Define the URL for your Flask backend
  const String url =
      'https://expertstrials.xyz/Garifix_app/api/posts'; // Adjust the endpoint accordingly

  // Prepare the request
  final request = http.MultipartRequest('POST', Uri.parse(url))
    ..fields['description'] = description
    ..headers['Authorization'] = 'Bearer $token'; // Add the JWT token in the headers

  if (imagePath != null) {
    // Attach the image file if it exists
    final imageFile = await http.MultipartFile.fromPath('image', imagePath);
    request.files.add(imageFile);
  }

  // Send the request
  try {
    final response = await request.send();
    Navigator.of(context).pop(); // Dismiss loading indicator
    if (response.statusCode == 200) {
      print('Post created successfully');
      _showCustomSnackBar(context, true, 'Post created successfully!');
    } else {
      print('Failed to create post: ${response.statusCode}');
      _showCustomSnackBar(context, false, 'Failed to create post!');
    }
  } catch (e) {
    Navigator.of(context).pop(); // Dismiss loading indicator on error
    print('Error occurred: $e');
    _showCustomSnackBar(context, false, 'An error occurred while creating the post!');
  }
}
// Show success or error dialog or SnackBar with improved visuals
void _showCustomSnackBar(BuildContext context, bool isSuccess, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: isSuccess ? Colors.green : Colors.red,
        onPressed: () {
          // Hide the SnackBar if user taps 'DISMISS'
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}



Widget _buildExplorePost({
  required int postId, // Added postId
  required String mechanicName,
  required String description,
  required String datePosted,
  required String imagePath,
  required String userProfilePic,
  required String location,
  required bool isLiked, // Added isLiked
  required bool isSaved, // Added isSaved
  required int totalLikes, // Added totalLikes
}) {
  Future<void> updateLikeStatus(bool isLiked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final response = await http.post(
        Uri.parse('https://expertstrials.xyz/Garifix_app/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'post_id': postId,
          'is_liked': isLiked,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update like status");
      }
    } catch (e) {
      print("Error updating like status: $e");
    }
  }

  Future<void> updateWishlistStatus(bool isSaved) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final response = await http.post(
        Uri.parse('https://expertstrials.xyz/Garifix_app/wishlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'post_id': postId,
          'is_saved': isSaved,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update wishlist status");
      }
    } catch (e) {
      print("Error updating wishlist status: $e");
    }
  }

  return StatefulBuilder(
    builder: (context, setState) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Image.network(
                imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          userProfilePic.isNotEmpty
                              ? userProfilePic
                              : 'https://example.com/default_user.png',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mechanicName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(description, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(datePosted,
                          style: const TextStyle(color: Colors.grey)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.deepPurple,
                            ),
                            onPressed: () {
                              setState(() {
                                isLiked = !isLiked;
                                totalLikes += isLiked ? 1 : -1;
                              });
                              updateLikeStatus(isLiked);
                            },
                          ),
                          Text(totalLikes.toString()),
                          IconButton(
                            icon: Icon(
                              isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: Colors.deepPurple,
                            ),
                            onPressed: () {
                              setState(() {
                                isSaved = !isSaved;
                              });
                              updateWishlistStatus(isSaved);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

}
class ChatService {
  final String apiUrl = 'https://expertstrials.xyz/Garifix_app'; // Your server URL
  Timer? _pollingTimer;
  String? authToken; // Variable to store the JWT token

  // Constructor to initialize the ChatService with the token
  ChatService() {
    _initializeToken();
  }

  // Initialize the JWT token from SharedPreferences
  Future<void> _initializeToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('jwt_token'); // Fetch the JWT token
  }

  // Start long polling for messages
// Start long polling for messages
void startLongPolling(Function(List<Map<String, dynamic>>) onMessageReceived) async {
  await _initializeToken(); // Ensure token is loaded before polling

  if (authToken == null) {
    print('Error: JWT token is not initialized.');
    return;
  }

  _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/messages'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );
      print('Polling response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final String currentUserId = responseData['user_id'].toString(); // Convert to String
        List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(responseData['conversations']);
        print('Messages received: $messages');
        if (messages.isNotEmpty) {
          // Process each message to identify sender and receiver
          for (var conversation in messages) {
            for (var message in conversation['messages']) {
              String messageRole = (message['sender_id'].toString() == currentUserId) ? 'sender' : 'receiver'; // Convert sender_id to String
              print('Message ID: ${message['id']} - You are the $messageRole');
            }
          }
          // Pass messages to the callback
          onMessageReceived(messages);
        } else {
          print('No new messages received.');
        }
      } else {
        print('Error fetching messages: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error during polling: $e');
    }
  });
}




  // Stop long polling
  void stopLongPolling() {
    _pollingTimer?.cancel();
  }

  // Send a message with id, mechanic name, and message to the server
  Future<void> sendMessage(String id, String message, String mechanicName) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // Include the JWT token in the request
        },
        body: json.encode({
          'id': id,  // Include the id in the request body
          'message': message,
          'mechanic_name': mechanicName,
        }),
      );

      print('Send message response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Error sending message: ${response.reasonPhrase}');
      } else {
        print('Message sent successfully: $message');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}



class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<dynamic> filteredProducts = [];
  bool isLoading = true; // Loading indicator
  bool isSearchVisible = false;
  String errorMessage = ""; // Store error messages
  late ChatService _chatService; // Declare ChatService instance
  bool isAddedToWishlist = false; // State to track if the icon is active
  
  @override
  void initState() {
    super.initState();
    _initializeProducts(); // Call the data initializer
    _chatService = ChatService(); // Initialize ChatService
  }

  Future<void> _initializeProducts() async {
    print("Initializing products...");
    try {
      await fetchProducts();
    } catch (e) {
      print("Error initializing products: $e");
      setState(() {
        errorMessage = "Failed to load products. Please try again.";
        isLoading = false;
      });
    }
  }

Future<void> fetchProducts() async {
  setState(() {
    isLoading = true; // Start loading state
    errorMessage = ""; // Clear previous errors
  });

  print("fetchProducts called");

  try {
    // Get the token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      // Handle missing token
      print("Error: User token not found.");
      setState(() {
        isLoading = false;
        errorMessage = "User not authenticated.";
      });
      return;
    }

    print("Token retrieved: $token");
    print("Making API request...");

    // Make the API request with the Authorization header
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> productList = json.decode(response.body);

      // Print the entire response data for debugging
      print("Response body: $productList");

      // Log and update the state with the fetched products
      print("Products fetched successfully, count: ${productList.length}");

      // Convert location coordinates to addresses
      for (var product in productList) {
        if (product['location'] != 'Location unavailable') {
          var coordinates = product['location'].split(',');
          double latitude = double.parse(coordinates[0].trim());
          double longitude = double.parse(coordinates[1].trim());
          List<Placemark> placemarks =
              await placemarkFromCoordinates(latitude, longitude);
          String address = placemarks.isNotEmpty
              ? placemarks.first.street ?? 'Address not found'
              : 'Address not found';
          product['location'] = address;
        }
      }

      setState(() {
        filteredProducts = productList;
        isLoading = false;
      });
    } else {
      print("Failed to load products with status: ${response.statusCode}");
      throw Exception('Failed to load products');
    }
  } catch (e) {
    print("Error fetching products: $e");
    setState(() {
      isLoading = false;
      errorMessage = "Error fetching products.";
    });
  }
}


  void filterProducts(String query) {
    final filtered = filteredProducts.where((product) {
      final titleLower = product['title'].toLowerCase();
      final companyNameLower = product['companyName'].toLowerCase();
      return titleLower.contains(query.toLowerCase()) ||
          companyNameLower.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height / 8 + 80,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  isSearchVisible = !isSearchVisible;
                });
              },
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.search),
            ),
          ),
Positioned(
  right: 16,
  bottom: MediaQuery.of(context).size.height / 8,
  child: FloatingActionButton(
    onPressed: () {
      _showPostDialog(context); // Show the post creation dialog
    },
    backgroundColor: Colors.deepPurple,
    child: const Icon(Icons.add),
  ),
),

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (isSearchVisible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  onChanged: filterProducts,
                  decoration: InputDecoration(
                    hintText: 'Search by company or product name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.deepPurple),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage))
                      : filteredProducts.isEmpty
                          ? const Center(child: Text("No products found"))
                          : ListView.builder(
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
return ProductCard(
  imageUrl: product['imageUrl'] ?? '',
  title: product['title'] ?? 'No Title',
  price: product['price'] ?? '\$0.00',
  description: product['description'] ?? 'No Description',
  companyName: product['companyName'] ?? 'Unknown Company',
  location: product['location'] ?? 'Unknown Location',
  productId: int.tryParse(product['id']?.toString() ?? '0') ?? 0,
  isBookmarked: product['isBookmarked'] ?? false, // Added bookmark status
);


                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showPostDialog(BuildContext context) {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String? imagePath;
  final ImagePicker picker = ImagePicker();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'Create a New Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            fontSize: 24,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? pickedFile =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          imagePath = pickedFile.path;
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        image: imagePath != null
                            ? DecorationImage(
                                image: FileImage(File(imagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: imagePath == null
                          ? const Icon(Icons.add_a_photo,
                              size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter product name/title...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter price in Ksh...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter post description...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                icon: const Icon(Icons.cancel, color: Colors.white),
                label:
                    const Text('Cancel', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 8,
                  shadowColor: Colors.red.withOpacity(0.5),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  // Check if all fields are filled
                  if (titleController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty &&
                      imagePath != null) {
                    // Fetch JWT token
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    final String? token = prefs.getString('jwt_token');

                    // Prepare data for upload
                    var request = http.MultipartRequest(
                      'POST',
                      Uri.parse(
                          'https://expertstrials.xyz/Garifix_app/create/post'),
                    );
                    request.headers['Authorization'] = 'Bearer $token';

                    request.fields['title'] = titleController.text;
                    request.fields['price'] = priceController.text;
                    request.fields['description'] = descriptionController.text;

                    request.files.add(
                        await http.MultipartFile.fromPath('image', imagePath!));

                    var response = await request.send();

                    // Check if the request was successful
                    if (response.statusCode == 201) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Post created successfully!')));
                      Navigator.of(context).pop(); // Close dialog
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Failed to create post.')));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please fill in all fields!')));
                  }
                },
                icon: const Icon(Icons.post_add, color: Colors.white),
                label:
                    const Text('Post', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 8,
                  shadowColor: Colors.deepPurple.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class ProductCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String description;
  final String companyName;
  final String location;
  final int productId;
  final bool isBookmarked; // Added parameter

  const ProductCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.description,
    required this.companyName,
    required this.location,
    required this.productId,
    required this.isBookmarked, // Added parameter
    super.key,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool isBookmarked; // Use late initialization

  @override
  void initState() {
    super.initState();
    // Initialize isBookmarked with the value from the widget
    isBookmarked = widget.isBookmarked;
  }

  Future<void> _toggleBookmark() async {
    // Toggle the bookmark state locally
    setState(() {
      isBookmarked = !isBookmarked;
    });

    try {
      // Get token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      print('Retrieved token: $token');

      if (token == null) {
        // Handle missing token
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated")),
        );
        return;
      }

      // Send request to backend
      final response = await http.post(
        Uri.parse('https://expertstrials.xyz/Garifix_app/bookmark'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': widget.productId,
          'is_bookmarked': isBookmarked,
        }),
      );

      print('Request sent with body:');
      print({
        'product_id': widget.productId,
        'is_bookmarked': isBookmarked,
      });

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        // Revert state if the request fails
        setState(() {
          isBookmarked = !isBookmarked;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update bookmark status")),
        );
      }
    } catch (e) {
      // Catch and log any errors
      print('Error occurred: $e');
      setState(() {
        isBookmarked = !isBookmarked; // Revert state on error
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card content
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.imageUrl),
                  onBackgroundImageError: (error, stackTrace) =>
                      const Icon(Icons.error),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.companyName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Image.network(
                    widget.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.error,
                        size: 80,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Ksh ${NumberFormat('#,##0.00').format(double.parse(widget.price))}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          title: widget.title,
                          price: widget.price,
                          imageUrl: widget.imageUrl,
                          companyName: widget.companyName,
                          description: widget.description,
                          productId: widget.productId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  label: const Text(
                    'Buy Now',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.deepPurple),
                  onPressed: () {
                    _showMessageBottomSheet(
                      context,
                      widget.productId,
                      widget.companyName,
                      widget.imageUrl,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border, // Toggle icon
                    color: isBookmarked ? Colors.purple : Colors.deepPurple,
                  ),
      onPressed: _toggleBookmark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


void _showMessageBottomSheet(
  BuildContext context,
  int id,  // Mechanic ID
  String mechanicName,
  String profileImageUrl,
) {
  List<Map<String, dynamic>> messages = [];
  String newMessage = '';
  bool isTyping = false;
  double keyboardHeight = 0;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, setState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (MediaQuery.of(context).viewInsets.bottom != keyboardHeight) {
              setState(() {
                keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
              });
            }
          });

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus(); // Dismiss keyboard when tapping outside
            },
            child: AnimatedPadding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  color: Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(profileImageUrl),
                          radius: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            mechanicName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 10),

                    // Messages List
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return MessageCard(
                            avatar: message['avatar'],
                            sender: message['sender'],
                            text: message['text'],
                            time: message['time'],
                            isRead: true,
                            unreadCount: 0,
                          );
                        },
                      ),
                    ),

                    // Typing Indicator
                    if (isTyping)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2),
                            const SizedBox(width: 10),
                            Text('Typing...', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Message Input Field
                    _buildMessageInput(
                      onChanged: (value) {
                        setState(() {
                          newMessage = value;
                          isTyping = value.isNotEmpty;
                        });
                      },
                      onSend: () {
                        if (newMessage.isNotEmpty) {
                          setState(() {
                            messages.add({
                              'avatar': profileImageUrl,
                              'sender': 'You',
                              'text': newMessage,
                              'time': TimeOfDay.now().format(context),
                            });
                            newMessage = '';
                            isTyping = false;
                          });
                        }
                      },
                      newMessage: newMessage,
                    ),

                    // Quick Replies
                    _buildQuickReplySuggestions((reply) {
                      setState(() {
                        messages.add({
                          'avatar': profileImageUrl,
                          'sender': 'You',
                          'text': reply,
                          'time': TimeOfDay.now().format(context),
                        });
                      });
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}



  Widget _buildMessageInput(
      {required ValueChanged<String> onChanged,
      required VoidCallback onSend,
      required String newMessage}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Type your message...',
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.message, color: Colors.deepPurple),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.deepPurple),
          onPressed: onSend,
        ),
      ],
    );
  }

  Widget _buildQuickReplySuggestions(Function(String) onSelectReply) {
    final List<String> quickReplies = [
      "👍",
      "👋",
      "🤔",
      "🚗"
    ]; // Sample quick replies
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: quickReplies.map((reply) {
        return GestureDetector(
          onTap: () => onSelectReply(reply),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.deepPurple[100],
            ),
            child: Text(reply, style: const TextStyle(fontSize: 18)),
          ),
        );
      }).toList(),
    );
  }

class CheckoutPage extends StatefulWidget {
  final String title;
  final String price;
  final String imageUrl;
  final String companyName;
  final String description;
  final int productId;

  const CheckoutPage({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.companyName,
    required this.description,
    required this.productId,
    super.key,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int quantity = 1;

double get totalPrice {
  // Print the original widget.price for debugging
  print("Original price from widget: ${widget.price}");

  // Remove all non-numeric characters, including dollar signs
  String cleanedPrice = widget.price.replaceAll(RegExp(r'[^0-9.]'), '');  
  print("Cleaned price: $cleanedPrice");

  // Calculate and print the total price
  double calculatedTotal = quantity * double.parse(cleanedPrice);
  print("Total price: $calculatedTotal");

  return calculatedTotal;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/app_logo.png',
                height: 50,
                width: 50,
              ),
            ),
            const SizedBox(width: 15),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color.fromARGB(255, 255, 171, 64), Colors.yellow],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'Mecar',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
actions: [
  PopupMenuButton<String>(
    icon: const Icon(Icons.settings, color: Colors.white),
    onSelected: (String value) async {
      // Handle menu selection
      switch (value) {
        case 'Switch Account':
          // Navigate to switch account screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SwitchAccountScreen()),
          );
          break;
        case 'Privacy Policy':
          // Navigate to privacy policy screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
          );
          break;
        case 'Help':
          // Navigate to help screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpScreen()),
          );
          break;
        case 'Logout':
          // Logout functionality
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
          break;
      }
    },
    itemBuilder: (BuildContext context) {
      return [
        const PopupMenuItem(
          value: 'Switch Account',
          child: Text('Switch Account'),
        ),
        const PopupMenuItem(
          value: 'Privacy Policy',
          child: Text('Privacy Policy'),
        ),
        const PopupMenuItem(
          value: 'Help',
          child: Text('Help'),
        ),
        const PopupMenuItem(
          value: 'Logout',
          child: Text('Logout'),
        ),
      ];
    },
  ),


        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.imageUrl,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.error, size: 80, color: Colors.red)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      'Ksh ${NumberFormat('#,##0.00').format(totalPrice)}',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepOrange,
      ),
    ),
  ],
),


              const SizedBox(height: 20),
              Card(
                elevation: 3,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business, color: Colors.black87, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Company: ${widget.companyName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.description, color: Colors.black54, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 28),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                        color: Colors.deepPurple,
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 28),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
ElevatedButton.icon(
  onPressed: () {
    // Navigate to the PaymentSummaryPage with the necessary data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSummaryPage(
          productId: widget.productId,
          imageUrl: widget.imageUrl,
          title: widget.title,
          quantity: quantity,
          totalPrice: totalPrice,
        ),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  icon: const Icon(Icons.payment, size: 24, color: Colors.white),
  label: const Text(
    'Proceed to Payment',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),

            ],
          ),
        ),
      ),
    );
  }
}


  final TextEditingController phoneController = TextEditingController();
class PaymentSummaryPage extends StatelessWidget {
  final String title; // Product name
  final int productId;
  final String imageUrl;
  final int quantity;
  final double totalPrice;

  const PaymentSummaryPage({
    required this.title,
    required this.productId,
    required this.imageUrl,
    required this.quantity,
    required this.totalPrice,
    super.key,
  });

Future<Map<String, String>> fetchUserShippingDetails() async {
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');

  if (token == null) {
    print('Error: Authentication token is missing');
    throw Exception('Authentication token is missing');
  }

  try {
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/get_shipping_details'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('Decoded JSON response: $jsonResponse');

        if (jsonResponse.containsKey('shipping_details') &&
            jsonResponse['shipping_details'] is List &&
            (jsonResponse['shipping_details'] as List).isNotEmpty) {
          
          final shippingDetail = jsonResponse['shipping_details'][0]; // Get the first item
          print('Shipping details found: $shippingDetail');

          if (shippingDetail is Map<String, dynamic>) {
            // Return the relevant fields in a Map<String, String>
            return {
              'full_name': shippingDetail['full_name'] ?? '',
              'address_line_1': shippingDetail['address_line_1'] ?? '',
              'address_line_2': shippingDetail['address_line_2'] ?? '',
              'city': shippingDetail['city'] ?? '',
              'state': shippingDetail['state'] ?? '',
              'postal_code': shippingDetail['postal_code'] ?? '',
              'phone_number': shippingDetail['phone_number'] ?? '',
            };
          } else {
            throw Exception('Unexpected structure for shipping details');
          }
        } else {
          print('Error: Shipping details not found or empty');
          throw Exception('Shipping details not found or empty');
        }
      } catch (e) {
        print('Error parsing JSON: ${e.toString()}');
        throw Exception('Error parsing shipping details: ${e.toString()}');
      }
    } else {
      print('Error: Failed to load shipping details, status code: ${response.statusCode}');
      throw Exception('Failed to load shipping details, status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error making the HTTP request: ${e.toString()}');
    throw Exception('Error making the HTTP request: ${e.toString()}');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/app_logo.png',
                height: 50,
                width: 50,
              ),
            ),
            const SizedBox(width: 15),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color.fromARGB(255, 255, 171, 64), Colors.yellow],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'Make Payments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
actions: [
  PopupMenuButton<String>(
    icon: const Icon(Icons.settings, color: Colors.white),
    onSelected: (String value) async {
      // Handle menu selection
      switch (value) {
        case 'Switch Account':
          // Navigate to switch account screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SwitchAccountScreen()),
          );
          break;
        case 'Privacy Policy':
          // Navigate to privacy policy screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
          );
          break;
        case 'Help':
          // Navigate to help screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpScreen()),
          );
          break;
        case 'Logout':
          // Logout functionality
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
          break;
      }
    },
    itemBuilder: (BuildContext context) {
      return [
        const PopupMenuItem(
          value: 'Switch Account',
          child: Text('Switch Account'),
        ),
        const PopupMenuItem(
          value: 'Privacy Policy',
          child: Text('Privacy Policy'),
        ),
        const PopupMenuItem(
          value: 'Help',
          child: Text('Help'),
        ),
        const PopupMenuItem(
          value: 'Logout',
          child: Text('Logout'),
        ),
      ];
    },
  ),


        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Table(
                      border: TableBorder.all(
                        color: Colors.grey,
                        width: 1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      columnWidths: const {
                        0: FixedColumnWidth(50), // Set width for image column
                        1: FlexColumnWidth(), // Flex for text
                        2: FixedColumnWidth(50), // Set width for quantity
                        3: FixedColumnWidth(80), // Set width for total price
                      },
                      children: [
                        // Header Row
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[100], // Header background color
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Image',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Product',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Total Price (ksh)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Data Row
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.network(
                                imageUrl,
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(child: Icon(Icons.error, size: 30, color: Colors.red)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                NumberFormat('#,##0.00').format(totalPrice),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // New Row for Shipping Details
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Icon(
      Icons.local_shipping, // Icon for shipping
      color: Colors.blue,
      size: 30,
    ),
    const SizedBox(width: 8), // Space between the icon and text
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
GestureDetector(
  onTap: () async {
    // Fetch user shipping details before showing the dialog
    Map<String, String> userShippingDetails = {};

    try {
      userShippingDetails = await fetchUserShippingDetails();
    } catch (e) {
      // Handle error (e.g., show an error message)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load shipping details: ${e.toString()}'),
        ),
      );
    }

    // Create TextEditingController instances and pre-populate them with user data
    TextEditingController fullNameController = TextEditingController(text: userShippingDetails['full_name'] ?? '');
    TextEditingController addressLine1Controller = TextEditingController(text: userShippingDetails['address_line_1'] ?? '');
    TextEditingController addressLine2Controller = TextEditingController(text: userShippingDetails['address_line_2'] ?? '');
    TextEditingController cityController = TextEditingController(text: userShippingDetails['city'] ?? '');
    TextEditingController stateController = TextEditingController(text: userShippingDetails['state'] ?? '');
    TextEditingController postalCodeController = TextEditingController(text: userShippingDetails['postal_code'] ?? '');
    TextEditingController phoneNumberController = TextEditingController(text: userShippingDetails['phone_number'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.blue, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Edit Shipping Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      hintText: 'Full Name',
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.location_city, color: Colors.blue),
                            hintText: 'City',
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stateController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.map, color: Colors.blue),
                            hintText: 'State/Province',
                            labelText: 'State/Province',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressLine1Controller,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                      hintText: 'Address Line 1',
                      labelText: 'Address Line 1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressLine2Controller,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                      hintText: 'Address Line 2 (Optional)',
                      labelText: 'Address Line 2',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: postalCodeController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.local_post_office, color: Colors.blue),
                            hintText: 'Postal Code',
                            labelText: 'Postal Code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone, color: Colors.blue),
                            hintText: 'Phone Number',
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        shadowColor: Colors.red.withOpacity(0.5),
        elevation: 5,
        backgroundColor: Colors.red.shade50,
      ),
      child: const Text(
        'Cancel',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    const SizedBox(width: 16),
    ElevatedButton.icon(

// The onPressed function
onPressed: () async {
  // Get token from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');

  if (token == null) {
    // Handle missing token
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Authentication token is missing!',
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    speed: const Duration(milliseconds: 50),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return;
  }

  // Prepare the data
// Prepare the data using TextEditingController values
Map<String, dynamic> formData = {
  'full_name': fullNameController.text,
  'address_line1': addressLine1Controller.text,
  'address_line2': addressLine2Controller.text,
  'city': cityController.text,
  'state': stateController.text,
  'postal_code': postalCodeController.text,
  'phone_number': phoneNumberController.text,
};

// Print the formData to the console
print('Form Data: $formData');

  // Send data to Flask backend
  final response = await http.post(
    Uri.parse('https://expertstrials.xyz/Garifix_app/api/save_shipping_details'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode(formData),
  );

  if (response.statusCode == 200) {
    // Handle success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Shipping details saved successfully!',
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    speed: const Duration(milliseconds: 50),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
    Navigator.of(context).pop();
  } else {
    // Handle error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Failed to save shipping details!',
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    speed: const Duration(milliseconds: 50),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
},

      icon: const Icon(Icons.save, color: Colors.white),
      label: const Text(
        'Save',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        shadowColor: Colors.blue.withOpacity(0.5),
        elevation: 8,
      ),
    ),
  ],
),

            ],
          ),
        ),
      ),
    );
  },
);

            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const Text(
                'Tap here to add or edit your shipping details.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
const SizedBox(height: 16),
const Row(
  children: [
    Icon(
      Icons.payment, // Icon for payment method
      color: Colors.deepPurple,
      size: 30,
    ),
    SizedBox(width: 8), // Space between the icon and text
    Text(
      'Payment Method',
      style: TextStyle(
        fontSize: 20, // Slightly larger font size for emphasis
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
        letterSpacing: 1.2, // Adds some spacing between the letters for elegance
      ),
    ),
  ],
),
const SizedBox(height: 12),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    ElevatedButton.icon(
      onPressed: () {
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
    title: const Text(
      'Card Payment',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    ),
    content: SizedBox(
      width: 600, // Increased the width for a wider dialog
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total Amount to Pay Input Field
            TextField(
              controller: TextEditingController(
                text: NumberFormat('#,##0.00').format(totalPrice),
              ),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Total Price (Ksh)',
                labelStyle: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(Icons.attach_money, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),


            // Card Number Input Field
            TextField(
              decoration: InputDecoration(
                labelText: 'Card Number',
                prefixIcon: const Icon(Icons.credit_card, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '1234 5678 9876 5432',
                filled: true,
                fillColor: Colors.grey[200],
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Row for Expiry Date and CVV
            Row(
              children: [
                // Expiry Date Input Field
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'MM/YY',
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    keyboardType: TextInputType.datetime,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // CVV Input Field
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      prefixIcon: const Icon(Icons.security, color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '123',
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cardholder Name Input Field
            TextField(
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'John Doe',
                filled: true,
                fillColor: Colors.grey[200],
              ),
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                // Handle the form submission logic here
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ],
  ),
);

      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        elevation: 5, // Adds depth with shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(
        Icons.credit_card, // Icon for card payment
        color: Colors.white,
        size: 20,
      ),
      label: const Text(
        'Card Payment',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    ElevatedButton.icon(
      onPressed: () {
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text(
      'Payment Details',
      style: TextStyle(
        color: Colors.deepPurple,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: TextEditingController(
                text: NumberFormat('#,##0.00').format(totalPrice),
              ),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Total Price (Ksh)',
                labelStyle: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.attach_money, color: Colors.deepPurple),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(Icons.phone, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ),
actions: [
  // Cancel Button with Gradient and Custom Styling
  TextButton(
    onPressed: () {
      Navigator.pop(context);
    },
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      backgroundColor: Colors.redAccent, // Bright background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
    ).copyWith(
      overlayColor: WidgetStateProperty.all(Colors.red.shade700.withOpacity(0.1)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cancel, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text(
          'Cancel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  ),
  
  // Confirm Button with Gradient and Custom Styling
  ElevatedButton(
onPressed: () async {
  String formatPhoneNumber(String phoneNumber) {
  // Check if the phone number starts with 07 or 01
  if (phoneNumber.startsWith('07')) {
    return '254${phoneNumber.substring(1)}';
  } else if (phoneNumber.startsWith('01')) {
    return '254${phoneNumber.substring(1)}';
  } else {
    // If it doesn't start with 07 or 01, return the original number or handle as needed
    return phoneNumber;
  }
}

  String phoneNumber = phoneController.text;
  phoneNumber = formatPhoneNumber(phoneNumber);
  
  if (phoneNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter your phone number')),
    );
    return;
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String authToken = prefs.getString('jwt_token') ?? '';

  if (authToken.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Authentication token is missing')),
    );
    return;
  }

  try {
    // Log the request payload
    print('Sending payment request with payload:');
    print('Phone: $phoneNumber');
    print('Total Amount: ${totalPrice.toString()}');
    print('Quantity: ${quantity.toString()}');
    print('Product ID: ${productId.toString()}');

    final response = await http.post(
      Uri.parse('https://expertstrials.xyz/Garifix_app/make-payment'), // Replace with your Flask endpoint
      headers: {
        'Authorization': 'Bearer $authToken', // Include the token in the headers
      },
      body: {
        'phone': phoneNumber,
        'total_amount': '1',//totalPrice.toInt().toString(), // Convert to integer and then to string
        'quantity': quantity.toString(),
        'product_id': productId.toString(),
      },
    );

    // Log the response status and body
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment request sent successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send payment request')),
      );
    }
  } catch (e) {
    // Log the exception details
    print('Error occurred: ${e.toString()}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
},


    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      backgroundColor: Colors.deepPurple, // Base color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 6, // Subtle shadow for depth
    ).copyWith(
      shadowColor: WidgetStateProperty.all(Colors.deepPurple.withOpacity(0.5)),
      overlayColor: WidgetStateProperty.all(Colors.deepPurple.shade700.withOpacity(0.1)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text(
          'Confirm',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  ),
],

  ),
);

      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        elevation: 5, // Adds depth with shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(
        Icons.phone_iphone, // Icon for M-PESA payment
        color: Colors.white,
        size: 20,
      ),
      label: const Text(
        'M-PESA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MessagesSection extends StatefulWidget {
  const MessagesSection({super.key});

  @override
  _MessagesSectionState createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<MessagesSection> {
  List<Map<String, dynamic>> messages = [];
  String? selectedSender;
  final List<Map<String, dynamic>> conversation = [];
  String newMessage = '';
  String? authToken;
  String? selectedSenderName;    // Holds the receiver's name for the selected conversation
  String? selectedProfileImage;  // Holds the receiver's profile image URL for the selected conversation

 Timer? _messageFetchTimer;  // Timer to call fetchMessages periodically
Timer? _fetchMessagesTimer;
  @override
  void initState() {
    super.initState();

    // Start the timer to fetch messages every 500ms (0.5 seconds)
    _messageFetchTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _fetchMessages();
    });
  }

  Future<void> _fetchMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('jwt_token') ?? '';

    print('Auth Token: $authToken');

    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/messages'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print('Decoded Response: $data');

      if (data.containsKey('conversations') && data['conversations'] is List) {
        final List<dynamic> conversations = data['conversations'];

        // Map to store the latest message for each conversation, with unread count
        final Map<int, Map<String, dynamic>> latestMessages = {};

        for (var conversation in conversations) {
          if (conversation['messages'] is List) {
            for (var msg in conversation['messages']) {
              // Null check for 'msg' and then safely accessing keys
              final receiverId = msg?['receiver_id'];

              if (receiverId != null) {
                // Update to keep only the latest message per receiver
                latestMessages[receiverId] = msg;

                // Add a new key for unread count
                final unreadCount = conversation['messages']
                    .where((message) => message?['is_read'] == false)
                    .length;

                latestMessages[receiverId]?['unread_count'] = unreadCount;
              }
            }
          }
        }

        setState(() {
          messages = latestMessages.values.map((msg) {
            return {
              'id': msg['id'] ?? 0, // Provide default if null
              'message': msg['message'] ?? '', // Default empty string
              'receiver_id': msg['receiver_id'] ?? 0, // Default 0 if null
              'receiver_name': msg['receiver_name'] ?? '', // Default empty string
              'receiver_profile_image': msg['sender_profile_image'] != null
                  ? 'https://expertstrials.xyz/Garifix_app/${msg['sender_profile_image']}'
                  : 'https://expertstrials.xyz/Garifix_app/default_image.png',
              'sender_id': msg['sender_id'] ?? 0, // Default 0 if null
              'timestamp': msg['timestamp'] ?? '', // Default empty string
              'read': msg['is_read'] ?? false, // Default to false
              'unread_count': msg['unread_count'] ?? 0, // Unread count, default to 0
            };
          }).toList();
        });
      } else {
        print('Conversations key not found or is not a list.');
      }
    } else {
      print('Failed to load messages: ${response.body}');
    }
  }

  @override
  void dispose() {
    super.dispose();

    // Cancel the timer when the widget is disposed
    _messageFetchTimer?.cancel();
  }



  void sendMessage() {  
    if (newMessage.isNotEmpty) {
      // Create a method to send the message to your backend
      _sendMessage(newMessage, selectedSender);
    }
  }

  Future<void> _sendMessage(String messageText, String? receiverId) async {
    if (receiverId != null && messageText.isNotEmpty) {
      final response = await http.post(
        Uri.parse('https://expertstrials.xyz/Garifix_app/send'), // Update with your API URL
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'id': receiverId,
          'message': messageText,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          conversation.add({
            'avatar': 'https://via.placeholder.com/50', // Placeholder for the current user
            'sender': 'You',
            'text': messageText,
            'time': TimeOfDay.now().format(context),
            'read': true,
          });
          newMessage = ''; // Clear the input field after sending
        });
      } else {
        // Handle error appropriately
        print('Failed to send message: ${response.body}');
      }
    }
  }

void toggleConversation(String receiverId, String receiverName, String profileImage) {
  if (selectedSender == receiverId) {
    setState(() {
      selectedSender = null;           // Hide the conversation if the same sender is clicked
      selectedSenderName = null;       // Reset selected name
      selectedProfileImage = null;     // Reset profile image
      conversation.clear();            // Clear conversation history
    });

    // Cancel the timer when closing the conversation
    _fetchMessagesTimer?.cancel();
  } else {
    setState(() {
      selectedSender = receiverId;     // Set selected sender by ID
      selectedSenderName = receiverName;  // Set selected sender's name
      selectedProfileImage = profileImage; // Set selected profile image
      conversation.clear();            // Clear previous messages
    });

    _fetchConversation(receiverId);    // Fetch conversation based on ID

    // Start periodic fetching of the conversation
    _startPeriodicFetch(receiverId);
  }
}

// Start a periodic timer to fetch messages every half second
void _startPeriodicFetch(String receiverId) {
  _fetchMessagesTimer?.cancel();  // Cancel any existing timer before starting a new one

  _fetchMessagesTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
    _fetchConversation(receiverId);  // Fetch the conversation every 500ms
  });
}

Future<void> _fetchConversation(String sender) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('jwt_token') ?? '';

  print("Auth Token: $authToken");

  final response = await http.get(
    Uri.parse('https://expertstrials.xyz/Garifix_app/get_messages/$sender'),
    headers: {
      'Authorization': 'Bearer $authToken',
    },
  );

  print("Response Status Code: ${response.statusCode}");
  print("Response Body: ${response.body}");

  if (response.statusCode == 200) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);
      print("Response Data: $data");

      if (data.containsKey('conversations') && data['conversations'] is List) {
        final List<dynamic> conversations = data['conversations'];

        setState(() {
          conversation.clear(); // Clear existing messages before adding new ones.

          for (var conv in conversations) {
            if (conv.containsKey('messages') && conv['messages'] is List) {
              final List<dynamic> fetchedMessages = conv['messages'];

              conversation.addAll(fetchedMessages.map((msg) {
                return {
                  'id': msg['id'] ?? 0,
                  'message': msg['message'] ?? '',
                  'receiver_id': msg['receiver_id'] ?? 0,
                  'receiver_name': msg['receiver_name'] ?? '',
                  'receiver_profile_image': msg['sender_profile_image'] != null
                      ? 'https://expertstrials.xyz/Garifix_app/${msg['sender_profile_image']}'
                      : 'https://expertstrials.xyz/Garifix_app/default_image.png',
                  'sender_id': msg['sender_id'] ?? 0,
                  'timestamp': msg['timestamp'] ?? '',
                  'read': msg['is_read'] ?? false,
                };
              }).toList());
            }
          }
        });
      } else {
        print("Conversations key not found or it's not a list.");
      }
    } catch (e) {
      print("Error decoding response: $e");
    }
  } else {
    print('Failed to load conversation for $sender. Status Code: ${response.statusCode}');
  }
}




@override
Widget build(BuildContext context) {
  return Scaffold(
appBar: selectedSender != null
    ? AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 4,
        title: Row(
          children: [
            // Profile image of the selected receiver
            CircleAvatar(
              backgroundImage: NetworkImage(
                selectedProfileImage ?? 'default_image.png', // Default image if profile is not set
              ),
              radius: 20,
            ),
            const SizedBox(width: 10), // Spacing between image and text

            // Column to show receiver's name and last seen information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedSenderName ?? 'Unknown', // Display receiver's name or fallback to 'Unknown'
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Last seen: 10:32 AM', // Static text for now; replace with dynamic last seen data if available
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Optional Icon button for additional options
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // Additional functionality can be added here
              },
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              selectedSender = null;           // Clear selected sender
              selectedSenderName = null;       // Clear selected name
              selectedProfileImage = null;     // Clear selected profile image
              conversation.clear();            // Clear conversation history
            });
          },
        ),
      )
    : null,

    body: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Expanded(
            child: selectedSender == null
                ? ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return GestureDetector(
      onTap: () {
        // Pass receiver_id, receiver_name, and receiver_profile_image
        toggleConversation(
          message['receiver_id'].toString(),
          message['receiver_name'] ?? 'Unknown',
          message['receiver_profile_image'] ?? 'default_image.png',
        );
      },
                        child: MessageCard(
                          avatar: message['receiver_profile_image'] ?? 'default_image.png', // Display receiver's profile image
                          sender: message['receiver_name'] ?? 'Unknown', // Display receiver's name
                          text: message['message'] ?? '', // Use empty string as default for message text
                          time: message['timestamp'] ?? '', // Use empty string as default for timestamp
                          isRead: message['read'] ?? false, // Default to false
                          unreadCount: message['unread_count'], // Display unread count for the conversation
                        ),
                      );
                    },
                  )
                : _buildDMConversation(), // Show direct messages if selectedSender is set
          ),
        ],
      ),
    ),
  );
}


Widget _buildDMConversation() {
  return Column(
    children: [
      Expanded(
        child: ListView.builder(
          itemCount: conversation.length,
          itemBuilder: (context, index) {
            final message = conversation[index];
            return MessageCard(
              avatar: message['receiver_profile_image'] ?? 'default_image.png',
              sender: 'you', // Set the sender to the word "you"
              text: message['message'] ?? '',
              time: message['timestamp'] ?? '',
              isRead: message['read'] ?? false,
              unreadCount: 0, // No unread count in DM
            );
          },
        ),
      ),
      _buildMessageInput(), // Message input at the bottom
    ],
  );
}



  Widget _buildMessageInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              setState(() {
                newMessage = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Type a message...',
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.message, color: Colors.deepPurple),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.deepPurple),
          onPressed: sendMessage,
        ),
      ],
    );
  }

  int _getUnreadCount() {
    return messages.where((msg) => !msg['is_read']).length;
  }
}

class MessageCard extends StatelessWidget {
  final String avatar;
  final String sender;
  final String text;
  final String time;
  final bool isRead;
  final int unreadCount;

  const MessageCard({
    super.key,
    required this.avatar,
    required this.sender,
    required this.text,
    required this.time,
    required this.isRead,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(avatar),
            radius: 25,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRead ? Colors.white : Colors.lightBlueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sender,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRead ? Colors.deepPurple : Colors.blue,
                        ),
                      ),
                      if (unreadCount > 0)
                        CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 12,
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(text),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class ExploreSection extends StatelessWidget {
  const ExploreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.pinkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative shapes
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnimatedText(),
                const SizedBox(height: 20),
                const Text(
                  'We are working on something amazing!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Stay tuned for updates!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Optional: Add a button or link
                ElevatedButton(
                  onPressed: () {
                    // Add your functionality here (e.g., subscribe, back to home)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber, // Primary button color
                    foregroundColor: Colors.black, // Text color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Notify Me'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedText extends StatefulWidget {
  const AnimatedText({super.key});

  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: const Text(
        'Coming Soon!',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(2, 2),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<Map<String, dynamic>> orders = [
    {'id': 1, 'status': 'Delivered', 'buyer': 'Alice', 'amount': 200.0, 'date': '2024-12-10', 'product': 'Laptop'},
    {'id': 2, 'status': 'Pending', 'buyer': 'Bob', 'amount': 350.0, 'date': '2024-12-11', 'product': 'Smartphone'},
    {'id': 3, 'status': 'Canceled', 'buyer': 'Charlie', 'amount': 150.0, 'date': '2024-12-09', 'product': 'Headphones'},
    {'id': 4, 'status': 'Delivered', 'buyer': 'David', 'amount': 400.0, 'date': '2024-12-08', 'product': 'Tablet'},
    {'id': 5, 'status': 'Pending', 'buyer': 'Eve', 'amount': 220.0, 'date': '2024-12-07', 'product': 'Camera'},
  ];

  String selectedFilter = 'All';
  DateTimeRange? dateRange;

  // Filter orders based on selected filter and date range
  List<Map<String, dynamic>> get filteredOrders {
    List<Map<String, dynamic>> filtered = selectedFilter == 'All'
        ? orders
        : orders.where((order) => order['status'] == selectedFilter).toList();

    if (dateRange != null) {
      filtered = filtered.where((order) {
        DateTime orderDate = DateTime.parse(order['date']);
        return orderDate.isAfter(dateRange!.start.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  void downloadPdf(String status) {
    // TODO: Implement PDF generation and download logic
    print('Downloading PDF for $status orders');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => downloadPdf(selectedFilter),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: selectedFilter == 'All',
                    onSelected: (bool selected) {
                      setState(() => selectedFilter = 'All');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Delivered'),
                    selected: selectedFilter == 'Delivered',
                    onSelected: (bool selected) {
                      setState(() => selectedFilter = 'Delivered');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: selectedFilter == 'Pending',
                    onSelected: (bool selected) {
                      setState(() => selectedFilter = 'Pending');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Canceled'),
                    selected: selectedFilter == 'Canceled',
                    onSelected: (bool selected) {
                      setState(() => selectedFilter = 'Canceled');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date Range Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateRange == null
                      ? 'Select Date Range'
                      : '${dateRange!.start.toLocal()} - ${dateRange!.end.toLocal()}'.split(' ')[0],
                  style: const TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => dateRange = picked);
                    }
                  },
                  child: const Text('Pick Date'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Orders List
            Expanded(
              child: filteredOrders.isEmpty
                  ? const Center(
                      child: Text('No orders found for the selected filter.'),
                    )
                  : ListView.builder(
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${order['id']} - ${order['product']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Buyer: ${order['buyer']}'),
                                Text('Amount: \$${order['amount']}'),
                                Text('Status: ${order['status']}'),
                                Text('Date: ${order['date']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDetails {
  final int id;
  final String fullName;
  final String email;
  final String? profilePicture;
  final String? role;

  UserDetails({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePicture,
    this.role,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      role: json['role'],
    );
  }
}

Future<List<UserDetails>?> fetchUserDetails() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');

  if (token == null) {
    print("Token is missing");
    return null;
  }

  try {
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/get-user-details'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Extract the list of accounts from the response
      final List<dynamic> accountsData = jsonResponse['data'];
      return accountsData.map((data) => UserDetails.fromJson(data)).toList();
    } else {
      print("Failed to fetch user details: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Error occurred while fetching user details: $e");
    return null;
  }
}


class SwitchAccountScreen extends StatelessWidget {
  const SwitchAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        logoPath: 'assets/logo/app_logo.png',
        title: 'Switch Account',
      ),
body: FutureBuilder<List<UserDetails>?>(
  future: fetchUserDetails(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(
        child: Text('Error: ${snapshot.error}'),
      );
    } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
      return const Center(child: Text('No user accounts found'));
    } else {
      final users = snapshot.data!;
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return GestureDetector(
                    onTap: () async {
                      // Clear and set new account data in SharedPreferences
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.remove('userEmail');
                      await prefs.remove('user_role');
                      await prefs.remove('jwt_token');

                      await prefs.setString('userEmail', user.email);
                      await prefs.setString('user_role', user.role ?? '');

                      // Navigate to the login screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: user.profilePicture != null
                                  ? NetworkImage('https://expertstrials.xyz/Garifix_app/${user.profilePicture}')
                                  : const AssetImage('assets/logo/account.jpg') as ImageProvider,
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (user.role != null)
                                    Text(
                                      'Role: ${user.role}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Navigate to the SignUpScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text(
                'Add New Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  },
),

    );
  }
}




class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        logoPath: 'assets/logo/app_logo.png',
        title: 'Privacy Policy',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              context,
              FontAwesomeIcons.shieldAlt,
              'Our Commitment',
              'Your trust matters to us. We prioritize safeguarding your personal information and ensuring transparency.',
            ),

            _buildSection(
              context,
              FontAwesomeIcons.database,
              'Data We Collect',
              'Personal details you share (name, email, phone) and technical data (IP address, usage stats) for improving your experience.',
            ),

            _buildSection(
              context,
              FontAwesomeIcons.userCheck,
              'How We Use Data',
              'We enhance your experience and protect the platform. Your data helps us personalize services and ensure security.',
            ),

            _buildSection(
              context,
              FontAwesomeIcons.peopleArrows,
              'Sharing Your Information',
              'We don’t sell your data. Limited sharing occurs with trusted partners or when required by law.',
            ),

            _buildSection(
              context,
              FontAwesomeIcons.userShield,
              'Your Rights',
              'Access, update, or delete your data anytime. Adjust your preferences or contact support for help.',
            ),

            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(FontAwesomeIcons.infoCircle, color: Colors.blueAccent, size: 28),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'For more details, visit our website or contact support.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, IconData icon, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}





class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        logoPath: 'assets/logo/app_logo.png',
        title: 'Help',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How Can We Help You?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),

            // Frequently Asked Questions Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    ExpansionTile(
                      leading: Icon(Icons.question_answer, color: Colors.blue),
                      title: Text('How do I reset my password?'),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Go to the login page and click on "Forgot Password". Follow the instructions sent to your email.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Icon(Icons.question_answer, color: Colors.blue),
                      title: Text('Where can I find my account settings?'),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Navigate to the "Settings" section in your profile menu to manage your account preferences.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Icon(Icons.question_answer, color: Colors.blue),
                      title: Text('Who can I contact for support?'),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'You can contact our support team by using the chat feature below or emailing us at support@example.com.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contact Support Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.green),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Email: support@example.com',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.orange),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Phone: +123 456 7890',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        label: const Text('Chat Assistant'),
        icon: const Icon(Icons.chat),
      ),
    );
  }
}



class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat Assistant',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4.0,
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: const [
                ChatBubble(
                  text: 'Hi! How can I assist you today?',
                  isUser: false,
                ),
                ChatBubble(
                  text: 'I need help with my account settings.',
                  isUser: true,
                ),
                ChatBubble(
                  text: 'Sure! What specifically would you like to know?',
                  isUser: false,
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1.0),

          // Message input area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {
                    // Handle message sending
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({required this.text, required this.isUser, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12.0),
            topRight: const Radius.circular(12.0),
            bottomLeft: Radius.circular(isUser ? 12.0 : 0.0),
            bottomRight: Radius.circular(isUser ? 0.0 : 12.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.black87 : Colors.black54,
            fontSize: 15.0,
          ),
        ),
      ),
    );
  }
}




class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String logoPath;
  final String title;

  const CustomAppBar({super.key, required this.logoPath, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      automaticallyImplyLeading: false, // Removes the left arrow
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Aligns content to the left
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Image.asset(
              logoPath, // Dynamic logo path
              height: 50,
              width: 50,
            ),
          ),
          const SizedBox(width: 15), // Space between logo and title
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Color.fromARGB(255, 255, 171, 64), Colors.yellow],
                tileMode: TileMode.mirror,
              ).createShader(bounds);
            },
            child: Text(
              title, // Dynamic title
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 2.0),
                    blurRadius: 3.0,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings, color: Colors.white),
          onSelected: (String value) async {
            switch (value) {
              case 'Switch Account':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SwitchAccountScreen()),
                );
                break;
              case 'Privacy Policy':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
                break;
              case 'Help':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
                break;
              case 'Logout':
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem(value: 'Switch Account', child: Text('Switch Account')),
              const PopupMenuItem(value: 'Privacy Policy', child: Text('Privacy Policy')),
              const PopupMenuItem(value: 'Help', child: Text('Help')),
              const PopupMenuItem(value: 'Logout', child: Text('Logout')),
            ];
          },
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
          onPressed: () async {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ],
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  // Mock data for user profile
  String userName = "John Doe";
  String userEmail = "johndoe@example.com";
  String userPhone = "+1234567890";
  File? profileImage;

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });

      // Automatically upload the profile data after selecting a new image
      await _uploadProfileData(); // Upload the new profile image
    }
  }

  // Method to upload the profile data
  Future<void> _uploadProfileData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      // Handle error if token is not found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://expertstrials.xyz/Garifix_app/update_profile'),
    );

    // Add token to the headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add the image file
    if (profileImage != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', profileImage!.path));
    }

    // Add additional user data
    request.fields['name'] = userName;
    request.fields['email'] = userEmail;
    request.fields['phone'] = userPhone;

    // Send the request
    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await http.Response.fromStream(response);
        final Map<String, dynamic> responseData = jsonDecode(responseBody.body);

        if (responseData['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Failed to update profile: ${responseData['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false, // This removes the left arrow
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.start, // Aligns content to the far left
          children: [
            // Logo with a subtle glow effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/app_logo.png', // Path to the Mecar logo
                height: 50,
                width: 50,
              ),
            ),
            const SizedBox(width: 15), // Space between logo and name
            // Gradient text for the company name
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color.fromARGB(255, 255, 171, 64), Colors.yellow],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'Mecar',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
actions: [
  PopupMenuButton<String>(
    icon: const Icon(Icons.settings, color: Colors.white),
    onSelected: (String value) async {
      // Handle menu selection
      switch (value) {
        case 'Switch Account':
          // Navigate to switch account screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SwitchAccountScreen()),
          );
          break;
        case 'Privacy Policy':
          // Navigate to privacy policy screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
          );
          break;
        case 'Help':
          // Navigate to help screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpScreen()),
          );
          break;
        case 'Logout':
          // Logout functionality
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
          break;
      }
    },
    itemBuilder: (BuildContext context) {
      return [
        const PopupMenuItem(
          value: 'Switch Account',
          child: Text('Switch Account'),
        ),
        const PopupMenuItem(
          value: 'Privacy Policy',
          child: Text('Privacy Policy'),
        ),
        const PopupMenuItem(
          value: 'Help',
          child: Text('Help'),
        ),
        const PopupMenuItem(
          value: 'Logout',
          child: Text('Logout'),
        ),
      ];
    },
  ),


IconButton(
  icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
  onPressed: () async {
    // Navigate to LoginScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  },
),

        ],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture and name
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage, // Tap to change the profile picture
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : const AssetImage("assets/profile_placeholder.png")
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Profile details section
            _buildProfileDetail("Email", userEmail),
            _buildProfileDetail("Phone", userPhone),
            const SizedBox(height: 30),

            // Edit button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showEditProfileDialog(context);
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text("Edit Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display each profile detail
  Widget _buildProfileDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const Divider(),
      ],
    );
  }

  // Method to show the Edit Profile Dialog
  void _showEditProfileDialog(BuildContext context) {
    final TextEditingController nameController =
        TextEditingController(text: userName);
    final TextEditingController emailController =
        TextEditingController(text: userEmail);
    final TextEditingController phoneController =
        TextEditingController(text: userPhone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Edit Profile"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField("Name", nameController),
                _buildTextField("Email", emailController),
                _buildTextField("Phone", phoneController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                // Update user profile details
                setState(() {
                  userName = nameController.text;
                  userEmail = emailController.text;
                  userPhone = phoneController.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Method to build text fields for the edit dialog
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
}
