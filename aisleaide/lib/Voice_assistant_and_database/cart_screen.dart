import 'package:aisleaide/Voice_assistant_and_database/recent_shopping_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'camera_screen.dart';
import 'home_screen.dart';
import 'navigation_screen.dart';
import 'profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final SpeechToText _speechToText;
  late final TextEditingController _searchController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  String _wordsSpoken = "";
  String _dialogFlowResponse = "";
  String _searchedProduct = "";
  double _totalAmount = 0.0;
  final List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
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
      } else if (_wordsSpoken.toLowerCase().contains('navigation screen')) {
        _navigateToNavigationScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('camera screen')) {
        _navigateToCameraScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('profile screen')) {
        _navigateToProfileScreen(context);
      } else if (_wordsSpoken.toLowerCase().contains('remove')) {
        _removeProductFromCart();
      } else if (_wordsSpoken.toLowerCase().contains('total price')) {
        _speakTotalPrice();
      } else {
        _handleFinalResult(_wordsSpoken);
      }
    }
  }

  void _removeProductFromCart() {
    bool found = false;
    if (_cartItems.isNotEmpty) {
      for (int i = 0; i < _cartItems.length; i++) {
        if (_wordsSpoken.toLowerCase().contains(_cartItems[i]['name'].toLowerCase())) {
          setState(() {
            _totalAmount -= _cartItems[i]['price'];
            _cartItems.removeAt(i);
            found = true;
          });
          _speakText("Product removed from cart.");
          break;
        }
      }
      if (!found) {
        _speakText("Product not found in cart.");
      }
    } else {
      _speakText("Cart is empty.");
    }
  }

  void _speakTotalPrice() {
    if (_totalAmount > 0) {
      final String totalPriceMessage = "Your total price is LKR $_totalAmount";
      _speakText(totalPriceMessage);
    } else {
      _speakText("Your cart is empty.");
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
    _searchedProduct = wordsSpoken.trim();
    await handleDialogFlow(wordsSpoken);
    // Search for the product when the final result is received
    _addToCart();
  }

  Future<double?> _fetchProductPrice(String productName) async {
    final QuerySnapshot<Map<String, dynamic>> products = await FirebaseFirestore
        .instance
        .collection('Products')
        .where('Product Name', isEqualTo: productName)
        .get();
    if (products.docs.isNotEmpty) {
      final product = products.docs.first.data();
      final int productPrice = product['Price'];
      return productPrice.toDouble();
    }
    return null;
  }

  void _navigateToHomeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
    _speakText("You have navigated to the Home screen.");
  }

  void _navigateToNavigationScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NavigationScreen()),
    );
    _speakText("You have navigated to the Navigation screen.");
  }

  void _navigateToCameraScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    _speakText("You have navigated to the Camera screen.");
  }

  void _navigateToProfileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    _speakText("You have navigated to the Profile screen.");
  }

  void _addToCart() async {
    if (_searchedProduct.isNotEmpty) {
      final productPrice = await _fetchProductPrice(_searchedProduct);
      if (productPrice != null) {
        setState(() {
          _cartItems.add({'name': _searchedProduct, 'price': productPrice});
          _totalAmount += productPrice;
          _searchController.clear(); // Clearing the text field
          _searchedProduct = ""; // Clearing the search text
        });

        final confirmationMessage = '$_searchedProduct has been added to the Cart';
        _speakText(confirmationMessage); // Speak out the confirmation message
      } else {
        // Handle case where product price is not found
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(54, 72, 107, 1), // Changing the background color to white
                border: Border.all(
                  color: const Color.fromRGBO(54, 72, 107, 1), // Changing the border color to black
                  width: 2.5, // Adjust the border width as desired
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount: LKR ${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white, // Changing the text color to white
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Functionality to print the bill
                      _navigateToRecentShoppingScreen(context); // Navigate to recent shopping screen
                    },
                    icon: const Icon(Icons.print),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(54, 72, 107, 1), // Change border color
                          width: 2.5, // Change border width
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(54, 72, 107, 1), // Change border color
                          width: 2.5, // Change border width
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchedProduct = value.trim();
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0), // Added padding
                child: TextButton(
                  onPressed: _addToCart, // Updated onPressed callback
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromRGBO(54, 72, 107, 1),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: const BorderSide(
                        color: Color.fromRGBO(54, 72, 107, 1),
                        width: 2.5, // Adjust the border width as desired
                      ),
                    ),
                  ),
                  child: const Text(
                    'Add Cart',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(54, 72, 107, 1), // Changing the border color to black
                    width: 2.5, // Adjust the border width as desired
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Products in the cart',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Column(
                      children: _cartItems.map((item) {
                        return Column(
                          children: [
                            ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['name']} - LKR ${item['price'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle),
                                    onPressed: () {
                                      setState(() {
                                        _totalAmount -= item['price']; // Update total amount
                                        _cartItems.remove(item); // Remove item from cart
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  void _navigateToRecentShoppingScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecentShoppingScreen()),
    );
    _speakText("You have navigated to the Recent Shopping screen.");
  }
}
