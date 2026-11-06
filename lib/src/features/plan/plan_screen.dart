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
import '../../shared/liquid_progress_bar.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final todayPlans =
        ref.watch(planTasksProvider(today)).valueOrNull ?? const <PlanTask>[];
    final todayHabits = ref.watch(habitEntriesProvider(today)).valueOrNull ??
        const <HabitEntry>[];
    final memos =
        ref.watch(memoTasksProvider).valueOrNull ?? const <MemoTask>[];
    final planRatio = completionRatio(
        todayPlans.where((task) => task.isDone).length, todayPlans.length);
    final normalHabits = todayHabits
        .where((entry) => entry.template.type == habitTypeNormal)
        .toList();
    final habitRatio = completionRatio(
        normalHabits.where((entry) => entry.isDone).length,
        normalHabits.length);
    final activeMemos = memos.where((memo) {
      final daysLeft = dateOnly(memo.dueDate).difference(today).inDays;
      return daysLeft <= 7;
    }).toList();
    final memoRatio = completionRatio(
        activeMemos.where((memo) => memo.isDone).length, activeMemos.length);
    final score = todayScore(
        planRatio: planRatio, habitRatio: habitRatio, memoRatio: memoRatio);
    final mood = moodFromScore(score);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 148),
      children: [
        _PetHeader(mood: mood, score: score, now: now),
        const SizedBox(height: 14),
        _PlanDaySection(
          title: '昨天',
          emptyTitle: '昨天还没有计划',
          date: yesterday,
          color: const Color(0xFF8C63D8),
          rewardIcon: Icons.local_florist_rounded,
          canCompletePlans: canEditPlanDate(yesterday, now: now),
          showMissedPlans: isPlanDateExpired(yesterday, now: now),
          canCompleteHabits: canEditPlanDate(yesterday, now: now),
        ),
        const SizedBox(height: 12),
        _PlanDaySection(
          title: '今天',
          emptyTitle: '今天先放一件小事',
          date: today,
          color: const Color(0xFF36AF6A),
          rewardIcon: Icons.eco_rounded,
          canCompletePlans: canEditPlanDate(today, now: now),
          showMissedPlans: isPlanDateExpired(today, now: now),
          canCompleteHabits: true,
        ),
        const SizedBox(height: 12),
        _PlanDaySection(
          title: '明天',
          emptyTitle: '明天还没有安排',
          date: tomorrow,
          color: const Color(0xFFE9942E),
          rewardIcon: Icons.wb_sunny_rounded,
          canCompletePlans: canEditPlanDate(tomorrow, now: now),
          showMissedPlans: isPlanDateExpired(tomorrow, now: now),
          canCompleteHabits: false,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pet header — centered pet image, time badge, motivational text
// ---------------------------------------------------------------------------
class _PetHeader extends StatelessWidget {
  const _PetHeader({
    required this.mood,
    required this.score,
    required this.now,
  });

  final PetMood mood;
  final double score;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(now);
    final status = _dailyPlanStatus(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(
          height: 188,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Container(
                  width: 204,
                  height: 178,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark
                                ? const Color(0xFFB8E0B8)
                                : const Color(0xFFDFF5E8))
                            .withValues(alpha: isDark ? 0.18 : 0.72),
                        const Color(0xFFDFF5E8).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                  left: 76,
                  top: 38,
                  child: _PetAccent(
                      icon: Icons.add_rounded, color: Color(0xFF9AD35C))),
              const Positioned(
                  right: 76,
                  top: 76,
                  child: _PetAccent(
                      icon: Icons.eco_rounded,
                      color: Color(0xFF76BE68),
                      size: 18)),
              const Positioned(
                  left: 102,
                  bottom: 34,
                  child: _PetAccent(
                      icon: Icons.local_florist_rounded,
                      color: Color(0xFFE7C56E),
                      size: 15)),
              Center(child: PetImage(mood: mood, size: 168)),
              Positioned(
                right: -4,
                bottom: 30,
                child: _GlassTimeBadge(time: time),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _PlanType.petStatus(context),
        ),
      ],
    );
  }
}

String _dailyPlanStatus(DateTime now) {
  final dayIndex = dateOnly(now).difference(DateTime(2026)).inDays;
  final index = dayIndex % _dailyPlanStatuses.length;
  return _dailyPlanStatuses[
      index < 0 ? index + _dailyPlanStatuses.length : index];
}

const _dailyPlanStatuses = <String>[
  '先完成一件小事，节奏就会回来',
  '慢一点也可以，今天仍然算数',
  '把最轻的一步先放到手边',
  '今天不求满分，只求往前一点',
  '你已经开始，剩下的会变清楚',
  '给自己一个容易完成的开头',
  '先整理一件事，心也会安静些',
  '小步前进，也是在认真生活',
  '事情很多时，先抓住最小的那件',
  '今天的完成感，可以从现在开始',
  '先做三分钟，别急着评判自己',
  '把复杂的事切成温柔的小块',
  '完成一项，就给今天一点亮光',
  '先把手边这件事照顾好',
  '节奏不必很快，只要不断线',
  '今天也可以从简单模式开始',
  '把注意力放回下一步就好',
  '一件一件来，压力会慢慢变小',
  '先清掉一件小任务，心会松一点',
  '不用追赶昨天，照顾好今天',
  '开始得晚，也仍然可以开始',
  '把今天过稳，就是很好的进度',
  '先完成能完成的，再处理难的',
  '小小的完成，也会积累成方向',
  '给今天一个清晰的第一个动作',
  '不必一次做好，先做出轮廓',
  '你的节奏正在重新长出来',
  '先把任务变小，再把它完成',
  '今天的努力，允许很安静',
  '做完一件，就离轻松近一点',
  '先靠近目标，不必立刻抵达',
  '每个勾选，都是一点掌控感',
  '把焦虑换成一个可执行动作',
  '先动起来，答案会跟上来',
  '今天适合稳稳地推进一点',
  '先完成一格，状态会慢慢回来',
  '别急着全做完，先让事情流动',
  '你可以慢，但不用停',
  '从最小的一步开始，也很可靠',
  '今天只需要比刚才更清楚一点',
  '把重要的事放在眼前',
  '完成不是证明，是照顾自己',
  '先给计划一个温和的开端',
  '你的每一步都在整理生活',
  '今天先收住一件散开的事',
  '有一点进展，就值得被看见',
  '把待办变短一点，心就轻一点',
  '先做容易启动的那件',
  '慢慢做，也能把一天接住',
  '让今天有一个小小的完成点',
  '不用完美，只要诚实推进',
  '先把注意力放到手上这件事',
  '今天可以温柔，也可以有效',
  '先完成，再优化',
  '用一个小动作打开心里的结',
  '计划不压人，它只是帮你记得',
  '把今天交给一个清楚的下一步',
  '你不需要很多力气，只需要开始',
  '先走一步，路会变近',
  '完成一点，明天就轻一点',
  '今天的你，已经在往前了',
  '把最重要的一件事先留出来',
  '节奏回来时，通常从小事开始',
  '别让任务吓你，先让它变小',
  '把今天过得有条理一点',
  '一点秩序，也能带来很多安定',
  '先勾掉一项，给自己一点反馈',
  '你可以从任何一件小事开始',
  '清楚的计划，会让行动更轻',
  '今天也值得被好好安排',
  '把大目标折成今天能做的事',
  '先照亮眼前这一步',
  '不急着证明，只认真完成',
  '小小推进，也是可靠的努力',
  '把散乱收成一个待办',
  '先完成最靠近你的那件事',
  '今天的秩序，从一个勾选开始',
  '别和时间较劲，和下一步合作',
  '你正在把生活一点点理顺',
  '今天先让自己回到轨道上',
  '一件事完成，整天都会轻一些',
  '把计划写下来，压力就少一点',
  '先做，不必先有完美状态',
  '你的进度，可以安静地发生',
  '今天的小完成，会托住明天',
  '选择一件事，然后温柔地完成它',
  '把注意力交给最值得的那一步',
  '不用做很多，做对一件也很好',
  '今天的节奏，由你慢慢调回来',
  '先让任务从脑子里落到纸面上',
  '每一次开始，都是一次整理',
  '把今天变轻，从少一件待办开始',
  '你可以先完成最小版本',
  '一点点清空，也是一种前进',
  '把能做的事放到现在',
  '今天先稳住，再慢慢变好',
  '任务会结束，你也会轻下来',
  '给自己一个不费力的入口',
  '把今天的重点放在一件事上',
  '你已经在照顾自己的未来',
];

class _PlanType {
  const _PlanType._();

  static TextStyle petStatus(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFamily: 'LXGWWenKaiScreen',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.28,
      letterSpacing: 0,
    );
  }

  static TextStyle timeBadge(Color color) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1,
      color: color,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle dayTitle(Color color) {
    return TextStyle(
      fontSize: 24,
      fontFamily: 'LXGWWenKaiScreen',
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.05,
      letterSpacing: 0,
    );
  }

  static TextStyle habitTitle(Color color) {
    return TextStyle(
      fontSize: 22,
      fontFamily: 'LXGWWenKaiScreen',
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.05,
      letterSpacing: 0,
    );
  }
}

class _GlassTimeBadge extends StatelessWidget {
  const _GlassTimeBadge({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF7DBE78);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: RadialGradient(
          center: const Alignment(0.64, -0.72),
          radius: 1.22,
          colors: [
            isDark
                ? const Color(0xFF2A312E).withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.96),
            isDark
                ? colors.surfaceContainerHighest.withValues(alpha: 0.94)
                : colors.surface.withValues(alpha: 0.82),
            accent.withValues(alpha: isDark ? 0.16 : 0.12),
          ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : colors.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.09 : 0.16),
            blurRadius: isDark ? 16 : 24,
            offset: const Offset(0, 10),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.76),
              blurRadius: 8,
              offset: const Offset(-3, -3),
            ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -5,
            top: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.52),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.64)
                      : colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                time,
                style: _PlanType.timeBadge(
                  isDark
                      ? Colors.white.withValues(alpha: 0.88)
                      : colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PetAccent extends StatelessWidget {
  const _PetAccent({
    required this.icon,
    required this.color,
    this.size = 16,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: color.withValues(alpha: 0.85), size: size);
  }
}

// ---------------------------------------------------------------------------
// Day section — one row with plan card + habit card side by side
// ---------------------------------------------------------------------------
class _PlanDaySection extends ConsumerWidget {
  const _PlanDaySection({
    required this.title,
    required this.emptyTitle,
    required this.date,
    required this.color,
    required this.rewardIcon,
    required this.canCompletePlans,
    required this.showMissedPlans,
    required this.canCompleteHabits,
  });

  final String title;
  final String emptyTitle;
  final DateTime date;
  final Color color;
  final IconData rewardIcon;
  final bool canCompletePlans;
  final bool showMissedPlans;
  final bool canCompleteHabits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(planTasksProvider(date));
    final habits = ref.watch(habitEntriesProvider(date));
    return plans.when(
      data: (planItems) {
        return habits.when(
          data: (habitItems) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 340;
                final planCard = _PlanListCard(
                  title: title,
                  emptyTitle: emptyTitle,
                  date: date,
                  color: color,
                  rewardIcon: rewardIcon,
                  tasks: planItems,
                  canComplete: canCompletePlans,
                  showMissed: showMissedPlans,
                );
                final habitCard = _HabitListCard(
                  date: date,
                  color: color,
                  habits: habitItems,
                  canComplete: canCompleteHabits,
                  showMissed: showMissedPlans,
                );
                if (!sideBySide) {
                  return Column(children: [
                    planCard,
                    const SizedBox(height: 12),
                    habitCard
                  ]);
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 62, child: planCard),
                      const SizedBox(width: 6),
                      Expanded(flex: 38, child: habitCard),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const _SectionSkeleton(),
          error: (error, _) => _InlineError(message: '$error'),
        );
      },
      loading: () => const _SectionSkeleton(),
      error: (error, _) => _InlineError(message: '$error'),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan list card — left card showing day title, progress bar, task list
// ---------------------------------------------------------------------------
class _PlanListCard extends ConsumerWidget {
  const _PlanListCard({
    required this.title,
    required this.emptyTitle,
    required this.date,
    required this.color,
    required this.rewardIcon,
    required this.tasks,
    required this.canComplete,
    required this.showMissed,
  });

  final String title;
  final String emptyTitle;
  final DateTime date;
  final Color color;
  final IconData rewardIcon;
  final List<PlanTask> tasks;
  final bool canComplete;
  final bool showMissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = tasks.where((task) => task.isDone).length;
    final ratio = completionRatio(done, tasks.length);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      tint: color,
      radius: 28,
      shadowAlpha: isDark ? 0.08 : 0.12,
      shadowBlur: isDark ? 24 : 34,
      shadowOffset: const Offset(0, 14),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: _PlanType.dayTitle(color),
                ),
              ),
              if (!showMissed)
                _EditButton(
                    color: color, onTap: () => _showPlanEditor(context, date)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LiquidProgressBar(
                  value: ratio,
                  color: color,
                  height: 18,
                  radius: 10,
                  label: '$done / ${tasks.length}',
                ),
              ),
              const SizedBox(width: 7),
              _GlassRewardIcon(
                icon: rewardIcon,
                color: color,
                progress: ratio,
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (tasks.isEmpty)
            SizedBox(
              height: 96,
              child: Center(
                child: EmptyState(
                  icon: Icons.add_task_rounded,
                  title: emptyTitle,
                  subtitle: '点击编辑添加',
                  compact: true,
                ),
              ),
            )
          else
            ...tasks.map(
              (task) => _PlanTaskRow(
                task: task,
                color: color,
                enabled: canComplete,
                showMissed: showMissed,
                onTap: () async {
                  final ok = await ref
                      .read(planRepositoryProvider)
                      .toggleCompletion(task.id);
                  if (!context.mounted) return;
                  if (!ok) _showLockedUndo(context);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showPlanEditor(BuildContext context, DateTime date) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlanEditorSheet(date: date),
    );
  }
}

// ---------------------------------------------------------------------------
// Task row — circle checkbox + text
// ---------------------------------------------------------------------------
class _PlanTaskRow extends StatelessWidget {
  const _PlanTaskRow({
    required this.task,
    required this.color,
    required this.enabled,
    required this.showMissed,
    required this.onTap,
  });

  final PlanTask task;
  final Color color;
  final bool enabled;
  final bool showMissed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final missed = showMissed && !task.isDone;
    const missedColor = Color(0xFFE15A5A);
    return InkWell(
      onTap: enabled && !missed ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _RoundCheck(
              color: missed ? missedColor : color,
              checked: task.isDone,
              enabled: enabled,
              failed: missed,
              size: 18,
              iconSize: 18,
              borderWidth: 1.65,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: 16,
                  height: 1.18,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                  color: missed
                      ? missedColor.withValues(alpha: 0.92)
                      : task.isDone
                          ? Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.58)
                          : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                  decorationThickness: 1.1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit list card — right card showing habits with icon + checkbox
// ---------------------------------------------------------------------------
class _HabitListCard extends ConsumerWidget {
  const _HabitListCard({
    required this.date,
    required this.color,
    required this.habits,
    required this.canComplete,
    required this.showMissed,
  });

  final DateTime date;
  final Color color;
  final List<HabitEntry> habits;
  final bool canComplete;
  final bool showMissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      tint: color,
      radius: 28,
      shadowAlpha: isDark ? 0.08 : 0.12,
      shadowBlur: isDark ? 24 : 34,
      shadowOffset: const Offset(0, 14),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '习惯',
                  style: _PlanType.habitTitle(color),
                ),
              ),
              _EditButton(color: color, onTap: () => _showHabitEditor(context)),
            ],
          ),
          const SizedBox(height: 12),
          ...habits.map((entry) {
            const metrics = _HabitMetrics();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final missed = showMissed && !entry.isDone;
            const missedColor = Color(0xFFE15A5A);
            return InkWell(
              onTap: canComplete && !missed
                  ? () async {
                      final ok = await ref
                          .read(habitRepositoryProvider)
                          .toggleHabit(entry.template, date);
                      if (!context.mounted) return;
                      if (!ok) _showLockedUndo(context);
                    }
                  : null,
              borderRadius: BorderRadius.circular(metrics.rowRadius),
              child: SizedBox(
                height: metrics.rowHeight,
                child: Row(
                  children: [
                    _HabitGlassIcon(
                      icon: _habitIcon(entry.template),
                      color: missed ? missedColor : color,
                      isDark: isDark,
                      metrics: metrics,
                      muted: missed,
                    ),
                    SizedBox(width: metrics.iconTextGap),
                    Expanded(
                      child: Text(
                        entry.template.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'LXGWWenKaiScreen',
                          fontSize: metrics.fontSize,
                          fontWeight: FontWeight.w400,
                          height: 1.12,
                          letterSpacing: 0,
                          color: missed
                              ? missedColor.withValues(alpha: 0.92)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.textCheckGap),
                    _RoundCheck(
                      color: missed ? missedColor : color,
                      checked: entry.isDone,
                      enabled: canComplete,
                      failed: missed,
                      size: metrics.checkCircle,
                      iconSize: metrics.checkIcon,
                      borderWidth: metrics.checkBorder,
                      shadowBlur: 9,
                      shadowOffset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _habitIcon(HabitTemplate template) {
    final id = template.id.toLowerCase();
    final title = template.title.toLowerCase();
    return switch (template.type) {
      habitTypeWakeUp => Icons.wb_sunny_rounded,
      habitTypeSleep => Icons.nightlight_round,
      _
          when id.contains('reading') ||
              title.contains('reading') ||
              title.contains('阅读') =>
        Icons.menu_book_rounded,
      _
          when id.contains('exercise') ||
              title.contains('exercise') ||
              title.contains('运动') =>
        Icons.fitness_center_rounded,
      _ => Icons.spa_rounded,
    };
  }

  void _showHabitEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _HabitEditorSheet(),
    );
  }
}

class _HabitMetrics {
  const _HabitMetrics();

  final double iconCircle = 30;
  final double iconGlyph = 18;
  final double checkCircle = 19;
  final double checkIcon = 17;
  final double checkBorder = 1.55;
  final double iconBorder = 1.25;
  final double fontSize = 16;
  final double rowHeight = 36;
  final double rowRadius = 18;
  final double iconTextGap = 12;
  final double textCheckGap = 7;
}

class _HabitGlassIcon extends StatelessWidget {
  const _HabitGlassIcon({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.metrics,
    required this.muted,
  });

  final IconData icon;
  final Color color;
  final bool isDark;
  final _HabitMetrics metrics;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.iconCircle,
      height: metrics.iconCircle,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.38, -0.42),
          radius: 1.05,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.10 : 0.96),
            color.withValues(alpha: isDark ? 0.12 : 0.13),
            color.withValues(alpha: isDark ? 0.07 : 0.05),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: muted ? 0.26 : 0.22),
          width: metrics.iconBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.13 : 0.19),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.86),
              blurRadius: 7,
              offset: const Offset(-2, -3),
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 5,
            left: 7,
            right: 7,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.46),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 7,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.54),
              ),
            ),
          ),
          Icon(
            icon,
            color: color.withValues(alpha: muted ? 0.78 : 0.92),
            size: metrics.iconGlyph,
          ),
        ],
      ),
    );
  }
}

class _GlassRewardIcon extends StatelessWidget {
  const _GlassRewardIcon({
    required this.icon,
    required this.color,
    required this.progress,
  });

  final IconData icon;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0, 1).toDouble();
    final tintAlpha = 0.18 + clamped * 0.30;
    final iconAlpha = 0.52 + clamped * 0.40;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.38),
          radius: 0.95,
          colors: [
            isDark
                ? const Color(0xFF2A302D).withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.92),
            color.withValues(alpha: isDark ? tintAlpha * 0.74 : tintAlpha),
            color.withValues(alpha: isDark ? 0.18 : 0.10),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.28 : 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: isDark ? 0.10 + clamped * 0.06 : 0.16 + clamped * 0.10,
            ),
            blurRadius: isDark ? 9 : 12,
            offset: const Offset(0, 5),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.72),
              blurRadius: 5,
              offset: const Offset(-2, -2),
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.46),
            size: 29,
          ),
          Icon(icon, color: color.withValues(alpha: iconAlpha), size: 26),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_square,
                  size: 15, color: color.withValues(alpha: 0.78)),
              const SizedBox(width: 3),
              Text(
                '编辑',
                style: TextStyle(
                    fontFamily: 'SmileySans',
                    fontSize: 13.5,
                    color: color.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundCheck extends StatelessWidget {
  const _RoundCheck({
    required this.color,
    required this.checked,
    required this.enabled,
    this.failed = false,
    this.size = 15,
    this.iconSize = 17,
    this.borderWidth = 1.8,
    this.shadowBlur = 10,
    this.shadowOffset = const Offset(0, 4),
  });

  final Color color;
  final bool checked;
  final bool enabled;
  final bool failed;
  final double size;
  final double iconSize;
  final double borderWidth;
  final double shadowBlur;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked
            ? color
            : failed
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
        border: Border.all(
          color: checked
              ? color
              : failed
                  ? color.withValues(alpha: 0.72)
                  : color.withValues(alpha: enabled ? 0.42 : 0.26),
          width: checked ? 0 : borderWidth,
        ),
        boxShadow: checked || failed
            ? [
                BoxShadow(
                  color: color.withValues(alpha: failed ? 0.14 : 0.24),
                  blurRadius: shadowBlur,
                  offset: shadowOffset,
                ),
              ]
            : null,
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: iconSize, color: Colors.white)
          : failed
              ? Icon(Icons.close_rounded, size: iconSize * 0.82, color: color)
              : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Plan editor bottom sheet (unchanged business logic)
// ---------------------------------------------------------------------------
class _PlanEditorSheet extends ConsumerStatefulWidget {
  const _PlanEditorSheet({required this.date});

  final DateTime date;

  @override
  ConsumerState<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends ConsumerState<_PlanEditorSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(planTasksProvider(widget.date));
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: tasks.when(
        data: (items) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('编辑计划',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'SmileySans', fontWeight: FontWeight.w400)),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) {
                  final reordered = [...items];
                  if (newIndex > oldIndex) newIndex -= 1;
                  final moved = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, moved);
                  ref.read(planRepositoryProvider).reorderPlans(
                      widget.date, reordered.map((item) => item.id).toList());
                },
                itemBuilder: (context, index) {
                  final task = items[index];
                  return ListTile(
                    key: ValueKey(task.id),
                    leading: const Icon(Icons.drag_indicator_rounded),
                    title: Text(task.title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => ref
                          .read(planRepositoryProvider)
                          .softDeletePlan(task.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '添加新的计划',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addPlan(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _addPlan,
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('$error'),
        ),
      ),
    );
  }

  Future<void> _addPlan() async {
    await ref
        .read(planRepositoryProvider)
        .addPlan(widget.date, _controller.text);
    _controller.clear();
  }
}

class _HabitEditorSheet extends ConsumerStatefulWidget {
  const _HabitEditorSheet();

  @override
  ConsumerState<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends ConsumerState<_HabitEditorSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(activeHabitTemplatesProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: habits.when(
        data: (items) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '编辑习惯',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'SmileySans',
                    fontWeight: FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '早起和早睡保留为核心习惯，其他习惯可新增、重命名、删除和排序。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) {
                  final reordered = [...items];
                  if (newIndex > oldIndex) newIndex -= 1;
                  final moved = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, moved);
                  ref.read(habitRepositoryProvider).reorderHabitTemplates(
                        reordered.map((item) => item.id).toList(),
                      );
                },
                itemBuilder: (context, index) {
                  final habit = items[index];
                  final locked = habit.type != habitTypeNormal;
                  return ListTile(
                    key: ValueKey(habit.id),
                    leading: const Icon(Icons.drag_indicator_rounded),
                    title: Text(habit.title),
                    subtitle: Text(locked ? '核心习惯' : '普通习惯'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _showHabitRenameDialog(context, habit),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: locked
                              ? null
                              : () => ref
                                  .read(habitRepositoryProvider)
                                  .softDeleteHabitTemplate(habit.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '添加新的习惯',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addHabit(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _addHabit,
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('$error'),
        ),
      ),
    );
  }

  Future<void> _addHabit() async {
    await ref.read(habitRepositoryProvider).addHabitTemplate(_controller.text);
    _controller.clear();
  }

  Future<void> _showHabitRenameDialog(
    BuildContext context,
    HabitTemplate habit,
  ) async {
    final controller = TextEditingController(text: habit.title);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('编辑习惯名称'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '习惯名称',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) async {
              await ref
                  .read(habitRepositoryProvider)
                  .updateHabitTitle(habit.id, controller.text);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(habitRepositoryProvider)
                    .updateHabitTitle(habit.id, controller.text);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }
}

// ---------------------------------------------------------------------------
// Loading / Error helpers
// ---------------------------------------------------------------------------
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: SizedBox(
          height: 180, child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Text('加载失败：$message'),
    );
  }
}

void _showLockedUndo(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('超过 5 分钟后不能直接撤销，历史记录已保留')),
  );
}
