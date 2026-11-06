import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pacekit/src/core/clock.dart';
import 'package:pacekit/src/data/app_database.dart';
import 'package:pacekit/src/data/repositories.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('MemoRepository deletion', () {
    late AppDatabase db;
    late MemoRepository memos;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      memos = MemoRepository(
        db,
        FixedClock(DateTime(2026, 4, 27, 10)),
        const Uuid(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('soft deleting an incomplete memo does not create a view event',
        () async {
      await memos.addMemo('不需要的备忘', DateTime(2026, 4, 29));

      final memo = await db.select(db.memoTasks).getSingle();
      await memos.softDeleteMemo(memo.id);

      final events = await db.select(db.completionEvents).get();
      final activeMemos = db.select(db.memoTasks)
        ..where((row) => row.deletedAt.isNull());

      expect(events, isEmpty);
      expect(await activeMemos.get(), isEmpty);
    });

    test('soft deleting a completed memo does not add a delete event',
        () async {
      await memos.addMemo('已经完成的备忘', DateTime(2026, 4, 29));

      final memo = await db.select(db.memoTasks).getSingle();
      await memos.toggleCompletion(memo.id);

      final eventsBeforeDelete = await db.select(db.completionEvents).get();
      expect(eventsBeforeDelete, hasLength(1));
      expect(eventsBeforeDelete.single.targetType, targetMemo);

      await memos.softDeleteMemo(memo.id);

      final eventsAfterDelete = await db.select(db.completionEvents).get();
      expect(eventsAfterDelete, hasLength(1));
      expect(eventsAfterDelete.single.id, eventsBeforeDelete.single.id);
      expect(eventsAfterDelete.single.targetTitleSnapshot, '已经完成的备忘');
    });
  });
}
