import '../enums/crop_type.dart';
import '../enums/plant_part.dart';
import '../enums/disease_severity.dart';
import 'dart:typed_data';

class DetectionResult {
  final CropType cropType;
  final PlantPart plantPart;
  final String diseaseClass;
  final double confidence;
  final double severityPct;
  final DiseaseSeverity severityEnum;
  final Float32List embedding;
  final Uint8List lesionMask;
  final Float32List gradCamHeatmap;
  final bool isHealthy;
  final String source;

  DetectionResult({
    required this.cropType, required this.plantPart, required this.diseaseClass,
    required this.confidence, required this.severityPct, required this.severityEnum,
    required this.embedding, required this.lesionMask, required this.gradCamHeatmap,
    required this.isHealthy, required this.source,
  });
}
