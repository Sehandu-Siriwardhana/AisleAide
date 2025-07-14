import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart' as dialogFlowtter;

import 'camera_screen.dart';
import 'cart_screen.dart';
import 'navigation_screen.dart';
import 'profile_screen.dart';
import 'search_products_screen.dart';
import 'recent_shopping_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SpeechToText _speechToText;
  final FlutterTts _flutterTts = FlutterTts();
  Uint8List? gif1Bytes;
  Uint8List? gif2Bytes;
  Uint8List? gif3Bytes;
  Uint8List? recentShoppingGifBytes;

  String _wordsSpoken = "";
  String _dialogFlowResponse = "";

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    initSpeech();
    loadGifs();
    _speakText("Welcome to Aisle Aide ");
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
     if (_wordsSpoken
          .toLowerCase()
          .contains('search products screen')) {
        _navigateToSearchProductsScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('recent shopping')) {
        _navigateToRecentShoppingScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('navigation screen')) {
        _navigateToNavigationScreen(context);
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
      final dialogFlowtter.DialogAuthCredentials credentials =
          await dialogFlowtter.DialogAuthCredentials.fromFile(
              'assets/aisleaide123-846df6ca964b.json');
      final dialogFlowtter.DialogFlowtter dialogFlowtterInstance =
          dialogFlowtter.DialogFlowtter(credentials: credentials);

      final dialogFlowtter.QueryInput queryInput = dialogFlowtter.QueryInput(
        text: dialogFlowtter.TextInput.fromJson({
          "text": query,
          "languageCode": "en",
        }),
      );

      final dialogFlowtter.DetectIntentResponse response =
          await dialogFlowtterInstance.detectIntent(
        queryInput: queryInput,
      );

      final String? textResponse = response.text;

      setState(() {
        _dialogFlowResponse = textResponse ?? "No response from Dialogflow";
      });

      _speakText(_dialogFlowResponse);
    } catch (error) {
      if (kDebugMode) {
        print("Error handling DialogFlow: $error");
      }
    }
  }

  Future<void> _handleFinalResult(String wordsSpoken) async {
    await handleDialogFlow(wordsSpoken);
  }

  Future<void> loadGifs() async {
    gif1Bytes = await _loadGifBytes('assets/checklist.gif');
    gif2Bytes = await _loadGifBytes('assets/search.gif');
    gif3Bytes = await _loadGifBytes('assets/shopping.gif');
    recentShoppingGifBytes = await _loadGifBytes('assets/history1.gif');
    setState(() {});
  }

  Future<Uint8List> _loadGifBytes(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return Uint8List.view(data.buffer);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(80), // Adjust the height as needed
      child: Padding(
        padding: const EdgeInsets.only(
            top: 20), // Adjust the top padding as needed
        child: AppBar(
          title: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: 'Welcome to ',
                  style: TextStyle(
                      color: Colors.black, fontSize: 20), // Change size here
                ),
                TextSpan(
                  text: '\n', // Add a newline here
                ),
                TextSpan(
                  text: 'AISLEAIDE',
                  style: TextStyle(
                      color: Color.fromRGBO(
                          54, 72, 107, 1)), // Change color here
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    body: Column(
      children: [
        // Add the image above the buttons
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Image.asset(
            'assets/homepageimage.jpg', // Replace 'your_image.png' with your actual image path
            // Adjust the width as needed
            height: 230, // Adjust the height as needed
          ),
        ),
        Expanded(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildButtonWithGif(
                    onPressed: () =>
                        _navigateToSearchProductsScreen(context),
                    label: 'Search\nProducts',
                    gifBytes: gif2Bytes,
                  ),
                ),
                const SizedBox(width: 10), // Adjust the spacing between buttons
                Expanded(
                  child: _buildButtonWithGif(
                    onPressed: () =>
                        _navigateToRecentShoppingScreen(context),
                    label: 'Recent\nShopping',
                    gifBytes: recentShoppingGifBytes,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 70), // Adjusted the SizedBox height
      ],
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


  Widget _buildButtonWithGif({
    required VoidCallback onPressed,
    required String label,
    Uint8List? gifBytes,
  }) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(
              color: Color.fromRGBO(54, 72, 107, 1),
              width: 2.5,
            ),
          ),
        ),
        child: SizedBox(
          width: 150, // Adjust button width as needed
          height: 150, // Adjust button height as needed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (gifBytes != null)
                Image.memory(
                  gifBytes,
                  width: 80,
                  height: 80,
                ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  void _navigateToSearchProductsScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const SearchProductsScreen(),
    ));
    _speakText("You have navigated to the Search Products screen.");
  }

 

  void _navigateToRecentShoppingScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const RecentShoppingScreen(),
    ));
    _speakText("You have navigated to the Recent screen.");
  }

  void _navigateToNavigationScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const NavigationScreen(),
    ));
    _speakText("You have navigated to the Navigation screen.");
  }

  void _navigateToCameraScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const CameraScreen(),
    ));
    _speakText("You have navigated to the Product Scanner screen.");
  }

  void _navigateToCartScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const CartScreen(),
    ));
    _speakText("You have navigated to the Cart screen.");
  }

  void _navigateToProfileScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const ProfileScreen(),
    ));
    _speakText("You have navigated to the Profile screen.");
  }
}

void main() {
  runApp(const MaterialApp(
    home: HomeScreen(),
  ));
}
