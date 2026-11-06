import 'package:flutter/foundation.dart';

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime startOfWeek(DateTime value) {
  final day = dateOnly(value);
  return day.subtract(Duration(days: day.weekday - 1));
}

DateTime startOfMonth(DateTime value) => DateTime(value.year, value.month);

DateTime businessDateForSleep(DateTime clickedAt, {int dayBoundaryHour = 5}) {
  final day = dateOnly(clickedAt);
  if (clickedAt.hour < dayBoundaryHour) {
    return day.subtract(const Duration(days: 1));
  }
  return day;
}

bool canEditPlanDate(DateTime visibleDate,
    {required DateTime now, int carryOverCutoffHour = 6}) {
  final target = dateOnly(visibleDate);
  final cutoff = target.add(Duration(days: 1, hours: carryOverCutoffHour));
  return !target.isAfter(dateOnly(now)) && now.isBefore(cutoff);
}

bool isPlanDateExpired(DateTime visibleDate,
    {required DateTime now, int carryOverCutoffHour = 6}) {
  final target = dateOnly(visibleDate);
  if (!target.isBefore(dateOnly(now))) return false;
  final cutoff = target.add(Duration(days: 1, hours: carryOverCutoffHour));
  return !now.isBefore(cutoff);
}

double completionRatio(int done, int total) {
  if (total <= 0) return 0;
  return (done / total).clamp(0, 1).toDouble();
}

enum PetMood { happy, normal, sad }

PetMood moodFromScore(double score) {
  if (score >= 0.75) return PetMood.happy;
  if (score >= 0.35) return PetMood.normal;
  return PetMood.sad;
}

double todayScore({
  required double planRatio,
  required double habitRatio,
  required double memoRatio,
}) {
  return (0.65 * planRatio + 0.25 * habitRatio + 0.10 * memoRatio)
      .clamp(0, 1)
      .toDouble();
}

enum MemoUrgency { overdue, today, oneDay, twoDays, threeDays, later, done }

MemoUrgency memoUrgency({
  required DateTime dueDate,
  required DateTime today,
  required bool isDone,
}) {
  if (isDone) return MemoUrgency.done;
  final daysLeft = dateOnly(dueDate).difference(dateOnly(today)).inDays;
  if (daysLeft < 0) return MemoUrgency.overdue;
  if (daysLeft == 0) return MemoUrgency.today;
  if (daysLeft == 1) return MemoUrgency.oneDay;
  if (daysLeft == 2) return MemoUrgency.twoDays;
  if (daysLeft == 3) return MemoUrgency.threeDays;
  return MemoUrgency.later;
}

int compareMemoDeadline({
  required DateTime aDueDate,
  required bool aDone,
  required DateTime aUpdatedAt,
  required DateTime bDueDate,
  required bool bDone,
  required DateTime bUpdatedAt,
  required DateTime today,
}) {
  final aUrgency = memoUrgency(dueDate: aDueDate, today: today, isDone: aDone);
  final bUrgency = memoUrgency(dueDate: bDueDate, today: today, isDone: bDone);
  final urgencyCompare = aUrgency.index.compareTo(bUrgency.index);
  if (urgencyCompare != 0) return urgencyCompare;
  final dueCompare = dateOnly(aDueDate).compareTo(dateOnly(bDueDate));
  if (dueCompare != 0) return dueCompare;
  return bUpdatedAt.compareTo(aUpdatedAt);
}

@immutable
class SleepSummary {
  const SleepSummary({
    required this.sleepAt,
    required this.wakeAt,
  });

  final DateTime? sleepAt;
  final DateTime? wakeAt;

  bool get isComplete =>
      sleepAt != null && wakeAt != null && wakeAt!.isAfter(sleepAt!);

  Duration? get duration => isComplete ? wakeAt!.difference(sleepAt!) : null;

  bool get isAbnormal {
    final value = duration;
    if (value == null) return true;
    return value < const Duration(hours: 6) ||
        value > const Duration(hours: 10);
  }
}
