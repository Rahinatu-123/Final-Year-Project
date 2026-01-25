import 'package:flutter/material.dart';

class MeasurementIndicationScreen extends StatelessWidget {
  const MeasurementIndicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme feels more "Tech/AI"
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.accessibility_new_rounded,
                color: Color(0xFFF06262),
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "AI Body Scan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "For the most accurate custom fit, follow these steps precisely.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Steps List
              _buildStep(
                Icons.checkroom,
                "Wear form-fitting clothes (e.g., leggings/t-shirt).",
              ),
              _buildStep(
                Icons.wb_sunny_outlined,
                "Ensure the room is well-lit.",
              ),
              _buildStep(
                Icons.person_pin_circle_outlined,
                "Stand 2 meters away from the camera.",
              ),
              _buildStep(
                Icons.phonelink_ring_outlined,
                "Keep the phone perfectly vertical.",
              ),

              const Spacer(),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06262),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    // This will lead to the Camera Overlay Screen
                    print("Opening AI Camera...");
                  },
                  child: const Text(
                    "I'M READY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
