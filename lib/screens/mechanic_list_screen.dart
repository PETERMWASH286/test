import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:image_picker/image_picker.dart'; // For image selection
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome
import 'package:mobile_scanner/mobile_scanner.dart'; // Make sure to import the MobileScanner package

class MechanicListScreen extends StatefulWidget {
  const MechanicListScreen({super.key});

  @override
  _MechanicListScreenState createState() => _MechanicListScreenState();
}

class _MechanicListScreenState extends State<MechanicListScreen> {
  List<dynamic> mechanics = [];
  int _selectedIndex = 0;
  String _userLocationName = '';
  String? userEmail; // Variable to hold user email
  Position? _previousPosition; // Variable to hold the previous location

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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
        content: const SingleChildScrollView( // Added to avoid overflow issues
          child: Text(
            'To show carowners near you, please allow location access.',
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


static final List<Widget> _bottomNavPages = <Widget>[
  const MechanicHomePage(), // Correct replacement
  const JobsPage(),
  const MessagesPage(),
  const ProfilePage(),
];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bottomNavPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Home',
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

class MechanicHomePage extends StatefulWidget {
  const MechanicHomePage({super.key});

  @override
  _MechanicHomePageState createState() => _MechanicHomePageState();
}

class _MechanicHomePageState extends State<MechanicHomePage> {
  String _userLocationName = 'Fetching location...'; // Default value

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _userLocationName = '${place.locality}, ${place.country}'; // Update location
      });
    } catch (e) {
      setState(() {
        _userLocationName = 'Location not available'; // Handle error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mechanic Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, size: 28), // Notification Icon
            tooltip: 'Notifications',
            onPressed: () {
              // Handle notification tap
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 28), // Settings Icon
            tooltip: 'Settings',
            onPressed: () {
              // Handle settings tap
            },
          ),
          const SizedBox(width: 10), // Add some space between icons
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMechanicInfo(context), // Pass the context here
            const SizedBox(height: 20),
            _buildStatsRow(), // Statistics section
            const SizedBox(height: 20),
            _buildRecentReviews(), // Recent reviews section
            const SizedBox(height: 20),
            _buildDailySchedule(), // Mechanic's daily schedule
            const SizedBox(height: 20),
            _buildToolsInventory(), // Tools inventory status
            const SizedBox(height: 20),
            _buildWorkshopStatus(), // Current workshop workload
            const SizedBox(height: 20),
            _buildNotifications(), // Notifications and alerts for urgent jobs
          ],
        ),
      ),
    );
  }

// Mechanic Info Section (Name, Specialization)
Widget _buildMechanicInfo(BuildContext context) {
  return Container(
    width: MediaQuery.of(context).size.width * 1, // Set width to 95% of the parent
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Increased vertical padding
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.deepPurple, Colors.purpleAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12), // Rounded corners
      boxShadow: const [
        BoxShadow(
          color: Colors.black26, // Shadow color
          offset: Offset(0, 4), // Shadow offset
          blurRadius: 8, // Blur radius
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'John Doe - Auto Mechanic',
          style: TextStyle(
            fontSize: 22, // Increased font size
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6), // Increased height for better spacing
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between items
          children: [
            // Experience Text
            const Text(
              'Experience: 10+ years',
              style: TextStyle(
                fontSize: 12, // Kept font size for experience
                color: Colors.white70,
              ),
            ),
            // Location Text
            Text(
              _userLocationName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


// Build the Stats Row
Widget _buildStatsRow() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildStatCard(
        icon: Icons.work,
        value: '120', // Replace with dynamic data if available
        title: 'Jobs', // Title for the Jobs card
        height: 80, // Increased height for the Jobs card
      ),
      _buildStatCard(
        icon: Icons.star,
        rating: 4.5, // Pass the rating value as a double
        width: 120,  // Custom width for the star rating card
        height: 80, // Increased height for the Ratings card
        title: 'Ratings', // Title for the Ratings card
      ),
      _buildStatCard(
        icon: Icons.people,
        value: '300', // Replace with dynamic data if available
        title: 'Customers', // Title for the Customers card
        height: 80, // Increased height for the Customers card
      ),
    ],
  );
}

// Build individual Stat Card
Widget _buildStatCard({
  required IconData icon,
  String? value,
  double? rating,
  double width = 80,
  double height = 60, // Default height value
  required String title, // New title parameter
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Container(
      padding: const EdgeInsets.all(8), // Adjusted padding for a better fit
      width: width, // Use the passed width parameter
      height: height, // Use the passed height parameter
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
        children: [
          Icon(icon, size: 24, color: Colors.deepPurple), // Increased icon size
          const SizedBox(height: 0), // Space between icon and title
          Text(
            title, // Display the title
            style: const TextStyle(fontSize: 11, color: Colors.deepPurple, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 0), // Space between title and content
          if (rating != null) ...[
            _buildStarRating(rating), // Display stars if rating is provided
          ] else if (value != null) ...[
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.deepPurple, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

// Method to build star rating with value
Widget _buildStarRating(double rating) {
  List<Widget> stars = [];
  int fullStars = rating.floor(); // Number of full stars
  double fractionalPart = rating - fullStars; // Fractional part of the rating
  double starSize = 12.0; // Size of each star

  // Create full stars
  for (int i = 0; i < fullStars; i++) {
    stars.add(Icon(Icons.star, size: starSize, color: Colors.yellow));
  }

  // Create half star if applicable
  if (fractionalPart >= 0.25 && fractionalPart < 0.75) {
    stars.add(Icon(Icons.star_half, size: starSize, color: Colors.yellow));
  } else if (fractionalPart >= 0.75) {
    stars.add(Icon(Icons.star, size: starSize, color: Colors.yellow));
  }

  // Fill the remaining stars with empty stars
  for (int i = fullStars + (fractionalPart >= 0.75 ? 1 : 0); i < 5; i++) {
    stars.add(Icon(Icons.star_border, size: starSize, color: Colors.yellow));
  }

  // Add the rating value next to the stars
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        children: stars,
      ),
      const SizedBox(width: 4), // Space between stars and rating text
      Text(
        rating.toStringAsFixed(1), // Format rating to one decimal place
        style: const TextStyle(fontSize: 16, color: Colors.deepPurple, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

  // Recent Reviews Section
  Widget _buildRecentReviews() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Reviews',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildReview('Alice Johnson', 'Great service! Highly recommend!', 5),
          _buildReview('Bob Smith', 'Very knowledgeable and quick.', 4),
          _buildReview('Charlie Brown', 'Satisfactory work, could improve communication.', 3),
        ],
      ),
    );
  }

  // Review Widget
  Widget _buildReview(String customerName, String feedback, int rating) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple, // Display first letter of the customer's name
          foregroundColor: Colors.white,
          child: Text(customerName[0]),
        ),
        title: Text(customerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feedback),
            Row(
              children: List.generate(rating, (index) => const Icon(Icons.star, color: Colors.yellow)),
            ),
          ],
        ),
      ),
    );
  }
  // Daily Schedule Section
  Widget _buildDailySchedule() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Schedule',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildScheduleItem('9:00 AM - Engine Repair - Toyota Corolla'),
          _buildScheduleItem('11:00 AM - Brake Inspection - Honda Civic'),
          _buildScheduleItem('2:00 PM - Diagnostics - Ford F-150'),
        ],
      ),
    );
  }

  // Schedule Item for daily tasks
  Widget _buildScheduleItem(String task) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.deepPurple),
        title: Text(task),
      ),
    );
  }

  // Tools Inventory Section to track tools usage
  Widget _buildToolsInventory() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tools Inventory',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildToolStatus('Wrench Set', 'Available'),
          _buildToolStatus('Hydraulic Jack', 'In Use'),
          _buildToolStatus('Tire Pressure Gauge', 'Available'),
          _buildToolStatus('Diagnostic Scanner', 'In Use'),
        ],
      ),
    );
  }

  // Tool Status Widget
  Widget _buildToolStatus(String tool, String status) {
    return ListTile(
      leading: Icon(
        status == 'Available' ? Icons.check_circle_outline : Icons.warning,
        color: status == 'Available' ? Colors.green : Colors.orange,
      ),
      title: Text(tool),
      trailing: Text(
        status,
        style: TextStyle(
          color: status == 'Available' ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  // Workshop Status Section (e.g., workload)
  Widget _buildWorkshopStatus() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Workshop Status',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildWorkshopLoad('Engine Bay', 'Occupied - 2 vehicles'),
          _buildWorkshopLoad('Lift Station', 'Available'),
          _buildWorkshopLoad('Tire Bay', 'Occupied - 1 vehicle'),
        ],
      ),
    );
  }

  // Workshop Load Widget
  Widget _buildWorkshopLoad(String section, String status) {
    return ListTile(
      leading: Icon(
        status.contains('Available') ? Icons.check_circle : Icons.error_outline,
        color: status.contains('Available') ? Colors.green : Colors.red,
      ),
      title: Text(section),
      subtitle: Text(status),
    );
  }

  // Notifications Section
  Widget _buildNotifications() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications & Alerts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.red),
              title: Text('Urgent: Brake fluid refill needed for Honda Civic'),
              subtitle: Text('Scheduled for 11:00 AM today'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.error_outline, color: Colors.orange),
              title: Text('Reminder: Diagnostics due for Ford F-150'),
              subtitle: Text('Scheduled for 2:00 PM'),
            ),
          ),
        ],
      ),
    );
  }

}






class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  _JobsPageState createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  bool isScanning = false; // QR code scanning state
  String qrData = '';
  TextEditingController nextRepairDateController = TextEditingController();

  // Dummy job data for static job history
  final List<Map<String, dynamic>> jobs = [
    {
      'title': 'Fix Car Engine',
      'description': 'Repair the engine of a Toyota Corolla.',
      'rating': 4.5,
      'date': '2024-09-21'
    },
    {
      'title': 'Replace Brakes',
      'description': 'Replace brake pads for a Ford Mustang.',
      'rating': 3.8,
      'date': '2024-08-14'
    },
    {
      'title': 'Oil Change',
      'description': 'Change oil for Honda Civic.',
      'rating': 4.2,
      'date': '2024-07-10'
    },
  ];

// QR Code scan function
void _onQRCodeScanned(String qrData) async {
  setState(() {
    this.qrData = qrData;
    isScanning = false;
  });

  // Extract the repair ID from the scanned QR code
  final Uri uri = Uri.parse(qrData);
  final String? repairId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;

  if (repairId != null) {
    // Make the request to the backend to get repair details
    final repairDetails = await _fetchRepairDetails(repairId, context);

    // Display the details dialog with fetched repair details
    if (repairDetails != null) {
    }
    // No need for else case here, since errors are handled in _fetchRepairDetails
  } else {
    _showErrorDialog('Invalid QR code. Please scan a valid QR code.');
  }
}

// Fetch repair details from the backend
Future<Map<String, dynamic>?> _fetchRepairDetails(String repairId, BuildContext context) async {
  try {
    // Log the repairId to debug
    print('Fetching details for Repair ID: $repairId');
    
    final url = 'https://expertstrials.xyz/Garifix_app/api/repair_details/$repairId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print('Repair details fetched successfully.');
      return jsonDecode(response.body);
    } else {
      // Return the error message from the response and show it in the error dialog
      String errorMessage = 'Error fetching repair details: ${response.statusCode} - ${response.body}';
      _showErrorDialog(errorMessage);  // Show error dialog
      print('Error response: $errorMessage');  // Debugging the error
      return null;  // Return null to indicate failure
    }
  } catch (e) {
    // Handle exceptions and provide a detailed error message
    String errorMessage = 'Error fetching repair details: $e';
    _showErrorDialog(errorMessage);  // Show error dialog
    print('Exception: $e');  // Log exception details for debugging
    return null;  // Return null to indicate failure
  }
}


// Show error dialog
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}


// Start QR Code Scanner
void _startQRCodeScanner() {
  setState(() {
    isScanning = true;
  });

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          height: 450, // Adjusted height for better layout
          width: 320,  // Adjusted width for better layout
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan QR Code',
                style: TextStyle(
                  fontSize: 22, // Increased font size for title
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple, // Changed title color
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.deepPurple, thickness: 2), // Divider for separation
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), // Rounded corners for the scanner
                  child: MobileScanner(
                    onDetect: (BarcodeCapture barcodeCapture) {
                      final barcode = barcodeCapture.barcodes.first;
                      if (barcode.rawValue != null) {
                        _onQRCodeScanned(barcode.rawValue!);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _stopQRCodeScanner();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Rounded button
                ),
                child: const Text(
                  'Close Scanner',
                  style: TextStyle(fontSize: 16), // Button text size
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
void _stopQRCodeScanner() {
  setState(() {
    isScanning = false;
  });
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Jobs Page',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.deepPurple,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search Jobs',
          onPressed: () {
            // Implement search functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          tooltip: 'Notifications',
          onPressed: () {
            // Implement notifications functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More Options',
          onPressed: () {
            // Implement more options functionality
          },
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    ),
    body: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0),
              // New Section for Job Stats
              _buildStatsRow(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return _buildJobCard(job);
                  },
                ),
              ),
            ],
          ),
        ),
        // QR Code Scanner Icon
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height * 0.55, // Positioning the icon
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Background color
              borderRadius: BorderRadius.circular(30), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2), // Shadow color
                  blurRadius: 6, // Shadow blur radius
                  spreadRadius: 2, // Shadow spread radius
                  offset: const Offset(0, 2), // Shadow position
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.qr_code_scanner,
                size: 40, // Adjust size as needed
                color: Colors.deepPurple,
              ),
              onPressed: _startQRCodeScanner, // Same functionality
              tooltip: 'Scan QR Code',
            ),
          ),
        ),
        // Floating Action Button to show dialog
        Positioned(
          right: 16,
          bottom: 16, // Positioned at the bottom right
          child: FloatingActionButton(
            onPressed: () => _showMechanicDialog(context),
            backgroundColor: Colors.deepPurple,
            child: const Icon(
              Icons.assignment_turned_in,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _showMechanicDialog(BuildContext context) async {
  TextEditingController repairIdController = TextEditingController();

  // Show the Mechanic Dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_circle_outlined, color: Colors.deepPurple, size: 30),
                  SizedBox(width: 10),
                  Text('Repair ID', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Please enter the Repair ID (numbers and/or letters).', style: TextStyle(fontSize: 14, color: Colors.black54), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              TextField(
                controller: repairIdController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Enter Repair ID',
                  labelStyle: const TextStyle(color: Colors.deepPurple),
                  hintText: 'e.g. A123B456',
                  hintStyle: TextStyle(color: Colors.deepPurple.shade100),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.deepPurple.shade200)),
                  prefixIcon: const Icon(Icons.directions_car, color: Colors.deepPurple),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  String repairId = repairIdController.text.trim();
                  if (repairId.isNotEmpty) {
                    try {
                      if (_isBase64(repairId)) {
                        String decodedRepairId = utf8.decode(base64Decode(repairId));
                        print('Decoded Repair ID: $decodedRepairId');

                        final repairDetails = await _fetchRepairDetails(decodedRepairId, context);
                        if (repairDetails != null) {
                          // Close the mechanic dialog before opening the details dialog
                          Navigator.of(context).pop(); // Close Mechanic Dialog
                          _showDetailsDialog(repairDetails, context); // Show Repair Details Dialog
                        }
                      } else {
                        throw const FormatException('Invalid Base64 format.');
                      }
                    } catch (e) {
                      print('Error decoding Repair ID: $e');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Repair ID format.')));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid Repair ID.')));
                  }
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 35, vertical: 12)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showDetailsDialog(Map<String, dynamic> repairDetails, BuildContext context) {
  print('Repair Details: $repairDetails'); // Log to check values

  // Ensure `images` is always treated as a List
  var images = repairDetails['images'];
  if (images is String) {
    // Convert a single image string to a list containing that image
    images = images.isNotEmpty ? [images] : [];
  } else if (images == null) {
    // Default to an empty list if null
    images = [];
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repair Details for ${repairDetails['problem_type'] ?? "Unknown"}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.deepPurple),
                      onPressed: () {
                        _showQRCodeDialog(repairDetails['id']);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow(Icons.calendar_today, 'Date', repairDetails['created_at'] ?? "Not available"),
                _buildDetailRow(Icons.description, 'Description', repairDetails['details'] ?? "No details provided"),
                _buildDetailRow(Icons.priority_high, 'Urgency Level', repairDetails['urgency_text'] ?? "No urgency level"),
                _buildDetailRow(Icons.monetization_on, 'Cost', '\$${repairDetails['cost']?.toString() ?? "N/A"}'),

                // Display the `images` as a comma-separated string if it's a non-empty list
                _buildDetailRow(
                  Icons.image,
                  'Images',
                  images.isNotEmpty ? images.join(', ') : 'No images available',
                ),

                const SizedBox(height: 20),

                // Additional input fields for updates
                _buildInputField(
                  Icons.monetization_on,
                  'Enter New Cost',
                  TextInputType.number,
                  (value) {
                    // Handle cost input
                  },
                ),
                const SizedBox(height: 10),

                _buildInputField(
                  Icons.comment,
                  'Comments/Recommendations',
                  TextInputType.multiline,
                  (value) {
                    // Handle comments input
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () {
                    _selectDate(context, nextRepairDateController);
                  },
                  child: AbsorbPointer(
                    child: _buildInputField(
                      Icons.calendar_today,
                      'Next Repair Date (Optional)',
                      TextInputType.none,
                      (value) {
                        // No callback needed here
                      },
                      controller: nextRepairDateController,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                const Text('Repair Steps...'),
              ],
            ),
          ),
        ),
      );
    },
  );
}




// Utility function to check if a string is Base64 encoded
bool _isBase64(String str) {
  final base64RegExp = RegExp(r'^[A-Za-z0-9+/=]+$');
  return base64RegExp.hasMatch(str);
}






Widget _buildStatsRow() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildStatCard(
        icon: Icons.work,
        value: '120', // Replace with dynamic data if available
      ),
      _buildStatCard(
        icon: Icons.star,
        rating: 4.5, // Pass the rating value as a double
        width: 120,  // Custom width for the star rating card
        height: 55, // Custom height for the star rating card
      ),
      _buildStatCard(
        icon: Icons.people,
        value: '300', // Replace with dynamic data if available
      ),
    ],
  );
}

Widget _buildStatCard({
  required IconData icon,
  String? value,
  double? rating,
  double width = 80,
  double height = 60, // Default height value
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Container(
      padding: const EdgeInsets.all(4), // Adjusted padding for a better fit
      width: width, // Use the passed width parameter
      height: height, // Use the passed height parameter
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(height: 0), // Set to 0 to eliminate space
          if (rating != null) ...[
            _buildStarRating(rating), // Display stars if rating is provided
          ] else if (value != null) ...[
            Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.deepPurple, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

// Method to build star rating with value
Widget _buildStarRating(double rating) {
  List<Widget> stars = [];
  int fullStars = rating.floor(); // Number of full stars
  double fractionalPart = rating - fullStars; // Fractional part of the rating
  double starSize = 10.0; // Size of each star

  // Create full stars
  for (int i = 0; i < fullStars; i++) {
    stars.add(Icon(Icons.star, size: starSize, color: Colors.yellow));
  }

  // Create half star if applicable
  if (fractionalPart >= 0.25 && fractionalPart < 0.75) {
    stars.add(Icon(Icons.star_half, size: starSize, color: Colors.yellow));
  } else if (fractionalPart >= 0.75) {
    stars.add(Icon(Icons.star, size: starSize, color: Colors.yellow));
  }

  // Fill the remaining stars with empty stars
  for (int i = fullStars + (fractionalPart >= 0.75 ? 1 : 0); i < 5; i++) {
    stars.add(Icon(Icons.star_border, size: starSize, color: Colors.yellow));
  }

  // Add the rating value next to the stars
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        children: stars,
      ),
      const SizedBox(width: 4), // Space between stars and rating text
      Text(
        rating.toStringAsFixed(1), // Format rating to one decimal place
        style: const TextStyle(fontSize: 14, color: Colors.deepPurple, fontWeight: FontWeight.bold),
      ),
    ],
  );
}




  // Job card widget with rating and details
  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job['description'],
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                Text('${job['rating']}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${job['date']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Build input field widget
  Widget _buildInputField(IconData icon, String hint, TextInputType keyboardType, Function(String) onChanged, {TextEditingController? controller, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        icon: Icon(icon, color: Colors.deepPurple),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
      ),
    );
  }

  // Build detail row for repair information
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 10),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  // Build a list of repair steps with status
  List<Widget> _buildRepairDetailsWithStatus(List<dynamic> details) {
    return details.map((detail) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(detail['name']),
            Text(detail['status']),
          ],
        ),
      );
    }).toList();
  }

  // Function to build the image upload field
  Widget _buildImageUploadField() {
    return ElevatedButton(
      onPressed: () {
        // Handle image upload
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
      ),
      child: const Text('Upload Image'),
    );
  }

  // Function to show QR code dialog
  void _showQRCodeDialog(String repairId) {
    // Implement showing QR code dialog
  }

  // Function to select date
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0]; // Format the date
      });
    }
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


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  String? userEmail;
  Map<String, dynamic>? userInfo;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _expertiseController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _paymentPlanController = TextEditingController(text: 'Ksh 2000 / Year');
  Map<String, bool> _editMode = {};

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _editMode = {
      'personal_information': false,
      'professional_information': false,
      'skills_achievements': false,
      'payment_plan': false,
      'ratings_reviews': false,
      'social_media_links': false,
    };
  }

  @override
  void dispose() {
    // Dispose the controllers when the widget is disposed
    _fullNameController.dispose();
    _emailController.dispose();
    _expertiseController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _paymentPlanController.dispose();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
    await Future.wait([_fetchUserProfile(), _fetchUserInfo()]); // Fetch data in parallel
  }
Future<void> _fetchUserProfile() async {
    // Get the JWT token
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token'); // Get the JWT token
  if (token == null) {
    print('Token is null, cannot fetch user profile.');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/get_user_profile'),
      headers: {
        'Authorization': 'Bearer $token',  // Add the token to the Authorization header
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true && data['profile'] != null) {
        setState(() {
          // Add the full URL for the image
          _imageUrl = 'https://expertstrials.xyz/Garifix_app/' + data['profile']['profile_image'];
        });
        
        // Print the profile image URL in the console
        print('Profile image URL: $_imageUrl');
      } else {
        print('Failed to load user profile: ${data['message']}');
      }
    } else {
      print('Failed to load user profile: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error occurred while fetching user profile: $e');
  }
}



  Future<void> requestPermission() async {
    await Permission.storage.request();
  }

Future<void> _changeProfilePicture() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    // Display the local image while waiting for upload to complete
    setState(() {
      _imageUrl = image.path; // Temporarily display the local image
    });

    // Get the JWT token
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token'); // Get the JWT token

    // Debug: Print the token
    print('JWT Token: $token'); // <-- Print the token for debugging

    // Create a request to send the image and token to the backend
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://expertstrials.xyz/Garifix_app/update_profile'),
    );

    // Add the token to the request headers
    request.headers['Authorization'] = 'Bearer $token';

    // Debug: Print image path
    print('Image path: ${image.path}');

    // Check if the file exists before adding
    if (await File(image.path).exists()) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path), // Use image.path directly
      );

      try {
        // Send the request
        var response = await request.send();

        if (response.statusCode == 200) {
          // Parse the response
          var responseData = await http.Response.fromStream(response);
          var responseJson = jsonDecode(responseData.body);

          // Assuming your server sends back the image URL after upload
          if (responseJson['success'] == true && responseJson['profile_image_url'] != null) {
            setState(() {
              // Update the image URL with the one returned from the server
              _imageUrl = responseJson['profile_image_url']; // Use the URL directly
            });
            print('Profile updated successfully');
          } else {
            print('Failed to update profile: ${responseJson['message']}');
          }
        } else {
          print('Failed to update profile: ${response.reasonPhrase}');
        }
      } catch (e) {
        print('Error occurred: $e');
      }
    } else {
      print('The image file does not exist at path: ${image.path}');
    }
  }
}

Future<void> _fetchUserInfo() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token'); // Get the JWT token

  if (token == null) {
    print('Token is null, cannot fetch user info.');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/get_user_info'),
      headers: {
        'Authorization': 'Bearer $token',  // Add the token to the Authorization header
      },
    );

    if (response.statusCode == 200) {
      print('User Info Response: ${response.body}'); // Log the entire response
      try {
        // Decode response JSON
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        userInfo = decodedResponse['user_info'];

        // Check for null before updating controllers
        setState(() {
          _fullNameController.text = userInfo?['full_name'] ?? '';
          _emailController.text = userInfo?['email'] ?? '';
          _expertiseController.text = userInfo?['field_of_expertise'] ?? 'No Expertise Provided';
          _experienceController.text = (userInfo?['years_of_experience'] ?? '0').toString(); // Ensure it's a string
          _educationController.text = userInfo?['education'] ?? 'No Education Provided';
        });

        // Print the data response
        print('User Info: $userInfo'); // Log the fetched user info
      } catch (e) {
        print('Error parsing user info: $e');
      }
    } else {
      print('Failed to fetch user info: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error occurred while fetching user info: $e');
  }
}



@override
Widget build(BuildContext context) {
      if (userEmail == null) {
      return const Center(child: CircularProgressIndicator()); // Show loading indicator while fetching data
    }
  return Scaffold(
          appBar: AppBar(
        title: const Text(
          'PROFILE PAGE',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, size: 28), // Notification Icon
            tooltip: 'Notifications',
            onPressed: () {
              // Handle notification tap
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 28), // Settings Icon
            tooltip: 'Settings',
            onPressed: () {
              // Handle settings tap
            },
          ),
          const SizedBox(width: 10), // Add some space between icons
        ],
      ),
    backgroundColor: Colors.grey[100], // Clean background
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfilePictureSection(),
          const SizedBox(height: 20),

          // Build Personal Information Section
          _buildSection(
            context,
            title: 'Personal Information',
            sectionId: 'personal_information',
            onEditPressed: _handleEditSection,
            onViewPressed: _handleViewSection,
            canEdit: true, // Allow editing
            children: [
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                readOnly: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Professional Information Section
          _buildSection(
            context,
            title: 'Professional Information',
            sectionId: 'professional_information',
            onEditPressed: _handleEditSection,
            onViewPressed: _handleViewSection,
            canEdit: true, // Allow editing
            children: [
              _buildTextField(
                controller: _expertiseController,
                label: 'Field of Expertise',
                icon: Icons.settings,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _experienceController,
                label: 'Years of Experience',
                icon: Icons.timelapse,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _educationController,
                label: 'Education',
                icon: Icons.school,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Skills & Achievements Section
          _buildSection(
            context,
            title: 'Skills & Achievements',
            sectionId: 'skills_achievements',
            onEditPressed: _handleEditSection,
            onViewPressed: _handleViewSection,
            canEdit: true, // Allow editing
            children: [
              _buildSkillsSection(),
              const SizedBox(height: 20),
              _buildAchievementsSection(),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Plan Section (View only)
          _buildSection(
            context,
            title: 'Payment Plan',
            sectionId: 'payment_plan',
            onEditPressed: _handleEditSection,
            onViewPressed: _handleViewSection,
            canEdit: false, // Disable editing
            children: [
              _buildTextField(
                controller: _paymentPlanController,
                label: 'Payment Plan',
                icon: Icons.payment,
                readOnly: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ratings & Reviews Section (View only)
          _buildSection(
            context,
            title: 'Ratings & Reviews',
            sectionId: 'ratings_reviews',
            onEditPressed: _handleEditSection,
            onViewPressed: _handleViewSection,
            canEdit: false, // Disable editing
            children: [
              _buildRatingsSection(),
            ],
          ),
          const SizedBox(height: 40),

          // Social Media Links Section
          _buildSection(
            context,
            title: 'Social Media Links',
            sectionId: 'social_media_links',
            onEditPressed: _handleEditSection,
            onViewPressed: _handleViewSection,
            canEdit: true, // Allow editing
            children: [
              _buildSocialMediaLinks(),
            ],
          ),
          const SizedBox(height: 40),

        ],
      ),
    ),
  );
}

// Toggle edit mode for the given section
void _handleEditSection(String sectionId) {
  setState(() {
    _editMode[sectionId] = !_editMode[sectionId]!;
  });
}

// No changes needed for viewing section in this context
void _handleViewSection(String sectionId) {
  print('Viewing section: $sectionId');
}

// Build section with optional save button based on edit state and whether editing is allowed
Widget _buildSection(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  required String sectionId, // Unique identifier for each section
  required Function(String) onEditPressed, // Callback for edit button
  required Function(String) onViewPressed, // Callback for view button
  required bool canEdit, // Flag to allow or disallow editing
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (canEdit) // Only show edit button if editing is allowed
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  onPressed: () {
                    onEditPressed(sectionId);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.teal),
                onPressed: () {
                  onViewPressed(sectionId);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,

if (_editMode[sectionId]! && canEdit)
  Align(
    alignment: Alignment.center,
    child: Container(
      margin: const EdgeInsets.only(top: 20),
      child: ElevatedButton.icon(
        onPressed: () {
          _saveChanges(sectionId); // Call the save function
        },
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          shadowColor: Colors.grey.withOpacity(0.5),
        ),
      ),
    ),
  ),


        ],
      ),
    ),
  );
}


Future<void> _saveChanges(String sectionId) async {
  String url = 'https://expertstrials.xyz/Garifix_app/update_bio_data'; // Your Flask API endpoint

  // Gather data based on the section
  Map<String, dynamic> data = {}; // Initialize data

  if (sectionId == 'personal_information') {
    // If updating personal information, include full name and new email
    data['full_name'] = _fullNameController.text; // Ensure this is not null or empty
    data['email'] = _emailController.text; // Ensure this is not null or empty
  } else if (sectionId == 'professional_information') {
    // If updating professional information, include expertise, experience, and education
    data['expertise'] = _expertiseController.text; // Ensure this is not null or empty
    data['experience'] = _experienceController.text; // Ensure this is not null or empty
    data['education'] = _educationController.text; // Ensure this is not null or empty
  } else if (sectionId == 'social_media_links') {
    // If updating social media links, add relevant fields (customize as needed)
    data['social_media_links'] = {

    };
  }

  try {
    // Retrieve the JWT token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('jwt_token'); // Retrieve the token

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Add the token to the Authorization header
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Handle successful response
      print('Data saved successfully!');
    } else {
      // Handle error response
      print('Failed to save data: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}




  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                ? NetworkImage(_imageUrl!) // Use NetworkImage for loaded images
                : const AssetImage('assets/logo/account.jpg') as ImageProvider, // Default image
            child: _imageUrl == null || _imageUrl!.isEmpty
                ? const Icon(Icons.person, size: 60) // Placeholder icon if no image
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 10,
            child: InkWell(
              onTap: _changeProfilePicture, // Call function to change picture
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Skills Section
  Widget _buildSkillsSection() {
    final List<String> skills = [
      'Engine Repair',
      'Transmission',
      'Brake Systems',
      'Suspension',
      'Diagnostics',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: skills.map((skill) => Chip(
            label: Text(skill),
            backgroundColor: Colors.teal.withOpacity(0.2),
            padding: const EdgeInsets.all(8),
          )).toList(),
        ),
      ],
    );
  }

  // Achievements Section
  Widget _buildAchievementsSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements & Certifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ListTile(
          leading: Icon(Icons.check_circle, color: Colors.teal),
          title: Text('Certified Engine Specialist'),
          subtitle: Text('Awarded by Automotive Association in 2022'),
        ),
        ListTile(
          leading: Icon(Icons.check_circle, color: Colors.teal),
          title: Text('Transmission Repair Specialist'),
          subtitle: Text('Completed advanced training in 2021'),
        ),
      ],
    );
  }

  // Ratings Section
  Widget _buildRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ratings & Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(5, (index) {
                return const Icon(
                  Icons.star,
                  color: Colors.teal,
                  size: 24,
                );
              }),
            ),
            const Text(
              '4.8/5 (120 Reviews)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  // Social Media Links Section
  Widget _buildSocialMediaLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Follow me on Social Media',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue, size: 30),
              onPressed: () {
                // Handle Facebook link
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.pink, size: 30),
              onPressed: () {
                // Handle Instagram link
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.linkedin, color: Colors.blueAccent, size: 30),
              onPressed: () {
                // Handle LinkedIn link
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.twitter, color: Colors.lightBlue, size: 30),
              onPressed: () {
                // Handle Twitter link
              },
            ),
          ],
        ),
      ],
    );
  }

  // Save Changes Button
  Widget _buildSaveChangesButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Save changes action
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}



