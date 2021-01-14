import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:image/image.dart';
import 'package:tflite/tflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<List<String>> getClassificationResults(
    List<Rect> rects, Uint8List codedImage) async {
  List<String> classifiedLabels = new List();
  List<String> imgPaths = await extractFacesToLocalFiles(rects, codedImage);
  for (String path in imgPaths) {
    var res = await Tflite.runModelOnImage(path: path);
    classifiedLabels.add(res.first["label"]);
  }
  return classifiedLabels;
}

Future<List<String>> extractFacesToLocalFiles(
    List<Rect> rects, Uint8List codedImage) async {
  // ret param: list of saved face images paths
  List<Image> faceImgs = getGrayScaleFaceImages(rects, codedImage);
  List<String> res = new List();
  String srcPath = join((await getTemporaryDirectory()).path, "face");
  for (int i = 0; i < faceImgs.length; i++) {
    Image face = faceImgs[i];
    List<int> encodedGrayFaceBytes = encodeJpg(face);
    String filePath = srcPath + i.toString() + ".jpg";
    File(filePath).writeAsBytesSync(encodedGrayFaceBytes);
    res.add(filePath);
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
