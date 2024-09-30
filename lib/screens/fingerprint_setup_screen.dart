import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart'; // Import the local_auth package
import 'dart:convert';
import 'home_screen.dart';

class FingerprintSetupScreen extends StatefulWidget {
  final String email;

  const FingerprintSetupScreen({super.key, required this.email});

  @override
  _FingerprintSetupScreenState createState() => _FingerprintSetupScreenState();
}

class _FingerprintSetupScreenState extends State<FingerprintSetupScreen> {
  final List<String> _pinDigits = ['', '', '', ''];
  final String _fingerprintData = ""; // Placeholder for actual fingerprint data
  final LocalAuthentication auth = LocalAuthentication(); // Instance of LocalAuthentication

  // Method to authenticate with fingerprint
  Future<void> _authenticateWithFingerprint() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to setup your fingerprint',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print("Error during fingerprint authentication: $e");
    }

    if (authenticated) {
      // Save the fingerprint to the server or locally
      await _saveFingerprint();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fingerprint authentication failed")),
      );
    }
  }

  // Save fingerprint to database
  Future<void> _saveFingerprint() async {
    final response = await http.post(
      Uri.parse('http://10.88.0.4:5000/save_fingerprint'), // Change to your server endpoint
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': widget.email,
        'fingerprint_data': _fingerprintData, // Placeholder for fingerprint data
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fingerprint saved successfully!")),
      );
      // Proceed to the next step
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
        title: const Text('Fingerprint and PIN Setup'),
        backgroundColor: Colors.deepPurple,
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
                  const Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Setup Your Fingerprint and PIN',
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
                    children: List.generate(4, (index) => _buildPinDigitInput(index)),
                  ),
                  const SizedBox(height: 20),
                  _buildNumberPad(),
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.fingerprint,
                    size: 50,
                    color: Colors.deepPurple,
                  ),
                  ElevatedButton(
                    onPressed: _authenticateWithFingerprint, // Add fingerprint authentication button
                    child: const Text("Authenticate with Fingerprint"),
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
            margin: const EdgeInsets.all(8),
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
      Uri.parse('http://10.88.0.4:5000/save_pin'), // Use the IP address of your Flask server
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
        title: const Text('Confirm Your PIN'),
        backgroundColor: Colors.deepPurple,
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
            margin: const EdgeInsets.all(8),
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
