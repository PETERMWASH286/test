import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'fingerprint_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';  // For text animation
import 'package:font_awesome_flutter/font_awesome_flutter.dart';  // For beautiful icons
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfUserExists();
  }

  Future<void> _checkIfUserExists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isSignedUp = prefs.getBool('isSignedUp') ?? false;

    if (isSignedUp) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // For beautiful icons

Future<void> _signup() async {
  final response = await http.post(
    Uri.parse('https://expertstrials.xyz/Garifix_app/signup'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'full_name': _fullNameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
    }),
  );

  if (response.statusCode == 201) {
    // Show success message with a beautiful custom SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.checkCircle,  // A success check icon
              color: Colors.greenAccent,
              size: 32.0,
            ),
            const SizedBox(width: 10),
            AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  'Signup Successful!',
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
            ),
          ],
        ),
        backgroundColor: Colors.green[600],  // Green background for success
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );

    // Parse the response body to extract token
    final responseData = jsonDecode(response.body);
    String? token = responseData['token']; // Assuming 'token' is in the response JSON

    if (token != null) {
      // Save the token in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      print('Token stored: $token'); // You can log it for debugging

      // Save additional user info if needed
      await prefs.setBool('isSignedUp', true);
      await prefs.setString('userEmail', _emailController.text);

      // Redirect to the Fingerprint Setup screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FingerprintSetupScreen(email: _emailController.text),
        ),
      );
    } else {
      print('Error: No token in the response.');
    }
  } else {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.timesCircle,  // Error icon
              color: Colors.redAccent,
              size: 32.0,
            ),
            const SizedBox(width: 10),
            AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  'Signup Failed: ${response.body}',
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
            ),
          ],
        ),
        backgroundColor: Colors.red[600],  // Red background for error
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  backgroundColor: Colors.transparent, // Transparent to apply gradient
  elevation: 0,
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.deepPurple, Colors.purpleAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between left and right
    children: [
      // "Sign Up" in graffiti-style font on the left
      const Text(
        'Sign Up', 
        style: TextStyle(
          fontFamily: 'Graffiti',  // Make sure you have a graffiti-style font installed or added in your project
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.w900,  // Bold graffiti style
          letterSpacing: 1.2,
        ),
      ),
      // Logo and Company Name on the far right
      Row(
        children: [
          // Logo
          Image.asset(
            'assets/logo/app_logo.png', // Replace with your logo path
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10), // Space between logo and text
          // Company Name
          const Text(
            'Mecar',  // Replace with your company name
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 1.5,  // Add some spacing between letters
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black45,
                  offset: Offset(3, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade100, Colors.blueGrey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 80,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create a New Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Full Name Field
                    _buildTextField(_fullNameController, 'Full Name', Icons.person),
                    const SizedBox(height: 15),
                    // Email Field
                    _buildTextField(_emailController, 'Email', Icons.email),
                    const SizedBox(height: 15),
                    // Phone Number Field
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone),
                    const SizedBox(height: 20),
                    // Sign Up Button
                    ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Or sign up with
                    const Text(
                      'Or sign up with',
                      style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    // Google Sign Up Button
                    _buildSocialButton('Google', 'assets/icons/google.svg', Colors.white, Colors.black),
                    const SizedBox(height: 10),
                    // Facebook Sign Up Button
                    _buildSocialButton('Facebook', 'assets/icons/facebook.svg', Colors.blue, Colors.white),
                    const SizedBox(height: 20),
                    // Already have an account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?", style: TextStyle(color: Colors.deepPurple)),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Login', style: TextStyle(color: Colors.deepPurple)),
                        ),
                      ],
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.deepPurple.shade50,
      ),
    );
  }

  Widget _buildSocialButton(String platform, String assetPath, Color bgColor, Color fgColor) {
    return ElevatedButton.icon(
      onPressed: () {
        // Implement social signup logic
      },
      icon: SvgPicture.asset(
        assetPath,
        height: 24.0,
        width: 24.0,
      ),
      label: Text(platform),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: fgColor.withOpacity(0.4)),
        ),
      ),
    );
  }
}
