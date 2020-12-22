import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

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
  var _imgFile;
  List<Rect> _rects;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _processedImage(context, widget.imgPath));
  }

  Widget _processedImage(BuildContext context, String imgPath) {
    return FutureBuilder(
        future: _setImageInfo(imgPath),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (this._imgHeight == null || this._imgWidth == null) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          Widget processedDisplay = FittedBox(
              child: SizedBox(
                  width: _imgWidth.toDouble(),
                  height: _imgHeight.toDouble(),
                  child: CustomPaint(
                    painter: FacePainter(rects: _rects, imageFile: _imgFile),
                  )));
          return this._imgHeight < this._imgWidth
              ? RotatedBox(quarterTurns: 1, child: processedDisplay)
              : processedDisplay;
        });
  }

  Future<int> _setImageInfo(String _imgPath) async {
    File imageFile = new File(_imgPath);
    this._imgFile = await decodeImageFromList(imageFile.readAsBytesSync());
    this._imgHeight = this._imgFile.height;
    this._imgWidth = this._imgFile.width;
    this._rects = new List<Rect>();
    for (Face face in widget.faces) {
      _rects.add(face.boundingBox);
    }
    return 1;
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
    print(rects.length);
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
