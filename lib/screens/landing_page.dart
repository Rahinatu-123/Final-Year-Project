import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // --- Logo Section ---
              Image.asset('assets/logo.png', height: 130, width: 120),
              const SizedBox(height: 20),

              // --- Brand Name ---
              RichText(
                text: TextSpan(
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 32,
                    letterSpacing: 1.2,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Fashion',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: 'Hub',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // --- Welcome Text ---
              const Text(
                "Welcome to FashionHub",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 15),

              // --- Subtitle Text ---
              const Text(
                "Generate precise measurements, visualize styles in 2D, and connect with world-class designers.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),

              const Spacer(flex: 2),

              // --- Get Started Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06262),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFFF06262).withOpacity(0.5),
                  ),
                  child: const Text(
                    "Get started",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
