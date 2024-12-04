import 'package:flutter/material.dart';
import 'mechanic_packages_payment.dart';
import 'car_owner_packages_payment.dart';
import 'enterprise_packages_payment.dart';
import 'enterprise_mechanic_packages_payment.dart';
import 'auto_supply_store_package_screen.dart'; // Import the new Auto Supply Store screen

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'switch_signup.dart';

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
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = "User"; // Default full name

  @override
  void initState() {
    super.initState();
    _fetchUserFullName();
  }

  Future<void> _fetchUserFullName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    final response = await http.get(Uri.parse('https://expertstrials.xyz/Garifix_app/get_full_name?email=$email'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        _fullName = data['full_name'] ?? "User";
      });
    } else {
      print('Failed to load user full name: ${response.statusCode}');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text('If you need assistance, please contact our support team at support@mecarapp.com.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Mecar App'),
        backgroundColor: Colors.deepPurple,
        elevation: 10,
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
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),

        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                child: Text(
                  'Hello, $_fullName! Please select your role to proceed.',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Car Owner Button
              CrazyButton(
                icon: Icons.directions_car,
                label: 'I am a Car Owner',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CarOwnerScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Mechanic Button
              CrazyButton(
                icon: Icons.build,
                label: 'I am a Mechanic',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MechanicScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Enterprise Car Owner Button
              CrazyButton(
                icon: FontAwesomeIcons.building,
                label: 'Enterprise Car Owner',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EnterpriseCarOwnerScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Enterprise Mechanic Button
              CrazyButton(
                icon: FontAwesomeIcons.building,
                label: 'Enterprise Mechanic',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EnterpriseMechanicScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Auto Supply Store Button
              CrazyButton(
                icon: FontAwesomeIcons.store, // Use a different icon for Auto Supply Store
                label: 'Auto Supply Store',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AutoStorePaymentScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom CrazyButton Widget for consistency and style
class CrazyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const CrazyButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      icon: Icon(icon, size: 28, color: Colors.white),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
