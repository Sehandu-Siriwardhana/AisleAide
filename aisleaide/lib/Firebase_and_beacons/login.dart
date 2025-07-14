import 'package:aisleaide/Firebase_and_beacons/fire_function.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      body: Stack(
        children: [
          _buildBackgroundCircles(context, topLeft: true),
          _buildBackgroundCircles(context),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 350,
                  child: Lottie.asset(
                    'assets/loginpage_animation.json',
                    height: 350,
                    width: 350,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Column(
                  children: [
                    Text(
                      "Welcome to",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    Text("AISLEAIDE",
                        style: TextStyle(
                            fontSize: 55,
                            fontWeight: FontWeight.w900,
                            color: Color.fromRGBO(54, 72, 107, 1))),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 250,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        side: const BorderSide(
                          color: Color.fromRGBO(54, 72, 107, 1),
                          width: 2.5, // Adjust the border width as desired
                        ),
                      ),
                      elevation: 10, // Add shadow effect
                    ),
                    onPressed: () async {
                      await _firebaseService.signInWithGoogle();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/google_icon.png',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Login with Google",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircles(BuildContext context, {bool topLeft = false}) {
    double topPosition = 0;
    double leftPosition = 0;

    if (topLeft) {
      topPosition = -MediaQuery.of(context).size.width * 0.5;
      leftPosition = -MediaQuery.of(context).size.width * 0.5;
    } else {
      topPosition = MediaQuery.of(context).size.height -
          MediaQuery.of(context).size.width * 0.5;
      leftPosition = MediaQuery.of(context).size.width -
          MediaQuery.of(context).size.width * 0.5;
    }

    return Positioned(
      top: topPosition,
      left: leftPosition,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(54, 72, 107, 1),
              Color.fromRGBO(122, 151, 195, 1),
            ],
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
