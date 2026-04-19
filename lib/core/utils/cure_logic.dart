import '../enums/cure_stage.dart';
import '../models/severity_point.dart';

class CureLogic {
  static CureStage determineCureStage(List<SeverityPoint> severityHistory) => CureStage.early; // stub
  static bool shouldEscalate(List<dynamic> scans, List<dynamic> treatments) => false; // stub
  static String getAdaptiveMessage(dynamic trend) => ''; // stub
}
