import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auto_store_home_screen.dart';

import 'home_screen.dart';

import 'enterprise_mechanic_home_screen.dart';
import 'car_owner_screen.dart';
import 'mechanic_list_screen.dart';
import 'enterprise_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  bool _isBiometricsSupported = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsSupport();
  }

  Future<void> _checkBiometricsSupport() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    setState(() {
      _isBiometricsSupported = canCheckBiometrics;
    });
  }

Future<void> _authenticateWithFingerprint() async {
  try {
    bool authenticated = await _localAuth.authenticate(
      localizedReason: 'Please authenticate to login',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (authenticated) {
      // Retrieve user email and role from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('userEmail');
      String? userRole = prefs.getString('user_role'); // Retrieve user role

      // Call the Flask backend to validate fingerprint
      final response = await http.post(
        Uri.parse('https://expertstrials.xyz/Garifix_app/validate_fingerprint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': userEmail}),
      );

      if (response.statusCode == 200) {
        // Extract access token
        
        // Store access token in SharedPreferences

        // Redirect based on the user role
        _redirectUser(userRole);
      } else {
        _showErrorSnackbar('Fingerprint validation failed. Please try PIN.');
      }
    }
  } on PlatformException catch (e) {
    print(e);
    _showErrorSnackbar('An error occurred during authentication.');
  }
}



void _loginWithPin() async {
  String pin = _pinController.text;

  // Retrieve user email from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userEmail = prefs.getString('userEmail');
  String? userRole = prefs.getString('user_role'); // Retrieve user role

  // Debugging logs
  print('User Email: $userEmail');
  print('User Role: $userRole');
  print('PIN: $pin');

  try {
    final response = await http.post(
      Uri.parse('https://expertstrials.xyz/Garifix_app/validate_pin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': userEmail, 'pin': pin}),
    );

    // Check for response status
    if (response.statusCode == 200) {
      // Extract the token from the response
      final responseData = jsonDecode(response.body);
      String? token = responseData['token']; // Assuming 'token' is the key in the JSON response

      if (token != null) {
        // Save the JWT token in SharedPreferences
        await prefs.setString('jwt_token', token);
        print('Token stored: $token');

        // Redirect based on the user role
        _redirectUser(userRole);
      } else {
        print('Error: No token in the response.');
        _showErrorSnackbar('Failed to retrieve token. Please try again.');
      }
    } else {
      // Print response body for debugging
      print('Error response: ${response.statusCode} - ${response.body}');
      _showErrorSnackbar('Invalid PIN. Please try again.');
    }
  } catch (e) {
    // Handle exceptions
    print('Error occurred: $e');
    _showErrorSnackbar('An error occurred while validating the PIN. Please try again.');
  }
}




void _redirectUser(String? userRole) {
  if (userRole == 'Mechanic') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MechanicListScreen()),
    );
  } else if (userRole == 'car_owner') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CarOwnerPage()),
    );
  } else if (userRole == 'enterprise_mechanic') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EnterpriseHomeScreen()),
    );
  } else if (userRole == 'enterprise_car_owner') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EnterpriseCarScreen()),
    );
  } else if (userRole == 'auto_store_owner') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AutoStoreHomeScreen()),
    );
  } else {
    // If no user role is found, navigate to HomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
}

// Error handling to show a message if needed
void _showErrorSnackbar(String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please login using your fingerprint or PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                if (_isBiometricsSupported) ...[
                  ElevatedButton(
                    onPressed: _authenticateWithFingerprint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fingerprint, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Login with Fingerprint',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter your PIN',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loginWithPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Login with PIN',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
