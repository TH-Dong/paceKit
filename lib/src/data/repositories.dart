import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../core/planning_rules.dart';
import 'app_database.dart';

const targetPlan = 'plan';
const targetMemo = 'memo';
const targetHabit = 'habit';
const targetWakeUp = 'wake_up';
const targetSleep = 'sleep';

const habitTypeNormal = 'normal';
const habitTypeWakeUp = 'wake_up';
const habitTypeSleep = 'sleep';

@immutable
class HabitEntry {
  const HabitEntry({
    required this.template,
    required this.record,
  });

  final HabitTemplate template;
  final HabitRecord? record;

  bool get isDone => record?.isDone ?? false;
}

@immutable
class DateRange {
  const DateRange(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;

  @override
  bool operator ==(Object other) {
    return other is DateRange &&
        other.start == start &&
        other.endExclusive == endExclusive;
  }

  @override
  int get hashCode => Object.hash(start, endExclusive);
}

class PlanRepository {
  PlanRepository(this._db, this._clock, this._uuid);

  final AppDatabase _db;
  final AppClock _clock;
  final Uuid _uuid;

  Stream<List<PlanTask>> watchPlans(DateTime date) {
    final target = dateOnly(date);
    final query = _db.select(_db.planTasks)
      ..where((task) => task.date.equals(target) & task.deletedAt.isNull())
      ..orderBy([(task) => OrderingTerm.asc(task.sortOrder)]);
    return query.watch();
  }

  Stream<List<PlanTask>> watchPlansInRange(DateRange range) {
    final query = _db.select(_db.planTasks)
      ..where(
        (task) =>
            task.date.isBiggerOrEqualValue(range.start) &
            task.date.isSmallerThanValue(range.endExclusive) &
            task.deletedAt.isNull(),
      )
      ..orderBy([
        (task) => OrderingTerm.asc(task.date),
        (task) => OrderingTerm.asc(task.sortOrder)
      ]);
    return query.watch();
  }

  Future<void> addPlan(DateTime date, String title) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final target = dateOnly(date);
    final existing = await watchPlans(target).first;
    final now = _clock.now();
    await _db.into(_db.planTasks).insert(
          PlanTasksCompanion.insert(
            id: _uuid.v4(),
            date: target,
            title: cleanTitle,
            sortOrder: existing.length,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<bool> toggleCompletion(String id) async {
    final task = await (_db.select(_db.planTasks)
          ..where((row) => row.id.equals(id)))
        .getSingle();
    final now = _clock.now();
    if (task.isDone) {
      if (task.completedAt == null ||
          now.isAfter(task.completedAt!.add(const Duration(minutes: 5)))) {
        return false;
      }
      await _db.transaction(() async {
        await (_db.update(_db.planTasks)..where((row) => row.id.equals(id)))
            .write(
          PlanTasksCompanion(
            isDone: const Value(false),
            completedAt: const Value<DateTime?>(null),
            updatedAt: Value(now),
            revision: Value(task.revision + 1),
          ),
        );
        await _cancelLatestEvent(targetPlan, id);
      });
      return true;
    }

    await _db.transaction(() async {
      await (_db.update(_db.planTasks)..where((row) => row.id.equals(id)))
          .write(
        PlanTasksCompanion(
          isDone: const Value(true),
          completedAt: Value(now),
          updatedAt: Value(now),
          revision: Value(task.revision + 1),
        ),
      );
      await _createCompletion(
        targetType: targetPlan,
        targetId: id,
        title: task.title,
        businessDate: task.date,
        completedAt: now,
        color: 'green',
      );
    });
    return true;
  }

  Future<void> softDeletePlan(String id) async {
    final now = _clock.now();
    await (_db.update(_db.planTasks)..where((row) => row.id.equals(id))).write(
      PlanTasksCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<void> reorderPlans(DateTime date, List<String> orderedIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.planTasks)
              ..where((row) => row.id.equals(orderedIds[i])))
            .write(
          PlanTasksCompanion(
              sortOrder: Value(i), updatedAt: Value(_clock.now())),
        );
      }
    });
  }

  Future<void> _createCompletion({
    required String targetType,
    required String targetId,
    required String title,
    required DateTime businessDate,
    required DateTime completedAt,
    String? color,
  }) {
    return _db.into(_db.completionEvents).insert(
          CompletionEventsCompanion.insert(
            id: _uuid.v4(),
            targetType: targetType,
            targetId: targetId,
            targetTitleSnapshot: title,
            date: dateOnly(businessDate),
            completedAt: completedAt,
            undoDeadlineAt: completedAt.add(const Duration(minutes: 5)),
            color: Value<String?>(color),
            createdAt: completedAt,
          ),
        );
  }

  Future<void> _cancelLatestEvent(String targetType, String targetId) async {
    final events = await (_db.select(_db.completionEvents)
          ..where(
            (event) =>
                event.targetType.equals(targetType) &
                event.targetId.equals(targetId) &
                event.isCanceled.equals(false),
          )
          ..orderBy([(event) => OrderingTerm.desc(event.completedAt)])
          ..limit(1))
        .get();
    if (events.isEmpty) return;
    await (_db.update(_db.completionEvents)
          ..where((event) => event.id.equals(events.first.id)))
        .write(
      const CompletionEventsCompanion(isCanceled: Value(true)),
    );
  }
}

class HabitRepository {
  HabitRepository(this._db, this._clock, this._uuid);

  final AppDatabase _db;
  final AppClock _clock;
  final Uuid _uuid;

  Stream<List<HabitEntry>> watchHabitEntries(DateTime date) {
    final target = dateOnly(date);
    final query = _db.select(_db.habitTemplates).join([
      leftOuterJoin(
        _db.habitRecords,
        _db.habitRecords.habitTemplateId.equalsExp(_db.habitTemplates.id) &
            _db.habitRecords.date.equals(target),
      ),
    ])
      ..where(_db.habitTemplates.deletedAt.isNull() &
          _db.habitTemplates.isEnabled.equals(true))
      ..orderBy([OrderingTerm.asc(_db.habitTemplates.sortOrder)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return HabitEntry(
          template: row.readTable(_db.habitTemplates),
          record: row.readTableOrNull(_db.habitRecords),
        );
      }).toList();
    });
  }

  Stream<List<HabitTemplate>> watchActiveTemplates() {
    final query = _db.select(_db.habitTemplates)
      ..where(
        (template) =>
            template.deletedAt.isNull() & template.isEnabled.equals(true),
      )
      ..orderBy([(template) => OrderingTerm.asc(template.sortOrder)]);
    return query.watch();
  }

  Stream<List<HabitRecord>> watchRecordsInRange(DateRange range) {
    final query = _db.select(_db.habitRecords)
      ..where(
        (record) =>
            record.date.isBiggerOrEqualValue(range.start) &
            record.date.isSmallerThanValue(range.endExclusive) &
            record.isDone.equals(true),
      );
    return query.watch();
  }

  Future<void> seedDefaultHabits() async {
    final now = _clock.now();
    final defaults = <HabitTemplatesCompanion>[
      HabitTemplatesCompanion.insert(
        id: 'habit-wake-up',
        title: '早起',
        type: habitTypeWakeUp,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      HabitTemplatesCompanion.insert(
        id: 'habit-sleep',
        title: '早睡',
        type: habitTypeSleep,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      HabitTemplatesCompanion.insert(
        id: 'habit-reading',
        title: '阅读',
        type: habitTypeNormal,
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
      HabitTemplatesCompanion.insert(
        id: 'habit-exercise',
        title: '运动',
        type: habitTypeNormal,
        sortOrder: 3,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final item in defaults) {
      await _db
          .into(_db.habitTemplates)
          .insert(item, mode: InsertMode.insertOrIgnore);
    }
  }

  Future<void> addHabitTemplate(String title) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final now = _clock.now();
    final existing = await watchActiveTemplates().first;
    await _db.into(_db.habitTemplates).insert(
          HabitTemplatesCompanion.insert(
            id: _uuid.v4(),
            title: cleanTitle,
            type: habitTypeNormal,
            sortOrder: existing.length,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateHabitTitle(String id, String title) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final current = await (_db.select(_db.habitTemplates)
          ..where((row) => row.id.equals(id)))
        .getSingle();
    await (_db.update(_db.habitTemplates)..where((row) => row.id.equals(id)))
        .write(
      HabitTemplatesCompanion(
        title: Value(cleanTitle),
        updatedAt: Value(_clock.now()),
        revision: Value(current.revision + 1),
      ),
    );
  }

  Future<void> softDeleteHabitTemplate(String id) async {
    final current = await (_db.select(_db.habitTemplates)
          ..where((row) => row.id.equals(id)))
        .getSingle();
    if (current.type != habitTypeNormal) return;
    final now = _clock.now();
    await (_db.update(_db.habitTemplates)..where((row) => row.id.equals(id)))
        .write(
      HabitTemplatesCompanion(
        isEnabled: const Value(false),
        deletedAt: Value(now),
        updatedAt: Value(now),
        revision: Value(current.revision + 1),
      ),
    );
  }

  Future<void> reorderHabitTemplates(List<String> orderedIds) async {
    final now = _clock.now();
    await _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        final current = await (_db.select(_db.habitTemplates)
              ..where((row) => row.id.equals(orderedIds[i])))
            .getSingle();
        await (_db.update(_db.habitTemplates)
              ..where((row) => row.id.equals(orderedIds[i])))
            .write(
          HabitTemplatesCompanion(
            sortOrder: Value(i),
            updatedAt: Value(now),
            revision: Value(current.revision + 1),
          ),
        );
      }
    });
  }

  Future<bool> toggleHabit(HabitTemplate template, DateTime visibleDate) async {
    final now = _clock.now();
    final visibleBusinessDate = dateOnly(visibleDate);
    final today = dateOnly(now);
    final targetDate =
        template.type == habitTypeSleep && visibleBusinessDate == today
            ? businessDateForSleep(now)
            : visibleBusinessDate;
    final existing = await (_db.select(_db.habitRecords)
          ..where(
            (record) =>
                record.habitTemplateId.equals(template.id) &
                record.date.equals(targetDate),
          )
          ..limit(1))
        .getSingleOrNull();

    if (existing?.isDone == true) {
      final checkedAt = existing!.checkedAt;
      if (checkedAt == null ||
          now.isAfter(checkedAt.add(const Duration(minutes: 5)))) {
        return false;
      }
      await _db.transaction(() async {
        await (_db.update(_db.habitRecords)
              ..where((row) => row.id.equals(existing.id)))
            .write(
          HabitRecordsCompanion(
            isDone: const Value(false),
            checkedAt: const Value<DateTime?>(null),
            valueTime: const Value<DateTime?>(null),
            updatedAt: Value(now),
            revision: Value(existing.revision + 1),
          ),
        );
        await _cancelLatestEvent(_targetTypeForHabit(template), existing.id);
      });
      return true;
    }

    final recordId = existing?.id ?? _uuid.v4();
    await _db.transaction(() async {
      if (existing == null) {
        await _db.into(_db.habitRecords).insert(
              HabitRecordsCompanion.insert(
                id: recordId,
                habitTemplateId: template.id,
                date: targetDate,
                isDone: const Value(true),
                checkedAt: Value(now),
                valueTime: Value<DateTime?>(
                    template.type == habitTypeNormal ? null : now),
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(_db.habitRecords)
              ..where((row) => row.id.equals(existing.id)))
            .write(
          HabitRecordsCompanion(
            isDone: const Value(true),
            checkedAt: Value(now),
            valueTime:
                Value<DateTime?>(template.type == habitTypeNormal ? null : now),
            updatedAt: Value(now),
            revision: Value(existing.revision + 1),
          ),
        );
      }
      await _createCompletion(
        targetType: _targetTypeForHabit(template),
        targetId: recordId,
        title: template.title,
        businessDate: targetDate,
        completedAt: now,
        color: template.type == habitTypeNormal ? 'purple' : 'violet',
      );
    });
    return true;
  }

  String _targetTypeForHabit(HabitTemplate template) {
    if (template.type == habitTypeWakeUp) return targetWakeUp;
    if (template.type == habitTypeSleep) return targetSleep;
    return targetHabit;
  }

  Future<void> _createCompletion({
    required String targetType,
    required String targetId,
    required String title,
    required DateTime businessDate,
    required DateTime completedAt,
    String? color,
  }) {
    return _db.into(_db.completionEvents).insert(
          CompletionEventsCompanion.insert(
            id: _uuid.v4(),
            targetType: targetType,
            targetId: targetId,
            targetTitleSnapshot: title,
            date: dateOnly(businessDate),
            completedAt: completedAt,
            undoDeadlineAt: completedAt.add(const Duration(minutes: 5)),
            color: Value<String?>(color),
            createdAt: completedAt,
          ),
        );
  }

  Future<void> _cancelLatestEvent(String targetType, String targetId) async {
    final events = await (_db.select(_db.completionEvents)
          ..where(
            (event) =>
                event.targetType.equals(targetType) &
                event.targetId.equals(targetId) &
                event.isCanceled.equals(false),
          )
          ..orderBy([(event) => OrderingTerm.desc(event.completedAt)])
          ..limit(1))
        .get();
    if (events.isEmpty) return;
    await (_db.update(_db.completionEvents)
          ..where((event) => event.id.equals(events.first.id)))
        .write(
      const CompletionEventsCompanion(isCanceled: Value(true)),
    );
  }
}

class MemoRepository {
  MemoRepository(this._db, this._clock, this._uuid);

  final AppDatabase _db;
  final AppClock _clock;
  final Uuid _uuid;

  Stream<List<MemoTask>> watchActiveMemos() {
    final query = _db.select(_db.memoTasks)
      ..where(
          (memo) => memo.deletedAt.isNull() & memo.isArchived.equals(false));
    return query.watch().map((items) {
      final today = dateOnly(_clock.now());
      final sorted = [...items]..sort(
          (a, b) => compareMemoDeadline(
            aDueDate: a.dueDate,
            aDone: a.isDone,
            aUpdatedAt: a.updatedAt,
            bDueDate: b.dueDate,
            bDone: b.isDone,
            bUpdatedAt: b.updatedAt,
            today: today,
          ),
        );
      return sorted;
    });
  }

  Stream<List<MemoTask>> watchMemosInRange(DateRange range) {
    final query = _db.select(_db.memoTasks)
      ..where(
        (memo) =>
            memo.deletedAt.isNull() &
            memo.dueDate.isBiggerOrEqualValue(range.start) &
            memo.dueDate.isSmallerThanValue(range.endExclusive),
      );
    return query.watch();
  }

  Future<void> addMemo(String content, DateTime dueDate) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;
    final now = _clock.now();
    await _db.into(_db.memoTasks).insert(
          MemoTasksCompanion.insert(
            id: _uuid.v4(),
            content: cleanContent,
            dueDate: dateOnly(dueDate),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateMemo(String id, String content, DateTime dueDate) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;
    final now = _clock.now();
    await (_db.update(_db.memoTasks)..where((row) => row.id.equals(id))).write(
      MemoTasksCompanion(
        content: Value(cleanContent),
        dueDate: Value(dateOnly(dueDate)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> toggleCompletion(String id) async {
    final memo = await (_db.select(_db.memoTasks)
          ..where((row) => row.id.equals(id)))
        .getSingle();
    final now = _clock.now();
    if (memo.isDone) {
      if (memo.completedAt == null ||
          now.isAfter(memo.completedAt!.add(const Duration(minutes: 5)))) {
        return false;
      }
      await _db.transaction(() async {
        await (_db.update(_db.memoTasks)..where((row) => row.id.equals(id)))
            .write(
          MemoTasksCompanion(
            isDone: const Value(false),
            completedAt: const Value<DateTime?>(null),
            updatedAt: Value(now),
            revision: Value(memo.revision + 1),
          ),
        );
        await _cancelLatestEvent(targetMemo, id);
      });
      return true;
    }

    await _db.transaction(() async {
      await (_db.update(_db.memoTasks)..where((row) => row.id.equals(id)))
          .write(
        MemoTasksCompanion(
          isDone: const Value(true),
          completedAt: Value(now),
          updatedAt: Value(now),
          revision: Value(memo.revision + 1),
        ),
      );
      await _db.into(_db.completionEvents).insert(
            CompletionEventsCompanion.insert(
              id: _uuid.v4(),
              targetType: targetMemo,
              targetId: id,
              targetTitleSnapshot: memo.content,
              date: dateOnly(now),
              completedAt: now,
              undoDeadlineAt: now.add(const Duration(minutes: 5)),
              color: const Value('blue'),
              createdAt: now,
            ),
          );
    });
    return true;
  }

  Future<void> archiveMemo(String id) async {
    final now = _clock.now();
    await (_db.update(_db.memoTasks)..where((row) => row.id.equals(id))).write(
      MemoTasksCompanion(isArchived: const Value(true), updatedAt: Value(now)),
    );
  }

  Future<void> softDeleteMemo(String id) async {
    final now = _clock.now();
    await (_db.update(_db.memoTasks)..where((row) => row.id.equals(id))).write(
      MemoTasksCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<void> _cancelLatestEvent(String targetType, String targetId) async {
    final events = await (_db.select(_db.completionEvents)
          ..where(
            (event) =>
                event.targetType.equals(targetType) &
                event.targetId.equals(targetId) &
                event.isCanceled.equals(false),
          )
          ..orderBy([(event) => OrderingTerm.desc(event.completedAt)])
          ..limit(1))
        .get();
    if (events.isEmpty) return;
    await (_db.update(_db.completionEvents)
          ..where((event) => event.id.equals(events.first.id)))
        .write(
      const CompletionEventsCompanion(isCanceled: Value(true)),
    );
  }
}

class CompletionRepository {
  CompletionRepository(this._db);

  final AppDatabase _db;

  Stream<List<CompletionEvent>> watchEvents(DateRange range) {
    final query = _db.select(_db.completionEvents)
      ..where(
        (event) =>
            event.isCanceled.equals(false) &
            event.date.isBiggerOrEqualValue(range.start) &
            event.date.isSmallerThanValue(range.endExclusive),
      )
      ..orderBy([(event) => OrderingTerm.asc(event.completedAt)]);
    return query.watch();
  }
}

class ProfileRepository {
  ProfileRepository(this._db, this._clock);

  final AppDatabase _db;
  final AppClock _clock;

  Stream<UserProfile> watchProfile() {
    return (_db.select(_db.userProfiles)
          ..where((row) => row.id.equals('local_user')))
        .watchSingle();
  }

  Future<void> seedProfile() async {
    final now = _clock.now();
    await _db.into(_db.userProfiles).insert(
          UserProfilesCompanion.insert(
            id: 'local_user',
            nickname: 'GreenSprout',
            username: 'local_user',
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> updateNickname(String nickname) async {
    final cleanNickname = nickname.trim();
    if (cleanNickname.isEmpty) return;
    await (_db.update(_db.userProfiles)
          ..where((row) => row.id.equals('local_user')))
        .write(
      UserProfilesCompanion(
        nickname: Value(cleanNickname),
        updatedAt: Value(_clock.now()),
      ),
    );
  }

  Future<void> updateAvatarUri(String? avatarUri) async {
    final cleanAvatarUri = avatarUri?.trim();
    await (_db.update(_db.userProfiles)
          ..where((row) => row.id.equals('local_user')))
        .write(
      UserProfilesCompanion(
        avatarUri: Value(
          cleanAvatarUri == null || cleanAvatarUri.isEmpty
              ? null
              : cleanAvatarUri,
        ),
        updatedAt: Value(_clock.now()),
      ),
    );
  }
}
