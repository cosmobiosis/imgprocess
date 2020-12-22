import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class ProcessedResultScreen extends StatefulWidget {
  final String imgPath;
  List<Face> faces;

  ProcessedResultScreen({this.imgPath, this.faces});

  @override
  _ProcessedResultScreenState createState() => _ProcessedResultScreenState();
}

class _ProcessedResultScreenState extends State<ProcessedResultScreen> {
  int _imgHeight;
  int _imgWidth;
  Image _img;

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    stackChildren.add(Container(
        height: double.infinity,
        width: double.infinity,
        child: _adjustedImage(context, widget.imgPath)));
    stackChildren.addAll(renderBoxes());

    return Scaffold(
      body: Stack(
        children: stackChildren,
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

  Future<void> _setImageInfo(String imgPath) async {
    File imageFile = new File(imgPath);
    var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
    this._imgHeight = decodedImage.height;
    this._imgWidth = decodedImage.width;
    this._img = Image.file(imageFile, fit: BoxFit.fill);
  }

  List<Widget> renderBoxes() {
    List<Face> faces = widget.faces;

    return faces.map((face) {
      print(face.boundingBox.left);
      return Positioned(
        right: face.boundingBox.left,
        bottom: face.boundingBox.top,
        width: face.boundingBox.width.toDouble(),
        height: face.boundingBox.height.toDouble(),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
            color: Colors.red,
            width: 3,
          )),
          child: Text(
            "P(happy): ${face.smilingProbability} %",
            style: TextStyle(
              background: Paint()..color = Colors.red,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      );
    }).toList();
  }
}
