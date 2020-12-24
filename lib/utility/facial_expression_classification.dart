import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart';
import 'package:tflite/tflite.dart';

Future<List<String>> getClassificationResults(
    List<Rect> rects, Uint8List codedImage, String imgPath) async {
  List<String> res = new List();
  List<Image> grayScaleImages = getGrayScaleFaceImages(rects, codedImage);
  for (Image face in grayScaleImages) {
    Image resizedImage = copyResize(face, width: 224, height: 224);
    var recogs = await Tflite.detectObjectOnImage(
      path: imgPath,
    );
    var recog = recogs.first;
    res.add(
      "${recog["detectedClass"]} ${(recog["confidenceInClass"] * 100).toStringAsFixed(0)}%",
    );
  }
  return res;
}

List<Image> getFaceImages(List<Rect> rects, Uint8List codedImage) {
  Image image = decodeImage(codedImage);
  return rects
      .map((rect) => copyCrop(image, rect.left.toInt(), rect.top.toInt(),
          rect.width.toInt(), rect.height.toInt()))
      .toList();
}

List<Image> getGrayScaleFaceImages(List<Rect> rects, Uint8List codedImage) {
  Image image = decodeImage(codedImage);
  image = grayscale(image);
  return rects
      .map((rect) => copyCrop(image, rect.left.toInt(), rect.top.toInt(),
          rect.width.toInt(), rect.height.toInt()))
      .toList();
}

List<int> encodeHelper(Image image) {
  return encodeJpg(image);
}

Uint8List imageToByteListUint8(Image image, int inputSize) {
  var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
  var buffer = Uint8List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < inputSize; i++) {
    for (var j = 0; j < inputSize; j++) {
      var pixel = image.getPixel(j, i);
      buffer[pixelIndex++] = getRed(pixel);
      buffer[pixelIndex++] = getGreen(pixel);
      buffer[pixelIndex++] = getBlue(pixel);
    }
  }
  return convertedBytes.buffer.asUint8List();
}
