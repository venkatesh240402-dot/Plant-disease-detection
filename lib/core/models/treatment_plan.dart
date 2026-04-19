import '../enums/cure_stage.dart';

class TreatmentPlan {
  final CureStage cureStage;
  final List<String> steps;
  final String organicOption;
  final String chemicalName;
  final String dosageMlPerLitre;
  final String applicationMethod;
  final int reCheckInDays;
  final String warningNotes;

  TreatmentPlan({
    required this.cureStage, required this.steps, required this.organicOption,
    required this.chemicalName, required this.dosageMlPerLitre,
    required this.applicationMethod, required this.reCheckInDays, required this.warningNotes
  });
}
