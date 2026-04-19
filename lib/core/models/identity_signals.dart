import 'dart:typed_data';
import '../enums/plant_part.dart';

class IdentitySignals {
  final Float32List embedding;
  final int? veinHash;
  final Uint8List? lesionMask;
  final double? gpsLat;
  final double? gpsLon;
  final double? compassDeg;
  final PlantPart plantPart;

  IdentitySignals({
    required this.embedding, this.veinHash, this.lesionMask,
    this.gpsLat, this.gpsLon, this.compassDeg, required this.plantPart
  });
}
