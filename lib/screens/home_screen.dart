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
    return const Scaffold(
      appBar: CustomAppBar(
        logoPath: 'assets/logo/app_logo.png',
        title: 'Privacy Policy',
      ),
      body: Center(child: Text('Privacy Policy Screen')),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        logoPath: 'assets/logo/app_logo.png',
        title: 'Help',
      ),
      body: Center(child: Text('Help Screen')),
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
