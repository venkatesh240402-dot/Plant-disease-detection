import 'package:drift/drift.dart';
class Plants extends Table {
  TextColumn get plantId => text().customConstraint('UNIQUE')();
  TextColumn get cropType => text()();
  TextColumn get plantPart => text()();
  TextColumn get variety => text().nullable()();
  IntColumn get registeredAt => integer()();
  RealColumn get gpsLat => real().nullable()();
  RealColumn get gpsLon => real().nullable()();
  RealColumn get compassDeg => real().nullable()();
  BlobColumn get embedding => blob()();
  IntColumn get veinHash => integer().nullable()();
  BlobColumn get lesionMask => blob().nullable()();
  TextColumn get qrCodeId => text().nullable()();
  TextColumn get plotName => text().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {plantId};
}
