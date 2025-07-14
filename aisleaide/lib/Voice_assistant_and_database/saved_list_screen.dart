import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';

class SavedListScreen extends StatefulWidget {
  const SavedListScreen({super.key});

  @override
  _SavedListScreenState createState() => _SavedListScreenState();
}

class _SavedListScreenState extends State<SavedListScreen> {
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
      _handleFinalResult(_wordsSpoken);
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

      _speakText(
          _dialogFlowResponse); // Speak out the Dialogflow response
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
      appBar: AppBar(
        title: const Text('Saved List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildResponseContainer(
              label: 'User Command: $_wordsSpoken',
              backgroundColor: const Color.fromARGB(255, 165, 171, 171),
            ),
            const SizedBox(height: 20),
            _buildResponseContainer(
              label: 'Dialogflow Response: $_dialogFlowResponse',
              backgroundColor: const Color.fromARGB(255, 165, 171, 171),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startListening,
        tooltip: 'Start Listening',
        backgroundColor: const Color.fromRGBO(20, 108, 148, 1),
        child: const Icon(
          Icons.mic,
          color: Color.fromRGBO(246, 241, 241, 1),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildResponseContainer({
    required String label,
    required Color backgroundColor,
  }) {
    return Opacity(
      opacity: 0.8,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.black,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
