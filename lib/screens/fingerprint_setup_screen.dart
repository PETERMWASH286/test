import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart'; // Import the local_auth package
import 'dart:convert';
import 'home_screen.dart';
import 'package:flutter/services.dart';

class FingerprintSetupScreen extends StatefulWidget {
  final String email;

  const FingerprintSetupScreen({super.key, required this.email});

  @override
  _FingerprintSetupScreenState createState() => _FingerprintSetupScreenState();
}

class _FingerprintSetupScreenState extends State<FingerprintSetupScreen> {
  final List<String> _pinDigits = ['', '', '', ''];
  final LocalAuthentication auth = LocalAuthentication(); // Instance of LocalAuthentication

// Method to check if the device has biometrics available
Future<bool> _checkBiometrics() async {
  try {
    // Check if the device can check biometrics and if the hardware is available
    final bool canCheckBiometrics = await auth.canCheckBiometrics;
    final bool isHardwareAvailable = await auth.isDeviceSupported();
    return canCheckBiometrics && isHardwareAvailable;
  } catch (e) {
    // Handle any errors during the check
    print("Error checking biometrics: $e");
    return false;
  }
}

// Method to authenticate with fingerprint
Future<void> _authenticateWithFingerprint() async {
  bool authenticated = false;

  // Check if the device has biometrics and if the hardware is available
  if (await _checkBiometrics()) {
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to setup your fingerprint',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      // Handle PlatformException during fingerprint authentication
      print("PlatformException during fingerprint authentication: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication error: ${e.message}")),
      );
      return;
    }

    if (authenticated) {
      // Save the fingerprint confirmation
      await _saveFingerprintConfirmation();
    } else {
      // Authentication failed, notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fingerprint authentication failed")),
      );
    }
  } else {
    // No biometric hardware or setup, notify the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No biometric authentication available. Please set up your fingerprint in device settings.")),
    );
  }
}

// Method to check both biometric and device credential authentication capabilities
Future<void> _checkAndAuthenticate() async {
  bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
  bool canAuthenticateWithDeviceCredentials = await auth.isDeviceSupported();

  if (!canAuthenticateWithBiometrics && !canAuthenticateWithDeviceCredentials) {
    // If neither biometric nor device credentials are available, show error
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please set up a fingerprint in device settings.")),
    );
    return;
  }

  // If available, proceed with fingerprint authentication
  await _authenticateWithFingerprint();
}

// Save fingerprint confirmation to the database
Future<void> _saveFingerprintConfirmation() async {
  final response = await http.post(
    Uri.parse('https://expertstrials.xyz/Garifix_app/setup_fingerprint'), // Update your server endpoint
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{  // Use dynamic to accommodate different types
      'email': widget.email,
      'fingerprint_data': 1,  // Setting fingerprint_data to 1
    }),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fingerprint enrolled successfully!")),
    );
    // Proceed to the next step
    // Navigate to HomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to save fingerprint: ${response.body}")),
    );
  }
}



  void _onNumberTap(String number) {
    // Fill the first empty PIN digit
    for (int i = 0; i < _pinDigits.length; i++) {
      if (_pinDigits[i].isEmpty) {
        setState(() {
          _pinDigits[i] = number;
        });
        break;
      }
    }

    // Auto-submit when all digits are filled
    if (!_pinDigits.contains('')) {
      // Navigate to confirmation page
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ConfirmPinScreen(
          email: widget.email,
          pin: _pinDigits.join(''), // Join digits into a single PIN string
        ),
      ));
    }
  }

  void _onDeleteTap() {
    // Remove the last digit
    for (int i = _pinDigits.length - 1; i >= 0; i--) {
      if (_pinDigits[i].isNotEmpty) {
        setState(() {
          _pinDigits[i] = '';
        });
        break;
      }
    }
  }

  Widget _buildPinDigitInput(int index) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.deepPurple[100],
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _pinDigits[index],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Fingerprint and PIN Setup',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 1.2, // Slight spacing for elegance
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 5,
      shadowColor: Colors.deepPurple.withOpacity(0.5), // Add a slight shadow
    ),
    body: SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(8, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 60,
                  color: Colors.deepPurple,
                  shadows: [
                    Shadow(
                      color: Colors.deepPurpleAccent,
                      blurRadius: 20,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                const Text(
                  'Setup Your Fingerprint and PIN',
                  style: TextStyle(
                    fontSize: 18, // Slightly larger font size
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) => _buildPinDigitInput(index)),
                ),
                const SizedBox(height: 5),
                _buildNumberPad(),
                const SizedBox(height: 30),
                const Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: Colors.deepPurple,
                  shadows: [
                    Shadow(
                      color: Colors.purpleAccent,
                      blurRadius: 20,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _authenticateWithFingerprint, // Add fingerprint authentication button
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: Colors.deepPurple, // Custom background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded button
                    ),
                    elevation: 5,
                    shadowColor: Colors.purpleAccent.withOpacity(0.5),
                  ),
                  child: const Text(
                    "Authenticate with Fingerprint",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildNumberPad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        String buttonText;
        if (index < 9) {
          buttonText = '${index + 1}';
        } else if (index == 9) {
          buttonText = '0';
        } else {
          buttonText = index == 10 ? 'X' : ''; // Changed to 'X' for delete
        }

        return GestureDetector(
          onTap: () {
            if (buttonText == 'X') {
              _onDeleteTap();
            } else {
              _onNumberTap(buttonText);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(15),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepPurple[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}


class ConfirmPinScreen extends StatefulWidget {
  final String email;
  final String pin;

  const ConfirmPinScreen({super.key, required this.email, required this.pin});

  @override
  _ConfirmPinScreenState createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends State<ConfirmPinScreen> {
  final List<String> _confirmPinDigits = ['', '', '', ''];

  void _onConfirmNumberTap(String number) {
    // Fill the first empty confirm PIN digit
    for (int i = 0; i < _confirmPinDigits.length; i++) {
      if (_confirmPinDigits[i].isEmpty) {
        setState(() {
          _confirmPinDigits[i] = number;
        });
        break;
      }
    }

    // Auto-submit when all digits are filled
    if (!_confirmPinDigits.contains('')) {
      _confirmPin();
    }
  }

  void _onDeleteTap() {
    // Remove the last digit
    for (int i = _confirmPinDigits.length - 1; i >= 0; i--) {
      if (_confirmPinDigits[i].isNotEmpty) {
        setState(() {
          _confirmPinDigits[i] = '';
        });
        break;
      }
    }
  }

void _confirmPin() async {
  if (_confirmPinDigits.join('') == widget.pin) {
    // Save to database
    final response = await http.post(
      Uri.parse('https://expertstrials.xyz/Garifix_app/save_pin'), // Use the IP address of your Flask server
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': widget.email,
        'pin': widget.pin, // The original PIN
      }),
    );

    if (response.statusCode == 200) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN saved successfully!")),
      );

      // Navigate to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save PIN: ${response.body}")),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PINs do not match!")),
    );
  }
}


  Widget _buildConfirmPinDigitInput(int index) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.deepPurple[100],
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _confirmPinDigits[index],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text(
    'Confirm Your PIN',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      letterSpacing: 1.2, // Add slight letter-spacing for elegance
    ),
  ),
  centerTitle: true,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.of(context).pop(); // Navigate back to the previous screen
    },
  ),
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.deepPurple, Colors.purpleAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
  elevation: 5,
  shadowColor: Colors.deepPurple.withOpacity(0.5), // Add a shadow for depth
),

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(10, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Confirm Your PIN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) => _buildConfirmPinDigitInput(index)),
                  ),
                  const SizedBox(height: 20),
                  _buildConfirmNumberPad(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmNumberPad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        String buttonText;
        if (index < 9) {
          buttonText = '${index + 1}';
        } else if (index == 9) {
          buttonText = '0';
        } else {
          buttonText = index == 10 ? 'X' : ''; // Changed to 'X' for delete
        }

        return GestureDetector(
          onTap: () {
            if (buttonText == 'X') {
              _onDeleteTap();
            } else {
              _onConfirmNumberTap(buttonText);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(15),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepPurple[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
