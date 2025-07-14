import 'package:aisleaide/Grid_and_Navigation/grid.dart';
import 'package:aisleaide/Voice_assistant_and_database/navigation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SearchProductsScreen extends StatefulWidget {
  const SearchProductsScreen({super.key});

  @override
  _SearchProductsScreenState createState() => _SearchProductsScreenState();
}

class _SearchProductsScreenState extends State<SearchProductsScreen> {
  late final SpeechToText _speechToText;
  late final FlutterTts _flutterTts;

  final TextEditingController _searchController = TextEditingController();
  String _availabilityMessage =
      "Check product availability"; // Track product availability message
  Color _availabilityColor =
      Colors.black; // Track text color based on availability

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    _flutterTts = FlutterTts();
    initSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _flutterTts.stop(); // Stop text-to-speech engine when disposing the widget
    super.dispose();
  }

  Future<void> initSpeech() async {
    try {
      await _speechToText.initialize();
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
    if (result.finalResult) {
      setState(() {
        _searchController.text = result.recognizedWords;
        _handleFinalResult(result.recognizedWords);
        String spokenWords = result.recognizedWords.toLowerCase();
        if (spokenWords == "navigate") {
          _navigateToNavigationScreen();
        }
      });
    }
  }

  Future<void> _handleFinalResult(String wordsSpoken) async {
    if (wordsSpoken.isNotEmpty && wordsSpoken.toLowerCase() != "navigate") {
      // Check if the product is available in Firestore
      bool available = await checkProductAvailability(wordsSpoken);
      if (available) {
        // Navigate to GridMap with the product name
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GridMap(productName: wordsSpoken.toLowerCase()),
          ),
        );
      }
      setState(() {
        if (available) {
          _availabilityMessage = "Product is available";
          _availabilityColor = Colors.green; // Set color to green
          _speakConfirmationMessage(
              "$wordsSpoken is available"); // Speak confirmation message
        } else {
          _availabilityMessage = "Product is not available";
          _availabilityColor = Colors.red; // Set color to red
          _speakConfirmationMessage(
              "$wordsSpoken is not available"); // Speak confirmation message
        }
      });
    } else {
      setState(() {
        _availabilityMessage =
            "Check product availability "; // Clear the availability message
        _availabilityColor = Colors.black; // Make text color transparent
      });
    }
  }

  Future<bool> checkProductAvailability(String productName) async {
    try {
      // Convert the searched product name to lowercase
      String lowercaseProductName = productName.toLowerCase();

      // Query Firestore to check if the product exists
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Products')
          .where('Product Name', isEqualTo: lowercaseProductName)
          .get();

      // Check if any documents are returned
      return querySnapshot.docs.isNotEmpty;
    } catch (error) {
      if (kDebugMode) {
        print("Error checking product availability: $error");
      }
      return false;
    }
  }

  Future<void> _speakConfirmationMessage(String message) async {
    await _flutterTts.speak(message);
  }

  void _navigateToNavigationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search by Products'),
      ),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 100.0), // Add top padding to the image
                child: Image.asset(
                  'assets/searchproductimage.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Product Name',
                    prefixIcon: const Icon(Icons.search),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color.fromRGBO(54, 72, 107, 1),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color.fromRGBO(54, 72, 107, 1),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (String value) {
                    _handleFinalResult(value);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color.fromRGBO(54, 72, 107, 1),
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _availabilityMessage,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: _availabilityColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _navigateToNavigationScreen();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromRGBO(54, 72, 107, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: const SizedBox(
                  width: 110,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.navigation,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
}
