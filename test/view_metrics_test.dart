import 'package:flutter_test/flutter_test.dart';
import 'package:pacekit/src/data/app_database.dart';
import 'package:pacekit/src/data/repositories.dart';
import 'package:pacekit/src/features/view/view_metrics.dart';

void main() {
  group('View metrics', () {
    test('day donut excludes wake and sleep events', () {
      final day = DateTime(2026, 4, 27);
      final stats = ViewDayStats(
        day: day,
        events: [
          _event(targetWakeUp, day, DateTime(2026, 4, 27, 7, 12)),
          _event(targetPlan, day, DateTime(2026, 4, 27, 9, 30)),
          _event(targetMemo, day, DateTime(2026, 4, 27, 11, 20)),
          _event(targetHabit, day, DateTime(2026, 4, 27, 18, 20)),
          _event(targetSleep, day, DateTime(2026, 4, 27, 23, 48)),
        ],
        planTotal: 1,
        memoTotal: 1,
        normalHabitTotal: 1,
      );

      expect(stats.donutEvents.map((event) => event.targetType), [
        targetPlan,
        targetMemo,
        targetHabit,
      ]);
      expect(stats.timelineEvents.map((event) => event.targetType), [
        targetWakeUp,
        targetPlan,
        targetMemo,
        targetHabit,
        targetSleep,
      ]);
    });

    test('cross-night sleep duration is calculated from sleep to next wake',
        () {
      final day = DateTime(2026, 4, 27);
      final stats = ViewDayStats(
        day: day,
        events: [
          _event(targetWakeUp, day, DateTime(2026, 4, 27, 7, 12)),
          _event(targetSleep, day, DateTime(2026, 4, 27, 23, 48)),
        ],
        planTotal: 0,
        memoTotal: 0,
        normalHabitTotal: 0,
      );

      expect(
          stats.sleepSummary.duration, const Duration(hours: 7, minutes: 24));
      expect(stats.sleepSummary.isAbnormal, isFalse);
    });

    test('missing wake or sleep is incomplete and abnormal', () {
      final day = DateTime(2026, 4, 27);
      final stats = ViewDayStats(
        day: day,
        events: [_event(targetSleep, day, DateTime(2026, 4, 27, 23, 48))],
        planTotal: 0,
        memoTotal: 0,
        normalHabitTotal: 0,
      );

      expect(stats.sleepSummary.isComplete, isFalse);
      expect(stats.sleepSummary.duration, isNull);
      expect(stats.sleepSummary.isAbnormal, isTrue);
    });

    test('plan ratio uses completed events as the minimum denominator', () {
      final day = DateTime(2026, 4, 27);
      final stats = ViewDayStats(
        day: day,
        events: [
          _event(targetPlan, day, DateTime(2026, 4, 27, 9)),
          _event(targetPlan, day, DateTime(2026, 4, 27, 10)),
          _event(targetPlan, day, DateTime(2026, 4, 27, 11)),
        ],
        planTotal: 2,
        memoTotal: 0,
        normalHabitTotal: 0,
      );

      expect(stats.safePlanTotal, 3);
      expect(stats.planRatio, 1);
    });

    test('range stats calculate habit streak and abnormal sleep days', () {
      final start = DateTime(2026, 4, 20);
      final days = [
        ViewDayStats(
          day: start,
          events: [
            _event(targetHabit, start, DateTime(2026, 4, 20, 12)),
            _event(targetWakeUp, start, DateTime(2026, 4, 20, 3)),
            _event(targetSleep, start, DateTime(2026, 4, 20, 23)),
          ],
          planTotal: 0,
          memoTotal: 0,
          normalHabitTotal: 1,
        ),
        ViewDayStats(
          day: start.add(const Duration(days: 1)),
          events: [
            _event(targetHabit, start.add(const Duration(days: 1)),
                DateTime(2026, 4, 21, 12)),
          ],
          planTotal: 0,
          memoTotal: 0,
          normalHabitTotal: 1,
        ),
      ];

      final stats = ViewRangeStats(days: days);

      expect(stats.habitStreak, 2);
      expect(stats.abnormalSleepDays, 1);
    });
  });
}

CompletionEvent _event(String type, DateTime day, DateTime completedAt) {
  return CompletionEvent(
    id: '$type-${completedAt.microsecondsSinceEpoch}',
    targetType: type,
    targetId: 'target-$type',
    targetTitleSnapshot: switch (type) {
      targetPlan => 'Finish slides',
      targetMemo => 'Reading',
      targetHabit => 'Exercise',
      targetWakeUp => 'Wake Up',
      targetSleep => 'Sleep Early',
      _ => 'Record',
    },
    date: day,
    completedAt: completedAt,
    undoDeadlineAt: completedAt.add(const Duration(minutes: 5)),
    isCanceled: false,
    createdAt: completedAt,
    syncStatus: 'local',
    revision: 0,
  );
}
