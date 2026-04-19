import '../enums/cure_stage.dart';

class SeverityPoint {
  final DateTime scannedAt;
  final double severityPct;
  final CureStage cureStage;
  final double identityScore;

  SeverityPoint({required this.scannedAt, required this.severityPct, required this.cureStage, required this.identityScore});
}
