import 'dart:developer';
import 'package:aisleaide/Voice_assistant_and_database/cart_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/home_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/navigation_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/profile_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
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
      } else if (_wordsSpoken.toLowerCase().contains('navigation screen')) {
        _navigateToNavigationScreen(context);
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
      appBar: AppBar(
        title: const Text('Product Scanner'),
      ),
      body: const CameraView(),
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
    _speakText("You have navigated to the Home screen.");
  }

  void _navigateToNavigationScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NavigationScreen()),
    );
    _speakText("You have navigated to the Navigation screen.");
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

class ScanController extends GetxController {
  CameraController? cameraController;
  late List<CameraDescription> cameras;
  RxList<dynamic> detectionResults = <dynamic>[].obs;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;

  @override
  void onInit() async {
    super.onInit();
    await initCamera();
    await initTflite();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController?.dispose();
  }

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
      );
      await cameraController?.initialize().then((_) {
        cameraController?.startImageStream((image) async {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            try {
              await objectDetector(image);
            } catch (e) {
              log('Error in object detection: $e');
            }
            cameraCount = 0;
          }
          update();
        });
      });
      isCameraInitialized.value = true;
      update();
    } else {
      log("Camera permission denied");
    }
  }

  initTflite() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    var detector = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
      }).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );

    if (detector != null) {
      log('Result is $detector');
      // Map each detection result to its label and ignore the confidence
      detectionResults.value = detector.map((result) => result['label']).toList();
      update();
    }
  }
}

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          if (!controller.isCameraInitialized.value) {
            return const Center(child: Text("Loading..."));
          }
          return Stack(
            children: [
              CameraPreview(controller.cameraController!),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  color: Colors.green.withOpacity(0.5),
                  child: Obx(() => Text(
                    'Product Details: ${controller.detectionResults.join(', ')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24, // Increased font size
                    ),
                  )),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
