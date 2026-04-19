import 'package:drift/drift.dart';
class ScanHistory extends Table {
  TextColumn get scanId => text()();
  TextColumn get plantId => text()(); // FK to plants
  IntColumn get scannedAt => integer()();
  RealColumn get identityScore => real().nullable()();
  TextColumn get cropType => text()();
  TextColumn get plantPart => text()();
  TextColumn get diseaseClass => text().nullable()();
  RealColumn get confidence => real().nullable()();
  RealColumn get severityPct => real().nullable()();
  BlobColumn get lesionMask => blob().nullable()();
  BlobColumn get embedding => blob().nullable()();
  TextColumn get cureStage => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('local'))();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {scanId};
}
