import 'package:aisleaide/Firebase_and_beacons/login.dart';
import 'package:aisleaide/Voice_assistant_and_database/home_screen.dart';
import 'package:aisleaide/firebase_options.dart';
import 'package:aisleaide/mynavigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check if the user is already logged in
  User? user = FirebaseAuth.instance.currentUser;

  runApp(MyApp(user));
}

class MyApp extends StatelessWidget {
  final User? user;

  const MyApp(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const Login(),
        '/home': (context) => const HomeScreen()
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasData || user != null) {
            // If user is authenticated, show the HomeScreen with navigation bar
            return const MyNavigationBar();
          } else {
            // If user is not authenticated, show the Login screen
            return const Login();
          }
        },
      ),
    );
  }
}
