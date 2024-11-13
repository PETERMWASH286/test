import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuccessPopup extends StatefulWidget {
  final String message; // The message to display in the popup

  const SuccessPopup({Key? key, required this.message}) : super(key: key);

  @override
  _SuccessPopupState createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
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
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.white,
        elevation: 24,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        titlePadding: const EdgeInsets.only(top: 24),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.rotate(
                angle: _controller.value * 6.28, // Rotates the icon
                child: child,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 60,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 10,
                    color: Colors.black26,
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Success!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent.shade700,
                shadows: const [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 8,
                    color: Colors.black26,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          widget.message,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
style: ElevatedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  backgroundColor: Colors.greenAccent.shade700, // Updated property
  foregroundColor: Colors.white, // Updated property
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  elevation: 10,
  shadowColor: Colors.greenAccent,
),

              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
