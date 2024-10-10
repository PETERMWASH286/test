import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import '../widgets/mechanic_card.dart';
import 'package:image_picker/image_picker.dart'; // For image selection
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome

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
    fetchMechanics();
    _checkLocationPermission();
    _loadUserEmail(); // Load user email from SharedPreferences
    _testAccessToken(); // Test access token on initialization

  }

  Future<void> fetchMechanics() async {
    try {
      final response = await http.get(Uri.parse('http://10.88.0.4:5000/mechanics'));
      if (response.statusCode == 200) {
        setState(() {
          mechanics = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load mechanics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching mechanics: $e');
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
Future<void> _testAccessToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('jwt_token'); // Retrieve the token

  if (accessToken == null) {
    print('No access token found.');
    return;
  }

  final url = Uri.parse('https://expertstrials.xyz/Garifix_app/protected'); // Your protected endpoint
  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Include the token in the Authorization header
      },
    );

    if (response.statusCode == 200) {
      // Access token is valid
      print('Token is valid! Response: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is valid!')),
      );
    } else if (response.statusCode == 401) {
      // Token is invalid or expired
      print('Invalid or expired token: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired token!')),
      );
    } else {
      print('Failed with status code: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error testing token: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error testing token!')),
    );
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
    const MechanicListScreenBody(mechanics: []),
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
      appBar: AppBar(
        title: const Text('Available Mechanics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality for mechanics
            },
            tooltip: 'Search Mechanics',
          ),
        ],
      ),
      body: _bottomNavPages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick action for creating new jobs or tasks
        },
        backgroundColor: Colors.deepPurple,
        tooltip: 'Add Job or Task',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Mechanics',
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

class MechanicListScreenBody extends StatelessWidget {
  final List<dynamic> mechanics;

  const MechanicListScreenBody({super.key, required this.mechanics});

  @override
  Widget build(BuildContext context) {
    return mechanics.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: mechanics.length,
            itemBuilder: (context, index) {
              return MechanicCard(
                name: mechanics[index]['name'],
                location: mechanics[index]['location'],
                specialty: mechanics[index]['specialty'],
              );
            },
          );
  }
}

// Additional pages remain the same
class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Jobs Page'),
    );
  }
}

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
  final String? email = userEmail;

  if (email == null) {
    print('Email is null, cannot fetch user profile.');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/get_user_profile?email=$email'),
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

    // Get the user email
    final String? email = userEmail;

    // Create a request to send the image and email to the backend
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://expertstrials.xyz/Garifix_app/update_profile'),
    );

    // Add the email to the request
    request.fields['email'] = email ?? '';

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
    final String? email = userEmail; // Assuming userEmail is defined
    print('Fetching user info for email: $email'); // Debug email

    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/get_user_info?email=$email'),
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
}


@override
Widget build(BuildContext context) {
      if (userEmail == null) {
      return const Center(child: CircularProgressIndicator()); // Show loading indicator while fetching data
    }
  return Scaffold(
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



