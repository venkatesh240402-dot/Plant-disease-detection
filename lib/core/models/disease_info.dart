import '../enums/crop_type.dart';

class DiseaseInfo {
  final String diseaseClass;
  final String commonName;
  final String scientificName;
  final CropType cropType;
  final String cause;
  final String symptoms;
  final String spreadMechanism;
  final List<String> affectedParts;
  final List<String> preventionTips;
  final String imageThumbPath;

  DiseaseInfo({
    required this.diseaseClass, required this.commonName, required this.scientificName,
    required this.cropType, required this.cause, required this.symptoms,
    required this.spreadMechanism, required this.affectedParts,
    required this.preventionTips, required this.imageThumbPath
  });
}
