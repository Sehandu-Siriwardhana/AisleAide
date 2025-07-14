import 'cart_screen.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';
import 'navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart' as services;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class RecentShoppingScreen extends StatefulWidget {
  const RecentShoppingScreen({super.key});

  @override
  State<RecentShoppingScreen> createState() => _RecentShoppingScreenState();
}

class _RecentShoppingScreenState extends State<RecentShoppingScreen> {
  /// Stream to fetch the user's recent shopping data
  Stream<QuerySnapshot>? _usersStream;
  final FlutterTts _flutterTts = FlutterTts();
  late final SpeechToText _speechToText;
  String _wordsSpoken = "";
  String _dialogFlowResponse = "";
  DateTime? _selectedDate;
  String? _selectedDateText;

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    initSpeech();
    /// Initialize the stream
    _usersStream = _getInitialStream();
  }

  /// Initialize the speech recognition
  Future<void> initSpeech() async {
    try {
      await _speechToText.initialize(
        debugLogging: true,
        finalTimeout: const Duration(seconds: 1),
      );
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1);
      await _flutterTts.setSpeechRate(0.5);
      setState(() {});
    } catch (error) {
      debugPrint("Error initializing speech recognition: $error");
    }
  }

  /// Get the initial stream of purchases
  Stream<QuerySnapshot> _getInitialStream() {
    return FirebaseFirestore.instance
        .collection('Purchases')
        .orderBy('purchaseDate', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getFilteredStream(DateTime selectedDate) {
    /// Get the start and end of the selected date
    DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
    /// Filter the purchases based on the selected date
    return FirebaseFirestore.instance
        .collection('Purchases')
        .where('purchaseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('purchaseDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('purchaseDate', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// Unfocuses the text field when tapping outside
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Your Recent Shopping'),
          /// Remove the shadow under the AppBar
          scrolledUnderElevation: 0,
          /// Set the status bar color
          systemOverlayStyle: const services.SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            /// Search bar to select the date
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                height: 54,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 26),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: const Color(0xFFEDF0F7)),
                  color: const Color(0xFFEDF0F7),
                ),
                child: Row(
                  children: [
                    /// Display the selected date
                    Text(
                      _selectedDateText ?? 'Search Date',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    const Spacer(),
                    /// Calendar icon
                    Icon(Icons.calendar_today, color: Colors.black.withOpacity(0.5)),
                    const SizedBox(width: 12),
                    /// Display the clear button if a date is selected
                    _selectedDateText != null
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = null;
                              _selectedDateText = null;
                              _usersStream = _getInitialStream();
                            });
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        )
                      : const SizedBox(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            /// StreamBuilder to fetch and display the user's recent shopping data
            StreamBuilder<QuerySnapshot>(
              stream: _usersStream,
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                /// Display error message if there is an error
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Text(
                      "Something went wrong",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  );
                }
                /// Display loading text while fetching data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Text(
                      "Loading",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  );
                }
                /// Display message if no data is found
                if(snapshot.data!.docs.isEmpty){
                  return const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Text(
                      "No data found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  );
                }
                return Expanded(
                  /// Removes padding from the ListView
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    /// ListView.builder to display the user's recent shopping data
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(26, 0, 26, 50),
                      itemBuilder: (context, index) {
                        /// Format DateTime to the desired format
                        String formattedDate = DateFormat('yyyy.MM.dd  hh:mma').format(snapshot.data!.docs[index]['purchaseDate'].toDate());
                        /// Get the total amount of the purchase
                        int totalProducts = snapshot.data!.docs[index]['purchasesTotal'];
                        /// Get the list of purchased items
                        List<dynamic> purchaseDetails = snapshot.data!.docs[index]['purchaseItems'];
                        return GestureDetector(
                          onTap: (){
                            /// Display the purchase details in an AlertDialog
                            _showPurchaseDetails(
                              context,
                              formattedDate,
                              purchaseDetails,
                              totalProducts,
                            );
                          },
                          /// Display the purchase date
                          child: Container(
                            height: 69,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  /// Display the index of the purchase
                                  child: Text(
                                    "${index + 1}.",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 260,
                                  /// Display the formatted date of the purchase
                                  child: Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        /// Floating action button to start listening to the user's speech
        floatingActionButton: FloatingActionButton(
          onPressed: _startListening,
          tooltip: 'Start Listening',
          backgroundColor: const Color.fromRGBO(20, 108, 148, 1),
          child: const Icon(
            Icons.mic,
            size: 32,
            color: Color.fromRGBO(246, 241, 241, 1),
          ),
        ),
      ),
    );
  }

  /// Function to select the date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        /// Format DateTime to the desired format
        _selectedDateText = DateFormat('yyyy.MM.dd').format(picked).toString();
        /// Update the stream
        _usersStream = _getFilteredStream(_selectedDate!);
      });
    }
  }

  /// Function to display the purchase details in an AlertDialog
  void _showPurchaseDetails(BuildContext context, String formattedDate, List<dynamic> purchaseDetails, int totalProducts) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Purchase Details',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const SizedBox(height: 15),
                /// Display the date of the purchase
                Row(
                  children: [
                    const Text(
                      'Date:  ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                /// Display the header of the purchase details
                const Row(
                  children: [
                    Text(
                      'Item',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(width: 3),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.normal,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                /// Display the list of purchased items
                ...purchaseDetails.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${item['productName']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${item['productQuantity']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          width: 73,
                          child: Text(
                            'Rs. ${item['ProductsTotal']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Divider(thickness: 0.5, color: Colors.black.withOpacity(0.5)),
                /// Display the total amount of the purchase
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(
                      width: 50,
                      child: Text(
                        'Total: ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 73,
                      child: Text(
                        "Rs. ${totalProducts.toString()}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Divider(thickness: 0.5, color: Colors.black.withOpacity(0.5)),
                Divider(thickness: 0.5, color: Colors.black.withOpacity(0.5)),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actions: <Widget>[
            /// Close button to close the AlertDialog
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(20, 108, 148, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.only(right: 25, bottom: 15, top: 10),
        );
      },
    );
  }

  /// Start listening to the user's speech
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
      } else if (_wordsSpoken.toLowerCase().contains('profile screen')) {
        _navigateToProfileScreen(context);
      } else {
        _handleFinalResult(_wordsSpoken);
      }
    }
  }

  Future<void> _handleFinalResult(String wordsSpoken) async {
    try {
      if(wordsSpoken.contains("clear")){
        setState(() {
          _selectedDate = null;
          _selectedDateText = null;
          _usersStream = _getInitialStream();
        });
      }
      DateTime dateTime = convertStringToDateTime(wordsSpoken);
      /// Check if the spoken words contain a valid date
      if(dateTime.toString().contains("00:00:00.000")){
        setState(() {
          /// Format DateTime to the desired format
          _selectedDateText = DateFormat('yyyy.MM.dd').format(dateTime).toString();
        });
        _usersStream = _getFilteredStream(dateTime);
      }
    } catch (error) {
      debugPrint("Error stopping speech recognition: $error");
    }
    await handleDialogFlow(wordsSpoken);
  }

  DateTime convertStringToDateTime(String dateString) {
    DateFormat dateFormat = DateFormat("yyyy MMMM dd");
    return dateFormat.parse(dateString);
  }

  Future<void> handleDialogFlow(String query) async {
    try {
      final DialogAuthCredentials credentials = await DialogAuthCredentials.fromFile('assets/aisleaide123-846df6ca964b.json');
      final DialogFlowtter dialogFlowtter = DialogFlowtter(credentials: credentials);

      final QueryInput queryInput = QueryInput(
        text: TextInput(text: query, languageCode: "en"),
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
      debugPrint("Error handling DialogFlow: $error");
    }
  }

  /// Speak the given text
  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (error) {
      debugPrint("Error speaking text: $error");
    }
  }

  /// Stop listening to the user's speech
  // void _stopListening() async {
  //   try {
  //     await _speechToText.stop();
  //     setState(() {});
  //   } catch (error) {
  //     debugPrint("Error stopping speech recognition: $error");
  //   }
  // }

  /// Navigate to the Home screen when the user says "Home screen"
  void _navigateToHomeScreen(BuildContext context) {
    _speakText("You are navigating to the Home screen.");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  /// Navigate to the Navigation screen when the user says "Navigation screen"
  void _navigateToNavigationScreen(BuildContext context) {
    _speakText("You are navigating to the Navigation screen.");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NavigationScreen()),
    );
  }

  /// Navigate to the Camera screen when the user says "Camera screen"
  void _navigateToCameraScreen(BuildContext context) {
    _speakText("You are navigating to the Camera screen.");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  /// Navigate to the Cart screen when the user says "Cart screen"
  void _navigateToCartScreen(BuildContext context) {
    _speakText("You are navigating to the Cart screen.");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  /// Navigate to the Profile screen when the user says "Profile screen"
  void _navigateToProfileScreen(BuildContext context) {
    _speakText("You are navigating to the Profile screen.");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }
}
