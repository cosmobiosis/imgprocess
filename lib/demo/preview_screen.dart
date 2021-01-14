import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:imgprocess/demo/result_screen.dart';

class PhotoPreviewScreen extends StatefulWidget {
  final String imgPath;

  PhotoPreviewScreen({this.imgPath});

  @override
  _PhotoPreviewScreenState createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  int _imgHeight;
  int _imgWidth;
  Image _img;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: <Widget>[
            _adjustedImage(context, widget.imgPath),
            _processButton(context, widget.imgPath),
          ],
        ),
      ),
    );
  }

  // generate image holder, first set the image and its meta data, then return the widget
  Widget _adjustedImage(BuildContext context, String imgPath) {
    return FutureBuilder(
        future: _setImageInfo(imgPath),
        builder: (context, snapshot) {
          if (this._imgHeight == null || this._imgWidth == null) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          // make sure the taken image span the whole screen
          return this._imgHeight < this._imgWidth
              ? RotatedBox(quarterTurns: 1, child: this._img)
              : this._img;
        });
  }

  // set image metadata and save the image to widget
  Future<void> _setImageInfo(String _imgPath) async {
    File imageFile = new File(_imgPath);
    Uint8List codedImage = await imageFile.readAsBytes();
    var decodedImage = await decodeImageFromList(codedImage);
    this._imgHeight = decodedImage.height;
    this._imgWidth = decodedImage.width;
    this._img = Image.file(imageFile, fit: BoxFit.fill);
  }

  Widget _processButton(BuildContext context, String _imgPath) {
    bool _firstPress = true;

    // construct the button logic
    Future<void> _processImage() async {
      File imageFile = new File(_imgPath);
      final FirebaseVisionImage visionImage =
          FirebaseVisionImage.fromFile(imageFile);
      final FaceDetector _faceDetector = FirebaseVision.instance.faceDetector(
          FaceDetectorOptions(
              mode: FaceDetectorMode.accurate,
              enableLandmarks: true,
              enableClassification: true));
      final List<Face> _faces = await _faceDetector.processImage(visionImage);

      // transistion to processed result page
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProcessedResultScreen(
                  imgPath: _imgPath,
                  faces: _faces,
                )),
      );
    }

    // construct the button UI
    Widget button = RaisedButton(
      onPressed: () async {
        if (_firstPress) {
          _firstPress = false;
          _processImage();
        }
      },
      textColor: Colors.white,
      padding: const EdgeInsets.all(1.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Text('Process Image', style: TextStyle(fontSize: 20)),
      ),
    );

    // async wrapper for button after the image meta data is set
    return FutureBuilder(
        future: _setImageInfo(_imgPath),
        builder: (context, snapshot) {
          if (this._imgHeight == null || this._imgWidth == null) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          return Container(
            alignment: Alignment(0.0, 0.9),
            child: button,
          );
        });
  }
}
