import 'dart:typed_data';

class ImageUtils {
  static Uint8List resizeImage(Uint8List img, int width, int height) => Uint8List(0); // stub
  static Uint8List jpegCompress(Uint8List img, int quality) => Uint8List(0); // stub
  static double computeFrameDiff(Uint8List frame1, Uint8List frame2) => 0.0; // stub
  static double computeLaplacianVariance(Uint8List frame) => 0.0; // stub
  static int extractVeinHash(Uint8List leafImage) => 0; // stub
  static double computeLesionIoU(Uint8List mask1, Uint8List mask2) => 0.0; // stub
}
