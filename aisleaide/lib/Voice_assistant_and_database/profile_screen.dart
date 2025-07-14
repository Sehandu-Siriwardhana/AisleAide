import 'package:aisleaide/Firebase_and_beacons/fire_function.dart';
import 'package:aisleaide/Voice_assistant_and_database/camera_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/cart_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/home_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/navigation_screen.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final SpeechToText _speechToText;
  final FlutterTts _flutterTts = FlutterTts();

  String _wordsSpoken = "";
  String _dialogFlowResponse = "";

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    initSpeech();
  }

  Future<void> initSpeech() async {
    try {
      await _speechToText.initialize();
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1);
      await _flutterTts.setSpeechRate(0.5);
      setState(() {});
    } catch (error) {
      if (kDebugMode) {
        print("Error initializing speech recognition: $error");
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechToText.isAvailable) {
      await initSpeech();
    } else {
      try {
        await _speechToText.listen(onResult: _onSpeechResult);
      } catch (error) {
        if (kDebugMode) {
          print("Error starting speech recognition: $error");
        }
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });

    if (result.finalResult) {
      if (_wordsSpoken.toLowerCase().contains('home screen')) {
        _navigateToHomeScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('navigation screen')) {
        _navigateToNavigationScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('camera screen')) {
        _navigateToCameraScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('cart screen')) {
        _navigateToCartScreen(context);
      } else {
        _handleFinalResult(_wordsSpoken);
      }
    }
  }

  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (error) {
      if (kDebugMode) {
        print("Error speaking text: $error");
      }
    }
  }

  Future<void> handleDialogFlow(String query) async {
    try {
      final DialogAuthCredentials credentials =
          await DialogAuthCredentials.fromFile(
              'assets/aisleaide123-846df6ca964b.json');
      final DialogFlowtter dialogFlowtter =
          DialogFlowtter(credentials: credentials);

      final QueryInput queryInput = QueryInput(
        text: TextInput(
          text: query,
          languageCode: "en",
        ),
      );

      final DetectIntentResponse response = await dialogFlowtter.detectIntent(
        queryInput: queryInput,
      );

      final String? textResponse = response.text;

      setState(() {
        _dialogFlowResponse = textResponse ?? "No response from Dialogflow";
      });

      _speakText(_dialogFlowResponse); // Speak out the Dialogflow response
    } catch (error) {
      if (kDebugMode) {
        print("Error handling DialogFlow: $error");
      }
    }
  }

  Future<void> _handleFinalResult(String wordsSpoken) async {
    await handleDialogFlow(wordsSpoken);
  }

  Future<void> _signOut() async {
    try {
      await FirebaseService()
          .signOutFromGoogle(); // Use the signOutFromGoogle method
    } catch (error) {
      if (kDebugMode) {
        print("Error signing out: $error");
      }
      // Show an error dialog or message to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text(
                "An error occurred while signing out. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout Confirmation"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                await _signOut(); // Logout the user
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await FirebaseService().deleteAccount();
    } catch (error) {
      if (kDebugMode) {
        print("Error deleting account: $error");
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text(
                "An error occurred while deleting your account. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Material(
                      elevation:
                          9, // Adjust the elevation as desired for the shadow effect
                      shape: const CircleBorder(),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                              "${_auth.currentUser?.photoURL}?${DateTime.now().millisecondsSinceEpoch}"),
                          radius: 90,
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _auth.currentUser?.displayName?.split(' ')[0] ?? "No User Found",
                          style: const TextStyle(
                              fontSize: 35, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _auth.currentUser?.displayName?.split(' ')[1] ?? "No User Found",
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              ElevatedButton(
                onPressed: _confirmLogout,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: const BorderSide(
                      color: Color.fromRGBO(54, 72, 107, 1),
                      width: 2.5, // Adjust the border width as desired
                    ),
                  ),
                ),
                child: const SizedBox(
                  width: 300, // Set the desired width for the button
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .start, // Align text and icon to the left
                    children: [
                      Icon(
                        Icons.logout_sharp, // Use the logout_sharp constant
                        size: 20,
                        color: Color.fromRGBO(54, 72, 107, 1),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18, // Adjust the font size as desired
                          color: Color.fromRGBO(54, 72, 107, 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _deleteAccount,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromRGBO(54, 72, 107, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: const SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.delete_forever,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 130),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startListening,
        tooltip: 'Start Listening',
        backgroundColor: const Color.fromRGBO(54, 72, 107, 1),
        child: const Icon(
          Icons.mic,
          color: Color.fromRGBO(246, 241, 241, 1),
          size: 32,
        ),
      ),
    );
  }

  void _navigateToHomeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _navigateToNavigationScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NavigationScreen()),
    );
  }

  void _navigateToCameraScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  void _navigateToCartScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }
}
