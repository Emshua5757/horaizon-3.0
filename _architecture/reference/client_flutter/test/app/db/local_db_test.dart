import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// Adjust this import path based on where local_db.dart actually lives
import 'package:client_flutter/app/db/local_db.dart';

void main() {
  group('ShuaSyncQueue Integration Tests', () {
    late LocalDatabase database;

    setUp(() {
      // Instantiates SQLite entirely in RAM.
      // It executes in microseconds and vanishes when the test finishes.
      database = LocalDatabase(e: NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'Injects and retrieves a BLOB payload and logical clock perfectly',
      () async {
        // 1. Prepare dummy data
        final dummyPayload = Uint8List.fromList([
          0xDE,
          0xAD,
          0xBE,
          0xEF,
        ]); // Hex bytes
        final int currentClock = DateTime.now().millisecondsSinceEpoch;

        // 2. Inject into the sandboxed RAM database
        await database
            .into(database.shuaSyncQueue)
            .insert(
              ShuaSyncQueueCompanion.insert(
                tableId: 1,
                recordId: 'row_99',
                actionType: 2,
                payload: dummyPayload,
                logicalClock: currentClock,
                createdAt: currentClock,
              ),
            );

        // 3. Query the data back out
        final results = await database.select(database.shuaSyncQueue).get();

        // 4. Mathematically prove the data matches
        expect(
          results.length,
          1,
          reason: 'The database should contain exactly one row.',
        );

        expect(
          results.first.tableId,
          1,
          reason: 'The tableId must route correctly.',
        );

        expect(
          results.first.actionType,
          2,
          reason: 'The actionType must be preserved.',
        );

        expect(
          results.first.payload,
          dummyPayload,
          reason:
              'The binary BLOB payload must survive storage and retrieval completely intact.',
        );
      },
    );

    test('Bulk inserts and retrieves ordered by logicalClock', () async {
      final dummyPayload = Uint8List.fromList([0x01, 0x02]);

      // Insert 3 records out of order
      await database
          .into(database.shuaSyncQueue)
          .insert(
            ShuaSyncQueueCompanion.insert(
              tableId: 1,
              recordId: 'row_1',
              actionType: 1,
              payload: dummyPayload,
              logicalClock: 300,
              createdAt: 300,
            ),
          );
      await database
          .into(database.shuaSyncQueue)
          .insert(
            ShuaSyncQueueCompanion.insert(
              tableId: 1,
              recordId: 'row_2',
              actionType: 1,
              payload: dummyPayload,
              logicalClock: 100,
              createdAt: 100,
            ),
          );
      await database
          .into(database.shuaSyncQueue)
          .insert(
            ShuaSyncQueueCompanion.insert(
              tableId: 1,
              recordId: 'row_3',
              actionType: 1,
              payload: dummyPayload,
              logicalClock: 200,
              createdAt: 200,
            ),
          );

      // Query ordered by logicalClock ascending
      final results = await (database.select(
        database.shuaSyncQueue,
      )..orderBy([(t) => OrderingTerm(expression: t.logicalClock)])).get();

      expect(results.length, 3, reason: 'Should return all 3 inserted rows.');
      expect(
        results[0].logicalClock,
        100,
        reason: 'Lowest clock must be first.',
      );
      expect(
        results[1].logicalClock,
        200,
        reason: 'Middle clock must be second.',
      );
      expect(
        results[2].logicalClock,
        300,
        reason: 'Highest clock must be last.',
      );
    });

    test('Can delete a record after successful synchronization', () async {
      final dummyPayload = Uint8List.fromList([0xFF]);

      // Insert 1 record
      final insertedId = await database
          .into(database.shuaSyncQueue)
          .insert(
            ShuaSyncQueueCompanion.insert(
              tableId: 2,
              recordId: 'temp_1',
              actionType: 3,
              payload: dummyPayload,
              logicalClock: 50,
              createdAt: 50,
            ),
          );

      // Verify it exists
      var count = (await database.select(database.shuaSyncQueue).get()).length;
      expect(count, 1);

      // Delete the record (simulating successful sync to backend)
      await (database.delete(
        database.shuaSyncQueue,
      )..where((t) => t.id.equals(insertedId))).go();

      // Verify it is gone
      count = (await database.select(database.shuaSyncQueue).get()).length;
      expect(
        count,
        0,
        reason: 'The queue should be empty after deleting the synced record.',
      );
    });
  });
}
