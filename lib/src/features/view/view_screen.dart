import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/planning_rules.dart';
import '../../data/app_database.dart';
import '../../data/repositories.dart';
import '../../features/pet/pet_image.dart';
import '../../shared/empty_state.dart';
import '../../shared/glass_card.dart';
import 'view_metrics.dart';

enum ViewMode { day, week, month }

const _activeGreen = Color(0xFF28B864);
const _ink = Color(0xFF24384B);
const _mutedInk = Color(0xFF5C7085);
const _planColor = Color(0xFF43C977);
const _memoColor = Color(0xFF6EA1EA);
const _habitColor = Color(0xFF9368E8);
const _wakeColor = Color(0xFFF0BF32);
const _sleepColor = Color(0xFF8C63D8);
const _dangerColor = Color(0xFFE94E5C);

class ViewScreen extends ConsumerStatefulWidget {
  const ViewScreen({super.key});

  @override
  ConsumerState<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends ConsumerState<ViewScreen> {
  var _mode = ViewMode.day;
  var _selectedDay = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final range = _rangeForMode(_mode, _selectedDay);
    final events = ref.watch(completionEventsProvider(range));
    final plans = ref.watch(planTasksInRangeProvider(range));
    final memos = ref.watch(memoTasksInRangeProvider(range));
    final habitTemplates = ref.watch(activeHabitTemplatesProvider);
    final asyncValues = <AsyncValue<dynamic>>[
      events,
      plans,
      memos,
      habitTemplates,
    ];
    final error = _firstAsyncError(asyncValues);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
      children: [
        _ViewModeControl(
          mode: _mode,
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 18),
        if (error != null)
          GlassCard(child: Text('加载失败：$error'))
        else if (_isAnyLoading(asyncValues))
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _buildModeView(
            range: range,
            events: events.requireValue,
            plans: plans.requireValue,
            memos: memos.requireValue,
            activeTemplates: habitTemplates.requireValue,
          ),
      ],
    );
  }

  Widget _buildModeView({
    required DateRange range,
    required List<CompletionEvent> events,
    required List<PlanTask> plans,
    required List<MemoTask> memos,
    required List<HabitTemplate> activeTemplates,
  }) {
    final normalHabitTotal = activeNormalHabitTotal(activeTemplates);
    final days = buildDayStats(
      start: range.start,
      dayCount: range.endExclusive.difference(range.start).inDays,
      events: events,
      plans: plans,
      memos: memos,
      normalHabitTotal: normalHabitTotal,
    );
    final selectedStats = _statsForDay(days, _selectedDay, normalHabitTotal);

    return switch (_mode) {
      ViewMode.day => _DayView(
          stats: selectedStats,
          onPreviousDay: () => setState(
            () => _selectedDay = _selectedDay.subtract(const Duration(days: 1)),
          ),
          onNextDay: () => setState(
            () => _selectedDay = _selectedDay.add(const Duration(days: 1)),
          ),
          onToday: () =>
              setState(() => _selectedDay = dateOnly(DateTime.now())),
        ),
      ViewMode.week => _WeekView(
          selectedDay: _selectedDay,
          days: days,
          onSelectDay: (day) => setState(() => _selectedDay = day),
          onPreviousWeek: () => setState(
            () => _selectedDay = _selectedDay.subtract(const Duration(days: 7)),
          ),
          onNextWeek: () => setState(
            () => _selectedDay = _selectedDay.add(const Duration(days: 7)),
          ),
        ),
      ViewMode.month => _MonthView(
          selectedDay: _selectedDay,
          days: days,
          onSelectDay: (day) => setState(() => _selectedDay = day),
          onShowDay: () => setState(() => _mode = ViewMode.day),
          onPreviousMonth: () => setState(
            () => _selectedDay =
                DateTime(_selectedDay.year, _selectedDay.month - 1),
          ),
          onNextMonth: () => setState(
            () => _selectedDay =
                DateTime(_selectedDay.year, _selectedDay.month + 1),
          ),
        ),
    };
  }

  DateRange _rangeForMode(ViewMode mode, DateTime selectedDay) {
    final day = dateOnly(selectedDay);
    return switch (mode) {
      ViewMode.day => DateRange(day, day.add(const Duration(days: 1))),
      ViewMode.week => DateRange(
          startOfWeek(day),
          startOfWeek(day).add(const Duration(days: 7)),
        ),
      ViewMode.month =>
        DateRange(startOfMonth(day), DateTime(day.year, day.month + 1)),
    };
  }
}

Object? _firstAsyncError(List<AsyncValue<dynamic>> values) {
  for (final value in values) {
    if (value.hasError) return value.error;
  }
  return null;
}

bool _isAnyLoading(List<AsyncValue<dynamic>> values) {
  return values.any((value) => !value.hasValue);
}

ViewDayStats _statsForDay(
  List<ViewDayStats> days,
  DateTime day,
  int normalHabitTotal,
) {
  final target = dateOnly(day);
  for (final stats in days) {
    if (stats.day == target) return stats;
  }
  return ViewDayStats(
    day: target,
    events: const <CompletionEvent>[],
    planTotal: 0,
    memoTotal: 0,
    normalHabitTotal: normalHabitTotal,
  );
}

class _ViewModeControl extends StatelessWidget {
  const _ViewModeControl({
    required this.mode,
    required this.onChanged,
  });

  final ViewMode mode;
  final ValueChanged<ViewMode> onChanged;

  static const _items = <_ViewModeItem>[
    _ViewModeItem(ViewMode.day, '日'),
    _ViewModeItem(ViewMode.week, '周'),
    _ViewModeItem(ViewMode.month, '月'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _items.indexWhere((item) => item.mode == mode);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 336),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.48),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _activeGreen.withValues(alpha: 0.07),
                blurRadius: 28,
                offset: const Offset(0, 11),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: itemWidth * selectedIndex + 6,
                    top: 6,
                    bottom: 6,
                    width: itemWidth - 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.98),
                            isDark
                                ? _activeGreen.withValues(alpha: 0.18)
                                : const Color(0xFFF1FCF5)
                                    .withValues(alpha: 0.98),
                            isDark
                                ? colors.surfaceContainerHighest
                                    .withValues(alpha: 0.88)
                                : Colors.white.withValues(alpha: 0.92),
                          ],
                        ),
                        border: Border.all(
                          color: _activeGreen.withValues(alpha: 0.13),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _activeGreen.withValues(alpha: 0.17),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          if (!isDark)
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.82),
                              blurRadius: 8,
                              offset: const Offset(-2, -3),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final item in _items)
                        Expanded(
                          child: InkWell(
                            onTap: () => onChanged(item.mode),
                            borderRadius: BorderRadius.circular(999),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: item.mode == mode
                                      ? _activeGreen
                                      : (isDark
                                          ? colors.onSurface
                                              .withValues(alpha: 0.74)
                                          : _ink.withValues(alpha: 0.74)),
                                  fontFamily: 'LXGWWenKaiScreen',
                                  fontSize: 19,
                                  fontWeight: item.mode == mode
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                                child: Text(item.label),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ViewModeItem {
  const _ViewModeItem(this.mode, this.label);

  final ViewMode mode;
  final String label;
}

class _DayView extends StatelessWidget {
  const _DayView({
    required this.stats,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onToday,
  });

  final ViewDayStats stats;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateSwitcher(
          title: _dayTitle(stats.day),
          subtitle: DateFormat('yyyy年M月d日').format(stats.day),
          onPrevious: onPreviousDay,
          onNext: onNextDay,
          trailing: _SmallTextButton(label: '今天', onTap: onToday),
        ),
        const SizedBox(height: 14),
        _DailyDonutSummaryCard(stats: stats),
        const SizedBox(height: 16),
        _TimelineCard(
          title: '今日时间线',
          events: stats.timelineEvents,
          emptyTitle: '还没有完成记录',
        ),
        const SizedBox(height: 16),
        _SleepSummaryCard(summary: stats.sleepSummary),
      ],
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.selectedDay,
    required this.days,
    required this.onSelectDay,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final DateTime selectedDay;
  final List<ViewDayStats> days;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final start = startOfWeek(selectedDay);
    final end = start.add(const Duration(days: 6));
    final selectedStats = _statsForDay(
      days,
      selectedDay,
      days.isEmpty ? 0 : days.first.normalHabitTotal,
    );
    return Column(
      children: [
        _DateSwitcher(
          title:
              '${DateFormat('M月d日').format(start)} - ${DateFormat('M月d日').format(end)}',
          subtitle: '${start.year}年第${_weekNumber(start)}周',
          onPrevious: onPreviousWeek,
          onNext: onNextWeek,
        ),
        const SizedBox(height: 14),
        _WeekCalendarCard(
          days: days,
          selectedDay: selectedDay,
          onSelectDay: onSelectDay,
        ),
        const SizedBox(height: 16),
        _RangeHighlightsCard(
          title: '本周亮点',
          stats: ViewRangeStats(days: days),
          periodLabel: '本周',
        ),
        const SizedBox(height: 16),
        _TimelineCard(
          title: '选中日期详情',
          dateLabel: _monthDayWeekdayLabel(selectedStats.day),
          events: selectedStats.timelineEvents,
          emptyTitle: '这天没有完成记录',
        ),
      ],
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.selectedDay,
    required this.days,
    required this.onSelectDay,
    required this.onShowDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime selectedDay;
  final List<ViewDayStats> days;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onShowDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final monthStart = startOfMonth(selectedDay);
    final selectedStats = _statsForDay(
      days,
      selectedDay,
      days.isEmpty ? 0 : days.first.normalHabitTotal,
    );
    final rangeStats = ViewRangeStats(days: days);
    return Column(
      children: [
        _DateSwitcher(
          title: DateFormat('yyyy年M月').format(monthStart),
          subtitle: '月度节奏回看',
          onPrevious: onPreviousMonth,
          onNext: onNextMonth,
        ),
        const SizedBox(height: 14),
        _MonthCalendarCard(
          monthStart: monthStart,
          days: days,
          selectedDay: selectedDay,
          onSelectDay: onSelectDay,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  _TimelineCard(
                    title: '选中日期详情',
                    dateLabel: _monthDayWeekdayLabel(selectedStats.day),
                    events: selectedStats.timelineEvents,
                    emptyTitle: '这天还没有完成记录',
                    action: _SmallTextButton(label: '日视图', onTap: onShowDay),
                  ),
                  const SizedBox(height: 16),
                  _RangeHighlightsCard(
                    title: '本月亮点',
                    stats: rangeStats,
                    periodLabel: '本月',
                    compactPet: true,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TimelineCard(
                    title: '选中日期详情',
                    dateLabel: _monthDayWeekdayLabel(selectedStats.day),
                    events: selectedStats.timelineEvents,
                    emptyTitle: '这天还没有完成记录',
                    action: _SmallTextButton(label: '日视图', onTap: onShowDay),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RangeHighlightsCard(
                    title: '本月亮点',
                    stats: rangeStats,
                    periodLabel: '本月',
                    compactPet: true,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _MonthSummaryCard(stats: rangeStats),
      ],
    );
  }
}

class _DateSwitcher extends StatelessWidget {
  const _DateSwitcher({
    required this.title,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _GlassIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPrevious,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                ).copyWith(
                  color: isDark ? Colors.white.withValues(alpha: 0.92) : _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.56)
                      : _mutedInk.withValues(alpha: 0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
        const SizedBox(width: 8),
        _GlassIconButton(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark
                ? colors.surfaceContainerHigh.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE1E9E5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.045),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isDark ? colors.onSurface.withValues(alpha: 0.90) : _ink,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _SmallTextButton extends StatelessWidget {
  const _SmallTextButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _activeGreen.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _activeGreen.withValues(alpha: 0.16)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _activeGreen,
              fontFamily: 'LXGWWenKaiScreen',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyDonutSummaryCard extends StatelessWidget {
  const _DailyDonutSummaryCard({required this.stats});

  final ViewDayStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final segments = _donutSegments(stats);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colors.surface.withValues(alpha: 0.94),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.050),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFC7D4E8).withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ringSize =
              math.max(226.0, math.min(258.0, constraints.maxWidth - 34));
          return Column(
            children: [
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DonutPainter(
                          segments: segments,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    Container(
                      width: ringSize * 0.47,
                      height: ringSize * 0.47,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.98),
                            isDark
                                ? colors.surfaceContainerHighest
                                    .withValues(alpha: 0.92)
                                : const Color(0xFFF8FAFF)
                                    .withValues(alpha: 0.92),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.10 : 0.92,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? colors.primary.withValues(alpha: 0.10)
                                : const Color(0xFFB6C3E5)
                                    .withValues(alpha: 0.16),
                            blurRadius: isDark ? 10 : 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                    PetImage(
                      mood: stats.completionRate >= 0.75
                          ? PetMood.happy
                          : PetMood.normal,
                      size: ringSize * 0.42,
                    ),
                    _DonutRingAnnotations(
                      segments: segments,
                      size: ringSize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DonutLegendBar(segments: segments),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.title,
    required this.events,
    required this.emptyTitle,
    this.dateLabel,
    this.action,
  });

  final String title;
  final String? dateLabel;
  final List<CompletionEvent> events;
  final String emptyTitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: _planColor,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      shadowAlpha: 0.060,
      shadowBlur: 24,
      shadowOffset: const Offset(0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded,
                  color: _activeGreen, size: 24),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _activeGreen,
                    fontFamily: 'LXGWWenKaiScreen',
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
              if (dateLabel != null)
                Flexible(
                  child: Text(
                    dateLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _activeGreen,
                      fontFamily: 'LXGWWenKaiScreen',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (action != null) ...[
                const SizedBox(width: 8),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            EmptyState(icon: Icons.timeline_outlined, title: emptyTitle)
          else
            Column(
              children: [
                for (var i = 0; i < events.length; i++)
                  _TimelineEntryRow(
                    event: events[i],
                    isFirst: i == 0,
                    isLast: i == events.length - 1,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineEntryRow extends StatelessWidget {
  const _TimelineEntryRow({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final CompletionEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.targetType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 51,
      child: Row(
        children: [
          SizedBox(
            width: 66,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 8,
                  top: isFirst ? 26 : -1,
                  bottom: isLast ? 26 : -1,
                  child: Container(
                    width: 2.2,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  top: 20,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.92),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.20),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 26,
                  top: 5,
                  child: _EventGlassIcon(type: event.targetType, size: 40),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 43,
              padding: const EdgeInsets.fromLTRB(11, 0, 8, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark
                        ? colors.surfaceContainerHigh.withValues(alpha: 0.82)
                        : Colors.white.withValues(alpha: 0.95),
                    isDark
                        ? colors.surfaceContainerHighest.withValues(alpha: 0.70)
                        : Colors.white.withValues(alpha: 0.78),
                    color.withValues(alpha: isDark ? 0.10 : 0.035),
                  ],
                  stops: const [0.0, 0.62, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.82),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.75),
                    blurRadius: 7,
                    offset: const Offset(-1.6, -2.2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      DateFormat('HH:mm').format(event.completedAt),
                      maxLines: 1,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'LXGWWenKaiScreen',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      event.targetTitleSnapshot,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontFamily: 'LXGWWenKaiScreen',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  _EventPill(type: event.targetType),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventGlassIcon extends StatelessWidget {
  const _EventGlassIcon({required this.type, this.size = 46});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.88),
                    blurRadius: 7,
                    offset: const Offset(-2, -3),
                  ),
              ],
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark
                        ? colors.surfaceContainerHighest.withValues(alpha: 0.96)
                        : Colors.white.withValues(alpha: 0.98),
                    color.withValues(alpha: isDark ? 0.18 : 0.12),
                    isDark
                        ? colors.surface.withValues(alpha: 0.90)
                        : Colors.white.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.56, 1.0],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.92),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            left: size * 0.15,
            top: size * 0.10,
            right: size * 0.27,
            height: size * 0.18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: size * 0.13,
            bottom: size * 0.12,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.10),
              ),
            ),
          ),
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.28, -0.28),
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.78),
                  color.withValues(alpha: isDark ? 0.26 : 0.20),
                ],
              ),
            ),
            child: Icon(_eventIcon(type), color: color, size: size * 0.38),
          ),
        ],
      ),
    );
  }
}

class _EventPill extends StatelessWidget {
  const _EventPill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? colors.surfaceContainerHighest.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.90),
            color.withValues(alpha: isDark ? 0.18 : 0.12),
          ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.04 : 0.08),
            blurRadius: isDark ? 5 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_eventIcon(type), color: color, size: 13),
          const SizedBox(width: 3),
          Text(
            _eventLabel(type),
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontFamily: 'LXGWWenKaiScreen',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepSummaryCard extends StatelessWidget {
  const _SleepSummaryCard({required this.summary});

  final ViewSleepSummary summary;

  @override
  Widget build(BuildContext context) {
    const designWidth = 760.0;
    const designHeight = 168.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth * designHeight / designWidth;
        return SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark
                          ? colors.surfaceContainerHighest
                              .withValues(alpha: 0.96)
                          : Colors.white.withValues(alpha: 0.92),
                      isDark
                          ? const Color(0xFF2A2437).withValues(alpha: 0.94)
                          : const Color(0xFFF9F7FF).withValues(alpha: 0.88),
                      isDark
                          ? const Color(0xFF201A2C).withValues(alpha: 0.96)
                          : const Color(0xFFF5F1FF).withValues(alpha: 0.80),
                    ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE3DDF4).withValues(alpha: 0.72),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _sleepColor.withValues(alpha: 0.070),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    if (!isDark)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.72),
                        blurRadius: 8,
                        offset: const Offset(-2, -3),
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      left: 24,
                      top: 20,
                      width: 164,
                      height: 124,
                      child: CustomPaint(painter: _SleepArtPainter()),
                    ),
                    Positioned(
                      left: 218,
                      top: 34,
                      width: 250,
                      child: _SleepMainText(summary: summary),
                    ),
                    Positioned(
                      right: 24,
                      top: 20,
                      width: 242,
                      height: 128,
                      child: _SleepQualityPanel(summary: summary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SleepMainText extends StatelessWidget {
  const _SleepMainText({required this.summary});

  final ViewSleepSummary summary;

  @override
  Widget build(BuildContext context) {
    final duration = summary.duration;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white.withValues(alpha: 0.92) : _ink;
    final secondaryText = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : _ink.withValues(alpha: 0.84);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '睡眠总结',
          style: TextStyle(
            color: _sleepColor,
            fontFamily: 'LXGWWenKaiScreen',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        if (duration == null)
          Text(
            '记录不完整',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryText,
              fontFamily: 'LXGWWenKaiScreen',
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              height: 1.0,
            ),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${duration.inHours}'),
                  const TextSpan(
                    text: ' h ',
                    style: TextStyle(fontSize: 26),
                  ),
                  TextSpan(text: '${duration.inMinutes.remainder(60)}'),
                  const TextSpan(
                    text: ' m',
                    style: TextStyle(fontSize: 26),
                  ),
                ],
              ),
              maxLines: 1,
              style: TextStyle(
                color: primaryText,
                fontFamily: 'LXGWWenKaiScreen',
                fontSize: 47,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                height: 1.0,
              ),
            ),
          ),
        const SizedBox(height: 13),
        Text(
          _sleepRangeText(summary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: secondaryText,
            fontFamily: 'LXGWWenKaiScreen',
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _SleepQualityPanel extends StatelessWidget {
  const _SleepQualityPanel({required this.summary});

  final ViewSleepSummary summary;

  @override
  Widget build(BuildContext context) {
    final label = !summary.isComplete
        ? '待补全'
        : summary.isAbnormal
            ? '需调整'
            : '良好';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? colors.surface.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.94),
            isDark
                ? colors.surfaceContainerHighest.withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.74),
            isDark
                ? const Color(0xFF2B223B).withValues(alpha: 0.82)
                : const Color(0xFFF1ECFF).withValues(alpha: 0.54),
          ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.78),
        ),
        boxShadow: [
          BoxShadow(
            color: _sleepColor.withValues(alpha: 0.090),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.68),
              blurRadius: 8,
              offset: const Offset(-2, -3),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _EventGlassIcon(type: targetSleep, size: 54),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '质量',
                      maxLines: 1,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.82)
                            : _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: summary.isAbnormal ? _dangerColor : _sleepColor,
                        fontFamily: 'LXGWWenKaiScreen',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          _StarRating(value: summary.qualityStars),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                i < value ? Icons.star_rounded : Icons.star_border_rounded,
                color: i < value
                    ? _sleepColor
                    : _sleepColor.withValues(alpha: 0.45),
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}

class _SleepArtPainter extends CustomPainter {
  const _SleepArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bounds = Offset.zero & size;

    final moon = Path()
      ..moveTo(w * 0.47, h * 0.08)
      ..cubicTo(w * 0.29, h * 0.11, w * 0.17, h * 0.27, w * 0.17, h * 0.46)
      ..cubicTo(w * 0.17, h * 0.68, w * 0.34, h * 0.83, w * 0.55, h * 0.78)
      ..cubicTo(w * 0.42, h * 0.70, w * 0.36, h * 0.56, w * 0.40, h * 0.41)
      ..cubicTo(w * 0.44, h * 0.27, w * 0.55, h * 0.17, w * 0.70, h * 0.17)
      ..cubicTo(w * 0.64, h * 0.12, w * 0.56, h * 0.09, w * 0.47, h * 0.08)
      ..close();

    canvas.drawPath(
      moon.shift(Offset(0, h * 0.035)),
      Paint()
        ..color = _sleepColor.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      moon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8DEFF).withValues(alpha: 0.98),
            const Color(0xFFC8B2F6).withValues(alpha: 0.94),
            const Color(0xFF9D78DD).withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(bounds),
    );
    canvas.drawPath(
      moon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF9A7CE3).withValues(alpha: 0.42),
    );
    canvas.drawPath(
      moon.shift(Offset(-w * 0.018, -h * 0.018)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.46),
    );

    final cloud = Path()
      ..moveTo(w * 0.07, h * 0.78)
      ..cubicTo(w * 0.05, h * 0.66, w * 0.18, h * 0.58, w * 0.29, h * 0.63)
      ..cubicTo(w * 0.32, h * 0.49, w * 0.50, h * 0.47, w * 0.58, h * 0.60)
      ..cubicTo(w * 0.64, h * 0.54, w * 0.76, h * 0.56, w * 0.79, h * 0.68)
      ..cubicTo(w * 0.91, h * 0.68, w * 0.95, h * 0.84, w * 0.82, h * 0.87)
      ..lineTo(w * 0.15, h * 0.87)
      ..cubicTo(w * 0.09, h * 0.87, w * 0.06, h * 0.83, w * 0.07, h * 0.78)
      ..close();

    canvas.drawPath(
      cloud.shift(Offset(0, h * 0.035)),
      Paint()
        ..color = _sleepColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      cloud,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            const Color(0xFFF2EDFF).withValues(alpha: 0.96),
            const Color(0xFFE0D6FA).withValues(alpha: 0.90),
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      cloud,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFA78DE6).withValues(alpha: 0.38),
    );
    canvas.drawLine(
      Offset(w * 0.08, h * 0.87),
      Offset(w * 0.88, h * 0.87),
      Paint()
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB8A1EC).withValues(alpha: 0.36),
    );

    _drawSparkle(canvas, Offset(w * 0.08, h * 0.38), 6.4);
    _drawSparkle(canvas, Offset(w * 0.80, h * 0.11), 6.0);
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.38), 6.2);
    _drawSparkle(canvas, Offset(w * 0.69, h * 0.29), 4.4);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFA68BE7).withValues(alpha: 0.76);
    canvas.drawLine(
        center.translate(-radius, 0), center.translate(radius, 0), paint);
    canvas.drawLine(
        center.translate(0, -radius), center.translate(0, radius), paint);
    canvas.drawCircle(
      center,
      1.5,
      Paint()..color = const Color(0xFFBBA6F0).withValues(alpha: 0.56),
    );
  }

  @override
  bool shouldRepaint(covariant _SleepArtPainter oldDelegate) => false;
}

class _WeekCalendarCard extends StatelessWidget {
  const _WeekCalendarCard({
    required this.days,
    required this.selectedDay,
    required this.onSelectDay,
  });

  final List<ViewDayStats> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      radius: 24,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final day in days)
              _WeekDayColumn(
                stats: day,
                selected: day.day == dateOnly(selectedDay),
                onTap: () => onSelectDay(day.day),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.stats,
    required this.selected,
    required this.onTap,
  });

  final ViewDayStats stats;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coreEvents = stats.timelineEvents
        .where((event) =>
            event.targetType != targetWakeUp && event.targetType != targetSleep)
        .take(6)
        .toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 112,
        height: 412,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        decoration: BoxDecoration(
          color: selected
              ? _activeGreen.withValues(alpha: 0.075)
              : isDark
                  ? const Color(0xFF1D2320).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _activeGreen.withValues(alpha: 0.72)
                : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2EAE7),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              _weekdayLabel(stats.day),
              style: TextStyle(
                color: selected
                    ? _activeGreen
                    : isDark
                        ? Colors.white.withValues(alpha: 0.86)
                        : _ink,
                fontFamily: 'LXGWWenKaiScreen',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${stats.day.day}',
              style: TextStyle(
                color: selected
                    ? _activeGreen
                    : isDark
                        ? Colors.white.withValues(alpha: 0.90)
                        : _ink,
                fontFamily: 'LXGWWenKaiScreen',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFDDE6E4).withValues(alpha: 0.78),
            ),
            _WeekSleepTime(type: targetWakeUp, stats: stats),
            const SizedBox(height: 9),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  for (final event in coreEvents) _WeekEventChip(event: event),
                  if (coreEvents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        '无记录',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.36)
                              : _mutedInk.withValues(alpha: 0.52),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _WeekSleepTime(type: targetSleep, stats: stats),
          ],
        ),
      ),
    );
  }
}

class _WeekSleepTime extends StatelessWidget {
  const _WeekSleepTime({required this.type, required this.stats});

  final String type;
  final ViewDayStats stats;

  @override
  Widget build(BuildContext context) {
    final summary = stats.sleepSummary;
    final time = type == targetWakeUp ? summary.wakeAt : summary.sleepAt;
    final color = _eventColor(type);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_eventIcon(type), size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          time == null ? '--' : DateFormat('HH:mm').format(time),
          maxLines: 1,
          style: TextStyle(
            color: time == null ? _mutedInk.withValues(alpha: 0.52) : color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WeekEventChip extends StatelessWidget {
  const _WeekEventChip({required this.event});

  final CompletionEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.targetType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.075),
        borderRadius: BorderRadius.circular(11),
        border:
            Border.all(color: color.withValues(alpha: isDark ? 0.18 : 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_eventIcon(event.targetType), color: color, size: 14),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              event.targetTitleSnapshot,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.82)
                    : _ink.withValues(alpha: 0.90),
                fontFamily: 'LXGWWenKaiScreen',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeHighlightsCard extends StatelessWidget {
  const _RangeHighlightsCard({
    required this.title,
    required this.stats,
    required this.periodLabel,
    this.compactPet = false,
  });

  final String title;
  final ViewRangeStats stats;
  final String periodLabel;
  final bool compactPet;

  @override
  Widget build(BuildContext context) {
    if (!compactPet) {
      return _WeekHighlightsReferenceCard(
        title: title,
        stats: stats,
      );
    }

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!compactPet) ...[
            PetImage(
              mood:
                  stats.completionRate >= 0.75 ? PetMood.happy : PetMood.normal,
              size: 112,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: _activeGreen, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _activeGreen,
                          fontFamily: 'LXGWWenKaiScreen',
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricTile(
                      icon: Icons.donut_large_rounded,
                      label: '完成率',
                      value: _percent(stats.completionRate),
                      color: _planColor,
                    ),
                    _MetricTile(
                      icon: Icons.check_circle_rounded,
                      label: '计划完成',
                      value: '${stats.planDone}/${stats.planTotal}',
                      color: _planColor,
                    ),
                    _MetricTile(
                      icon: Icons.bookmark_rounded,
                      label: '备忘完成',
                      value: stats.memoTotal == 0
                          ? '${stats.memoDone}'
                          : '${stats.memoDone}/${stats.memoTotal}',
                      color: _memoColor,
                    ),
                    _MetricTile(
                      icon: Icons.local_florist_rounded,
                      label: '习惯连续',
                      value: '${stats.habitStreak}天',
                      color: _habitColor,
                    ),
                    _MetricTile(
                      icon: Icons.nightlight_round,
                      label: '平均睡眠',
                      value: _durationLabel(stats.averageSleep),
                      color: _sleepColor,
                      wide: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHighlightsReferenceCard extends StatelessWidget {
  const _WeekHighlightsReferenceCard({
    required this.title,
    required this.stats,
  });

  final String title;
  final ViewRangeStats stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      shadowAlpha: 0.060,
      shadowBlur: 24,
      shadowOffset: const Offset(0, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final petWidth = compact ? 76.0 : 150.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: petWidth,
                height: compact ? 126 : 158,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: petWidth,
                      height: petWidth,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.25, -0.30),
                          colors: [
                            isDark
                                ? colors.surfaceContainerHighest
                                    .withValues(alpha: 0.96)
                                : Colors.white.withValues(alpha: 0.92),
                            isDark
                                ? const Color(0xFF252B31)
                                    .withValues(alpha: 0.88)
                                : const Color(0xFFF3F2FF)
                                    .withValues(alpha: 0.78),
                            _activeGreen.withValues(
                                alpha: isDark ? 0.08 : 0.045),
                          ],
                        ),
                      ),
                    ),
                    PetImage(
                      mood: stats.completionRate >= 0.75
                          ? PetMood.happy
                          : PetMood.normal,
                      size: petWidth * 0.96,
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 10 : 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reviews_rounded,
                            color: _activeGreen, size: compact ? 20 : 24),
                        SizedBox(width: compact ? 6 : 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _activeGreen,
                              fontFamily: 'LXGWWenKaiScreen',
                              fontSize: compact ? 19 : 23,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HighlightTile(
                            icon: Icons.donut_large_rounded,
                            label: '完成率',
                            value: _percent(stats.completionRate),
                            color: _planColor,
                            compact: compact,
                          ),
                        ),
                        SizedBox(width: compact ? 7 : 10),
                        Expanded(
                          child: _HighlightTile(
                            icon: Icons.check_circle_rounded,
                            label: '计划完成',
                            value: '${stats.planDone}/${stats.planTotal}',
                            color: _planColor,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 7 : 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HighlightTile(
                            icon: Icons.bookmark_rounded,
                            label: '备忘完成',
                            value: stats.memoTotal == 0
                                ? '${stats.memoDone}'
                                : '${stats.memoDone}/${stats.memoTotal}',
                            color: _memoColor,
                            compact: compact,
                          ),
                        ),
                        SizedBox(width: compact ? 7 : 10),
                        Expanded(
                          child: _HighlightTile(
                            icon: Icons.local_florist_rounded,
                            label: '习惯连续',
                            value: '${stats.habitStreak}天',
                            color: _habitColor,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 7 : 10),
                    _AverageSleepStrip(
                      value: _durationLabel(stats.averageSleep),
                      compact: compact,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: compact ? 54 : 64,
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        compact ? 8 : 10,
        compact ? 8 : 11,
        compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: isDark
            ? const Color(0xFF232926).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.86),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE4EAE7).withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9FAAA4).withValues(alpha: 0.075),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.62),
              blurRadius: 7,
              offset: const Offset(-2, -3),
            ),
        ],
      ),
      child: Row(
        children: [
          _SoftIcon(icon: icon, color: color, size: compact ? 26 : 36),
          SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.52)
                            : _mutedInk.withValues(alpha: 0.84),
                        fontFamily: 'LXGWWenKaiScreen',
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : 5),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'LXGWWenKaiScreen',
                        fontSize: compact ? 17 : 22,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AverageSleepStrip extends StatelessWidget {
  const _AverageSleepStrip({
    required this.value,
    required this.compact,
  });

  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: compact ? 48 : 54,
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        8,
        compact ? 9 : 12,
        8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: isDark
            ? const Color(0xFF232926).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.86),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE4EAE7).withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9FAAA4).withValues(alpha: 0.070),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _SoftIcon(
              icon: Icons.nightlight_round,
              color: _sleepColor,
              size: compact ? 26 : 34),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '平均睡眠',
                maxLines: 1,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.52)
                      : _mutedInk.withValues(alpha: 0.84),
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Flexible(
            flex: 0,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.86) : _ink,
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: compact ? 17 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Icon(Icons.auto_awesome_rounded,
                color: _sleepColor.withValues(alpha: 0.58), size: 15),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: wide ? 202 : 136,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF232926).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE6ECE9),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.070),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _SoftIcon(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.50)
                        : _mutedInk.withValues(alpha: 0.82),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'LXGWWenKaiScreen',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({
    required this.icon,
    required this.color,
    this.size = 38,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.58),
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.monthStart,
    required this.days,
    required this.selectedDay,
    required this.onSelectDay,
  });

  final DateTime monthStart;
  final List<ViewDayStats> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1);
    final leadingBlank = monthStart.weekday % 7;
    final totalCells = leadingBlank + monthEnd.difference(monthStart).inDays;
    final rows = (totalCells / 7).ceil();
    final normalHabitTotal = days.isEmpty ? 0 : days.first.normalHabitTotal;

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: Column(
        children: [
          const Row(
            children: [
              _WeekLabel('日'),
              _WeekLabel('一'),
              _WeekLabel('二'),
              _WeekLabel('三'),
              _WeekLabel('四'),
              _WeekLabel('五'),
              _WeekLabel('六'),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var column = 0; column < 7; column++)
                  _monthCellFor(
                    row: row,
                    column: column,
                    leadingBlank: leadingBlank,
                    monthStart: monthStart,
                    monthEnd: monthEnd,
                    normalHabitTotal: normalHabitTotal,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _monthCellFor({
    required int row,
    required int column,
    required int leadingBlank,
    required DateTime monthStart,
    required DateTime monthEnd,
    required int normalHabitTotal,
  }) {
    final cellIndex = row * 7 + column;
    final dayOffset = cellIndex - leadingBlank;
    if (dayOffset < 0 || dayOffset >= monthEnd.difference(monthStart).inDays) {
      return const Expanded(child: SizedBox(height: 96));
    }
    final day = monthStart.add(Duration(days: dayOffset));
    return _MonthCell(
      stats: _statsForDay(days, day, normalHabitTotal),
      selected: day == dateOnly(selectedDay),
      onTap: () => onSelectDay(day),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.48)
                : _mutedInk.withValues(alpha: 0.84),
            fontFamily: 'LXGWWenKaiScreen',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.stats,
    required this.selected,
    required this.onTap,
  });

  final ViewDayStats stats;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final abnormalSleep =
        stats.sleepSummary.hasAnyRecord && stats.sleepSummary.isAbnormal;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 96,
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
            decoration: BoxDecoration(
              color: selected
                  ? _activeGreen.withValues(alpha: 0.085)
                  : isDark
                      ? const Color(0xFF1D2320).withValues(alpha: 0.96)
                      : Colors.white.withValues(alpha: 0.44),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? _activeGreen.withValues(alpha: 0.62)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE3EAE8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${stats.day.day}',
                      style: TextStyle(
                        color: selected
                            ? _activeGreen
                            : isDark
                                ? Colors.white.withValues(alpha: 0.82)
                                : _ink,
                        fontFamily: 'LXGWWenKaiScreen',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (abnormalSleep)
                      const _SleepWarningIcon()
                    else
                      const SizedBox(width: 14, height: 14),
                  ],
                ),
                const Spacer(),
                Center(
                  child: _MiniPlanRing(ratio: stats.planRatio),
                ),
                const SizedBox(height: 2),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _percent(stats.planRatio),
                      maxLines: 1,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.72)
                            : _ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: double.infinity,
                  height: 12,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (stats.memoDone > 0) ...[
                          const Icon(Icons.bookmark_rounded,
                              color: _memoColor, size: 12),
                          const SizedBox(width: 1.5),
                          Text(
                            '${stats.memoDone}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : _ink,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        _HabitBoxes(
                            done: stats.habitDone, total: stats.safeHabitTotal),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlanRing extends StatelessWidget {
  const _MiniPlanRing({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _MiniRingPainter(ratio: ratio),
        child: const Center(
          child:
              Icon(Icons.event_available_rounded, color: _planColor, size: 11),
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  const _MiniRingPainter({required this.ratio});

  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 2.8;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = _planColor.withValues(alpha: 0.16),
    );
    if (ratio <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * ratio.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = _planColor,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) =>
      oldDelegate.ratio != ratio;
}

class _HabitBoxes extends StatelessWidget {
  const _HabitBoxes({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final visibleTotal = math.max(1, math.min(total == 0 ? 2 : total, 5));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visibleTotal; i++)
          Container(
            width: 7,
            height: 7,
            margin: EdgeInsets.only(right: i == visibleTotal - 1 ? 0 : 1.5),
            decoration: BoxDecoration(
              color: i < done ? _planColor : Colors.transparent,
              borderRadius: BorderRadius.circular(1.8),
              border: Border.all(
                color: i < done
                    ? _planColor
                    : const Color(0xFFBFC9C5).withValues(alpha: 0.82),
                width: 0.9,
              ),
            ),
            child: i < done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 5)
                : null,
          ),
      ],
    );
  }
}

class _SleepWarningIcon extends StatelessWidget {
  const _SleepWarningIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            top: 1,
            child: Icon(Icons.nightlight_round, color: _dangerColor, size: 13),
          ),
          Positioned(
            right: -1,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _dangerColor,
              ),
              child: const Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.stats});

  final ViewRangeStats stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          PetImage(
            mood: stats.completionRate >= 0.75 ? PetMood.happy : PetMood.normal,
            size: 92,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.completionRate >= 0.75 ? '这个月节奏很稳' : '这个月还有调整空间',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _activeGreen,
                    fontFamily: 'LXGWWenKaiScreen',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '月完成率 ${_percent(stats.completionRate)}，异常睡眠 ${stats.abnormalSleepDays} 天。',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.58)
                        : _ink.withValues(alpha: 0.76),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniSummaryPill(
                      icon: Icons.donut_large_rounded,
                      label: _percent(stats.completionRate),
                      color: _planColor,
                    ),
                    _MiniSummaryPill(
                      icon: Icons.bookmark_rounded,
                      label: '${stats.memoDone} DDL',
                      color: _memoColor,
                    ),
                    _MiniSummaryPill(
                      icon: Icons.local_florist_rounded,
                      label: '${stats.habitDone}/${stats.habitTotal}',
                      color: _habitColor,
                    ),
                    _MiniSummaryPill(
                      icon: Icons.nightlight_round,
                      label: '${stats.abnormalSleepDays} 天',
                      color: _dangerColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryPill extends StatelessWidget {
  const _MiniSummaryPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontFamily: 'LXGWWenKaiScreen',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutSegment {
  const _DonutSegment({
    required this.label,
    required this.count,
    required this.share,
    required this.percent,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final int count;
  final double share;
  final int percent;
  final Color color;
  final Color textColor;
  final IconData icon;
}

double get _donutStartAngle => math.pi * 0.92;

List<_DonutSegment> _donutSegments(ViewDayStats stats) {
  final counts = <int>[stats.planDone, stats.memoDone, stats.habitDone];
  final total = counts.fold<int>(0, (sum, value) => sum + value);
  final percents = balancedPercents(counts);
  double shareFor(int index) => total == 0 ? 0 : counts[index] / total;

  return [
    _DonutSegment(
      label: '计划',
      count: counts[0],
      share: shareFor(0),
      percent: percents[0],
      color: const Color(0xFF7ED79A),
      textColor: const Color(0xFF2F8A5D),
      icon: Icons.check_box_rounded,
    ),
    _DonutSegment(
      label: '备忘',
      count: counts[1],
      share: shareFor(1),
      percent: percents[1],
      color: const Color(0xFFAFC9F8),
      textColor: const Color(0xFF3F75BD),
      icon: Icons.bookmark_border_rounded,
    ),
    _DonutSegment(
      label: '习惯',
      count: counts[2],
      share: shareFor(2),
      percent: percents[2],
      color: const Color(0xFFA98DE8),
      textColor: const Color(0xFF7554C8),
      icon: Icons.local_florist_rounded,
    ),
  ];
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.isDark,
  });

  final List<_DonutSegment> segments;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.22;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = isDark
          ? const Color(0xFF232A31).withValues(alpha: 0.96)
          : const Color(0xFFF4F6FA).withValues(alpha: 0.86);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.96
      ..strokeCap = StrokeCap.butt
      ..color = isDark
          ? const Color(0xFF5C7B92).withValues(alpha: 0.05)
          : const Color(0xFFB7C4DF).withValues(alpha: 0.09)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        isDark ? 10 : 14,
      );
    canvas.drawCircle(center.translate(0, 5), radius, glow);
    canvas.drawCircle(center, radius, background);

    if (segments.every((segment) => segment.count == 0)) {
      _drawGlassRims(canvas, center, radius, stroke);
      return;
    }

    const gap = 0.022;
    var start = _donutStartAngle;
    for (final segment in segments) {
      if (segment.share <= 0) continue;
      final sweep = segment.share * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + sweep,
          colors: [
            segment.color.withValues(alpha: 0.50),
            segment.color.withValues(alpha: 0.70),
            segment.color.withValues(alpha: 0.46),
          ],
          stops: const [0.0, 0.54, 1.0],
        ).createShader(rect);
      canvas.drawArc(
        arcRect,
        start + gap,
        math.max(0, sweep - gap * 2),
        false,
        paint,
      );
      start += sweep;
    }

    _drawGlassRims(canvas, center, radius, stroke);
  }

  void _drawGlassRims(
    Canvas canvas,
    Offset center,
    double radius,
    double stroke,
  ) {
    final outerRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.84);
    final innerRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = isDark
          ? const Color(0xFF4E5962).withValues(alpha: 0.72)
          : const Color(0xFFD8E1EC).withValues(alpha: 0.68);
    canvas.drawCircle(center, radius + stroke / 2, outerRim);
    canvas.drawCircle(center, radius - stroke / 2, innerRim);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.isDark != isDark;
}

class _DonutRingAnnotations extends StatelessWidget {
  const _DonutRingAnnotations({
    required this.segments,
    required this.size,
  });

  final List<_DonutSegment> segments;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (segments.every((segment) => segment.share <= 0)) {
      return const SizedBox.shrink();
    }

    final stroke = size * 0.22;
    final ringRadius = (size - stroke) / 2;
    final center = Offset(size / 2, size / 2);
    var start = _donutStartAngle;
    final labels = <Widget>[];

    for (final segment in segments) {
      if (segment.share <= 0) continue;

      final sweep = segment.share * math.pi * 2;
      final midAngle = start + sweep / 2;
      final boxWidth = _annotationWidthFor(segment.share, size);
      final boxHeight = segment.share < 0.14 ? 30.0 : 48.0;
      final point = Offset(
        center.dx + math.cos(midAngle) * ringRadius,
        center.dy + math.sin(midAngle) * ringRadius,
      );
      final left =
          (point.dx - boxWidth / 2).clamp(6.0, size - boxWidth - 6).toDouble();
      final top = (point.dy - boxHeight / 2)
          .clamp(6.0, size - boxHeight - 6)
          .toDouble();

      labels.add(
        Positioned(
          left: left,
          top: top,
          width: boxWidth,
          height: boxHeight,
          child: _RingSegmentLabel(
            segment: segment,
            compact: segment.share < 0.14,
          ),
        ),
      );

      start += sweep;
    }

    return Positioned.fill(
      child: Stack(children: labels),
    );
  }
}

double _annotationWidthFor(double share, double size) {
  if (share < 0.14) return size * 0.18;
  if (share < 0.22) return size * 0.22;
  return size * 0.26;
}

class _RingSegmentLabel extends StatelessWidget {
  const _RingSegmentLabel({
    required this.segment,
    required this.compact,
  });

  final _DonutSegment segment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelColor = _ink.withValues(alpha: 0.92);
    final percentStyle = TextStyle(
      color: segment.textColor.withValues(alpha: 0.90),
      fontFamily: 'LXGWWenKaiScreen',
      fontSize: compact ? 12 : 15,
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    if (compact) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${segment.percent}%',
          maxLines: 1,
          style: percentStyle,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                segment.icon,
                color: segment.color.withValues(alpha: 0.94),
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                segment.label,
                maxLines: 1,
                style: TextStyle(
                  color: labelColor,
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${segment.percent}%', maxLines: 1, style: percentStyle),
        ],
      ),
    );
  }
}

class _DonutLegendBar extends StatelessWidget {
  const _DonutLegendBar({required this.segments});

  final List<_DonutSegment> segments;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.46),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(child: _DonutLegendItem(segment: segment)),
        ],
      ),
    );
  }
}

class _DonutLegendItem extends StatelessWidget {
  const _DonutLegendItem({required this.segment});

  final _DonutSegment segment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    segment.color.withValues(alpha: 0.78),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: segment.color.withValues(alpha: 0.22),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${segment.percent}%',
          style: const TextStyle(
            color: Color(0xFF33475B),
            fontFamily: 'LXGWWenKaiScreen',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

Color _eventColor(String type) {
  return switch (type) {
    targetPlan => _planColor,
    targetMemo => _memoColor,
    targetHabit => _habitColor,
    targetWakeUp => _wakeColor,
    targetSleep => _sleepColor,
    _ => const Color(0xFF6B7A86),
  };
}

IconData _eventIcon(String type) {
  return switch (type) {
    targetPlan => Icons.check_circle_outline_rounded,
    targetMemo => Icons.menu_book_rounded,
    targetHabit => Icons.local_florist_rounded,
    targetWakeUp => Icons.wb_sunny_outlined,
    targetSleep => Icons.nightlight_round,
    _ => Icons.circle_outlined,
  };
}

String _eventLabel(String type) {
  return switch (type) {
    targetPlan => '计划',
    targetMemo => '备忘',
    targetHabit => '习惯',
    targetWakeUp => '习惯',
    targetSleep => '睡眠',
    _ => '记录',
  };
}

String _weekdayLabel(DateTime day) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[day.weekday - 1];
}

String _monthDayWeekdayLabel(DateTime day) {
  return '${DateFormat('M月d日').format(day)} 周${_weekdayLabel(day)}';
}

String _dayTitle(DateTime day) {
  final today = dateOnly(DateTime.now());
  final target = dateOnly(day);
  if (target == today) return '今天';
  if (target == today.subtract(const Duration(days: 1))) return '昨天';
  if (target == today.add(const Duration(days: 1))) return '明天';
  return DateFormat('M月d日').format(day);
}

String _percent(double value) => '${(value * 100).round()}%';

String _durationLabel(Duration? duration) {
  if (duration == null) return '--';
  return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
}

String _sleepRangeText(ViewSleepSummary summary) {
  if (!summary.isComplete) return '需要早起和早睡记录';
  return '${DateFormat('HH:mm').format(summary.sleepAt!)}  ->  ${DateFormat('HH:mm').format(summary.wakeAt!)}';
}

int _weekNumber(DateTime day) {
  final first = DateTime(day.year);
  return ((day.difference(first).inDays + first.weekday) / 7).ceil();
}
