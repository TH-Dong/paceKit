import 'package:flutter_test/flutter_test.dart';
import 'package:pacekit/src/core/planning_rules.dart';

void main() {
  group('planning rules', () {
    test('sleep before the 05:00 boundary belongs to previous day', () {
      final clickedAt = DateTime(2026, 4, 27, 1, 20);

      expect(businessDateForSleep(clickedAt), DateTime(2026, 4, 26));
    });

    test('sleep after the 05:00 boundary belongs to current day', () {
      final clickedAt = DateTime(2026, 4, 27, 23, 40);

      expect(businessDateForSleep(clickedAt), DateTime(2026, 4, 27));
    });

    test('today score maps to the expected pet mood thresholds', () {
      expect(moodFromScore(0.80), PetMood.happy);
      expect(moodFromScore(0.50), PetMood.normal);
      expect(moodFromScore(0.20), PetMood.sad);
    });

    test('today score uses plan, habit, and memo weights', () {
      final score = todayScore(planRatio: 1, habitRatio: 0.5, memoRatio: 0);

      expect(score, closeTo(0.775, 0.001));
    });

    test('yesterday plan remains editable before the 06:00 carry-over cutoff',
        () {
      final yesterday = DateTime(2026, 4, 26);
      final now = DateTime(2026, 4, 27, 5, 59);

      expect(canEditPlanDate(yesterday, now: now), isTrue);
      expect(isPlanDateExpired(yesterday, now: now), isFalse);
    });

    test('yesterday plan expires at the 06:00 carry-over cutoff', () {
      final yesterday = DateTime(2026, 4, 26);
      final now = DateTime(2026, 4, 27, 6);

      expect(canEditPlanDate(yesterday, now: now), isFalse);
      expect(isPlanDateExpired(yesterday, now: now), isTrue);
    });

    test('future plan dates are not editable but are not missed', () {
      final tomorrow = DateTime(2026, 4, 28);
      final now = DateTime(2026, 4, 27, 20);

      expect(canEditPlanDate(tomorrow, now: now), isFalse);
      expect(isPlanDateExpired(tomorrow, now: now), isFalse);
    });

    test('memo urgency is based on local calendar days, not hours', () {
      final today = DateTime(2026, 4, 27, 23, 30);
      final tomorrow = DateTime(2026, 4, 28, 0, 10);

      expect(memoUrgency(dueDate: tomorrow, today: today, isDone: false),
          MemoUrgency.oneDay);
    });

    test('completed memos sort after active memos', () {
      final today = DateTime(2026, 4, 27);
      final result = compareMemoDeadline(
        aDueDate: DateTime(2026, 4, 27),
        aDone: true,
        aUpdatedAt: DateTime(2026, 4, 27, 10),
        bDueDate: DateTime(2026, 5, 1),
        bDone: false,
        bUpdatedAt: DateTime(2026, 4, 27, 9),
        today: today,
      );

      expect(result, greaterThan(0));
    });

    test('sleep summary detects incomplete and abnormal records', () {
      expect(
          const SleepSummary(sleepAt: null, wakeAt: null).isAbnormal, isTrue);

      final shortSleep = SleepSummary(
        sleepAt: DateTime(2026, 4, 27, 1),
        wakeAt: DateTime(2026, 4, 27, 5),
      );

      expect(shortSleep.isComplete, isTrue);
      expect(shortSleep.isAbnormal, isTrue);
    });
  });
}
