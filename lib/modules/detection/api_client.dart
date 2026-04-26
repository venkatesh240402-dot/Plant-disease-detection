import 'dart:convert';
import 'package:http/http.dart' as http;
import '../offline/offline_inference.dart'; // For DetectionResult

class ApiClient {
  // Use 10.0.2.2 for Android Emulator, or your computer's local Wi-Fi IP for a physical phone
  static const String baseUrl = 'http://192.168.29.155:8000';

  static Future<DetectionResult?> detectDisease(List<int> imageBytes) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/detect'));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'scan.jpg',
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);
        
        // Parse the roboflow response
        if (jsonResponse['predictions'] != null && jsonResponse['predictions'].isNotEmpty) {
          String rawResponse = jsonResponse['predictions'][0]['class'] ?? '';
          
          String crop = "Unknown Crop";
          String disease = "Unknown Status";
          String solution = "Could not generate a solution. Please try scanning again.";
          
          final lines = rawResponse.split('\n');
          for (var line in lines) {
              final trimmed = line.trim();
              if (trimmed.startsWith('Crop:')) crop = trimmed.substring(5).trim();
              else if (trimmed.startsWith('Disease:')) disease = trimmed.substring(8).trim();
              else if (trimmed.startsWith('Solution:')) solution = trimmed.substring(9).trim();
          }
          
          return DetectionResult(
             crop: crop,
             disease: disease,
             solution: solution,
             confidence: 0.99,
          );
        }
      } else {
        print("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print('API Exception: $e');
    }
    return null;
  }
}
