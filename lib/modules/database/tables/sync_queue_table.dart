import 'package:drift/drift.dart';
class SyncQueue extends Table {
  TextColumn get queueId => text()();
  TextColumn get tableName => text()();
  TextColumn get rowId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get queuedAt => integer().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  @override Set<Column> get primaryKey => {queueId};
}
