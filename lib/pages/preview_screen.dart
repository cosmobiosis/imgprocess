import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhotoPreviewScreen extends StatefulWidget {
  final String imgPath;

  PhotoPreviewScreen({this.imgPath});

  @override
  _PhotoPreviewScreenState createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  int imgHeight;
  int imgWidth;
  Image img;

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
            _processButtonWidget(widget.imgPath),
          ],
        ),
      ),
    );
  }

  Widget _adjustedImage(BuildContext context, String imgPath) {
    return FutureBuilder(
        future: _setImageInfo(imgPath),
        builder: (context, snapshot) {
          if (this.imgHeight == null || this.imgWidth == null) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          return this.imgHeight < this.imgWidth
              ? RotatedBox(quarterTurns: 1, child: this.img)
              : this.img;
        });
  }

  Future<void> _setImageInfo(String imgPath) async {
    File imageFile = new File(imgPath);
    var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
    this.imgHeight = decodedImage.height;
    this.imgWidth = decodedImage.width;
    this.img = Image.file(imageFile, fit: BoxFit.fill);
  }

  Widget _processButtonWidget(String imgPath) {
    Future<ByteData> getBytesFromFile() async {
      Uint8List bytes = File(imgPath).readAsBytesSync() as Uint8List;
      return ByteData.view(bytes.buffer); 
    }

    Widget button = RaisedButton(
      onPressed: () {
        getBytesFromFile();
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
        future: _setImageInfo(imgPath),
        builder: (context, snapshot) {
          if (this.imgHeight == null || this.imgWidth == null) {
            // Future hasn't finished yet, return a placeholder
            return Center(child: CircularProgressIndicator());
          }
          return this.imgHeight < this.imgWidth
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
