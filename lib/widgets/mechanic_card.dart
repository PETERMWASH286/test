import 'package:flutter/material.dart';

class MechanicCard extends StatelessWidget {
  final String name;
  final String location;
  final String specialty;

  const MechanicCard({
    super.key,
    required this.name,
    required this.location,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text('Location: $location'),
            Text('Specialty: $specialty'),
          ],
        ),
      ),
    );
  }
}
