import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:imgprocess/demo/facial_expression_classification.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/services.dart';

class ProcessedResultScreen extends StatefulWidget {
  final String imgPath;
  final List<Face> faces;

  ProcessedResultScreen({this.imgPath, this.faces});

  @override
  _ProcessedResultScreenState createState() => _ProcessedResultScreenState();
}

class _ProcessedResultScreenState extends State<ProcessedResultScreen> {
  int _imgHeight;
  int _imgWidth;
  var _decodedImage;
  List<Rect> _rects;
  List<Image> _faceImages;
  List<String> _labels;
  bool _busy;
  bool _infoSet;

  @override
  void initState() {
    super.initState();
    _busy = true;
    _infoSet = false;
    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  // load the pre-trained model for TFLite library
  Future<void> loadModel() async {
    Tflite.close();
    try {
      await Tflite.loadModel(
        // model: "assets/ssd_mobilenet.tflite",
        // labels: "assets/ssd_mobilenet.txt",
        model: "assets/model.tflite",
        labels: "assets/model.txt",
      );
    } on Exception {
      print("Model Initlization Failure");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _processedImage(context, widget.imgPath));
  }

  // async processing wrapper for processed image widget
  Widget _processedImage(BuildContext context, String imgPath) {
    return FutureBuilder(
        future: _setImageInfo(imgPath),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (this._imgHeight == null || this._imgWidth == null || this._busy) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          return this._imgHeight < this._imgWidth
              ? RotatedBox(quarterTurns: 1, child: getProcessedDisplay())
              : getProcessedDisplay();
          // return getRowOfCroppedFaces();
        });
  }

  // process the image and set the image processed result data
  Future<int> _setImageInfo(String _imgPath) async {
    if (_infoSet) return 1;
    _infoSet = true;
    File imageFile = new File(_imgPath);
    Uint8List codedImage = await imageFile.readAsBytes();

    this._decodedImage = await decodeImageFromList(codedImage);
    this._imgHeight = this._decodedImage.height;
    this._imgWidth = this._decodedImage.width;
    this._rects = new List<Rect>();
    for (Face face in widget.faces) {
      _rects.add(face.boundingBox);
    }

    // List<String> grayFacePaths =
    //     await extractFacesToLocalFiles(_rects, codedImage);
    // this._faceImages =
    //     grayFacePaths.map((path) => Image.file(new File(path))).toList();

    var labels = await getClassificationResults(_rects, codedImage);
    setState(() {
      _labels = labels;
    });
    return 1;
  }

  // image widget with processed results
  Widget getProcessedDisplay() {
    Widget processedDisplay = FittedBox(
        child: Stack(children: [
      SizedBox(
          width: _imgWidth.toDouble(),
          height: _imgHeight.toDouble(),
          child: CustomPaint(
            painter: FacePainter(rects: _rects, imageFile: _decodedImage),
          )),
      ...renderTexts(),
    ]));
    return processedDisplay;
  }

  // labels of classification results
  List<Widget> renderTexts() {
    if (_labels == null || _labels.length == 0) return [];
    if (_imgHeight == null || _imgWidth == null) return [];

    Color color = Colors.red;

    return _labels
        .asMap()
        .map((i, label) => MapEntry(
            i,
            Positioned(
              left: _rects[i].left,
              top: _rects[i].bottom,
              width: _rects[i].width,
              height: _rects[i].height,
              child: Container(
                child: Text(
                  label,
                  style: TextStyle(
                    background: Paint()..color = color,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            )))
        .values
        .toList();
  }

  // frames of faces
  Widget getRowOfCroppedFaces() {
    return Container(
      margin: EdgeInsets.only(top: 20.0),
      height: 200.0,
      child: ListView(
          padding: EdgeInsets.all(0.0),
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: this._faceImages == null
                  ? <Widget>[Card()]
                  : this
                      ._faceImages
                      .asMap()
                      .map((i, faceImage) => MapEntry(
                          i,
                          Card(
                              child: Column(
                            children: <Widget>[faceImage, Text(_labels[i])],
                          ))))
                      .values
                      .toList(), // this is a list containing Cards with image
            )
          ]),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Rect> rects;
  var imageFile;

  FacePainter({@required this.rects, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }
    for (Rect rectangle in rects) {
      canvas.drawRect(
        rectangle,
        Paint()
          ..color = Colors.teal
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
