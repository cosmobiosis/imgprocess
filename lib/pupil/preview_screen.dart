import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
// import 'package:opencv/opencv.dart';

class PupilPreviewScreen extends StatefulWidget {
  final String imgPath;
  final double lightIntensity;
  PupilPreviewScreen({this.imgPath, this.lightIntensity});

  @override
  _PupilPreviewScreenState createState() => _PupilPreviewScreenState();
}

class _PupilPreviewScreenState extends State<PupilPreviewScreen> {
  int _imgHeight;
  int _imgWidth;
  Image _img;
  double irisX = 0, irisY = 0, irisRadius = 70;
  bool irisMiddle = true;
  double pupilX = 0, pupilY = 0, pupilRadius = 35;
  bool pupilMiddle = true;
  // stage to fit iris
  bool irisStage = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Stack(children: <Widget>[
              _processedImage(context),
              irisStage ? _irisFitter(context) : _pupilFitter(context)
            ]),
            irisStage ? _irisSlider() : _pupilSlider(),
          ],
        ),
      ),
      floatingActionButton: Align(
          child: irisStage ? _irisConfirm() : _pupilConfirm(),
          alignment: Alignment(1, 0.8)),
    );
  }

  // generate image holder, first set the image and its meta data, then return the widget
  Widget _processedImage(BuildContext context) {
    return FutureBuilder(
        future: _setMetaData(widget.imgPath),
        builder: (context, snapshot) {
          if (this._imgHeight == null || this._imgWidth == null) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          // make sure the taken image span the whole screen
          return this._img;
        });
  }

  // set image metadata and save the image to widget
  Future<void> _setMetaData(String _imgPath) async {
    File imageFile = new File(_imgPath);
    Uint8List codedImage = await imageFile.readAsBytes();
    var decodedImage = await decodeImageFromList(codedImage);
    this._imgHeight = decodedImage.height;
    this._imgWidth = decodedImage.width;
    this._img = Image.file(imageFile, fit: BoxFit.fill);
  }

  Widget _irisFitter(BuildContext context) {
    return Positioned(
      left: this.irisMiddle
          ? MediaQuery.of(context).size.width / 2 - irisRadius / 2
          : this.irisX,
      top: this.irisMiddle
          ? MediaQuery.of(context).size.height / 2 - irisRadius / 2
          : this.irisY,
      child: Draggable(
        child: _circle(irisRadius, Colors.yellow),
        feedback: _circle(irisRadius, Colors.yellow),
        childWhenDragging: Container(),
        onDragEnd: (dragDetails) {
          setState(
            () {
              this.irisMiddle = false;
              this.irisX = dragDetails.offset.dx;
              // We need to remove offsets like app/status bar from Y
              this.irisY = dragDetails.offset.dy;
            },
          );
        },
      ),
    );
  }

  Widget _pupilFitter(BuildContext context) {
    return Positioned(
      left: this.pupilMiddle
          ? MediaQuery.of(context).size.width / 2 - pupilRadius / 2
          : this.pupilX,
      top: this.pupilMiddle
          ? MediaQuery.of(context).size.height / 2 - pupilRadius / 2
          : this.pupilY,
      child: Draggable(
        child: _circle(pupilRadius, Colors.red),
        feedback: _circle(pupilRadius, Colors.red),
        childWhenDragging: Container(),
        onDragEnd: (dragDetails) {
          setState(
            () {
              this.pupilMiddle = false;
              this.pupilX = dragDetails.offset.dx;
              // We need to remove offsets like app/status bar from Y
              this.pupilY = dragDetails.offset.dy;
            },
          );
        },
      ),
    );
  }

  Widget _irisSlider() {
    return Slider(
      value: this.irisRadius,
      min: 1,
      max: 400,
      divisions: 400,
      label: this.irisRadius.round().toString(),
      onChanged: (double value) {
        setState(() {
          this.irisRadius = value;
        });
      },
    );
  }

  Widget _pupilSlider() {
    return Slider(
      value: this.pupilRadius,
      min: 1,
      max: 200,
      divisions: 200,
      label: this.pupilRadius.round().toString(),
      onChanged: (double value) {
        setState(() {
          this.pupilRadius = value;
        });
      },
    );
  }

  Widget _irisConfirm() {
    Future<void> _confirmIris() async {
      setState(() {
        this.irisStage = false;
      });
    }

    return FloatingActionButton(
        onPressed: _confirmIris,
        heroTag: null,
        child: Icon(Icons.navigate_next));
  }

  Widget _pupilConfirm() {
    Future<void> _confirmPupil() async {}

    return FloatingActionButton(
        onPressed: _confirmPupil,
        heroTag: null,
        child: Icon(Icons.navigate_next));
  }

  Widget _circle(double radius, Color colorParam) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
              width: 1, color: colorParam, style: BorderStyle.solid)),
    );
  }
}
