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


  final List<TextEditingController> _pinControllers =
      List.generate(4, (index) => TextEditingController());

  void _loginWithPin() async {
    String pin = _pinControllers.map((controller) => controller.text).join();

    // Retrieve user email from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');
    String? userRole = prefs.getString('user_role');

    print('User Email: $userEmail');
    print('User Role: $userRole');
    print('PIN: $pin');

    try {
      final response = await http.post(
        Uri.parse('https://expertstrials.xyz/Garifix_app/validate_pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': userEmail, 'pin': pin}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String? token = responseData['token'];

        if (token != null) {
          await prefs.setString('jwt_token', token);
          print('Token stored: $token');
          _redirectUser(userRole);
        } else {
          print('Error: No token in the response.');
          _showErrorSnackbar('Failed to retrieve token. Please try again.');
        }
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        _showErrorSnackbar('Invalid PIN. Please try again.');
      }
    } catch (e) {
      print('Error occurred: $e');
      _showErrorSnackbar('An error occurred while validating the PIN. Please try again.');
    }
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.blue.shade100,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.blue.shade200,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 5,
                blurRadius: 15,
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
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Enter your 4-digit PIN to login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: _pinControllers[index],
                      autofocus: index == 0,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      obscureText: true,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < 3) {
                            FocusScope.of(context).nextFocus();
                          } else {
                            _loginWithPin();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
