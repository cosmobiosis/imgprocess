import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:imgprocess/pupil/preview_screen.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:light/light.dart';

class TakePupilPictureScreen extends StatefulWidget {
  @override
  _TakePupilPictureScreenState createState() => _TakePupilPictureScreenState();
}

class _TakePupilPictureScreenState extends State<TakePupilPictureScreen> {
  CameraController _camera;
  String imgPath;
  bool getBackLen = true;

  String _luxString = 'Unknown';
  Light _light;
  StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    startLightSensing();
    availableCameras().then((availableCameras) {
      CameraDescription description = availableCameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.front,
      );
      _initCameraController(description).then((void v) {});
    }).catchError((err) {
      print('Error :${err.code}Error message : ${err.message}');
    });
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (_camera != null) {
      await _camera.dispose();
    }
    _camera = CameraController(cameraDescription, ResolutionPreset.high);
    _camera.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (_camera.value.hasError) {
        print('Camera error ${_camera.value.errorDescription}');
      }
    });

    try {
      await _camera.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: Column(
          children: <Widget>[
            _cameraPreviewWidget(),
            _camera == null || !_camera.value.isInitialized
                ? Center()
                : Expanded(
                    child: SizedBox(
                        width: double.infinity, // match_parent
                        child: _shutterButtonWidget(context)))
            // _luxStringWidget()
          ],
        ),
      ),
      floatingActionButton:
          Align(child: _toggleCameraButton(), alignment: Alignment(1, 0.8)),
    );
  }

  /// Display Camera preview.
  Widget _cameraPreviewWidget() {
    if (_camera == null || !_camera.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    // wrap the camera in aspect radio
    return AspectRatio(
      aspectRatio: _camera.value.aspectRatio,
      child: CameraPreview(_camera),
    );
  }

  Widget _luxStringWidget() {
    return Center(
        child: Text(
      "Light Intensity: " + this._luxString,
      style: TextStyle(color: Colors.blue[300]),
    ));
  }

  /// Display the control bar with buttons to take pictures
  Widget _shutterButtonWidget(context) {
    return RaisedButton(
        onPressed: () {
          _onCapturePressed(context);
          // _onCapturePressed(context);
        },
        color: Color(0xFF1976D2),
        textColor: Colors.white,
        child: Center(
          child: Text('Confirm', style: TextStyle(fontSize: 20)),
        ));
  }

  void _onCapturePressed(context) async {
    try {
      final path =
          join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
      await _camera.takePicture(path);
      this.stopLightSensing();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PupilPreviewScreen(
                imgPath: path,
                lightIntensity: double.parse(_luxString) ?? 0.0)),
      );
    } catch (e) {
      _showCameraException(e);
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error:${e.code}\nError message : ${e.description}';
    print(errorText);
  }

  Future<void> startLightSensing() async {
    _light = new Light();
    try {
      _subscription = _light.lightSensorStream.listen(onData);
    } on LightException catch (exception) {
      print(exception);
    }
  }

  Future<void> stopLightSensing() async {
    _subscription.cancel();
  }

  void onData(int luxValue) async {
    setState(() {
      _luxString = "$luxValue";
    });
  }

  Widget _toggleCameraButton() {
    Future<void> _toggleCameraDirection() async {
      CameraLensDirection dirt =
          getBackLen ? CameraLensDirection.back : CameraLensDirection.front;
      availableCameras().then((availableCameras) {
        CameraDescription description = availableCameras.firstWhere(
          (CameraDescription camera) => camera.lensDirection == dirt,
        );
        _initCameraController(description).then((void v) {});
        setState(() {
          getBackLen = !getBackLen;
        });
      }).catchError((err) {
        print('Error :${err.code}Error message : ${err.message}');
      });
    }

    return _camera == null || !_camera.value.isInitialized
        ? Center(child: null)
        : FloatingActionButton(
            onPressed: _toggleCameraDirection,
            heroTag: null,
            child: getBackLen
                ? const Icon(Icons.camera_rear)
                : const Icon(Icons.camera_front));
  }
}
