import 'package:drift/drift.dart';
class DiseaseCache extends Table {
  TextColumn get cacheId => text()();
  TextColumn get cropType => text()();
  TextColumn get diseaseClass => text()();
  TextColumn get apiResponse => text().nullable()();
  IntColumn get cachedAt => integer().nullable()();
  @override Set<Column> get primaryKey => {cacheId};
}
