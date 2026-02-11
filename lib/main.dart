import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/landing_page.dart';
import 'screens/home.dart'; // Universal feed home for customers
import 'screens/fabric_seller_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize Firebase App Check. Use debug providers for local development so
  // the emulator / debug builds don't fail due to missing App Check provider.
  try {
    // Activate App Check. For local development, the debug provider
    // configured in Firebase Console will be used automatically.
    await FirebaseAppCheck.instance.activate();
  } catch (e) {
    debugPrint('Firebase App Check activation failed: $e');
  }

  // Set system UI overlay style for a modern look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FashionHub',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('authStateChanges: waiting...');
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          debugPrint('authStateChanges: hasData=${snapshot.hasData}');

          if (snapshot.hasData && snapshot.data != null) {
            final uid = snapshot.data!.uid;
            debugPrint('authStateChanges: user uid=$uid');
            // Fetch user profile to decide which home to show
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (ctx, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  debugPrint('userDoc: waiting for uid=$uid');
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                debugPrint(
                  'userDoc: hasData=${userSnap.hasData} exists=${userSnap.data?.exists}',
                );

                if (userSnap.hasData &&
                    userSnap.data != null &&
                    userSnap.data!.exists) {
                  final data = userSnap.data!.data() as Map<String, dynamic>?;
                  debugPrint('userDoc data for $uid: ${data.toString()}');
                  final role = (data?['role'] ?? 'customer')
                      .toString()
                      .toLowerCase();
                  if (role.contains('seller') || role.contains('fabric')) {
                    debugPrint('Navigating to FabricSellerHome for $uid');
                    return const FabricSellerHome();
                  }
                }

                debugPrint('Navigating to UniversalHome for $uid');
                // Default: universal feed home for customers/tailors
                return const UniversalHome();
              },
            );
          }

          return const WelcomeScreen();
        },
      ),
      routes: {'/home': (context) => const UniversalHome()},
    );
  }
}
