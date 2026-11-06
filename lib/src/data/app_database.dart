import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'app_storage.dart';

part 'app_database.g.dart';

class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get nickname => text()();
  TextColumn get username => text()();
  TextColumn get avatarUri => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PlanTasks extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get title => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitRecords extends Table {
  TextColumn get id => text()();
  TextColumn get habitTemplateId => text().references(HabitTemplates, #id)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get checkedAt => dateTime().nullable()();
  DateTimeColumn get valueTime => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class MemoTasks extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class CompletionEvents extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  TextColumn get targetTitleSnapshot => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get undoDeadlineAt => dateTime()();
  TextColumn get color => text().nullable()();
  BoolColumn get isCanceled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    UserProfiles,
    PlanTasks,
    HabitTemplates,
    HabitRecords,
    MemoTasks,
    CompletionEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
        beforeOpen: (_) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final file = await getAppDatabaseFile();
    return NativeDatabase.createInBackground(file);
  });
}
