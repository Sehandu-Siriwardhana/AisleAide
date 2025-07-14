import 'dart:async';
import 'package:aisleaide/Grid_and_Navigation/grid.dart';
import 'package:aisleaide/Voice_assistant_and_database/camera_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/cart_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/home_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';


class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
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

  void _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() {});
    } catch (error) {
      if (kDebugMode) {
        print("Error stopping speech recognition: $error");
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
      } else if (_wordsSpoken.toLowerCase().contains('camera screen')) {
        _navigateToCameraScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('cart screen')) {
        _navigateToCartScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('profile screen')) {
        _navigateToProfileScreen(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GridMap(productName: ''),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _startListening,
              tooltip: 'Start Listening',
              backgroundColor: const Color.fromRGBO(54, 72, 107, 1),
              child: const Icon(
                Icons.mic,
                color: Color.fromRGBO(246, 241, 241, 1),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHomeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
    _speakText("You have navigated to the Home screen.");
  }

  void _navigateToCameraScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    _speakText("You have navigated to the Camera screen.");
  }

  void _navigateToCartScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
    _speakText("You have navigated to the Cart screen.");
  }

  void _navigateToProfileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    _speakText("You have navigated to the Profile screen.");
  }
}

void main() {
  runApp(const MaterialApp(
    home: NavigationScreen(),
  ));
}
