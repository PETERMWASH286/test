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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(const MyApp());
List<XFile>? _imageFiles = [];
final ImagePicker _picker = ImagePicker();

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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back arrow
        backgroundColor: Colors.deepPurple,
        elevation: 10, // Adds shadow for a more dynamic look
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Aligns content to the far left
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
          IconButton(
            icon: const Icon(Icons.notification_add_rounded),
            iconSize: 28,
            color: Colors.white,
            splashRadius: 25,
            onPressed: () {
              // Implement notification functionality here
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back, Car Owner!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
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

class _RepairsPageState extends State<RepairsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<dynamic> _repairsHistory = []; // List to hold fetched data

  bool _isFabClicked = false;

  final ValueNotifier<double> _urgencyLevel = ValueNotifier<double>(3.0);
  final _formKey = GlobalKey<FormState>();
  String? _problemType;
  final TextEditingController _detailsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles; // Define a list to hold the selected images

  @override
  void initState() {
    super.initState();
    _fetchRepairsHistory();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    var uri = Uri.parse('https://expertstrials.xyz/Garifix_app/submit_report');
    var request = http.MultipartRequest('POST', uri);

    // Add fields
    request.fields['problemType'] = _problemType!;
    request.fields['urgencyLevel'] = _urgencyLevel.value.toString();
    request.fields['details'] = _detailsController.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');

    if (email != null) {
      request.fields['email'] = email;
    } else {
      print('No email found in SharedPreferences');
    }

    // Add image files if any
    if (_imageFiles != null) {
      for (var image in _imageFiles!) {
        request.files
            .add(await http.MultipartFile.fromPath('images', image.path));
      }
    }

    // Send the request
    var response = await request.send();

    if (response.statusCode == 201) {
      // Handle success
      var responseData = await response.stream.bytesToString();
      print('Response: $responseData');

      // Close the modal first
      Navigator.of(context).pop(); // Close the modal before showing the dialog
      // Show success message dialog
      _showSuccessDialog();
      _fetchRepairsHistory();

      // Clear the form inputs
      _formKey.currentState!.reset();
      setState(() {
        _problemType = null; // Reset problem type
        _imageFiles = null; // Reset image files
        _detailsController.clear(); // Clear details controller
      });
    } else {
      // Handle error
      print('Error: ${response.statusCode}');
      var responseData = await response.stream.bytesToString();
      print('Error details: $responseData');
    }
  }

// Method to show success message dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Success!',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          content: const Text(
            'Your problem report has been submitted successfully!',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('OK', style: TextStyle(color: Colors.deepPurple)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Refresh the data after success
                _fetchRepairsHistory();
                setState(() {
                  // Trigger a UI refresh
                });
              },
            ),
          ],
        );
      },
    );
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
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
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
      key: _formKey, // Add the key to the Form widget
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
              DropdownMenuItem(
                  value: 'Electrical', child: Text('Electrical Issue')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
              setState(() {
                _problemType = value; // Store the selected value
              });
            },
            validator: (value) => value == null
                ? 'Please select a problem type'
                : null, // Validator
          ),
          const SizedBox(height: 20),

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
            controller: _detailsController, // Add the controller
            decoration: const InputDecoration(
              labelText: 'Additional Details',
              hintText: 'Describe the problem in detail...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) => value!.isEmpty
                ? 'Please provide additional details'
                : null, // Validator
          ),
          const SizedBox(height: 20),

          // Upload image button
          ElevatedButton.icon(
            onPressed: () async {
              // Pick multiple images using the camera
              final List<XFile> selectedImages = await _picker.pickMultiImage();

              // Add the images to the list
              setState(() {
                _imageFiles = selectedImages;
              });
            },
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text(
              'Upload Images of the Problem',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              elevation: 5,
            ),
          ),
          const SizedBox(height: 20),

          // Display the selected images (if any)
          if (_imageFiles != null)
            Wrap(
              spacing: 8.0,
              children: _imageFiles!.map((file) {
                return Image.file(
                  File(file.path),
                  width: 100,
                  height: 100,
                );
              }).toList(),
            ),

          // Submit button with gradient background
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                'Submit Problem Report',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shadowColor: Colors.transparent,
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

  Future<void> _fetchRepairsHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');

    if (email != null) {
      final response = await http.get(Uri.parse(
          'https://expertstrials.xyz/Garifix_app/api/repairs/$email'));

      if (response.statusCode == 200) {
        setState(() {
          _repairsHistory = json.decode(response.body);
        });
      } else {
        print('Failed to load repairs history: ${response.statusCode}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back arrow
        backgroundColor: Colors.deepPurple,
        elevation: 10, // Adds shadow for a more dynamic look
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Aligns content to the far left
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
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: 28,
            color: Colors.white,
            splashRadius: 25,
            onPressed: () {
              // Implement search functionality here
            },
            tooltip: 'Search',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Repairs History',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _repairsHistory.length,
                itemBuilder: (context, index) {
                  var repair = _repairsHistory[index];
                  return _buildRepairCard(
                    date: repair['date'],
                    description: repair['description'],
                    cost: '\$${repair['cost'].toString()}',
                    // Add ID to the repair object for internal use
                    repairId: repair['id'], // Store ID internally if needed
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isFabClicked = !_isFabClicked;
            _isFabClicked
                ? _animationController.forward()
                : _animationController.reverse();
          });
          _showProblemForm();
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

Widget _buildRepairCard({
  required String date,
  required String description,
  required String cost,
  required int repairId, // Accept the repair ID
}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    elevation: 4,
    child: ListTile(
      title: Text(description, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text(cost, style: const TextStyle(color: Colors.green)),
      onTap: () => _showRepairDetails(repairId), // Call the function to show details
    ),
  );
}

// Function to convert urgency level to descriptive words
String urgencyLevelToText(double urgencyLevel) {
  // Use switch case to determine the urgency level description
  switch (urgencyLevel.toInt()) {
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
      return 'Unknown'; // Return a default value for invalid inputs
  }
}

Future<void> _showRepairDetails(int repairId) async {
  final response = await http.get(Uri.parse('https://expertstrials.xyz/Garifix_app/api/repair_details/$repairId'));

  if (response.statusCode == 200) {
    var repairDetails = json.decode(response.body);

    // Convert urgency level to text
    double urgencyLevel = double.tryParse(repairDetails['urgency_level'].toString()) ?? 0.0;
    repairDetails['urgency_text'] = urgencyLevelToText(urgencyLevel); // Add urgency text to repair details

    _showDetailsDialog(repairDetails);
  } else {
    print('Failed to load repair details: ${response.statusCode}');
  }
}

void _showDetailsDialog(Map<String, dynamic> repairDetails) {
  TextEditingController nextRepairDateController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row with QR button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repair Details for ${repairDetails['problem_type']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    // QR code button
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.deepPurple),
                      onPressed: () {
                        // Trigger QR code generation
                                                _showQRCodeDialog(repairDetails['id']); // Pass the repair ID or any data you want to encode
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Details (same as before)
                _buildDetailRow(Icons.calendar_today, 'Date', repairDetails['created_at']),
                _buildDetailRow(Icons.description, 'Description', repairDetails['details']),
                _buildDetailRow(Icons.priority_high, 'Urgency Level', repairDetails['urgency_text']),
                _buildDetailRow(Icons.monetization_on, 'Cost', '\$${repairDetails['cost'].toString()}'),

                const SizedBox(height: 20),

                // Additional form fields and buttons (same as your original implementation)
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

                // Steps and image upload
                const Text(
                  'Repair Steps:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 10),
                ..._buildRepairDetailsWithStatus(repairDetails['details']),
                const SizedBox(height: 20),

                _buildImageUploadField(),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Handle submission here if needed
                        Navigator.of(context).pop();
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                      ),
                      child: const Text('Submit'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
                        foregroundColor: WidgetStateProperty.all(Colors.black),
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                      ),
                      child: const Text('Close'),
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
}
void _showQRCodeDialog(int repairId) {
  String qrData = 'https://expertstrials.xyz/Garifix_app/api/repair_details/$repairId'; // Data for QR code
  String qrApiUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$qrData'; // QR code API URL

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Scan the QR Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),

              // Instruction text
              const Text(
                'Please scan the QR code below to access the repair details.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Fetch QR code image from the API and display it
              Image.network(
                qrApiUrl, // URL of the QR code generated by the API
                width: 200,
                height: 200,
                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                  return const Text('Error loading QR code');
                },
              ),
              const SizedBox(height: 20),



              // Action button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.deepPurple), // Background color
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16, color: Colors.white), // Text color
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Function to select a date
Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  if (picked != null && picked != DateTime.now()) {
    controller.text = "${picked.toLocal()}".split(' ')[0]; // Format the date as needed
  }
}

// Function to build the input field for image upload
Widget _buildImageUploadField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Upload Images of Repairs:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed: () {
          // Handle image upload here
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.blue),
        ),
        child: const Text('Choose Image'),
      ),
    ],
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

// Function to build detail row with icon and paragraph handling
Widget _buildDetailRow(IconData icon, String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0), // Adds vertical spacing
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Aligns icon and text at the top
      children: [
        Icon(icon, color: Colors.deepPurple, size: 24), // Size adjusted for better visibility
        const SizedBox(width: 8),
        Expanded( // Allows text to wrap properly
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title:',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Bold title for emphasis
              ),
              const SizedBox(height: 4), // Space between title and value
              Text(
                value,
                style: const TextStyle(fontSize: 16),
                maxLines: 5, // Limits to 5 lines
                overflow: TextOverflow.ellipsis, // Adds ellipsis if the text overflows
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


// Function to build input fields
Widget _buildInputField(IconData icon, String label, TextInputType keyboardType, Function(String) onChanged, {TextEditingController? controller, int maxLines = 1}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
    ),
    onChanged: onChanged,
  );
}


}

class FindMechanicPage extends StatefulWidget {
  const FindMechanicPage({super.key});

  @override
  _FindMechanicPageState createState() => _FindMechanicPageState();
}

class _FindMechanicPageState extends State<FindMechanicPage> {
  String? selectedDistance;
  String? selectedExpertise;
  String searchName = '';
  bool showDistanceDropdown = false;
  bool showExpertiseDropdown = false;
  bool showNameDropdown = false;
  String _userLocationName = 'Fetching location...';
  Position? _previousPosition;
  String? userEmail; // Variable to hold the user email
  List<dynamic> mechanics = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadUserEmail(); // Call to load user email when the widget is initialized
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail'); // Retrieve user email
    });
    await fetchMechanics(); // Ensure this is awaited to fetch mechanics after loading email
  }

  Future<void> fetchMechanics() async {
    try {
      final response = await http.get(Uri.parse(
          'https://expertstrials.xyz/Garifix_app/get_mechanics?email=$userEmail'));

      if (response.statusCode == 200) {
        // Print the response for debugging
        print("Response data: ${response.body}");

        setState(() {
          mechanics = json.decode(response.body);
        });
      } else {
        print("Error: ${response.statusCode}, Body: ${response.body}");
        throw Exception(
            'Failed to load mechanics. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception occurred: $e");
      throw Exception('Failed to load mechanics');
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

      setState(() {}); // Update UI after fetching location
    } catch (e) {
      print('Error fetching location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching location!')),
        );
      }
    }
  }

  // Current Location Section
  Widget _buildCurrentLocationSection() {
    return Container(

      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.deepPurple, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Current Location: $_userLocationName', // Display dynamic location
              style: const TextStyle(fontSize: 14, color: Colors.deepPurple),
            ),
          ),
          TextButton(
            onPressed: () {
              _getUserLocation(); // Refresh location when button pressed
            },
            child: const Text('Refresh',
                style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back arrow
        backgroundColor: Colors.deepPurple,
        elevation: 10, // Adds shadow for a more dynamic look
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Aligns content to the far left
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
          IconButton(
            icon: const Icon(Icons.notification_add_rounded),
            iconSize: 28,
            color: Colors.white,
            splashRadius: 25,
            onPressed: () {
              // Implement search functionality here
            },
            tooltip: 'Search',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current location section
                _buildCurrentLocationSection(),
                const SizedBox(height: 20),
                // Mechanics List
                Expanded(
                  child: ListView.builder(
                    itemCount: mechanics.length,
                    itemBuilder: (context, index) {
                      final mechanic = mechanics[index];
                      return _buildMechanicCard(
                        name: mechanic['name'],
                        rating: mechanic['rating'].toString(), // Ensure rating is a string
                        distance: mechanic['distance'].toString(), // Ensure distance is a string
                        phone: mechanic['phone'],
                        expertise: mechanic['expertise'],
                        profileImageUrl: 'https://expertstrials.xyz/Garifix_app/' + mechanic['profile_image'], // Concatenate the base URL
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Floating filter icons on the right
          Positioned(
            right: 8,
            top: MediaQuery.of(context).size.height * 0.05, // Adjusted to screen height
            child: Column(
              children: [
                _buildFloatingActionButton(
                  icon: Icons.map_outlined,
                  onPressed: () {
                    setState(() {
                      showDistanceDropdown = !showDistanceDropdown;
                      showExpertiseDropdown = false;
                      showNameDropdown = false;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildFloatingActionButton(
                  icon: Icons.build_outlined,
                  onPressed: () {
                    setState(() {
                      showExpertiseDropdown = !showExpertiseDropdown;
                      showDistanceDropdown = false;
                      showNameDropdown = false;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildFloatingActionButton(
                  icon: Icons.person_search,
                  onPressed: () {
                    setState(() {
                      showNameDropdown = !showNameDropdown;
                      showDistanceDropdown = false;
                      showExpertiseDropdown = false;
                    });
                  },
                ),
              ],
            ),
          ),
          // Dropdowns for filters
          if (showDistanceDropdown)
            Positioned(
              right: 70,
              top: MediaQuery.of(context).size.height * 0.05,
              child: _buildDistanceDropdown(),
            ),
          if (showExpertiseDropdown)
            Positioned(
              right: 70,
              top: MediaQuery.of(context).size.height * 0.15,
              child: _buildExpertiseDropdown(),
            ),
          if (showNameDropdown)
            Positioned(
              right: 70,
              top: MediaQuery.of(context).size.height * 0.25,
              child: _buildNameSearch(),
            ),
        ],
      ),
    );
  }

  // Helper method to build floating action buttons
  Widget _buildFloatingActionButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return FloatingActionButton(
      heroTag: icon.toString(),
      mini: true,
      backgroundColor: Colors.deepPurple,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  // Dropdown UI for Distance Filter
  Widget _buildDistanceDropdown() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedDistance,
          onChanged: (String? value) {
            setState(() {
              selectedDistance = value;
              showDistanceDropdown = false;
            });
          },
          items: ['< 1 km', '1-3 km', '3-5 km', '> 5 km']
              .map((distance) =>
                  DropdownMenuItem(value: distance, child: Text(distance)))
              .toList(),
        ),
      ),
    );
  }

  // Dropdown UI for Expertise Filter
  Widget _buildExpertiseDropdown() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedExpertise,
          onChanged: (String? value) {
            setState(() {
              selectedExpertise = value;
              showExpertiseDropdown = false;
            });
          },
          items: ['General Repair', 'Engine Specialist', 'Tire Specialist']
              .map((expertise) =>
                  DropdownMenuItem(value: expertise, child: Text(expertise)))
              .toList(),
        ),
      ),
    );
  }

  // Dropdown UI for Name Search
  Widget _buildNameSearch() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'Search by Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              searchName = value;
              showNameDropdown = false;
            });
          },
        ),
      ),
    );
  }

// Mechanic Card UI
  Widget _buildMechanicCard({
    required String name,
    required String rating,
    required String distance,
    required String phone,
    required String expertise,
    required String profileImageUrl,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(profileImageUrl),
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.person, color: Colors.white), // Fallback icon
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'Rating: $rating ★\nDistance: $distance\nExpertise: $expertise'),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.deepPurple),
          onPressed: () async {
            if (phone != "N/A" && phone.isNotEmpty) {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: phone, // This will be the mechanic's phone number
              );
              // Launch the dialer
              if (await canLaunch(launchUri.toString())) {
                await launch(launchUri.toString());
              } else {
                throw 'Could not launch $launchUri';
              }
            } else {
              // Optionally, handle case where phone number is not available
              print('Phone number is not available');
            }
          },
        ),
      ),
    );
  }

  // Simulating posting user location
  void _postUserLocation(Position position) {
    // Add your code to send the user's location to your backend or service here
    print('Posting user location: $position');
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
    HomeSection(),
    ProductsSection(),
    MessagesSection(),
    ExploreSection(),
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
          mainAxisAlignment: MainAxisAlignment.start, // Aligns content to the far left
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
          preferredSize: const Size.fromHeight(60.0), // Set height for the bottom navigation
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
            selectedItemColor: Color.fromARGB(255, 255, 171, 64), // Single color
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





class HomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Navigation items for Home section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.grey[200],
          // You might want to add some widgets here for navigation items, like buttons or text.
        ),
        // Main content starts here
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildExplorePost(
                mechanicName: 'Expert Auto Repairs',
                description:
                    'Completed a full engine overhaul on a BMW M3. Professional service guaranteed!',
                datePosted: '2 days ago',
                imagePath: 'https://www.pngplay.com/wp-content/uploads/15/Bmw-Engine-PNG-Free-File-Download.png',
                userProfilePic: 'assets/user1.png', // Placeholder for user profile image
                location: 'New York, USA',
              ),
              _buildExplorePost(
                mechanicName: 'Quick Tune Garage',
                description:
                    'Specialized in brake systems and suspension upgrades. Book a service today!',
                datePosted: '5 days ago',
                imagePath: 'https://c4.wallpaperflare.com/wallpaper/782/765/99/bmw-engine-wallpaper-preview.jpg',
                userProfilePic: 'assets/user2.png', // Placeholder for user profile image
                location: 'Los Angeles, USA',
              ),
              _buildExplorePost(
                mechanicName: 'Luxury Car Repair',
                description:
                    'Premium car detailing and interior refurbishment. Transform your ride!',
                datePosted: '1 week ago',
                imagePath: 'https://c4.wallpaperflare.com/wallpaper/385/762/349/bmw-engine-hd-wallpaper-preview.jpg',
                userProfilePic: 'assets/user3.png', // Placeholder for user profile image
                location: 'Miami, USA',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget for posts in the Explore page
  Widget _buildExplorePost({
    required String mechanicName,
    required String description,
    required String datePosted,
    required String imagePath,
    required String userProfilePic,
    required String location,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Image.network(
              imagePath, // Load image from URL
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
                return const Center(child: Icon(Icons.error)); // Error icon if the image fails to load
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile section
                Row(
                  children: [
                    // User profile picture
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(userProfilePic),
                    ),
                    const SizedBox(width: 10),
                    // Mechanic's name and location
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
                // Post description
                Text(description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                // Date posted and interaction icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(datePosted, style: const TextStyle(color: Colors.grey)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border, color: Colors.deepPurple),
                          onPressed: () {
                            // Implement like functionality
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.deepPurple),
                          onPressed: () {
                            // Implement share functionality
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
  }
}


class ProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Products Section'));
  }
}

class MessagesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Messages Section'));
  }
}

class ExploreSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Explore Section'));
  }
}




class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.deepPurple,
      title: const Text('Profile'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            // Navigate to account settings
          },
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
          onPressed: () {
            // Implement logout functionality
          },
        ),
      ],
      elevation: 0,
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileHeader(context),
          const SizedBox(height: 30),
          _buildCarSection(),
          const SizedBox(height: 30),
          _buildContactSection(),
          const SizedBox(height: 30), // Adjust spacing if needed
          _buildPaymentSection(), // New payment section
          const SizedBox(height: 20),
          _buildDocumentsSection(),
        ],
      ),
    ),
  );
}

// Payment Section Widget
Widget _buildPaymentSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.payment, // Icon for Payment section
              color: Colors.deepPurple,
              size: 30,
            ),
            SizedBox(width: 8), // Spacing between icon and text
            Text(
              'Payment Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.deepPurple),
                title: const Text('+1 234 567 890'), // Phone number
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () {
                    // Implement phone number edit functionality
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.deepPurple),
                title: const Text('Amount Paid'),
                subtitle: const Text('\$250.00'), // Placeholder for amount paid
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () {
                    // Implement amount edit functionality
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                title: const Text('Package Type'),
                subtitle: const Text('Monthly'), // Can be "Monthly" or "Annually"
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () {
                    // Implement package type edit functionality
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



Widget _buildProfileHeader(BuildContext context) {
  return Center(
    child: Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey[200],
              child: const Icon(
                Icons.account_circle, // Big account icon
                size: 105, // Adjust the size as needed
                color: Colors.deepPurple, // Icon color
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: () {
                  // Implement profile picture upload
                },
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const Text(
          'John Doe',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        const SizedBox(height: 1),
        const Text(
          'Joined: January 2018',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),

      ],
    ),
  );
}

// Horizontal scrollable My Car section
Widget _buildCarSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.directions_car, // Icon for My Cars section
              color: Colors.deepPurple,
              size: 30, // Adjust the size as needed
            ),
            SizedBox(width: 8), // Spacing between icon and text
            Text(
              'My Cars',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180, // Adjusted height for car cards
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCarCard('Toyota Camry', 'ABC-1234', 'Black', '2019'),
              _buildCarCard('Tesla Model S', 'XYZ-5678', 'White', '2022'),
              _buildCarCard('Ford Mustang', 'MNO-4321', 'Red', '2021'),
              _buildAddCarCard(),
            ],
          ),
        ),
      ],
    ),
  );
}

// Widget for each car card
Widget _buildCarCard(String name, String plate, String color, String year) {
  return Container(
    width: 240, // Width for each car card
    margin: const EdgeInsets.only(right: 16),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Stack( // Use Stack to position the edit icon
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset('assets/icons/car.svg', height: 40),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Use maxLines to prevent overflow
                Text(
                  'License Plate: $plate\nColor: $color\nYear: $year',
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 3, // Limit to 3 lines
                  overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                ),
              ],
            ),
          ),
          Positioned( // Position the edit button at the top right
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.deepPurple),
              onPressed: () {
                // Implement car details edit functionality
              },
            ),
          ),
        ],
      ),
    ),
  );
}


// Add new car card
Widget _buildAddCarCard() {
  return Container(
    width: 160, // Smaller width for add car button
    margin: const EdgeInsets.only(right: 16),
    child: GestureDetector(
      onTap: () {
        // Implement add new car functionality
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8, // Increased elevation for better shadow effect
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient( // Gradient background
              colors: [
                Colors.deepPurple.withOpacity(0.5), 
                Colors.deepPurple.withOpacity(0.2)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0), // Padding around icon
              child: Column(
                mainAxisSize: MainAxisSize.min, // Adjust height based on content
                children: [
                  Icon(Icons.add, size: 40, color: Colors.white), // White icon for better contrast
                  SizedBox(height: 8), // Space between icon and text
                  Text(
                    'Add New Car',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}


// Contact Information with detailed icons
Widget _buildContactSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.contact_phone, // Icon for contact information
              color: Colors.deepPurple,
              size: 30, // Adjust the size as needed
            ),
            SizedBox(width: 8), // Spacing between icon and text
            Text(
              'Contact Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Column(
            children: [
              // Username Field
              ListTile(
                leading: const Icon(Icons.person, color: Colors.deepPurple), // Icon for username
                title: const Text('John Doe'), // Placeholder for username
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () {
                    // Implement username edit functionality
                  },
                ),
              ),
              const Divider(),
              // Email Field
              ListTile(
                leading: const Icon(Icons.email, color: Colors.deepPurple),
                title: const Text('john.doe@email.com'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () {
                    // Implement email edit functionality
                  },
                ),
              ),
              const Divider(),
              // Phone Number Field
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.deepPurple),
                title: const Text('+1 234 567 890'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () {
                    // Implement phone number edit functionality
                  },
                ),
              ),
              const Divider(),
              // Address Field
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.deepPurple),
                title: const Text('123 Street, City, Country'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () {
                    // Implement address edit functionality
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // Documents and Insurance section
  Widget _buildDocumentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insurance & Documents',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.file_copy, color: Colors.deepPurple),
              title: const Text('View Insurance & Documents'),
              trailing: const Icon(Icons.arrow_forward, color: Colors.deepPurple),
              onTap: () {
                // Navigate to document viewer
              },
            ),
          ),
        ],
      ),
    );
  }
}
