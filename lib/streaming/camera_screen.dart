import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image/image.dart' as imglib;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:quiver/collection.dart';

import 'package:imgprocess/utility/face_painter.dart';
import 'package:imgprocess/utility/streaming_utils.dart';

class CameraStreamingScreen extends StatefulWidget {
  @override
  _CameraStreamingScreenState createState() => _CameraStreamingScreenState();
}

class _CameraStreamingScreenState extends State<CameraStreamingScreen> {
  dynamic _scanResults;
  CameraController _camera;
  var interpreter;
  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.front;
  dynamic data = {};
  List e1;
  bool _faceFound = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: Column(
          children: <Widget>[
            _cameraStreamingWidget(context),
            Container(
                alignment: Alignment(0.0, 0.9),
                child: _toggleCameraButton()) // implement result here
          ],
        ),
      ),
    );
  }

  // INITIALIZATION GOES HERE
  void _initializeCamera() async {
    await loadModel();
    CameraDescription description = await getCamera(_direction);

    ImageRotation rotation = rotationIntToImageRotation(
      description.sensorOrientation,
    );

    _camera = CameraController(description, ResolutionPreset.high,
        enableAudio: false);
    await _camera.initialize();
    await Future.delayed(Duration(milliseconds: 500));

    _camera.startImageStream((CameraImage image) {
      if (_camera != null) {
        if (_isDetecting) return;
        _isDetecting = true;
        String res;
        dynamic finalResult = Multimap<String, Face>();
        detect(image, _getDetectionMethod(), rotation).then(
          (dynamic result) async {
            if (result.length == 0)
              _faceFound = false;
            else
              _faceFound = true;
            Face _face;
            imglib.Image convertedImage = convertCameraImage(image, _direction);
            for (_face in result) {
              double x, y, w, h;
              x = (_face.boundingBox.left - 10);
              y = (_face.boundingBox.top - 10);
              w = (_face.boundingBox.width + 10);
              h = (_face.boundingBox.height + 10);
              imglib.Image croppedImage = imglib.copyCrop(
                  convertedImage, x.round(), y.round(), w.round(), h.round());
              // 112 is the targeted input dimension of the face picture
              croppedImage = imglib.copyResizeCropSquare(croppedImage, 112);
              // int startTime = new DateTime.now().millisecondsSinceEpoch;
              res = _recog(croppedImage);
              // int endTime = new DateTime.now().millisecondsSinceEpoch;
              // print("Inference took ${endTime - startTime}ms");
              finalResult.add(res, _face);
            }
            setState(() {
              _scanResults = finalResult;
            });

            _isDetecting = false;
          },
        ).catchError(
          (_) {
            _isDetecting = false;
          },
        );
      }
    });
  }

  Future loadModel() async {
    try {
      // final gpuDelegateV2 = tfl.GpuDelegateV2(
      //     options: tfl.GpuDelegateOptionsV2(
      //   false,
      //   tfl.TfLiteGpuInferenceUsage.fastSingleAnswer,
      //   tfl.TfLiteGpuInferencePriority.minLatency,
      //   tfl.TfLiteGpuInferencePriority.auto,
      //   tfl.TfLiteGpuInferencePriority.auto,
      // ));

      // var interpreterOptions = tfl.InterpreterOptions()
      //   ..addDelegate(gpuDelegateV2);
      interpreter = await tfl.Interpreter.fromAsset('mobilefacenet.tflite');
    } on Exception {
      print('Failed to load model.');
    }
  }

  // PROCESSING LOGIC GOES HERE:
  String _recog(imglib.Image img) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    List output = List(1 * 192).reshape([1, 192]);
    interpreter.run(input, output);
    output = output.reshape([192]);
    e1 = List.from(output);
    return "Output";
  }

  HandleDetection _getDetectionMethod() {
    final faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
      ),
    );
    return faceDetector.processImage;
  }

  // UI GOES HERE:
  Widget _cameraStreamingWidget(context) {
    if (_camera == null || !_camera.value.isInitialized) {
      return Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _camera.value.aspectRatio,
      child: Container(
        constraints: const BoxConstraints.expand(),
        child: _camera == null
            ? const Center(child: null)
            : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CameraPreview(_camera),
                  _renderProcessedResults(),
                ],
              ),
      ),
    );
  }

  // machine learning outputs visualized
  Widget _renderProcessedResults() {
    const Text noResultsText = const Text('');
    if (_scanResults == null ||
        _camera == null ||
        !_camera.value.isInitialized) {
      return noResultsText;
    }
    CustomPainter painter;

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );
    painter = FaceDetectorPainter(imageSize, _scanResults);
    return CustomPaint(
      painter: painter,
    );
  }

  Widget _toggleCameraButton() {
    void _toggleCameraDirection() async {
      if (_direction == CameraLensDirection.back) {
        _direction = CameraLensDirection.front;
      } else {
        _direction = CameraLensDirection.back;
      }
      await _camera.stopImageStream();
      await _camera.dispose();

      setState(() {
        _camera = null;
      });

      _initializeCamera();
    }

    return _camera == null || !_camera.value.isInitialized
        ? Center(child: null)
        : FloatingActionButton(
            onPressed: _toggleCameraDirection,
            heroTag: null,
            child: _direction == CameraLensDirection.back
                ? const Icon(Icons.camera_front)
                : const Icon(Icons.camera_rear),
          );
  }
}
