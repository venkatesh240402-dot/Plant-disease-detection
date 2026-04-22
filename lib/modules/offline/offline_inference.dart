import 'dart:developer';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import 'knowledge_base.dart';

class DetectionResult {
  final String crop;
  final String disease;
  final String solution;
  final double confidence;

  DetectionResult({
    required this.crop,
    required this.disease,
    required this.solution,
    required this.confidence,
  });
}

class OfflineInference {
  static final OfflineInference _instance = OfflineInference._internal();
  factory OfflineInference() => _instance;
  OfflineInference._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initializeModels() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: options,
      );
      
      _isInitialized = true;
      log("Single model loaded successfully");
    } catch (e) {
      log("Error loading model.tflite: $e");
    }
  }

  Future<DetectionResult?> processFrame(CameraImage image) async {
    if (!_isInitialized || _interpreter == null) return null;

    try {
      // 1. Preprocess camera image to match standard Kaggle shapes (224x224x3)
      var inputImage = _processCameraImage(image);
      if (inputImage == null) return null;

      var input = inputImage; // inputImage is already [1, 224, 224, 3]
      
      // Determine output shape dynamically
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      var outputSize = outputShape.reduce((a, b) => a * b);
      var output = List.filled(outputShape[0] * outputSize, 0.0).reshape(outputShape);

      // 2. Run Inference
      _interpreter!.run(input, output);
      
      // 3. Parse output classification
      final probabilities = output[0] as List<dynamic>;
      int maxIndex = 0;
      double maxProb = 0.0;
      
      for (int i = 0; i < probabilities.length; i++) {
        double prob = (probabilities[i] as num).toDouble();
        if (prob > maxProb) {
          maxProb = prob;
          maxIndex = i;
        }
      }

      // We derive a generic name since labels aren't hardcoded yet.
      // (Standard Kaggle models use 38 labels from the PlantVillage dataset)
      String detectedLabel = _getLabelFromIndex(maxIndex);
      List<String> parts = detectedLabel.split("___");
      String cropName = parts.length > 1 ? parts[0].replaceAll("_", " ") : "Unknown Crop";
      String diseaseName = parts.length > 1 ? parts[1].replaceAll("_", " ") : detectedLabel;
      
      if (diseaseName.toLowerCase() == "healthy") {
         diseaseName = "Healthy";
      }

      return DetectionResult(
        crop: cropName,
        disease: diseaseName,
        solution: KnowledgeBase.getSolution(cropName, diseaseName),
        confidence: maxProb,
      );
    } catch (e) {
      log("Inference error: $e");
      return null;
    }
  }

  Object? _processCameraImage(CameraImage image) {
    const int inputSize = 224; // Standard size for Kaggle mobile models
    
    try {
      img.Image? convertedImg;
      if (image.format.group == ImageFormatGroup.yuv420) {
        convertedImg = _convertYUV420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        convertedImg = _convertBGRA8888ToImage(image);
      }

      if (convertedImg == null) return null;

      // CRITICAL FIX: Android camera frames are rotated 90 degrees sideways in portrait mode!
      // Feeding a sideways leaf to the AI scrambles its predictions completely.
      img.Image rotatedImage = img.copyRotate(convertedImg, angle: 90);
      
      img.Image resizedImage = img.copyResize(rotatedImage, width: inputSize, height: inputSize);
      
      // CRITICAL FIX: Avoid Dart nested lists which cause GC stutter. Use Float32List
      var inputBuffer = Float32List(1 * inputSize * inputSize * 3);
      int pixelIndex = 0;
      
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          // Standard normalization parameters for Plant Village models [0, 1]
          inputBuffer[pixelIndex++] = pixel.r / 255.0;
          inputBuffer[pixelIndex++] = pixel.g / 255.0;
          inputBuffer[pixelIndex++] = pixel.b / 255.0;
        }
      }
      
      return inputBuffer.reshape([1, inputSize, inputSize, 3]);
    } catch (e) {
      log("Image processing error: $e");
      return null;
    }
  }

  img.Image? _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;
    
    final imgImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      int pY = y * image.planes[0].bytesPerRow;
      int pUV = (y ~/ 2) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final int uvOffset = pUV + (x ~/ 2) * uvPixelStride;
        final yp = image.planes[0].bytes[pY];
        final up = image.planes[1].bytes[uvOffset];
        final vp = image.planes[2].bytes[uvOffset];

        // Improved YUV to RGB formulas 
        int r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
        int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round().clamp(0, 255);
        int b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

        imgImage.setPixelRgb(x, y, r, g, b);
        pY++;
      }
    }
    return imgImage;
  }

  img.Image _convertBGRA8888ToImage(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  String _getLabelFromIndex(int index) {
      // These are the standard 38 PlantVillage Dataset classes which are ubiquitous on Kaggle
      const List<String> labels = [
        "Apple___Apple_scab", "Apple___Black_rot", "Apple___Cedar_apple_rust", "Apple___healthy",
        "Blueberry___healthy", "Cherry_(including_sour)___Powdery_mildew", "Cherry_(including_sour)___healthy",
        "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot", "Corn_(maize)___Common_rust_", "Corn_(maize)___Northern_Leaf_Blight", "Corn_(maize)___healthy",
        "Grape___Black_rot", "Grape___Esca_(Black_Measles)", "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)", "Grape___healthy",
        "Orange___Haunglongbing_(Citrus_greening)", "Peach___Bacterial_spot", "Peach___healthy",
        "Pepper,_bell___Bacterial_spot", "Pepper,_bell___healthy", "Potato___Early_blight", "Potato___Late_blight", "Potato___healthy",
        "Raspberry___healthy", "Soybean___healthy", "Squash___Powdery_mildew",
        "Strawberry___Leaf_scorch", "Strawberry___healthy", "Tomato___Bacterial_spot", "Tomato___Early_blight", "Tomato___Late_blight",
        "Tomato___Leaf_Mold", "Tomato___Septoria_leaf_spot", "Tomato___Spider_mites Two-spotted_spider_mite",
        "Tomato___Target_Spot", "Tomato___Tomato_Yellow_Leaf_Curl_Virus", "Tomato___Tomato_mosaic_virus", "Tomato___healthy"
      ];
      
      if (index >= 0 && index < labels.length) {
          return labels[index];
      }
      return "Unknown___Disease_Class_$index";
  }

  void dispose() {
    _interpreter?.close();
  }
}
