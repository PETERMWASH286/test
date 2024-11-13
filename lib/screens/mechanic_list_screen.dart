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
import 'package:path/path.dart' as path; // Import the path package
import 'success_popup.dart'; // Import the newly created file

// Import shared_preferences
import 'post.dart'; // Make sure to import the Post model
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:lottie/lottie.dart'; // Ensure you have this package in your pubspec.yaml
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
  const MechanicHomePage(), // Home tab
  const JobsPage(),         // Jobs tab
  const MessagesPage(),     // Messages tab
  const ExplorePage(),      // Explore tab (added here)
  const ProfilePage(),      // Profile tab
];

void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _bottomNavPages[_selectedIndex], // Update this to reflect the changes
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
          icon: Icon(Icons.explore), // Icon for the Explore tab
          label: 'Explore',          // Label for the Explore tab
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
 final TextEditingController commentsController = TextEditingController();
  final TextEditingController laborCostController = TextEditingController();
  List<String> uploadedImages = [];
  List<bool> repairStatus = [];
  String repairId = "Unknown ID"; // Default value


  // Function to update the uploaded images list when new images are selected
  // Function to update the uploaded images list when new images are selected

// Function to update the uploaded images list when new images are selected
void _handleUploadedImages(List<File> images) {
  setState(() {
    // Use path.basename() to get the file name from the file path
    uploadedImages = images.map((file) {
      print("Full path: ${file.path}"); // Debugging: print full path
      return path.basename(file.path); // Extract file name
    }).toList();
  });

  print('Uploaded images in parent class: $uploadedImages');
}


  // Function to handle repair status updates

  // Function to handle repair status updates
  void _handleRepairStatusUpdate(List<bool> updatedStatus) {
    setState(() {
      repairStatus = updatedStatus;
    });
    print('Updated repair status: $repairStatus');
  }
Future<void> _submitData() async {
  // Retrieve the token from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token'); // Retrieve the token
  
  // Check if token is retrieved correctly
  if (token == null) {
    print('Error: JWT token is missing.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: JWT token is missing.')),
    );
    return;
  }
  print('JWT token retrieved successfully: $token');
  
  // Prepare the data to be sent
  print('Uploaded images before submitting: $uploadedImages');
  final repairData = {
    'repair_id': repairId,  // Accessing repairId from the class level
    'comments': commentsController.text,
    'labor_cost': laborCostController.text,
    'next_repair_date': nextRepairDateController.text,
    'images': uploadedImages,
    'repair_status': repairStatus,
  };

  // Print the repair data to the console before sending
  print('Repair Data:');
  print('Repair ID: ${repairData['repair_id']}');
  print('Comments: ${repairData['comments']}');
  print('Labor Cost: ${repairData['labor_cost']}');
  print('Next Repair Date: ${repairData['next_repair_date']}');
  print('Images: ${repairData['images']}');
  print('Repair Status: ${repairData['repair_status']}');

  // Convert the data to JSON format
  final jsonData = json.encode(repairData);
  print('Sending the following data to backend: $jsonData');

  // Send the data to Flask backend
  final response = await http.post(
    Uri.parse('https://expertstrials.xyz/Garifix_app/api/repair_update'), // Replace with your Flask backend URL
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Add the token here
    },
    body: jsonData,
  );

  // Print response status and body for debugging
  print('Response status code: ${response.statusCode}');
  print('Response body: ${response.body}');

if (response.statusCode == 200) {
  // Successfully sent data
  print('Repair details submitted successfully!');
  
  // Add a delay to ensure the dialog has time to show after the response
  Future.delayed(const Duration(milliseconds: 500), () {
    showDialog(
      context: context,
      builder: (context) => const SuccessPopup(message: 'Repair details submitted successfully!'),
    );
  });

  Navigator.of(context).pop(); // Close the dialog
} else {
  // Error occurred
  print('Failed to submit repair details. Error: ${response.body}');
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Failed to submit repair details.')),
  );
}

}



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
  // Accessing 'repair_id' from repairDetails
  var repairIdValue = repairDetails['id']; // Get the ID from the details

  // If it's an integer, convert it to a string
  repairId = repairIdValue != null ? repairIdValue.toString() : "Unknown ID"; // Default to "Unknown ID" if not found

  // Now you can use repairId in your dialog
  print('Repair ID in dialog: $repairId');

  var images = repairDetails['images'];
  if (images is String) {
    images = images.isNotEmpty ? [images] : [];
  } else {
    images ??= [];
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95, // 95% of screen width
          height: MediaQuery.of(context).size.height * 0.9, // 90% of screen height
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Repair Details - ${repairDetails['problem_type'] ?? "Unknown"}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.deepPurple),
                        onPressed: () {
                          _showQRCodeDialog(repairId); // Using the repairId here
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.person,
                    'Car Owner',
                    repairDetails['user_full_name'] ?? "No owner details",
                  ),
                  _buildDetailRow(
                    Icons.directions_car,
                    'Selected Car',
                    repairDetails['selected_car'] ?? "Not specified",
                  ),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    repairDetails['created_at'] ?? "Not available",
                  ),
                  _buildDetailRow(
                    Icons.description,
                    'Description',
                    repairDetails['details'] ?? "No details provided",
                  ),
                  _buildDetailRow(
                    Icons.priority_high,
                    'Urgency Level',
                    repairDetails['urgency_level']?.toString() ?? "No urgency level",
                  ),
                  _buildDetailRow(
                    Icons.image,
                    'Images',
                    images.isNotEmpty ? images.join(', ') : 'No images available',
                  ),
                  const SizedBox(height: 20),
        _buildInputField(
          Icons.comment,
          'Comments/Recommendations',
          TextInputType.multiline,
          (value) {},
          maxLines: 3,
          controller: commentsController,  // Use commentsController for the comment field
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
              (value) {},
              controller: nextRepairDateController,  // Use nextRepairDateController
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          Icons.monetization_on,
          'Labor Cost',
          TextInputType.number,
          (value) {},
          controller: laborCostController,  // Use laborCostController
        ),
        const SizedBox(height: 10),
ImageUploadField(
  icon: Icons.image,
  label: 'Upload Repair Images',
  onUpload: (List<File> imageFiles) {
    print('Uploaded image files: $imageFiles');
    
    // Convert the List<File> to List<String> by extracting only the filename (not the full path)
    List<String> imageNames = imageFiles.map((file) {
      // Extract the filename (without path) using path.basename()
      String fileName = path.basename(file.path);
      print('Extracted filename: $fileName'); // Debugging: print the extracted filename
      return fileName; // Return just the file name
    }).toList();
    
    print('Uploaded image filenames: $imageNames');
    
    // Update the state with the filenames (not full paths)
    setState(() {
      uploadedImages = imageNames;
    });
  },
),

    const SizedBox(height: 20),
                  const Text(
                    'Repairs Done:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RepairStatus(details: repairDetails['details']!, onStatusChanged: _handleRepairStatusUpdate),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          backgroundColor: Colors.redAccent,
                          elevation: 8,
                        ).copyWith(
                          side: WidgetStateProperty.all(
                            const BorderSide(color: Colors.redAccent, width: 2),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                      onPressed: _submitData, // Submit data
                                              icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          elevation: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}





// Function to build repair details with radio buttons for completion status
  List<Widget> _buildRepairDetailsWithStatus(String details) {
    // Split the details into paragraphs
    List<String> paragraphs = details.split('\n');

    return paragraphs.map((paragraph) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(paragraph),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  // Handle completion status for this step
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  // Handle non-completion status for this step
                },
              ),
            ],
          ),
        ],
      );
    }).toList();
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

class ImageUploadField extends StatefulWidget {
  final IconData icon;
  final String label;
  final Function(List<File>) onUpload;  // Pass List<File> instead of List<String> if needed

  const ImageUploadField({super.key, 
    required this.icon,
    required this.label,
    required this.onUpload,
  });

  @override
  _ImageUploadFieldState createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  final ImagePicker _picker = ImagePicker();
  List<File> _imageFiles = []; // To store selected images

  // Function to pick multiple images
  Future<void> _pickImages() async {
    // Pick multiple images using the ImagePicker
    final pickedFiles = await _picker.pickMultiImage();

    setState(() {
      _imageFiles = pickedFiles.map((e) => File(e.path)).toList();
    });

    // Send the selected images to the parent widget
    widget.onUpload(_imageFiles); // Pass the File list directly
    }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple, // Bold label color
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: Icon(
            widget.icon,
            color: Colors.white, // Icon color for better contrast
          ),
          label: const Text(
            'Upload Repair Images',
            style: TextStyle(
              color: Colors.white, // Text color to match the icon for a clean look
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50), // A vibrant green background for visibility
            foregroundColor: Colors.white, // Corrected parameter for text and icon color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Slightly rounded corners for a modern look
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Padding to make the button bigger and more clickable
          ),
        ),
        const SizedBox(height: 16),
        // Show selected images as previews
        if (_imageFiles.isNotEmpty) 
          Wrap(
            spacing: 8,
            children: _imageFiles.map((image) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              );
            }).toList(),
          ),
        if (_imageFiles.isEmpty) 
          const Text(
            'No images selected',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
      ],
    );
  }
}

class RepairStatus extends StatefulWidget {
  final String details;
  final Function(List<bool>) onStatusChanged;  // Callback to send the status back

  const RepairStatus({super.key, required this.details, required this.onStatusChanged});

  @override
  _RepairStatusState createState() => _RepairStatusState();
}

class _RepairStatusState extends State<RepairStatus> {
  List<bool> _repairStatus = [];

  @override
  void initState() {
    super.initState();
    // Initialize all repair steps to false (not completed)
    _repairStatus = List.filled(widget.details.split('\n').length, false);
  }

  void _updateRepairStatus(int index, bool status) {
    setState(() {
      _repairStatus[index] = status;
    });
    // Notify the parent with the updated status list
    widget.onStatusChanged(_repairStatus);
  }

  List<Widget> _buildRepairDetailsWithStatus(String details) {
    List<String> paragraphs = details.split('\n');

    return paragraphs.asMap().map((index, paragraph) {
      return MapEntry(
        index,
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(paragraph),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _updateRepairStatus(index, true);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _repairStatus[index] ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check,
                      color: _repairStatus[index] ? Colors.white : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _updateRepairStatus(index, false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: !_repairStatus[index] ? Colors.red : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: !_repairStatus[index] ? Colors.white : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildRepairDetailsWithStatus(widget.details),
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
            bottom: MediaQuery.of(context).size.height / 8 +
                1, // Increase the value to move it lower
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
                                  description: product['description'] ??
                                      'No Description',
                                  companyName: product['companyName'] ??
                                      'Unknown Company',
                                  location:
                                      product['location'] ?? 'Unknown Location',
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



