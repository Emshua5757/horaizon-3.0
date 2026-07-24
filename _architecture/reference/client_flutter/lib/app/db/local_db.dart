import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This tells the compiler to look for the generated code.
// It will be red until we run the build_runner command.
part 'local_db.g.dart';

/// Define the Offline Synchronization Queue Table
class ShuaSyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tableId => integer()();
  TextColumn get recordId => text()();
  IntColumn get actionType => integer()();
  BlobColumn get payload => blob()();
  IntColumn get logicalClock => integer()();
  IntColumn get createdAt => integer()();
}

/// Define the Offline Long-Term Episodic Memory Table
class EpisodicMemories extends Table {
  TextColumn get id => text()(); // UUID String
  TextColumn get userId => text()(); // UUID String
  TextColumn get memoryContent => text()();
  IntColumn get priorityTier => integer().withDefault(const Constant(3))();
  TextColumn get moodTag => text().withDefault(const Constant('neutral'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get suggestedTags => text().nullable()(); // Comma-separated or JSON array string

  @override
  Set<Column> get primaryKey => {id};
}

/// Define the Offline Diary Entries Table
class ShuaDiaryEntries extends Table {
  TextColumn get id => text()(); // UUID String
  TextColumn get title => text().withDefault(const Constant('Untitled'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();
  TextColumn get privacyTag => text().withDefault(const Constant('sfw'))(); // 'sfw' or 'nsfw'

  // ── Offline-First Analysis State Machine columns ──────────────────
  // FSM: 'idle' → 'pending' → 'processing' → 'done' | 'error'
  TextColumn get analysisState => text().withDefault(const Constant('idle'))();
  RealColumn get sentimentScore => real().nullable()(); // null until FSM reaches 'done'
  TextColumn get milestoneTag => text().nullable()();   // null until FSM reaches 'done'

  @override
  Set<Column> get primaryKey => {id};
}

/// Define the Offline Diary Blocks Table
class ShuaDiaryBlocks extends Table {
  TextColumn get id => text()(); // UUID String
  TextColumn get entryId => text()(); // Foreign Key
  TextColumn get blockType => text()(); // e.g., 'paragraph', 'heading'
  TextColumn get content => text()();
  TextColumn get metadata => text().nullable()(); // JSON string for SDUI block properties
  BlobColumn get sortKey => blob()(); // BinaryLexoRank
  IntColumn get lamportClock => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The Main Local Database Class
@DriftDatabase(tables: [ShuaSyncQueue, EpisodicMemories, ShuaDiaryEntries, ShuaDiaryBlocks])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase({QueryExecutor? e}) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(episodicMemories);
          }
          if (from < 3) {
            await m.createTable(shuaDiaryEntries);
            await m.createTable(shuaDiaryBlocks);
          }
          if (from < 4) {
            await m.addColumn(shuaDiaryEntries, shuaDiaryEntries.privacyTag);
          }
          if (from < 5) {
            // Offline-First Analysis State Machine: add FSM tracking columns
            await m.addColumn(shuaDiaryEntries, shuaDiaryEntries.analysisState);
            await m.addColumn(shuaDiaryEntries, shuaDiaryEntries.sentimentScore);
            await m.addColumn(shuaDiaryEntries, shuaDiaryEntries.milestoneTag);
          }
          if (from < 6) {
            await m.addColumn(shuaDiaryBlocks, shuaDiaryBlocks.metadata);
          }
        },
      );
}

/// Finds the OS-specific safe sandboxed folder to store the SQLite file.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'horaizon_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Expose the database safely via Riverpod
/// 
/// [FUTURE ARCHITECTURE NOTE]: Once the DB operations (insert/delete) are 
/// implemented in their respective repositories, ensure they return 
/// DiagnosticResult objects and are piped into diagnosticsHistoryProvider 
/// for telemetry tracking.
final localDbProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});
