import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:geocoding/geocoding.dart';
// Import shared_preferences
import 'post.dart'; // Make sure to import the Post model

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

// Placeholder screens for navigation tabs
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
          // Animated search icon on the far right
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: 28,
            color: Colors.white,
            splashRadius: 25,
            onPressed: () {
              // Implement search functionality here
            },
            tooltip: 'Search', // Tooltip on hover for better UX
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
                icon: Icon(Icons.explore),
                label: 'Explore',
              ),
            ],
            currentIndex: _selectedNavIndex,
            selectedItemColor:
                const Color.fromARGB(255, 255, 171, 64), // Single color
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
                                mechanicName: post.fullName,
                                description: post.description,
                                datePosted: post.createdAt.toString(),
                                imagePath:
                                    'https://expertstrials.xyz/Garifix_app/${post.imagePath}',
                                userProfilePic:
                                    'https://expertstrials.xyz/Garifix_app/${post.profileImage}' ??
                                        'assets/default_user.png',
                                location: locationText,
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token'); // Get the JWT token

    // Define the URL for your Flask backend
    const String url =
        'https://expertstrials.xyz/Garifix_app/api/posts'; // Adjust the endpoint accordingly

    // Prepare the request
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['description'] = description
      ..headers['Authorization'] =
          'Bearer $token'; // Add the JWT token in the headers

    if (imagePath != null) {
      // Attach the image file if it exists
      final imageFile = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(imageFile);
    }

    // Send the request
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print('Post created successfully');
        // Show success dialog or SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      } else {
        print('Failed to create post: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post!')),
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while creating the post!')),
      );
    }
  }

  Widget _buildExplorePost({
    required String mechanicName,
    required String description,
    required String datePosted,
    required String imagePath,
    required String userProfilePic,
    required String location,
  }) {
    int likeCount = 0;
    bool isLiked = false;
    bool isSaved = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                                : 'https://example.com/default_user.png', // Default image URL if needed
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
                                  likeCount += isLiked ? 1 : -1;
                                });
                              },
                            ),
                            Text(likeCount.toString()),
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

  @override
  void initState() {
    super.initState();
    _initializeProducts(); // Call the data initializer
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
    print("Making API request...");
    final response = await http
        .get(Uri.parse('https://expertstrials.xyz/Garifix_app/api/products'));

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
          List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
          String address = placemarks.isNotEmpty ? placemarks.first.street ?? 'Address not found' : 'Address not found';
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

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String description;
  final String companyName;
  final String location;

  const ProductCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.description,
    required this.companyName,
    required this.location,
    super.key,
  });

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
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(imageUrl),
                  onBackgroundImageError: (error, stackTrace) =>
                      const Icon(Icons.error),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        location,
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
                    imageUrl,
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
              title,
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
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              price,
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
                    // Implement buy functionality
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
                    // Implement message functionality
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border,
                      color: Colors.deepPurple),
                  onPressed: () {
                    // Implement wishlist functionality
                  },
                ),
              ],
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
  final List<Map<String, dynamic>> messages = [
    {
      'avatar':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTzly6IVaAUXTkRvHgdnUelmf8VNvXTUHW32w&s',
      'sender': 'John Doe',
      'text': 'Hey! How are you doing?',
      'time': '10:30 AM',
      'read': false,
    },
    {
      'avatar':
          'https://www.singulart.com/blog/wp-content/uploads/2023/10/Famous-Portrait-Paintings-848x530-1.jpg',
      'sender': 'Jane Smith',
      'text': 'Just wanted to check in!',
      'time': '10:31 AM',
      'read': true,
    },
    {
      'avatar': 'https://i.insider.com/5d2ce2b7b44ce742214c1007?width=700',
      'sender': 'Alex Johnson',
      'text': 'Did you get my last message?',
      'time': '10:32 AM',
      'read': false,
    },
    // Add more messages as needed...
  ];

  String? selectedSender; // Track the selected sender
  final List<Map<String, dynamic>> conversation =
      []; // Track conversation messages
  String newMessage = '';

  void sendMessage() {
    if (newMessage.isNotEmpty) {
      setState(() {
        conversation.add({
          'avatar':
              'https://via.placeholder.com/50', // Placeholder for the current user
          'sender': 'You',
          'text': newMessage,
          'time': TimeOfDay.now().format(context),
          'read': true, // Marking the sent message as read
        });
        newMessage = ''; // Clear the input field after sending
      });
    }
  }

  void toggleConversation(String sender) {
    if (selectedSender == sender) {
      setState(() {
        selectedSender =
            null; // Hide the conversation if the same sender is clicked
      });
    } else {
      setState(() {
        selectedSender =
            sender; // Show the conversation for the selected sender
        conversation.clear(); // Clear previous messages for a new conversation
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedSender != null
          ? AppBar(
              backgroundColor: Colors.deepPurpleAccent,
              elevation: 4, // Adds shadow effect
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      messages.firstWhere(
                          (msg) => msg['sender'] == selectedSender)['avatar'],
                    ),
                    radius: 25,
                  ),
                  const SizedBox(
                      width: 10), // Increased space for better layout
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSender!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18, // Increased font size
                            color:
                                Colors.white, // Changed text color for contrast
                          ),
                        ),
                        const Text(
                          'Last seen: 10:32 AM',
                          style: TextStyle(
                            fontSize: 14, // Slightly increased font size
                            color: Colors
                                .white70, // Lighter color for the last seen text
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white), // More options button
                    onPressed: () {
                      // Add your functionality here
                    },
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white), // Back button
                onPressed: () {
                  setState(() {
                    selectedSender = null; // Go back to messages
                    conversation
                        .clear(); // Clear the conversation when going back
                  });
                },
              ),
            )
          : null, // No AppBar when no DM is active
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Show the list of messages or DM conversation
            Expanded(
              child: selectedSender ==
                      null // Check if there's a selected sender
                  ? ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return GestureDetector(
                          onTap: () {
                            toggleConversation(message['sender']);
                          },
                          child: MessageCard(
                            avatar: message['avatar'],
                            sender: message['sender'],
                            text: message['text'],
                            time: message['time'],
                            isRead: message['read'], // Pass read status
                            unreadCount: _getUnreadCount(), // Pass unread count
                          ),
                        );
                      },
                    )
                  : _buildDMConversation(),
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
                avatar: message['avatar'],
                sender: message['sender'],
                text: message['text'],
                time: message['time'],
                isRead: message['read'], // Pass read status
                unreadCount: 0, // No unread count in DM
              );
            },
          ),
        ),
        _buildMessageInput(),
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
    return messages
        .where((msg) => !msg['read'])
        .length; // Count unread messages
  }
}

class MessageCard extends StatelessWidget {
  final String avatar;
  final String sender;
  final String text;
  final String time;
  final bool isRead; // New parameter for read status
  final int unreadCount; // New parameter for unread count

  const MessageCard({
    super.key,
    required this.avatar,
    required this.sender,
    required this.text,
    required this.time,
    required this.isRead, // Add read status parameter
    required this.unreadCount, // Add unread count parameter
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
                color: isRead
                    ? Colors.white
                    : Colors.lightBlueAccent.withOpacity(
                        0.1), // Different color for unread messages
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
                          color: isRead
                              ? Colors.deepPurple
                              : Colors.blue, // Change color for unread
                        ),
                      ),
                      // Display unread message count if greater than 0
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

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Orders Screen"));
  }
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
        title: const Text("Your Profile"),
        backgroundColor: Colors.deepPurpleAccent,
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