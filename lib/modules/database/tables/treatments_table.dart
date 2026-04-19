import 'package:drift/drift.dart';
class Treatments extends Table {
  TextColumn get treatmentId => text()();
  TextColumn get plantId => text()(); // FK to plants
  IntColumn get appliedAt => integer()();
  TextColumn get treatmentType => text().nullable()();
  TextColumn get dosage => text().nullable()();
  TextColumn get applicationMethod => text().nullable()();
  TextColumn get outcome => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {treatmentId};
}
