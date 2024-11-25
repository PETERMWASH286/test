import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // Import animated_text_kit
import 'sign_up_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Enhanced Slider Example',
      home: SliderPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SliderPage extends StatefulWidget {
  const SliderPage({super.key});

  @override
  _SliderPageState createState() => _SliderPageState();
}

class _SliderPageState extends State<SliderPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for sliders
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              SlideWidget(
                title: 'Mechanic',
                description:
                    'Get professional services from skilled mechanics.',
                icon: FontAwesomeIcons.wrench,
                colors: [
                  Color(0xFFFF6F61), // Vibrant Orange-Red
                  Color(0xFF42A5F5), // Bright Blue Accent
                  Color(0xFFFFEB3B), // Bright Yellow
                ], // Multi-gradient for a crazy effect
                iconColor: Color(0xFF1DE9B6), // Bright Teal
              ),
              SlideWidget(
                title: 'Car Owner',
                description: 'Empower your journey with reliable service.',
                icon: FontAwesomeIcons.car,
                colors: [
                  Color(0xFF283593), // Indigo
                  Color(0xFF64B5F6), // Light Blue Accent
                  Color(0xFF8E24AA), // Vibrant Purple
                ], // Multi-gradient for a crazy effect
                iconColor: Colors.yellow, // Unique icon color
              ),
              SlideWidget(
                title: 'Enterprise Mechanic',
                description: 'Scale your mechanical operations effortlessly.',
                icon: FontAwesomeIcons.industry,
                colors: [
                  Color(0xFF388E3C), // Green
                  Color(0xFF66BB6A), // Light Green
                  Color(0xFF0288D1), // Blue
                ], // Multi-gradient for a crazy effect
                iconColor: Colors.pink, // Unique icon color
              ),
              SlideWidget(
                title: 'Enterprise Car Owner',
                description: 'Efficient management for your vehicle fleet.',
                icon: FontAwesomeIcons.truck,
                colors: [
                  Color(0xFFEF6C00), // Orange
                  Color(0xFFFFD54F), // Amber
                  Color(0xFF7C4DFF), // Purple
                ], // Multi-gradient for a crazy effect
                iconColor: Colors.cyan, // Unique icon color
              ),
              SlideWidget(
                title: 'Retail Spare Parts',
                description: 'Buy high-quality parts from trusted suppliers.',
                icon: FontAwesomeIcons.cogs,
                colors: [
                  Color(0xFFD32F2F), // Red
                  Color(0xFFF06292), // Pink
                  Color(0xFF1976D2), // Blue
                ], // Multi-gradient for a crazy effect
                iconColor: Colors.greenAccent, // Unique icon color
              ),
            ],
          ),
          // "Get Started" Button
          if (_currentIndex == 4)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the SignUpScreen when pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ),
          // Slider indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _currentIndex == index ? Colors.white : Colors.white70,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class SlideWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final Color iconColor;

  const SlideWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon for slide
              Icon(
                icon,
                size: 100,
                color: iconColor, // Custom icon color
              ),
              const SizedBox(height: 20),
              // Slide title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Animated Slide description
              SizedBox(
                width: 300, // Control the width of the animation
                child: TypewriterAnimatedTextKit(
                  text: [description],
                  textStyle: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  speed: const Duration(milliseconds: 50), // Speed of animation
                  totalRepeatCount: 1, // Set to 1 for animation to appear once
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
