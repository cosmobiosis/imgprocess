import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:imgprocess/pages/result_screen.dart';

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
        child: Stack(
          children: <Widget>[
            Container(
                height: double.infinity,
                width: double.infinity,
                child: _adjustedImage(context, widget.imgPath)),
            _processButton(context, widget.imgPath),
          ],
        ),
      ),
    );
  }

  Widget _adjustedImage(BuildContext context, String imgPath) {
    return FutureBuilder(
        future: _setImageInfo(imgPath),
        builder: (context, snapshot) {
          if (this._imgHeight == null || this._imgWidth == null) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          return this._imgHeight < this._imgWidth
              ? RotatedBox(quarterTurns: 1, child: this._img)
              : this._img;
        });
  }

  Future<void> _setImageInfo(String _imgPath) async {
    File imageFile = new File(_imgPath);
    var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
    this._imgHeight = decodedImage.height;
    this._imgWidth = decodedImage.width;
    this._img = Image.file(imageFile, fit: BoxFit.fill);
  }

  Widget _processButton(BuildContext context, String _imgPath) {
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

    Widget button = RaisedButton(
      onPressed: () {
        _processImage();
      },
      textColor: Colors.white,
      padding: const EdgeInsets.all(1.0),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: const Text('Process Image', style: TextStyle(fontSize: 20)),
      ),
    );

    return FutureBuilder(
        future: _setImageInfo(_imgPath),
        builder: (context, snapshot) {
          if (this._imgHeight == null || this._imgWidth == null) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          return this._imgHeight < this._imgWidth
              ? Container(
                  alignment: Alignment(-0.9, 0),
                  child: RotatedBox(quarterTurns: 1, child: button),
                )
              : Container(
                  alignment: Alignment(0.0, 0.9),
                  child: button,
                );
        });
  }
}
