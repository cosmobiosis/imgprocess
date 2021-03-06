import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:imgprocess/demo/camera_screen.dart';
// import 'package:imgprocess/streaming/camera_screen.dart';
import 'package:imgprocess/pupil/camera_screen.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();
  // disable auto rotation of cell phone
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(ImageProcessApp());
}

class ImageProcessApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.black));
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.black,
      ),
      debugShowCheckedModeBanner: false,
      home: TakePupilPictureScreen(),
    );
  }
}
