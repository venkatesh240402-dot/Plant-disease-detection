import 'package:drift/drift.dart';
// import tables...
part 'app_database.g.dart'; // Drift generator output
@DriftDatabase(tables: []) // We'll add tables here later
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override int get schemaVersion => 1;
}
