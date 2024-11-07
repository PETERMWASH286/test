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
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:lottie/lottie.dart'; // Ensure you have this package in your pubspec.yaml

class SocketService {
  late IO.Socket socket;

  void initializeSocket() {
    // Configure the Socket.IO connection
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Connect to the socket server
    socket.connect();

    // Event listeners
    socket.onConnect((_) {
      print('Connected to the socket server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from the socket server');
    });

    socket.on('message', (data) {
      print('Message from server: $data');
    });

    socket.on('custom_response', (data) {
      print('Custom response from server: ${data['data']}');
    });
  }

  // Emit message to the server
  void sendMessage(String msg) {
    socket.emit('message', msg);
  }

  // Emit custom event to the server
  void sendCustomEvent(Map<String, dynamic> data) {
    socket.emit('custom_event', data);
  }
}

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
// Welcome Message Section
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
                      // Define action for seeking support
                      // For example, navigate to support page or open a dialog
                    },
                    icon: const Icon(Icons.support_agent,
                        size: 20), // Icon for support
                    label: const Text('Seek Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.deepPurple, // Updated button color
                      foregroundColor: Colors.white, // Updated text color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8), // Padding for the button
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SummaryCard(
                    label: 'Total Cost',
                    amount: 8000,
                    icon: Icons.attach_money, // Money icon for total cost
                  ),
                  SummaryCard(
                    label: "This Month's Cost",
                    amount: 1500,
                    icon:
                        Icons.calendar_today, // Calendar icon for monthly cost
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Your Cars:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    CarCard(
                        carModel: 'Toyota Corolla',
                        totalCost: 3000,
                        repairDetails: 'Brake Pad Replacement',
                        imageUrl:
                            'https://haynes.com/en-gb/sites/default/files/styles/unaltered_webp/public/carphoto-location_0.jpg?itok=ctj5rnvC&timestamp=1476269366'),
                    CarCard(
                        carModel: 'Honda Civic',
                        totalCost: 1500,
                        repairDetails: 'Oil Change',
                        imageUrl:
                            'https://media.istockphoto.com/id/501282196/photo/laferrari.jpg?s=612x612&w=0&k=20&c=yJH3oUuhYSmta_BYdwoUOktqWps5zC86guy5hQ29608='),
                    CarCard(
                        carModel: 'Ford Focus',
                        totalCost: 2500,
                        repairDetails: 'Tire Rotation',
                        imageUrl:
                            'https://hips.hearstapps.com/hmg-prod/images/2026-bugatti-tourbillon-104-66709d54aa287.jpg?crop=0.819xw:0.692xh;0.0994xw,0.185xh&resize=2048:*'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Recent Services:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const ServiceCard(
                serviceName: 'Engine Check',
                date: 'Oct 23, 2024',
                cost: 150.00,
              ),
              const ServiceCard(
                serviceName: 'Tire Replacement',
                date: 'Oct 18, 2024',
                cost: 400.00,
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
              '\$${amount.toStringAsFixed(2)}',
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

// Service Card Widget
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
      title: Text(serviceName),
      subtitle: Text(date),
      trailing: Text('\$$cost'),
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

// Car Card Widget
class CarCard extends StatelessWidget {
  final String carModel;
  final double totalCost;
  final String repairDetails;
  final String imageUrl;

  const CarCard({
    super.key,
    required this.carModel,
    required this.totalCost,
    required this.repairDetails,
    required this.imageUrl,
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
              'Total Cost: \$${totalCost.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 5),
            Text(
              'Last Repair: $repairDetails',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdditionalCostsDialog extends StatefulWidget {
  @override
  __AdditionalCostsDialogState createState() => __AdditionalCostsDialogState();
}

class __AdditionalCostsDialogState extends State<_AdditionalCostsDialog> {
  // A list to store the controllers for each row
  List<Map<String, TextEditingController>> costRows = [
    {
      'costName': TextEditingController(),
      'company': TextEditingController(),
      'cost': TextEditingController(),
    }
  ];

  @override
  void dispose() {
    // Dispose controllers when the dialog is closed
    for (var row in costRows) {
      row['costName']?.dispose();
      row['company']?.dispose();
      row['cost']?.dispose();
    }
    super.dispose();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
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
                // Handle adding the additional costs
                print('Additional Costs Added');
                Navigator.of(context).pop(); // Close the dialog
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
  String? email = prefs.getString('userEmail'); // This can be null

  // Check if email is not null before adding it to request
  if (email != null) {
    request.fields['email'] = email; // Safe to use email since we checked for null
  } else {
    // Handle the case when email is null, maybe set a default or skip adding it
    // request.fields['email'] = 'default@example.com'; // Example of setting a default
    print('No email found in preferences');
  }

  // Add image files if any
  if (_imageFiles != null) {
    for (var image in _imageFiles!) {
      request.files.add(await http.MultipartFile.fromPath('images', image.path));
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
        backgroundColor: const Color.fromRGBO(103, 58, 183, 1),
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
        'https://expertstrials.xyz/Garifix_app/api/repair_details/$repairId'));

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

void _showDetailsDialog(Map<String, dynamic> repairDetails) {
  TextEditingController nextRepairDateController = TextEditingController();

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
                  'Cost',
                  '\$${repairDetails['cost'].toString()}',
                ),
                const SizedBox(height: 20),

                // Additional form fields
Row(
  children: [
    Flexible(
      child: _buildInputField(
        Icons.monetization_on,
        'Enter Labor Cost',
        TextInputType.number,
        (value) {
          // Handle cost input
        },
      ),
    ),
    SizedBox(width: 8), // Space between the button and the input field
    Flexible(
      child: ElevatedButton(
        onPressed: () {
          _showAdditionalCostsDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: Colors.deepPurpleAccent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
                  'Repairs Done:',
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
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

void _showAdditionalCostsDialog(BuildContext context) {
  // Use StatefulWidget to manage the rows dynamically
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _AdditionalCostsDialog();
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
                  backgroundColor: MaterialStateProperty.all(Colors.deepPurple), // Background color
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
  final ImagePicker _picker = ImagePicker();
  final List<XFile> selectedImages = await _picker.pickMultiImage() ?? [];

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
          backgroundColor: MaterialStateProperty.all(Colors.blue),
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
  
  late ChatService _chatService; // Declare ChatService instance

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(); // Initialize ChatService
    _chatService.startLongPolling(_onMessagesReceived); // Start polling for messages
    _getUserLocation();
    _loadUserEmail(); // Load user email when the widget is initialized
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
                    itemCount: mechanics.length,
                    itemBuilder: (context, index) {
                      final mechanic = mechanics[index];
return _buildMechanicCard(
  id: mechanic['id'],  // Add the mechanic's ID here
  name: mechanic['name'],
  rating: mechanic['rating'].toString(),  // Ensure rating is a string
  distance: mechanic['distance'].toString(),  // Ensure distance is a string
  phone: mechanic['phone'],
  expertise: mechanic['expertise'],
  profileImageUrl: 'https://expertstrials.xyz/Garifix_app/' + mechanic['profile_image'],  // Concatenate the base URL
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
      subtitle: Text(
        'Rating: $rating ★\nDistance: $distance km away\nExpertise: $expertise',
        style: TextStyle(color: Colors.grey[600]),
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

// Function to show success dialog and call the add car form dialog
  void _showSuccessDialog(BuildContext context, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: const Text('The car has been added successfully!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onSuccess(); // Call the function to show the add car form dialog
              },
            ),
          ],
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
          _showSuccessDialog(context, () {
            _showAddCarFormDialog(
                context); // Call to show the add car form dialog
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
