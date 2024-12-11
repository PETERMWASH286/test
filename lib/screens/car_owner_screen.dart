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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:lottie/lottie.dart'; // Ensure you have this package in your pubspec.yaml
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Add flutter_rating_bar package for star rating bar
// Import the newly created file
import 'success_popup.dart'; // Import the newly created file
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'switch_signup.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // For text animation

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
  late StreamController<String> _streamController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
    _loadUserEmail(); // Load user email from SharedPreferences
    _streamController = StreamController<String>();
    _connectToSSE(); // Start SSE connection
  }

  // Connect to SSE endpoint
void _connectToSSE() async {
  print('Attempting to connect to SSE endpoint...');
  final client = http.Client();
  final url = Uri.parse('https://expertstrials.xyz/Garifix_app/notifications'); // Your SSE server URL
  final request = http.Request('GET', url);
  request.headers['accept'] = 'text/event-stream';

  try {
    // Send the request to the server
    final streamedResponse = await client.send(request);
    print('Response received from SSE endpoint.');

    // Check the status code of the response
    print('Response status: ${streamedResponse.statusCode}');
    print('Response headers: ${streamedResponse.headers}');

    // If status is 200 OK, start listening to the stream
    if (streamedResponse.statusCode == 200) {
      print('Successfully connected to SSE endpoint.');

      // Start listening to the stream and print each chunk of data received
      streamedResponse.stream.transform(utf8.decoder).listen(
        (data) {
          print('Data received from SSE: $data');
          if (data.isNotEmpty) {
            _streamController.add(data); // Add the data to stream
          }
        },
        onError: (error) {
          print('Error in stream: $error');
        },
        onDone: () {
          print('Stream closed');
        },
        cancelOnError: true,
      );
    } else {
      print('Failed to connect to SSE endpoint. Status code: ${streamedResponse.statusCode}');
    }
  } catch (e) {
    // Catch any other error in the try block
    print('Failed to connect to SSE endpoint: $e');
  }
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

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
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







class HomePage extends StatelessWidget {
  const HomePage({super.key});



Future<Map<String, dynamic>> fetchMaintenanceData() async {
  try {
    final maintenanceData = await fetchMaintenanceCosts();
    final userCars = await fetchUserCars();
    final recentServices = await fetchRecentServices();
    return {
      "maintenanceData": maintenanceData ?? {},
      "userCars": userCars ?? [],
      "recentServices": recentServices ?? []
    };
  } catch (e) {
    print("Error fetching data: $e");
    return {
      "maintenanceData": {},
      "userCars": [],
      "recentServices": []
    };
  }
}


Future<List<dynamic>> fetchUserCars() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token is missing!');
    }

    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/user_cars'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Debugging: Print the raw response body
      print('Response body: ${response.body}');
      
      // Decode the response and access the 'cars' key
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Debugging: Print the decoded response data
      print('Decoded response data: $responseData');
       
      final List<dynamic> cars = responseData['cars']; // Access the 'cars' list

      // Debugging: Print the list of cars
      print('Cars data: $cars');
      
      return cars;
    } else {
      print('Failed to load user cars: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load user cars: ${response.body}');
    }
  } catch (e) {
    print('Error fetching user cars: $e');
    return [];
  }
}
Future<List<dynamic>> fetchRecentServices() async {
  try {
    // Get token from shared preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    // Check if token is available
    if (token == null) {
      throw Exception('Token is missing!');
    }

    // Make API request
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/recent_services'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Handle response
    if (response.statusCode == 200) {
      // Debugging: Print the raw response body
      print('Response body: ${response.body}');
      
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Debugging: Print the decoded response data
      print('Decoded response data: $responseData/ta');
      
      final List<dynamic> services = responseData['recent_services']; // Access the 'recent_services' list

      // Debugging: Print the list of services
      print('Services data: $services');
      
      return services;
    } else {
      throw Exception('Failed to load recent services: ${response.body}');
    }
  } catch (e) {
    print('Error fetching recent services: $e');
    return [];
  }
}


Future<Map<String, dynamic>> fetchMaintenanceCosts() async {
  try {
    // Fetch token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing or invalid.');
    }

    // API request
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/maintenance_costs'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Check for response status
    if (response.statusCode == 200) {
      // Parse JSON response
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Debugging print statement
      print('Maintenance Costs Data: $data');

      return data;
    } else {
      // Log error details for non-200 responses
      print('Failed to load maintenance costs: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load maintenance costs. HTTP status: ${response.statusCode}');
    }
  } catch (e) {
    // Catch any errors during the request or JSON parsing
    print('Error fetching maintenance costs: $e');
    return {'error': e.toString()};
  }
}

void _showHelpDialog(BuildContext context) async {
  String selectedProblem = 'App Crashing'; // Default or selected problem
  TextEditingController messageController = TextEditingController();

Future<void> submitHelpRequest() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    if (token == null) {
      // Handle token not found scenario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Prepare data
    Map<String, dynamic> requestData = {
      "problem": selectedProblem,
      "message": messageController.text,
    };

    // Make POST request
    final response = await http.post(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/help-request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 201) { // Check for the 201 status code
      // Hide the dialog and clear inputs
      Navigator.of(context).pop(); // Close the help dialog
      messageController.clear(); // Clear the input field

      // Request successful, show the success popup
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const SuccessPopup(
        message: 'Our support team will review your request and get back to you as soon as possible. Thank you for reaching out to us!',          );
        },
      );
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: ${response.body}')),
      );
    }
  } catch (e) {
    // Handle exceptions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}


  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.purple.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading with Icon
                const Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.amberAccent, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Problem Type Dropdown
                const Text(
                  'Select a Problem:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Select an issue...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: selectedProblem,
                  items: [
                    'App Crashing',
                    'Slow Performance',
                    'Login Issues',
                    'Payment Problems',
                    'Other'
                  ]
                      .map((problem) => DropdownMenuItem<String>(
                            value: problem,
                            child: Text(problem),
                          ))
                      .toList(),
                  onChanged: (value) {
                    selectedProblem = value ?? selectedProblem;
                  },
                ),
                const SizedBox(height: 20),

                // Optional Message TextField
                const Text(
                  'Additional Message (Optional):',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Describe your issue...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),

                // Chat and Submit Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open chat functionality
                      },
                      icon: const Icon(Icons.chat_bubble, size: 18, color: Colors.cyan),
                      label: const Text('Chat with Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shadowColor: Colors.cyan.withOpacity(0.5),
                        elevation: 8,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => submitHelpRequest(),
                      icon: const Icon(Icons.send, size: 18, color: Colors.redAccent),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shadowColor: Colors.redAccent.withOpacity(0.5),
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
}

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
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchMaintenanceData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data available"));
          }

          final maintenanceData = snapshot.data!['maintenanceData'];
          final userCars = snapshot.data!['userCars'];
          final recentServices = snapshot.data!['recentServices'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
    ElevatedButton.icon(
      onPressed: () {
        // Show pop-up when the button is pressed
        _showHelpDialog(context);
      },
      icon: const Icon(Icons.support_agent, size: 20),
      label: const Text('Seek Support'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    ),
  
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Maintenance Costs Summary Section
const Text(
  'Maintenance Costs Summary:',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    SummaryCard(
      label: 'Total Cost',
      amount: maintenanceData['total_cost'] ?? 0,  // Default to 0 if null or missing
      icon: Icons.attach_money,
    ),
    SummaryCard(
      label: "This Month's Cost",
      amount: maintenanceData['monthly_cost'] ?? 0,  // Default to 0 if null or missing
      icon: Icons.calendar_today,
    ),
  ],
),
const SizedBox(height: 20),


const Text(
  'Your Cars:',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),

// Check if userCars list is empty
if (userCars.isEmpty) 
  // Display a beautiful message when there are no cars
  Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        colors: [Colors.purple.shade200, Colors.deepPurple.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          offset: Offset(2, 2),
          blurRadius: 4,
        ),
      ],
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_car, color: Colors.white, size: 30),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'You currently have no cars added. Add a car to track maintenance costs and details!',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  )
else 
  // Display the list of cars when available
  SizedBox(
    height: 200,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: userCars.length,  // Length of the userCars list
      itemBuilder: (context, index) {
        final car = userCars[index];
        final imageUrl = car['image_path'] != null 
            ? 'https://expertstrials.xyz/Garifix_app/${car['image_path']}'  // Prepend the base URL to the image path
            : '';  // Default to empty string if image path is null
            
        return CarCard(
          carModel: car['car_name'] ?? 'Unknown Car',  // Provide default if null
          totalCost: (car['total_cost'] != null) ? double.tryParse(car['total_cost'].toString()) ?? 0.0 : 0.0,
          imageUrl: imageUrl,  // Use the updated image URL
          year: car['year'] ?? 'Unknown Year',  // Added year
          mileage: car['mileage'] ?? 0.0,  // Added mileage
          color: car['color'] ?? 'Unknown Color',  // Added color
        );
      },
    ),
  ),
const SizedBox(height: 20),



          // Recent Services Section
// Recent Services Section
const Text(
  'Recent Services:',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
recentServices.isEmpty
    ? const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No recent services available.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      )
    : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentServices.length,
        itemBuilder: (context, index) {
          final service = recentServices[index];
          return ServiceCard(
            serviceName: service['service_name'], // service_name now contains "service_name - selected_car"
            date: service['date'],
            cost: (service['cost'] != null) ? double.tryParse(service['cost'].toString()) ?? 0.0 : 0.0,
          );
        },
      ),
const SizedBox(height: 20),


              const Text(
                'News & Tips:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const NewsCard(
                title: 'Top 5 Maintenance Tips for Winter',
                icon: Icons.ac_unit,
              ),
              const NewsCard(
                title: 'How to Save on Car Repairs',
                icon: Icons.money_off,
              ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Summary Card Widget
class SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple[50],
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: 150,
        height: 100, // Increased height for icon and text balance
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/maintenance_bg.png'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon for the label
            Icon(
              icon,
              color: Colors.deepPurple,
              size: 23,
            ),
            const SizedBox(height: 5), // Space between icon and label
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              'Ksh ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String serviceName;
  final String date;
  final double cost;

  const ServiceCard({
    super.key,
    required this.serviceName,
    required this.date,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.build, color: Colors.deepPurple),
      title: Text(serviceName), // This will now display "service_name - selected_car"
      subtitle: Text(date),
      trailing: Text('Ksh $cost'),
    );
  }
}


// News Card Widget
class NewsCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const NewsCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.orangeAccent),
      title: Text(title),
    );
  }
}

class CarCard extends StatelessWidget {
  final String carModel;
  final double totalCost;
  final String imageUrl;
  final String year;  // Added year
  final double mileage;  // Added mileage
  final String color;  // Added color

  const CarCard({
    super.key,
    required this.carModel,
    required this.totalCost,
    required this.imageUrl,
    required this.year,  // Required year
    required this.mileage,  // Required mileage
    required this.color,  // Required color
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent, // Make card transparent to see background
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              carModel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Year: $year',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              'Color: $color',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              'Mileage: ${mileage.toStringAsFixed(2)} km',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 5),
            Text(
              'Total Cost: \$${totalCost.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),

          ],
        ),
      ),
    );
  }
}



class _AdditionalCostsDialog extends StatefulWidget {
  final int repairId;

  const _AdditionalCostsDialog({required this.repairId});

  @override
  __AdditionalCostsDialogState createState() => __AdditionalCostsDialogState();
}

class __AdditionalCostsDialogState extends State<_AdditionalCostsDialog> {
  List<Map<String, TextEditingController>> costRows = [
    {
      'costName': TextEditingController(),
      'company': TextEditingController(),
      'cost': TextEditingController(),
    }
  ];

  @override
  void dispose() {
    for (var row in costRows) {
      row['costName']?.dispose();
      row['company']?.dispose();
      row['cost']?.dispose();
    }
    super.dispose();
  }


void showSuccessPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,  // Make the dialog non-dismissable
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 290,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Animated success icon (Lottie animation)
            Lottie.asset(
              'assets/lotti/Animation - 1730958529727.json', // Add your Lottie success animation file here
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 15),
            // Success Text
            const Text(
              'Success!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            // Message
            Text(
              'Additional costs saved successfully!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Close button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();  // Close the dialog
                Navigator.of(context).pop();  // Close the dialog

              },
              style: ElevatedButton.styleFrom(

              ),
              child: const Text('Okay'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _sendDataToFlask(BuildContext context) async {
  // Collect the cost data
  List<Map<String, String>> costs = costRows.map((row) {
    return {
      'costName': row['costName']?.text ?? '',
      'company': row['company']?.text ?? '',
      'cost': row['cost']?.text ?? '',
    };
  }).toList();

  // Prepare the request body
  final Map<String, dynamic> requestBody = {
    'repairId': widget.repairId,  // Send repairId along with costs
    'costs': costs,
  };

  // Get the JWT token from SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');

  if (token == null) {
    print("No token found");
    return;
  }

  // Make the POST request to the Flask backend
  final response = await http.post(
    Uri.parse('https://expertstrials.xyz/Garifix_app/additional-costs'), // Your Flask API endpoint
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode(requestBody),
  );

  if (response.statusCode == 200) {
    // Success
    print("Data sent successfully: ${response.body}");

    // Ensure the widget is still mounted before showing the dialog
    if (mounted) {
      showSuccessPopup(context);  // Show success popup
    }
  } else {
    // Error
    print("Failed to send data: ${response.statusCode}");
  }
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(  // Added to make the dialog scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Additional Costs',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.deepPurple),
                    onPressed: () => Navigator.of(context).pop(), // Close dialog
                  ),
                ],
              ),
              const Divider(color: Colors.deepPurple, thickness: 1),

              // Table header
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('Cost Name', textAlign: TextAlign.center)),
                  Expanded(child: Text('Company', textAlign: TextAlign.center)),
                  Expanded(child: Text('Cost', textAlign: TextAlign.center)),
                ],
              ),
              const Divider(),

              // Dynamic rows for cost entries
              Column(
                children: List.generate(costRows.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costRows[index]['costName'],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              labelText: 'Cost Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costRows[index]['company'],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              labelText: 'Company',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costRows[index]['cost'],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              labelText: 'Cost',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            if (costRows.length > 1) {
                              setState(() {
                                costRows.removeAt(index); // Remove this row
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Add Row button with icon
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 30),
                  onPressed: () {
                    setState(() {
                      costRows.add({
                        'costName': TextEditingController(),
                        'company': TextEditingController(),
                        'cost': TextEditingController(),
                      });
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Add cost button with gradient
              ElevatedButton(
                onPressed: () {
                  _sendDataToFlask(context); // Send data to Flask
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // Background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shadowColor: Colors.deepPurpleAccent,
                  elevation: 10,
                ),
                child: const Text(
                  'Add Costs',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
  List<XFile> _images = []; // List to store selected images
  final ValueNotifier<double> _urgencyLevel = ValueNotifier<double>(3.0);
  final _formKey = GlobalKey<FormState>();
  String? _problemType;
  final TextEditingController _detailsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles; // Define a list to hold the selected images
String? _selectedCar;
List<String> _carOptions = [];
  @override
  void initState() {
    super.initState();
    _fetchRepairsHistory();
    _fetchCarOptions(); // Fetch car options when the widget is initialized
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


Future<void> _fetchCarOptions() async {
  try {
    // Retrieve the token from SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    print('Retrieved JWT Token: $token'); // Debugging: Print the token

    // Check if the token is null
    if (token == null) {
      print('Token is null. User might not be authenticated.');
      return;
    }

    // Make the HTTP GET request to the Flask backend
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/cars'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Print the response status code
    print('HTTP Response Status Code: ${response.statusCode}');
    // Print the response body for inspection
    print('HTTP Response Body: ${response.body}');

    // Handle the response
    if (response.statusCode == 200) {
      // Parse the response body
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('Parsed Response Data: $responseData'); // Debugging: Print parsed data

      if (responseData['success'] == true && responseData['cars'] != null) {
        final List<dynamic> carData = responseData['cars'];
        print('Car Data List: $carData'); // Debugging: Print car data list

        setState(() {
          // Assuming you only need the car names for the dropdown options
          _carOptions = carData.map<String>((car) => car['car_name'] as String).toList();
        });
        print('Populated Car Options: $_carOptions'); // Debugging: Print car options
      } else {
        // Handle unsuccessful response
        print('Failed to fetch car options: Invalid response structure.');
        if (responseData.containsKey('message')) {
          print('Error Message from Server: ${responseData['message']}'); // Optional error message
        }
      }
    } else {
      // Handle error response
      print('Failed to fetch car options: ${response.statusCode}');
      print('Response Body (Error): ${response.body}'); // Additional debug for non-200 responses
    }
  } catch (e) {
    // Handle exceptions
    print('Error fetching car options: $e');
  }
}

Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  _formKey.currentState!.save();
  print('Form saved successfully. Problem Type: $_problemType, Urgency Level: ${_urgencyLevel.value}, Details: ${_detailsController.text}, Selected Car: $_selectedCar');

  var uri = Uri.parse('https://expertstrials.xyz/Garifix_app/submit_report');
  var request = http.MultipartRequest('POST', uri);

  request.fields['problemType'] = _problemType ?? '';
  request.fields['urgencyLevel'] = _urgencyLevel.value.toString();
  request.fields['details'] = _detailsController.text;

  if (_selectedCar != null) {
    request.fields['car'] = _selectedCar!;
    print('Selected Car: $_selectedCar added to request.');
  } else {
    print('No car selected.');
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? email = prefs.getString('userEmail');
  request.fields['email'] = email ?? ''; // Default to empty if null
  print('Email added to request: ${request.fields['email']}');

  if (_imageFiles != null && _imageFiles!.isNotEmpty) {
    for (var image in _imageFiles!) {
      try {
        request.files.add(await http.MultipartFile.fromPath('images', image.path));
        print('Added image: ${image.path}');
      } catch (e) {
        print('Error adding image: $e');
      }
    }
  } else {
    print('No images to upload.');
  }

  var response = await request.send();

  if (response.statusCode == 201) {
    var responseData = await response.stream.bytesToString();
    print('Form submitted successfully. Response: $responseData');

    Navigator.of(context).pop();
    _showSuccessDialog();
    _fetchRepairsHistory();

    _formKey.currentState!.reset();
    setState(() {
      _problemType = null;
      _selectedCar = null;
      _imageFiles = null;
      _detailsController.clear();
    });
  } else {
    print('Error: ${response.statusCode}');
    var responseData = await response.stream.bytesToString();
    print('Error details: $responseData');
  }
}





void _showSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large animated tick icon
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Lottie.asset(
                'assets/lotti/Animation - 1730958529727.json', // Ensure the path is correct
                width: 100,
                height: 100,
                repeat: false,
              ),
            ),
            // Dialog content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Success!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your problem report has been submitted successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      // Refresh the data after success
                      _fetchRepairsHistory();
                      setState(() {
                        // Trigger a UI refresh
                      });
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

Widget _buildProblemForm() {
  return Form(
    key: _formKey, // Add the key to the Form widget
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown for selecting car
        // Dropdown for selecting car
DropdownButtonFormField<String>(
  decoration: const InputDecoration(
    labelText: 'Select Car',
    border: OutlineInputBorder(),
  ),
  items: _carOptions.map<DropdownMenuItem<String>>((String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      _selectedCar = value;
    });
  },
  validator: (value) => value == null ? 'Please select a car' : null,
),

        const SizedBox(height: 20),

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
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
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
List<Map<String, dynamic>> _filteredRepairs() {
  return _repairsHistory.where((repair) {
    if (_searchType == 'description') {
      return repair['description']
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    } else if (_searchType == 'selected_car') {
      return repair['selected_car']
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    } else if (_searchType == 'date') {
      return repair['date']
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }
    return true;
  }).toList().cast<Map<String, dynamic>>(); // Cast the filtered list to List<Map<String, dynamic>>
}

  Future<void> _fetchRepairsHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');

    final response = await http.get(
        Uri.parse('https://expertstrials.xyz/Garifix_app/api/repairs/$email'));

    if (response.statusCode == 200) {
      setState(() {
        _repairsHistory = json.decode(response.body);
      });
    } else {
      print('Failed to load repairs history: ${response.statusCode}');
    }
  }

bool _isSearchVisible = false; // State to toggle search input visibility
String _searchQuery = ''; // State for the search query
String _searchType = 'description'; // Default search type

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
          // Logo
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
          const SizedBox(width: 10),
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
            setState(() {
              _isSearchVisible = !_isSearchVisible; // Toggle search visibility
            });
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
          // Search Input
if (_isSearchVisible) ...[
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,  // Adjust alignment to start if needed
      children: [
        // Dropdown field
        SizedBox(
          width: 150, // Set a fixed width for the dropdown to prevent overflow
          child: DropdownButtonFormField<String>(
            value: _searchType,
            items: const [
              DropdownMenuItem(value: 'description', child: Text('Description')),
              DropdownMenuItem(value: 'selected_car', child: Text('Selected Car')),
              DropdownMenuItem(value: 'date', child: Text('Date')),
            ],
            onChanged: (value) {
              setState(() {
                _searchType = value!;
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Search field
        Expanded(
          flex: 2, // Adjust flex to make sure this takes up more space
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value; // Update search query
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
              hintText: 'Search here...',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 20),
],

          // Repairs History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Repairs History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showReportDialog();
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text(
                  'Download reports',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredRepairs().length, // Use filtered repairs
              itemBuilder: (context, index) {
                var repair = _filteredRepairs()[index];
                return _buildRepairCard(
                  date: repair['date'],
                  description: '${repair['description']} - ${repair['selected_car']}',
                  cost: 'Ksh ${repair['cost'].toString()}',
                  repairId: repair['id'],
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
          _isFabClicked ? _animationController.forward() : _animationController.reverse();
        });
        _showProblemForm();
      },
      backgroundColor: const Color.fromRGBO(103, 58, 183, 1),
      child: const Icon(Icons.add),
    ),
  );
}

void _showReportDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // The dialog can only be dismissed by user selection
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 24,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with a title and an icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Report Type',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.deepPurple, size: 30),
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Report Options with Icons
              Column(
                children: [
                  ..._carOptions.map((car) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context); // Close the dialog
                          _generateReport(car); // Generate the selected report
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[50],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car, color: Colors.deepPurple, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  car,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  // General Summary Report
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context); // Close the dialog
                        _generateReport('General Summary Report'); // Generate summary report
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purpleAccent, Colors.deepPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.report_gmailerrorred, color: Colors.white, size: 24),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'General Summary Report',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}




Future<void> _generateReport(String reportType) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      print('Token is null. User might not be authenticated.');
      return;
    }

    final Map<String, dynamic> payload = {
      'report_type': reportType,
    };

    final response = await http.post(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/generate_report'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!data['success']) {
        print('Failed to fetch report data: ${data['message']}');
        return;
      }

      final reports = data['reports'] as List;

      // Create the PDF document
      final pdf = pw.Document();

      String emailSubject = '$reportType - CAR REPAIR REPORT';
      String emailBody = 'The report contains details about the car repairs and any additional costs incurred. Below are the main details of the report:\n\n';

      for (var report in reports) {
        pdf.addPage(pw.Page(
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$reportType - CAR REPAIR REPORT',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#FF5733'),
                    ),
                  ),
                  pw.Divider(color: PdfColor.fromHex('#FF5733')),
                  pw.Text(
                    'Report Details',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  _buildReportDetailSection(report),
                  if (report['repairs'] != null && report['repairs'].isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Repairs',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    ...report['repairs'].map<pw.Widget>((repair) => _buildRepairItem(repair)),
                  ],
                  if (report['additional_costs'] != null && report['additional_costs'].isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Additional Costs',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    ...report['additional_costs'].map<pw.Widget>((cost) => _buildAdditionalCostItem(cost)),
                  ],
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Generated At: ${formatDate(report['created_at'])}',
                    style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex('#888888')),
                  ),
                ],
              ),
            );
          },
        ));

        // Append report summary for email body
        emailBody += 'Report Date: ${formatDate(report['created_at'])}\n';
        emailBody += 'Total Repairs: ${report['repairs'].length}\n';
        emailBody += 'Additional Costs: ${report['additional_costs'].length}\n\n';
      }

      // Request storage permission
      await _requestPermission();

      // Get the download directory
      final directory = await getExternalStorageDirectory();
      final downloadDirectory = Directory('${directory?.path}/Download');
      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(recursive: true);
      }

      final filePath = '${downloadDirectory.path}/$reportType.pdf';
      final file = File(filePath);

      // Save the PDF
      await file.writeAsBytes(await pdf.save());
      print("Report saved at $filePath");

      // Send the PDF and email to the backend
_sendReportToEmail(filePath, emailSubject, emailBody)
    .then((_) => print('Email sent successfully in the background'))
    .catchError((error) => print('Error sending email: $error'));

      // Notify the user
      Fluttertoast.showToast(
        msg: "Report downloaded and sent via email successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );

      // Open the PDF
      OpenFile.open(filePath);
    } else {
      print('Failed to generate report: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error generating report: $e');
  }
}
Future<void> _sendReportToEmail(String filePath, String subject, String body) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      print('Token is null. User might not be authenticated.');
      return;
    }

    final file = File(filePath);

    if (!file.existsSync()) {
      print('File does not exist at $filePath.');
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/send_report_email'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('report', filePath));
    
    // Add subject and body to the request payload
    request.fields['subject'] = subject;
    request.fields['body'] = body;

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (data['success'] == true) {
        print('Report sent successfully: ${data['message']}');
      } else {
        print('Failed to send report: ${data['message']}');
      }
    } else {
      print('Failed to send report: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending report: $e');
  }
}


pw.Widget _buildReportDetailSection(dynamic report) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _buildDetailItem('Problem Type', report['problem_type']),
      _buildDetailItem('Urgency Level', report['urgency_level']),
      _buildDetailItem('Details', report['details']),
      _buildDetailItem('Car', report['selected_car']),
      _buildDetailItem('Total Cost', 'Ksh ${report['total_cost']}'),
      _buildDetailItem('Date', report['created_at']),
    ],
  );
}

pw.Widget _buildRepairItem(dynamic repair) {
  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 5),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#D5DBDB'), // Light grey
      borderRadius: pw.BorderRadius.circular(5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildDetailItem('Status', repair['repair_status']),
        _buildDetailItem('Labor Cost', 'Ksh ${repair['labor_cost']}'),
        if (repair['next_repair_date'] != null)
          _buildDetailItem('Next Repair Date', repair['next_repair_date']),
        if (repair['comments'] != null) _buildDetailItem('Comments', repair['comments']),
        _buildDetailItem('Repair Date', repair['created_at']),
      ],
    ),
  );
}

pw.Widget _buildAdditionalCostItem(dynamic cost) {
  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 5),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#FAD7A0'), // Light yellow
      borderRadius: pw.BorderRadius.circular(5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildDetailItem('Cost Name', cost['cost_name']),
        _buildDetailItem('Company', cost['company']),
        _buildDetailItem('Value', 'Ksh ${cost['cost_value']}'),
      ],
    ),
  );
}



String formatDate(String dateTime) {
  try {
    final parsedDate = DateTime.parse(dateTime); // Parse the ISO string
    final formatter = DateFormat('yyyy-MM-dd hh:mm a'); // Format to desired style
    return formatter.format(parsedDate); // Return formatted string
  } catch (e) {
    return dateTime; // Return original string if parsing fails
  }
}

pw.Widget _buildDetailItem(String title, dynamic value) {
  return pw.Row(
    children: [
      pw.Text(
        '$title: ',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1F618D')),
      ),
      pw.Text(
        (title.toLowerCase().contains('date') && value is String)
            ? formatDate(value) // Format the datetime
            : (value is double ? value.toStringAsFixed(2) : value.toString()),
      ),
    ],
  );
}

Future<void> _requestPermission() async {
  // Request storage permission if not already granted
  PermissionStatus status = await Permission.storage.request();
  if (!status.isGranted) {
    // If permission is denied, show a message and return
    Fluttertoast.showToast(
      msg: "Storage permission is required to download the report.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
    );
    return;
  }
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
        title: Text(description,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Text(cost, style: const TextStyle(color: Colors.green)),
        onTap: () =>
            _showRepairDetails(repairId), // Call the function to show details
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
  final response = await http.get(Uri.parse(
      'https://expertstrials.xyz/Garifix_app/api/get_repair_details/$repairId'));

  if (response.statusCode == 200) {
    var repairDetails = json.decode(response.body);

    // Convert urgency level to text
    double urgencyLevel =
        double.tryParse(repairDetails['urgency_level'].toString()) ?? 0.0;
    repairDetails['urgency_text'] = urgencyLevelToText(
        urgencyLevel); // Add urgency text to repair details

    _showDetailsDialog(repairDetails);
  } else {
    print('Failed to load repair details: ${response.statusCode}');
  }
}


// Assuming 'repair_status' is a string representation of a list, we need to parse it into a List<bool>.
List<bool> _parseRepairStatus(String repairStatusString) {
  // Parse the repairStatus string into a List<bool>.
  // If repairStatus is like '[True, False, True]', we can convert it to a list of booleans.
  return (repairStatusString
          .replaceAll(RegExp(r'\[|\]'), '')  // Remove square brackets
          .split(',')  // Split by commas
          .map((e) => e.trim() == 'True')  // Convert 'True' to true and 'False' to false
          .toList()) ??
      [];
}
void _showDetailsDialog(Map<String, dynamic> repairDetails) {
  TextEditingController nextRepairDateController = TextEditingController();

  // Check if repair details have comments, labor cost, and next repair date
  bool hasRepairData = repairDetails.containsKey('comments') &&
      repairDetails.containsKey('labor_cost') &&
      repairDetails.containsKey('next_repair_date') &&
      repairDetails.containsKey('created_at') &&
      repairDetails.containsKey('user_full_name');

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        insetPadding: const EdgeInsets.all(8), // Reduce padding to use more screen space
        child: Container(
          width: screenWidth * 0.95, // Cover most of the screen width
          height: screenHeight * 0.85, // Cover most of the screen height
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row with QR button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Repair Details for ${repairDetails['problem_type']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                        overflow: TextOverflow.ellipsis, // Handle overflow
                      ),
                    ),
                    // QR code button
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.deepPurple),
                      onPressed: () {
                        // Trigger QR code generation
                        _showQRCodeDialog(repairDetails['id']);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Details
                _buildDetailRow(
                  Icons.calendar_today,
                  'Date',
                  repairDetails['created_at'],
                ),
                _buildDetailRow(
                  Icons.description,
                  'Description',
                  repairDetails['details'],
                ),
                _buildDetailRow(
                  Icons.priority_high,
                  'Urgency Level',
                  repairDetails['urgency_text'],
                ),
                _buildDetailRow(
                  Icons.monetization_on,
                  'Total Cost',
                  'Ksh ${repairDetails['cost'].toString()}',
                ),
                const SizedBox(height: 20),

                // Display additional fields if available or prompt to add them
// Display additional fields if available or prompt to add them
if (hasRepairData) ...[
  // Container to wrap all details with crazy styling
// Updated Container with "Rate Me" button
Container(
  margin: const EdgeInsets.symmetric(vertical: 10),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.deepPurple.withOpacity(0.4),
        spreadRadius: 4,
        blurRadius: 10,
        offset: const Offset(2, 6), // Shadow position
      ),
      BoxShadow(
        color: Colors.deepPurpleAccent.withOpacity(0.2),
        spreadRadius: -4,
        blurRadius: 10,
        offset: const Offset(-4, -4),
      ),
    ],
    gradient: const LinearGradient(
      colors: [Colors.purpleAccent, Colors.deepPurple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Existing code for displaying repair date
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Repair Done on Date: ${repairDetails['created_at']}', // Date information
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      const SizedBox(height: 5),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Repair for: ${repairDetails['selected_car']}', // Heading that displays the selected car
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      // Comments field
      _buildDetailRow(
        Icons.comment,
        'Comments/Recommendations',
        repairDetails['comments'] ?? 'No comments provided',
      ),

      // Next repair date field
      _buildDetailRow(
        Icons.calendar_today,
        'Next Repair Date',
        repairDetails['next_repair_date'] ?? 'No date set',
      ),

      // User who did the repair and "Rate Me" button
      Row(
        children: [
          // Existing repair done by text
          Expanded(
            child: _buildDetailRow(
              Icons.person,
              'Repair Done By',
              repairDetails['user_full_name'],
            ),
          ),
          // "Rate Me" button
          ElevatedButton.icon(
            onPressed: () {
              // Define the action for rating
_rateRepair(context, repairDetails['user_full_name'], repairDetails['repair_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 6,
              shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
            ),
            icon: const Icon(
              Icons.star_rate,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Rate Me',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      // Additional existing fields
      if (repairDetails.containsKey('labor_cost')) ...[
        // If labor cost exists, show "Add Additional Costs" beside it
        Row(
          children: [
            Flexible(
              child: _buildDetailRow(
                Icons.monetization_on,
                'Labor Cost',
                'Ksh ${repairDetails['labor_cost'].toString()}',
              ),
            ),
            const SizedBox(width: 8), // Space between the button and the input field
            Flexible(
              child: ElevatedButton(
                onPressed: () {
                  _showAdditionalCostsDialog(context, repairDetails['id']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: Colors.deepPurpleAccent,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add Additional Costs',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 10),
    ],
  ),
),

] else ...[
  // Input fields to add missing details
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
],
const SizedBox(height: 10),

// Only show labor cost input if it's not already available
if (!repairDetails.containsKey('labor_cost')) ...[
  Row(
    children: [
      Flexible(
        child: _buildInputField(
          Icons.monetization_on,
          'Enter Labor Cost',
          TextInputType.number,
          (value) {
            // Handle labor cost input
          },
        ),
      ),
      const SizedBox(width: 8), // Space between the input field and the button
      Flexible(
        child: ElevatedButton(
          onPressed: () {
                  _showAdditionalCostsDialog(context, repairDetails['id']);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: Colors.deepPurpleAccent,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Additional Costs',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
  const SizedBox(height: 10),
],
                // Add Additional Costs button beside the Labor Cost
                const SizedBox(height: 10),


                // Image upload and submit buttons
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Repairs Done:',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    ),
    const SizedBox(height: 10),

    // Determine the appropriate function to call based on repair_status
    ...(
      repairDetails['repair_status'] == null 
        ? _buildRepairDetailsWithStatusNoStyling(repairDetails['details'] ?? '')
        : _buildRepairDetailsWithStatus(
            repairDetails['details'] ?? '',
            _parseRepairStatus(repairDetails['repair_status']),
          )
    ),
    
    const SizedBox(height: 20),
  ],
),


                _buildImageUploadField(),

                // Buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple, // Button background color
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                        shadowColor: Colors.deepPurpleAccent, // Shadow color for the button
                        elevation: 8, // Elevation to give it a floating effect
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent, // Button background color
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                        shadowColor: Colors.orange, // Shadow color for the button
                        elevation: 8, // Elevation for a floating effect
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
}



void _rateRepair(BuildContext context, String userFullName, int repairId) {
  double rating = 0.0; // Initial rating value
  TextEditingController messageController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rate Me',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                glowColor: Colors.purpleAccent.withOpacity(0.4),
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.deepPurpleAccent,
                ),
onRatingUpdate: (newRating) {
  setState(() {
    rating = newRating;
  });
},

                unratedColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Add a message (optional)',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
onPressed: () async {
  // Capture the current context safely at this point
  String message = messageController.text;
  print('Message to send: $message');

  // Retrieve token from shared preferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');
  print('Retrieved token: $token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: Token not found')),
    );
    print('Error: Token not found');
    return;
  }

  // Prepare headers and body
  const String url = 'https://expertstrials.xyz/Garifix_app/rate_mechanic';
  final Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };
  final Map<String, dynamic> body = {
    'user_full_name': userFullName,
    'rating': rating,
    'repair_id': repairId, // Include repair ID
    'message': message,
  };
  print('Request headers: $headers');
  print('Request body: $body');

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Display a success dialog
      if (context.mounted) { // Ensure context is still valid
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/lotti/Animation - 1730958529727.json', // Add your Lottie animation file
                      width: 100,
                      height: 100,
                      repeat: false,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Success!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your rating was successfully submitted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the success dialog
                        Navigator.of(context).pop(); // Close the rateRepair dialog
                        setState(() {
                          rating = 0.0; // Reset the rating
                        });
                        messageController.clear(); // Clear the text field input
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(color: Colors.white),
                      ),
                    )

                  ],
                ),
              ),
            );
          },
        );
      }
    } else {
      print('Failed to submit rating. HTTP Error: ${response.statusCode}');
      // Extract the error message from backend response
      final backendMessage = response.body.isNotEmpty ? jsonDecode(response.body)['message'] : 'Unknown error occurred';
      _showErrorDialog(context, backendMessage);
    }
  } catch (e) {
    print('Error occurred while submitting rating: $e');
    _showErrorDialog(context, 'An error occurred while submitting the rating');
  }
},


                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  shadowColor: Colors.deepPurple.withOpacity(0.5),
                  elevation: 8,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Submit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
// Function to show a custom error dialog with Lottie animation and styling
void _showErrorDialog(BuildContext context, String errorMessage) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lotti/Animation - 1731569705908.json', // Path to error animation file
                width: 100,
                height: 100,
                repeat: false,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the error dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


void _showAdditionalCostsDialog(BuildContext context, int repairId) {
  // Use StatefulWidget to manage the rows dynamically
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _AdditionalCostsDialog(repairId: repairId); // Pass the repairId here
    },
  );
}



void _showQRCodeDialog(int repairId) {
  // Encrypt the repair ID using Base64 encoding
  String encodedRepairId = base64Encode(utf8.encode(repairId.toString()));

  // The URL with the encrypted repair ID for the QR code
  String qrData = 'https://expertstrials.xyz/Garifix_app/api/repair_details/$encodedRepairId'; // Data for QR code
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

              // Instruction text with encrypted repair ID
              Text(
                'Please scan the QR code below to access the repair details for Repair ID: $encodedRepairId',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      controller.text =
          "${picked.toLocal()}".split(' ')[0]; // Format the date as needed
    }
  }

Future<void> _pickImages() async {
  final ImagePicker picker = ImagePicker();
  final List<XFile> selectedImages = await picker.pickMultiImage() ?? [];

  print("Selected Images: $selectedImages");

  if (selectedImages.isNotEmpty) {
    setState(() {
      _images = selectedImages;
    });
  }
}

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
        onPressed: _pickImages, // Handle image upload here
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.blue),
        ),
        child: const Text('Choose Images'),
      ),
      const SizedBox(height: 8),
      if (_images.isNotEmpty) ...[
        const Text('Selected Images:', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _images.map((image) {
            // Ensure that the path is correct before proceeding
            return FutureBuilder<bool>(
              future: File(image.path).exists(), // Check if file exists
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData && snapshot.data!) {
                    return GestureDetector(
                      onTap: () {
                        print('Image clicked: ${image.path}');
                      },
                      child: Image.file(
                        File(image.path), // Display the image
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  } else {
                    // If the file doesn't exist
                    return const Text("Error: Image not found");
                  }
                } else {
                  // Display loading spinner while checking the file existence
                  return const CircularProgressIndicator();
                }
              },
            );
          }).toList(),
        ),
      ] else ...[
        const Text(
          'No images selected.',
          style: TextStyle(fontSize: 14, color: Colors.red),
        ),
      ],
    ],
  );
}



// Function to build repair details with radio buttons for completion status
// Function to build repair details without any styling when repairStatus is null
List<Widget> _buildRepairDetailsWithStatusNoStyling(String details) {
  // Split the details into paragraphs
  List<String> paragraphs = details.split('\n');

  // Generate a list of widgets with tick and cross buttons only
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
// Function to build repair details with simplified styling based on repairStatus
List<Widget> _buildRepairDetailsWithStatus(String? details, List<bool>? repairStatus) {
  if (details == null || details.isEmpty) {
    return [
      const Text(
        'No repair details available.',
        style: TextStyle(color: Colors.grey),
      ),
    ];
  }

  // Split the details into paragraphs
  List<String> paragraphs = details.split('\n');

  // Generate a list of widgets based on the status
  return List.generate(paragraphs.length, (index) {
    bool status = (repairStatus != null && index < repairStatus.length) ? repairStatus[index] : false;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                paragraphs[index],
                style: const TextStyle(color: Colors.black87), // Dark text for better readability
              ),
            ),
          ),
          // Show a single icon based on the status
          Icon(
            status ? Icons.check_circle : Icons.cancel, // Icon based on status
            color: status ? Colors.green : Colors.red,  // Color based on status
            size: 24.0, // Icon size for better visibility
          ),
        ],
      ),
    );
  });
}



// Function to build detail row with icon and paragraph handling
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8.0), // Adds vertical spacing
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Aligns icon and text at the top
        children: [
          Icon(icon,
              color: Colors.deepPurple,
              size: 24), // Size adjusted for better visibility
          const SizedBox(width: 8),
          Expanded(
            // Allows text to wrap properly
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title:',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold), // Bold title for emphasis
                ),
                const SizedBox(height: 4), // Space between title and value
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 5, // Limits to 5 lines
                  overflow: TextOverflow
                      .ellipsis, // Adds ellipsis if the text overflows
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Function to build input fields
  Widget _buildInputField(IconData icon, String label,
      TextInputType keyboardType, Function(String) onChanged,
      {TextEditingController? controller, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
  
  List<Map<String, dynamic>> messages = []; // Messages list
    List<dynamic> filteredMechanics = [];  // List for filtered mechanics
  late ChatService _chatService; // Declare ChatService instance

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(); // Initialize ChatService
    _chatService.startLongPolling(_onMessagesReceived); // Start polling for messages
    _getUserLocation();
    _loadUserEmail(); // Load user email when the widget is initialized
    filteredMechanics = mechanics;  // Initialize filtered mechanics with all mechanics
  }

  // Method to handle incoming messages
// Assuming newMessages contains a list of strings (you might need to adapt this)
void _onMessagesReceived(List<Map<String, dynamic>> newMessages) {
  setState(() {
    messages.addAll(newMessages);
    print('Updated messages list: $messages'); // Log the updated messages list
  });
}



  @override
  void dispose() {
    _chatService.stopLongPolling(); // Stop polling when the widget is disposed
    super.dispose();
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
    itemCount: getFilteredMechanics().length, // Use the filtered list length
    itemBuilder: (context, index) {
      final mechanic = getFilteredMechanics()[index]; // Get filtered mechanic
      return _buildMechanicCard(
        id: mechanic['id'],  
        name: mechanic['name'],
        rating: mechanic['rating'].toString(),
        distance: mechanic['distance'].toString(),
        phone: mechanic['phone'],
        expertise: mechanic['expertise'],
        profileImageUrl: 'https://expertstrials.xyz/Garifix_app/' + mechanic['profile_image'],
      );
    },
  ),
)


              ],
            ),
          ),
          // Floating filter icons on the right
          Positioned(
            right: 8,
            top: MediaQuery.of(context).size.height *
                0.05, // Adjusted to screen height
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
            // Update the mechanic list based on the new distance filter
            showDistanceDropdown = false;
          });
        },
        items: ['< 1 km', '1-3 km', '3-5 km', '5 - 10 km']
            .map((distance) => DropdownMenuItem(value: distance, child: Text(distance)))
            .toList(),
      ),
    ),
  );
}


List<String> getUniqueExpertise() {
  Set<String> expertiseSet = {};
  for (var mechanic in mechanics) {
    if (mechanic['expertise'] != null) {
      expertiseSet.add(mechanic['expertise']);
    }
  }
  return expertiseSet.toList();
}
List<dynamic> getFilteredMechanics() {
  List<dynamic> filteredMechanics = mechanics;

  // Filter by expertise if selected
  if (selectedExpertise != null && selectedExpertise!.isNotEmpty) {
    filteredMechanics = filteredMechanics.where((mechanic) {
      return mechanic['expertise'] == selectedExpertise;
    }).toList();
  }

  // Filter by distance if selected
  if (selectedDistance != null && selectedDistance!.isNotEmpty) {
    filteredMechanics = filteredMechanics.where((mechanic) {
      double mechanicDistance = double.tryParse(mechanic['distance'].toString()) ?? 0.0;

      // Define the distance ranges and filter accordingly
      switch (selectedDistance) {
        case '< 1 km':
          return mechanicDistance < 1;
        case '1-3 km':
          return mechanicDistance >= 1 && mechanicDistance <= 3;
        case '3-5 km':
          return mechanicDistance >= 3 && mechanicDistance <= 5;
        case '5 - 10 km':
          return mechanicDistance >= 5 && mechanicDistance <= 10;
        default:
          return true; // No filtering if no distance is selected
      }
    }).toList();
  }

  // Filter by name or expertise if searchName is not empty
  if (searchName.isNotEmpty) {
    filteredMechanics = filteredMechanics.where((mechanic) {
      return mechanic['name'].toLowerCase().contains(searchName.toLowerCase()) || 
             mechanic['expertise'].toLowerCase().contains(searchName.toLowerCase());
    }).toList();
  }

  return filteredMechanics;
}



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
            selectedExpertise = value; // Update the selected expertise
            showExpertiseDropdown = false; // Close the dropdown
          });
        },
        items: getUniqueExpertise().map((expertise) {
          return DropdownMenuItem(value: expertise, child: Text(expertise));
        }).toList(),
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
            searchName = value;  // Update searchName with the entered value
          });
        },
      ),
    ),
  );
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
                          _chatService.sendMessage(id.toString(), newMessage, mechanicName); // Pass id as a string
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

// Mechanic Card UI
Widget _buildMechanicCard({
  required int id,  // Add mechanic ID here
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
    elevation: 6,
    child: ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profileImageUrl),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.person, color: Colors.white), // Fallback icon
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStarRating(double.tryParse(rating) ?? 0), // Show the star rating
          const SizedBox(height: 4),  // Add some spacing
          Text(
            'Distance: $distance km away\nExpertise: $expertise',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.deepPurple),
            onPressed: () async {
              if (phone != "N/A" && phone.isNotEmpty) {
                final Uri launchUri = Uri(
                  scheme: 'tel',
                  path: phone, // Mechanic's phone number
                );
                if (await canLaunch(launchUri.toString())) {
                  await launch(launchUri.toString());
                } else {
                  throw 'Could not launch $launchUri';
                }
              } else {
                print('Phone number is not available');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.deepPurple), // Message icon
            onPressed: () {
              _showMessageBottomSheet(context, id, name, profileImageUrl);  // Pass mechanic ID
            },
          ),
        ],
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
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}



// Car model class
class Car {
  final String carName;
  final String color;
  final String? document; // Allowing document to be nullable
  final String image;
  final String licensePlate;
  final double mileage;
  final String year;

  Car({
    required this.carName,
    required this.color,
    this.document, // This field is now optional
    required this.image,
    required this.licensePlate,
    required this.mileage,
    required this.year,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      carName: json['car_name'] as String,
      color: json['color'] as String,
      document: json['document'] as String?, // Accepts null
      image: json['image'] as String,
      licensePlate: json['license_plate'] as String,
      mileage: (json['mileage'] as num).toDouble(), // Safe conversion
      year: json['year'] as String,
    );
  }
}

class DocumentViewerScreen extends StatelessWidget {
  final String carName;
  final String? document;

  const DocumentViewerScreen({super.key, required this.carName, this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$carName Documents'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents for $carName',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (document != null)
              Text(
                'Document: $document',
                style: const TextStyle(fontSize: 18),
              )
            else
              const Text(
                'No documents available.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountPageState extends State<AccountPage> {
  String? _imageUrl; // URL for the profile image
  final ImagePicker _picker = ImagePicker();
  String? fullName;
  String? email;
  String? profileImage; // Add this for the profile image
  String? phoneNumber;
  String? address; // Add this for user address
  List<Map<String, dynamic>> paymentDetails = []; // Declare paymentDetails here
  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(context),
            const SizedBox(height: 30),
            _buildCarSection(context),
            const SizedBox(height: 30),
            _buildContactSection(),
            const SizedBox(height: 30),
            _buildPaymentSection(),
            const SizedBox(height: 20),
            _buildDocumentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    // Base URL for profile images
    const String baseUrl = 'https://expertstrials.xyz/Garifix_app/';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[200],
                // Display the user's profile image or a placeholder
                backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                    ? NetworkImage(baseUrl +
                        _imageUrl!) // Load profile image with full URL
                    : const AssetImage('assets/placeholder.png')
                        as ImageProvider, // Placeholder image
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _changeProfilePicture,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          // Update this line to use fullName
          Text(
            fullName ?? 'Loading...', // Use dynamic fullName or default text
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          const SizedBox(height: 1),
          const Text(
            'Joined: January 2018', // You may also consider making this dynamic
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Temporarily display the local image
      setState(() {
        _imageUrl = image.path; // Set the image path temporarily
      });

      // Get the JWT token
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      // Create a request to send the image and token to the backend
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://expertstrials.xyz/Garifix_app/update_profile'),
      );

      // Add the token to the request headers
      request.headers['Authorization'] = 'Bearer $token';

      // Check if the file exists before adding
      if (await File(image.path).exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );

        try {
          // Send the request
          var response = await request.send();

          if (response.statusCode == 200) {
            var responseData = await http.Response.fromStream(response);
            var responseJson = jsonDecode(responseData.body);

            // Assuming your server sends back the image URL after upload
            if (responseJson['success'] == true &&
                responseJson['profile_image_url'] != null) {
              setState(() {
                // Update the image URL with the one returned from the server
                _imageUrl = responseJson['profile_image_url'];
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
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: Column(
              children: paymentDetails.map<Widget>((payment) {
                return Column(
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.phone, color: Colors.deepPurple),
                      title:
                          Text(payment['phone_number']), // Dynamic phone number
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () {
                          // Implement phone number edit functionality
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.monetization_on,
                          color: Colors.deepPurple),
                      title: const Text('Amount Paid'),
                      subtitle: Text(
                          'Ksh ${payment['amount']}'), // Dynamic amount paid
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () {
                          // Implement amount edit functionality
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calendar_today,
                          color: Colors.deepPurple),
                      title: const Text('Package Type'),
                      subtitle: Text(
                          payment['subscription_type']), // Dynamic package type
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () {
                          // Implement package type edit functionality
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Car>> fetchCars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    try {
      final response = await http.get(
        Uri.parse('https://expertstrials.xyz/Garifix_app/api/my-cars'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print the status code and body for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Decode the response body
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Access the data key to get the list of cars
        List<dynamic> carData = jsonResponse['data'];

        // Print the JSON response for debugging
        print('Fetched car data: $carData');

        return carData.map((car) => Car.fromJson(car)).toList();
      } else {
        // Print error response for debugging
        print('Failed to load cars. Status code: ${response.statusCode}');
        print('Error response: ${response.body}');
        throw Exception('Failed to load cars');
      }
    } catch (e) {
      // Print any exceptions that occur during the fetch
      print('Error occurred: $e');
      throw Exception('Failed to fetch cars: $e');
    }
  }

// Horizontal scrollable My Car section
  Widget _buildCarSection(BuildContext context) {
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
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Car>>(
            future: fetchCars(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return SizedBox(
                  height: 180, // Adjusted height for car cards
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length +
                        1, // Increase count by 1 for the Add Car card
                    itemBuilder: (context, index) {
                      if (index == snapshot.data!.length) {
                        return _buildAddCarCard(
                            context); // Add Car card at the end
                      }
                      final car =
                          snapshot.data![index]; // Fetch the car from the list
                      return _buildCarCard(car); // Build the car card
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

// Widget for each car card
// Widget for each car card
  Widget _buildCarCard(Car car) {
    return Container(
      width: 240, // Width for each car card
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(
              'https://expertstrials.xyz/Garifix_app/${car.image}'), // Use full image URL
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Card(
          color: Colors.black54, // Overlay color for better text visibility
          elevation: 4,
          child: Stack(
            // Use Stack to position the edit icon
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset('assets/icons/car.svg', height: 40),
                    const SizedBox(height: 10),
                    Text(
                      car.carName, // Use car.carName instead of car.name
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    // Use maxLines to prevent overflow
                    Text(
                      'License Plate: ${car.licensePlate}\nColor: ${car.color}',
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2, // Limit to 2 lines
                      overflow: TextOverflow
                          .ellipsis, // Add ellipsis if text overflows
                    ),
                    const SizedBox(
                        height: 4), // Space between car info and year/mileage
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Distribute space between elements
                      children: [
                        Expanded(
                          // Expand to take available space
                          child: Text(
                            'Year: ${car.year}',
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                            width: 8), // Small space between year and mileage
                        Expanded(
                          child: Text(
                            'Mileage: ${car.mileage.toString()} km',
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Optional: Display the document if it exists
                    if (car.document != null)
                      Text(
                        'Document: ${car.document}',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Positioned(
                // Position the edit button at the top right
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
      ),
    );
  }

// Add new car card with form dialog
  Widget _buildAddCarCard(BuildContext context) {
    return Container(
      width: 160, // Smaller width for add car button
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          // Show form dialog when tapped
          _showAddCarFormDialog(context);
        },
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8, // Increased elevation for better shadow effect
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // Gradient background
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
                  mainAxisSize:
                      MainAxisSize.min, // Adjust height based on content
                  children: [
                    Icon(Icons.add,
                        size: 40,
                        color: Colors.white), // White icon for better contrast
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

void _showSuccessDialog(BuildContext context, VoidCallback onSuccess) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated success icon with transition effect
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title with smooth animation
              AnimatedDefaultTextStyle(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                duration: const Duration(milliseconds: 500),
                child: const Text('Success'),
              ),
              const SizedBox(height: 10),

              // Content text with animation
              AnimatedDefaultTextStyle(
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.7),
                ),
                duration: const Duration(milliseconds: 500),
                child: const Text('The car has been added successfully!'),
              ),

              const SizedBox(height: 30),

              // Beautiful and elevated "OK" button with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    onSuccess(); // Call the function to show the add car form dialog
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  void _showAddCarFormDialog(BuildContext context) {
    final carNameController = TextEditingController();
    final licensePlateController = TextEditingController();
    final colorController = TextEditingController();
    final yearController = TextEditingController();
    final mileageController = TextEditingController();
    String? carImagePreviewPath;
    final ImagePicker picker = ImagePicker();
    String? documentName;

    // Function to pick a document
    Future<void> pickDocument() async {
      final XFile? document = await picker.pickImage(
          source: ImageSource.gallery); // Change as per requirement
      if (document != null) {
        setState(() {
          documentName = document.name; // Save the document name for display
        });
      }
    }

    Future<void> pickImage(StateSetter setState) async {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          carImagePreviewPath = image.path;
        });
      }
    }

Future<void> addCar(BuildContext context) async {
  // Get the JWT token
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');

  // Prepare the request data
  final Map<String, dynamic> carData = {
    'car_name': carNameController.text,
    'license_plate': licensePlateController.text,
    'color': colorController.text,
    'year': yearController.text,
    'mileage': mileageController.text,
    'car_image':
        carImagePreviewPath != null ? File(carImagePreviewPath!) : null,
    'document_name': documentName,
  };

  // Create multipart request
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://expertstrials.xyz/Garifix_app/api/add-car'),
  );

  // Add JWT token to headers
  request.headers['Authorization'] = 'Bearer $token';

  // Add fields to the request
  request.fields['car_name'] = carData['car_name'];
  request.fields['license_plate'] = carData['license_plate'];
  request.fields['color'] = carData['color'];
  request.fields['year'] = carData['year'];
  request.fields['mileage'] = carData['mileage'];

  // Add image file if selected
  if (carImagePreviewPath != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'car_image',
        carImagePreviewPath!,
      ),
    );
  }

  // Add document file if selected
  if (documentName != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        documentName!,
      ),
    );
  }

  try {
    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Handle success
      print('Car added successfully');
      
      // Clear the input fields
      carNameController.clear();
      licensePlateController.clear();
      colorController.clear();
      yearController.clear();
      mileageController.clear();
      carImagePreviewPath = null; // Reset image
      documentName = null; // Reset document

      // Close the dialog and show success message
      Navigator.of(context).pop(); // Close the dialog
      _showSuccessDialog(context, () {
        _showAddCarFormDialog(context); // Optionally, reopen the dialog
      });
    } else {
      // Handle other status codes
      print('Failed to add car: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.add_circle,
                              color: Colors.deepPurple, size: 30),
                          SizedBox(width: 8),
                          Text(
                            'Add New Car',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Image upload with preview box
                      GestureDetector(
                        onTap: () async {
                          await pickImage(setState);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.deepPurple, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.3),
                                offset: const Offset(0, 5),
                                blurRadius: 10,
                              ),
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.15),
                                offset: const Offset(0, 15),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: carImagePreviewPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(carImagePreviewPath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo_camera,
                                        color: Colors.deepPurple, size: 40),
                                    SizedBox(height: 8),
                                    Text(
                                      'Upload Car Photo',
                                      style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Car details inputs with icons and shadows
                      _buildStyledTextField(
                        controller: carNameController,
                        labelText: 'Car Name',
                        hintText: 'e.g., Toyota Camry',
                        icon: Icons.directions_car,
                      ),
                      _buildStyledTextField(
                        controller: licensePlateController,
                        labelText: 'License Plate',
                        hintText: 'e.g., ABC-1234',
                        icon: Icons.confirmation_number,
                      ),
                      _buildStyledTextField(
                        controller: colorController,
                        labelText: 'Color',
                        hintText: 'e.g., Black',
                        icon: Icons.color_lens,
                      ),
                      _buildStyledTextField(
                        controller: yearController,
                        labelText: 'Year',
                        hintText: 'e.g., 2020',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                      ),
                      _buildStyledTextField(
                        controller: mileageController,
                        labelText: 'Mileage (Optional)',
                        hintText: 'e.g., 15000 km',
                        icon: Icons.speed,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      // Document upload field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description,
                                  color: Colors.deepPurple),
                              const SizedBox(width: 10),
                              Text(
                                'Upload Document (Optional)',
                                style: TextStyle(
                                    color: Colors.deepPurple[700],
                                    fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await pickDocument();
                            },
                            icon: const Icon(Icons.upload_file,
                                color: Colors.white),
                            label: const Text('Choose File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 222, 218, 230),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 5,
                              shadowColor: Colors.deepPurple.withOpacity(0.3),
                            ),
                          ),
                          // Display the document name after selection
                          if (documentName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Selected: $documentName',
                                style:
                                    const TextStyle(color: Colors.deepPurple),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Action buttons with shadows and icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStyledButton(
                            context,
                            label: 'Cancel',
                            color: Colors.redAccent,
                            icon: Icons.cancel,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              addCar(
                                  context); // Call the function to send data to backend
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              elevation: 8,
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add),
                                SizedBox(width: 8),
                                Text('Add Car'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

// Helper method to build a TextField with shadow
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.deepPurple),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

// Helper method to build a Button with shadow
  Widget _buildStyledButton(BuildContext context,
      {required String label, required Color color, required IconData icon}) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop(); // Close the dialog
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        elevation: 10,
        shadowColor: color.withOpacity(0.5),
      ).copyWith(elevation: WidgetStateProperty.all(10)), // Increase shadow
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              offset: const Offset(0, 8),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Ensure the button takes minimum space
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('https://expertstrials.xyz/Garifix_app/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Print the raw data from the API response
        print('Response Data: $data');

        if (data['success']) {
          setState(() {
            fullName = data['data']['full_name'];
            email = data['data']['email'];
            phoneNumber = data['data']['phone_number'];
            // Extract the profile image URL
            _imageUrl = data['data']['profile_image']; // Profile image

            // Extract latitude and longitude for geocoding
            double? latitude = data['data']['location']['latitude'];
            double? longitude = data['data']['location']['longitude'];

            // Fetch address using latitude and longitude
            _getAddressFromLatLng(latitude, longitude);

            // Handle payment details
            paymentDetails = List<Map<String, dynamic>>.from(data['data'][
                'payments']); // Convert List<dynamic> to List<Map<String, dynamic>>
          });
        } else {
          // Handle error response and print the message
          print('Error message from API: ${data['message']}');
        }
      } else {
        // Handle server error
        print('Failed to load user data. Status Code: ${response.statusCode}');
        print(
            'Response: ${response.body}'); // Print the full response body for debugging
      }
    } else {
      print('No token found. User is not authenticated.');
    }
  }

// Method to get the address from latitude and longitude
  Future<void> _getAddressFromLatLng(
      double? latitude, double? longitude) async {
    if (latitude != null && longitude != null) {
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
        Placemark place = placemarks[0]; // Get the first result
        setState(() {
          address =
              '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      } catch (e) {
        print('Error fetching address: $e');
      }
    }
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.contact_phone,
                color: Colors.deepPurple,
                size: 30,
              ),
              SizedBox(width: 8),
              Text(
                'Contact Information',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: Column(
              children: [
                // Username Field
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.deepPurple),
                  title: Text(fullName ?? 'Loading...'), // Dynamic username
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
                  title: Text(email ?? 'Loading...'), // Dynamic email
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
                  title:
                      Text(phoneNumber ?? 'Loading...'), // Dynamic phone number
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
                  leading:
                      const Icon(Icons.location_on, color: Colors.deepPurple),
                  title: Text(address ?? 'Loading...'), // Dynamic address
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
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          const SizedBox(height: 10),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.file_copy, color: Colors.deepPurple),
              title: const Text('View Insurance & Documents'),
              trailing:
                  const Icon(Icons.arrow_forward, color: Colors.deepPurple),
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
