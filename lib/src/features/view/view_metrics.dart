import '../../core/planning_rules.dart';
import '../../data/app_database.dart';
import '../../data/repositories.dart';

class ViewSleepSummary {
  const ViewSleepSummary({
    required this.sleepAt,
    required this.wakeAt,
  });

  final DateTime? sleepAt;
  final DateTime? wakeAt;

  bool get hasAnyRecord => sleepAt != null || wakeAt != null;

  bool get isComplete => sleepAt != null && wakeAt != null;

  DateTime? get adjustedWakeAt {
    if (!isComplete) return null;
    if (wakeAt!.isAfter(sleepAt!)) return wakeAt;
    return wakeAt!.add(const Duration(days: 1));
  }

  Duration? get duration {
    final adjusted = adjustedWakeAt;
    if (sleepAt == null || adjusted == null) return null;
    return adjusted.difference(sleepAt!);
  }

  bool get isAbnormal {
    final value = duration;
    if (value == null) return true;
    return value < const Duration(hours: 6) ||
        value > const Duration(hours: 10);
  }

  int get qualityStars {
    final value = duration;
    if (value == null) return 0;
    if (value >= const Duration(hours: 7) &&
        value <= const Duration(hours: 9)) {
      return 5;
    }
    if (value >= const Duration(hours: 6) &&
        value <= const Duration(hours: 10)) {
      return 4;
    }
    return 2;
  }
}

class ViewDayStats {
  const ViewDayStats({
    required this.day,
    required this.events,
    required this.planTotal,
    required this.memoTotal,
    required this.normalHabitTotal,
  });

  final DateTime day;
  final List<CompletionEvent> events;
  final int planTotal;
  final int memoTotal;
  final int normalHabitTotal;

  List<CompletionEvent> get timelineEvents =>
      [...events]..sort((a, b) => a.completedAt.compareTo(b.completedAt));

  List<CompletionEvent> get donutEvents => events
      .where((event) =>
          event.targetType == targetPlan ||
          event.targetType == targetMemo ||
          event.targetType == targetHabit)
      .toList();

  int get planDone => _countType(targetPlan);
  int get memoDone => _countType(targetMemo);
  int get habitDone => _countType(targetHabit);

  int get safePlanTotal => planTotal < planDone ? planDone : planTotal;
  int get safeMemoTotal => memoTotal < memoDone ? memoDone : memoTotal;
  int get safeHabitTotal =>
      normalHabitTotal < habitDone ? habitDone : normalHabitTotal;

  double get planRatio => completionRatio(planDone, safePlanTotal);

  double get completionRate {
    final done = planDone + memoDone + habitDone;
    final total = safePlanTotal + safeMemoTotal + safeHabitTotal;
    if (total == 0) return done > 0 ? 1 : 0;
    return completionRatio(done, total);
  }

  ViewSleepSummary get sleepSummary {
    DateTime? sleepAt;
    DateTime? wakeAt;
    for (final event in timelineEvents) {
      if (event.targetType == targetSleep) sleepAt = event.completedAt;
      if (event.targetType == targetWakeUp) wakeAt = event.completedAt;
    }
    return ViewSleepSummary(sleepAt: sleepAt, wakeAt: wakeAt);
  }

  int _countType(String type) =>
      events.where((event) => event.targetType == type).length;
}

class ViewRangeStats {
  const ViewRangeStats({required this.days});

  final List<ViewDayStats> days;

  int get planDone => days.fold(0, (sum, day) => sum + day.planDone);
  int get planTotal => days.fold(0, (sum, day) => sum + day.safePlanTotal);
  int get memoDone => days.fold(0, (sum, day) => sum + day.memoDone);
  int get memoTotal => days.fold(0, (sum, day) => sum + day.safeMemoTotal);
  int get habitDone => days.fold(0, (sum, day) => sum + day.habitDone);
  int get habitTotal => days.fold(0, (sum, day) => sum + day.safeHabitTotal);

  double get completionRate {
    final done = planDone + memoDone + habitDone;
    final total = planTotal + memoTotal + habitTotal;
    if (total == 0) return done > 0 ? 1 : 0;
    return completionRatio(done, total);
  }

  int get abnormalSleepDays => days
      .where(
          (day) => day.sleepSummary.hasAnyRecord && day.sleepSummary.isAbnormal)
      .length;

  Duration? get averageSleep {
    final durations = days
        .map((day) => day.sleepSummary.duration)
        .whereType<Duration>()
        .toList();
    if (durations.isEmpty) return null;
    final totalMinutes =
        durations.fold<int>(0, (sum, value) => sum + value.inMinutes);
    return Duration(minutes: (totalMinutes / durations.length).round());
  }

  int get habitStreak {
    var streak = 0;
    for (final day in days.reversed) {
      if (day.habitDone <= 0) break;
      streak++;
    }
    return streak;
  }
}

Map<DateTime, List<CompletionEvent>> groupEventsByDay(
  List<CompletionEvent> events,
) {
  final map = <DateTime, List<CompletionEvent>>{};
  for (final event in events) {
    final day = dateOnly(event.date);
    map.putIfAbsent(day, () => []).add(event);
  }
  for (final entry in map.entries) {
    entry.value.sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }
  return map;
}

List<ViewDayStats> buildDayStats({
  required DateTime start,
  required int dayCount,
  required List<CompletionEvent> events,
  required List<PlanTask> plans,
  required List<MemoTask> memos,
  required int normalHabitTotal,
}) {
  final byDay = groupEventsByDay(events);
  return List.generate(dayCount, (index) {
    final day = dateOnly(start.add(Duration(days: index)));
    return ViewDayStats(
      day: day,
      events: byDay[day] ?? const <CompletionEvent>[],
      planTotal: plans.where((plan) => dateOnly(plan.date) == day).length,
      memoTotal: memos.where((memo) => dateOnly(memo.dueDate) == day).length,
      normalHabitTotal: normalHabitTotal,
    );
  });
}

int activeNormalHabitTotal(List<HabitTemplate> templates) {
  return templates
      .where((template) =>
          template.isEnabled &&
          template.deletedAt == null &&
          template.type == habitTypeNormal)
      .length;
}

List<int> balancedPercents(List<int> counts) {
  final total = counts.fold<int>(0, (sum, value) => sum + value);
  if (total == 0) return List<int>.filled(counts.length, 0);

  final raw = counts.map((count) => count * 100 / total).toList();
  final floors = raw.map((value) => value.floor()).toList();
  var remaining = 100 - floors.fold<int>(0, (sum, value) => sum + value);
  final order = List<int>.generate(counts.length, (index) => index)
    ..sort((a, b) => (raw[b] - floors[b]).compareTo(raw[a] - floors[a]));

  for (var i = 0; i < order.length && remaining > 0; i++, remaining--) {
    floors[order[i]]++;
  }
  return floors;
}
