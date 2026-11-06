import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/planning_rules.dart';
import '../../data/app_database.dart';
import '../../features/pet/pet_assets.dart';
import '../../features/pet/pet_image.dart';
import '../../shared/empty_state.dart';
import '../../shared/liquid_progress_bar.dart';

class MemoScreen extends ConsumerStatefulWidget {
  const MemoScreen({super.key});

  @override
  ConsumerState<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends ConsumerState<MemoScreen> {
  static const Duration _completionVisualHold = Duration(milliseconds: 820);

  String? _openMemoId;
  final Set<String> _pendingCompletionIds = <String>{};
  final Map<String, Timer> _completionTimers = <String, Timer>{};

  @override
  void dispose() {
    for (final timer in _completionTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _toggleMemoCompletion(MemoTask memo) {
    if (_pendingCompletionIds.contains(memo.id)) return;

    if (memo.isDone) {
      _toggleDoneMemo(memo.id);
      return;
    }

    setState(() {
      _openMemoId = null;
      _pendingCompletionIds.add(memo.id);
    });

    _completionTimers[memo.id]?.cancel();
    _completionTimers[memo.id] = Timer(_completionVisualHold, () {
      _commitPendingCompletion(memo.id);
    });
  }

  Future<void> _toggleDoneMemo(String id) async {
    final ok = await ref.read(memoRepositoryProvider).toggleCompletion(id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('超过 5 分钟后不能直接撤销，历史记录已保留')),
      );
    }
  }

  Future<void> _commitPendingCompletion(String id) async {
    _completionTimers.remove(id);
    var ok = false;
    try {
      ok = await ref.read(memoRepositoryProvider).toggleCompletion(id);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('完成失败，请稍后重试')),
      );
    }
    setState(() => _pendingCompletionIds.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final memos = ref.watch(memoTasksProvider);
    return _MemoPageSurface(
      child: memos.when(
        data: (items) {
          final done = items
              .where((memo) =>
                  memo.isDone || _pendingCompletionIds.contains(memo.id))
              .length;
          final progress = completionRatio(done, items.length);

          return NotificationListener<ScrollStartNotification>(
            onNotification: (_) {
              if (_openMemoId != null) {
                setState(() => _openMemoId = null);
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 112),
              children: [
                _MemoProgressHeader(
                  progress: progress,
                  done: done,
                  total: items.length,
                ),
                const SizedBox(height: 18),
                if (items.isEmpty)
                  const _MemoEmptyCard()
                else
                  for (final memo in items)
                    _MemoCard(
                      key: ValueKey(memo.id),
                      memo: memo,
                      isCompleting: _pendingCompletionIds.contains(memo.id),
                      isOpen: _openMemoId == memo.id,
                      onOpen: () => setState(() => _openMemoId = memo.id),
                      onClose: () {
                        if (_openMemoId == memo.id) {
                          setState(() => _openMemoId = null);
                        }
                      },
                      onToggleCompletion: () => _toggleMemoCompletion(memo),
                    ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败：$error')),
      ),
    );
  }
}

class _MemoPageSurface extends StatelessWidget {
  const _MemoPageSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF0F1316),
                  Color(0xFF121519),
                  Color(0xFF151715),
                ]
              : const [
                  Color(0xFFF7F8FE),
                  Color(0xFFFEFBF8),
                  Color(0xFFF5F7F6),
                ],
        ),
      ),
      child: child,
    );
  }
}

class _MemoProgressHeader extends StatelessWidget {
  const _MemoProgressHeader({
    required this.progress,
    required this.done,
    required this.total,
  });

  final double progress;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const color = Color(0xFF8B5EF2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 116,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const petSize = 70.0;
                final travel = constraints.maxWidth > petSize
                    ? constraints.maxWidth - petSize
                    : 0.0;
                final petLeft = travel * progress.clamp(0.02, 1.0).toDouble();

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 3,
                      right: 0,
                      child: Row(
                        children: [
                          Text(
                            '备忘进度',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: isDark
                                      ? const Color(0xFFC6D0EB)
                                      : const Color(0xFF405074),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            '$done / $total',
                            style: const TextStyle(
                              color: color,
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 70,
                      child: LiquidProgressBar(
                        value: progress,
                        color: color,
                        height: 22,
                      ),
                    ),
                    Positioned(
                      left: petLeft,
                      top: 30,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final petKind = PetAssets.kindFromName(
                              ref.watch(petKindProvider));
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                            child: PetImage(
                              asset: PetAssets.runningForKind(petKind),
                              size: petSize,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        _AddMemoButton(onPressed: () => showMemoEditor(context)),
      ],
    );
  }
}

class _AddMemoButton extends StatelessWidget {
  const _AddMemoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const color = Color(0xFF8B5EF2);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.34, -0.42),
              radius: 1.15,
              colors: [
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.94),
                color.withValues(alpha: 0.11),
                isDark
                    ? color.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.76),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.20),
                blurRadius: 17,
                offset: const Offset(0, 7),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.78),
                  blurRadius: 7,
                  offset: const Offset(-2, -3),
                ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: color, size: 35),
        ),
      ),
    );
  }
}

class _MemoCard extends ConsumerStatefulWidget {
  const _MemoCard({
    super.key,
    required this.memo,
    required this.isCompleting,
    required this.isOpen,
    required this.onOpen,
    required this.onClose,
    required this.onToggleCompletion,
  });

  final MemoTask memo;
  final bool isCompleting;
  final bool isOpen;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onToggleCompletion;

  @override
  ConsumerState<_MemoCard> createState() => _MemoCardState();
}

class _MemoCardState extends ConsumerState<_MemoCard> {
  static const double _actionExtent = 148;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    final urgency = memoUrgency(
      dueDate: widget.memo.dueDate,
      today: DateTime.now(),
      isDone: widget.memo.isDone || widget.isCompleting,
    );
    final tone = _toneFor(urgency);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: 1.0,
          child: GestureDetector(
            onHorizontalDragStart: (_) => _dragDistance = 0,
            onHorizontalDragUpdate: (details) {
              _dragDistance += details.primaryDelta ?? 0;
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_dragDistance < -18 || velocity < -220) {
                widget.onOpen();
              } else if (_dragDistance > 14 || velocity > 200) {
                widget.onClose();
              }
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _MemoActionPane(
                      extent: _actionExtent,
                      memo: widget.memo,
                      onDone: widget.onClose,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 210),
                  curve: Curves.easeOutCubic,
                  margin:
                      EdgeInsets.only(right: widget.isOpen ? _actionExtent : 0),
                  child: _MemoCardFace(
                    memo: widget.memo,
                    isCompleting: widget.isCompleting,
                    urgency: urgency,
                    tone: tone,
                    onToggleCompletion: widget.onToggleCompletion,
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

class _MemoCardFace extends ConsumerWidget {
  const _MemoCardFace({
    required this.memo,
    required this.isCompleting,
    required this.urgency,
    required this.tone,
    required this.onToggleCompletion,
  });

  final MemoTask memo;
  final bool isCompleting;
  final MemoUrgency urgency;
  final _MemoTone tone;
  final VoidCallback onToggleCompletion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVisuallyDone = memo.isDone || isCompleting;
    final textColor = isVisuallyDone
        ? (isDark ? const Color(0xFF8F9991) : const Color(0xFF8A969E))
        : (isDark ? const Color(0xFFE6EEE9) : const Color(0xFF173957));

    return SizedBox(
      height: 112,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MemoCardSurfacePainter(
                color: tone.color,
                isDone: isVisuallyDone,
                isDark: isDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DeadlinePill(
                      label: 'DDL ${DateFormat('M月dd日').format(memo.dueDate)}',
                      color: tone.color,
                      isDone: isVisuallyDone,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _urgencyLabel(urgency, memo.dueDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tone.color
                              .withValues(alpha: isVisuallyDone ? 0.70 : 1),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => showMemoEditor(context, memo: memo),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFFA88EFF)
                            : const Color(0xFF8B63F5),
                        minimumSize: const Size(42, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.edit_square, size: 13),
                      label: const Text(
                        '编辑',
                        style: TextStyle(
                          fontFamily: 'SmileySans',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          memo.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontFamily: 'LXGWWenKaiScreen',
                                    color: textColor,
                                    fontSize: 14,
                                    height: 1.30,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0,
                                    decoration: isVisuallyDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: isDark
                                        ? const Color(0xFF8F9991)
                                        : const Color(0xFF8E999F),
                                    decorationThickness: 1.1,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MemoStatusMark(
                        tone: tone,
                        isDone: isVisuallyDone,
                        size: 50,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _MemoCheckButton(
                      color: tone.color,
                      isChecked: isVisuallyDone,
                      isAnimating: isCompleting,
                      onTap: onToggleCompletion,
                    ),
                    const Spacer(),
                    Text(
                      '编辑于 ${DateFormat('M月d日').format(memo.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? const Color(0xFF94A3C3)
                                : const Color(0xFF7890AE),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                            height: 1,
                          ),
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

class _MemoCardSurfacePainter extends CustomPainter {
  const _MemoCardSurfacePainter({
    required this.color,
    required this.isDone,
    required this.isDark,
  });

  final Color color;
  final bool isDone;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(18);
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), radius);
    final alphaScale = isDone ? 0.55 : 1.0;

    final shadowPath = Path()..addRRect(rrect);
    canvas.drawPath(
      shadowPath.shift(const Offset(0, 10)),
      Paint()
        ..color = color.withValues(alpha: 0.105 * alphaScale)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawPath(
      shadowPath.shift(const Offset(0, 4)),
      Paint()
        ..color = (isDark ? Colors.black : const Color(0xFF46536E))
            .withValues(alpha: isDark ? 0.20 : 0.055)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              color.withValues(alpha: (isDark ? 0.12 : 0.038) * alphaScale),
              isDark ? const Color(0xFF1A201D) : const Color(0xFFFFFDFD),
            ),
            Color.alphaBlend(
              color.withValues(alpha: (isDark ? 0.16 : 0.065) * alphaScale),
              isDark ? const Color(0xFF1F2622) : const Color(0xFFFEFBFA),
            ),
            isDark ? const Color(0xFF151A17) : const Color(0xFFFFFCFA),
          ],
          stops: const [0.0, 0.54, 1.0],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.04, -size.height * 0.30, size.width * 0.58,
          size.height * 0.62),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 0.82,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.08 : 0.72),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.50, size.height * 0.14, size.width * 0.44,
          size.height * 0.74),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.35, -0.18),
          radius: 0.78,
          colors: [
            color.withValues(alpha: (isDark ? 0.14 : 0.035) * alphaScale),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    final leftHighlight = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.1, 8, 3.1, size.height - 16),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      leftHighlight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.94 * alphaScale),
            color.withValues(alpha: 0.58 * alphaScale),
            color.withValues(alpha: 0.88 * alphaScale),
          ],
        ).createShader(leftHighlight.outerRect),
    );

    canvas.restore();

    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.36 * alphaScale),
            Colors.white.withValues(alpha: isDark ? 0.09 : 0.80),
            color.withValues(alpha: 0.12 * alphaScale),
          ],
          stops: const [0.0, 0.44, 1.0],
        ).createShader(rect),
    );

    final innerTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 10, size.width - 36, 2.4),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      innerTop,
      Paint()..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.56),
    );

    final bottomGlow = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.05 : 0.52)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18, size.height - 8, size.width - 36, 3),
        const Radius.circular(8),
      ),
      bottomGlow,
    );
  }

  @override
  bool shouldRepaint(covariant _MemoCardSurfacePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isDone != isDone ||
        oldDelegate.isDark != isDark;
  }
}

class _MemoCheckButton extends StatefulWidget {
  const _MemoCheckButton({
    required this.color,
    required this.isChecked,
    required this.isAnimating,
    required this.onTap,
  });

  final Color color;
  final bool isChecked;
  final bool isAnimating;
  final VoidCallback onTap;

  @override
  State<_MemoCheckButton> createState() => _MemoCheckButtonState();
}

class _MemoCheckButtonState extends State<_MemoCheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.isChecked) {
      _checkController.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_disableAnimations) {
      _checkController.value = widget.isChecked ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(covariant _MemoCheckButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked && !oldWidget.isChecked) {
      if (_disableAnimations) {
        _checkController.value = 1;
      } else {
        _checkController.forward(from: 0);
      }
    } else if (!widget.isChecked && oldWidget.isChecked) {
      _checkController.value = 0;
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.isChecked ? const Color(0xFF96A1A8) : widget.color;
    final targetScale = widget.isAnimating && !_disableAnimations ? 1.08 : 1.0;

    return Semantics(
      button: true,
      checked: widget.isChecked,
      label: widget.isChecked ? '取消完成' : '完成备忘',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isAnimating ? null : widget.onTap,
          customBorder: const CircleBorder(),
          child: AnimatedScale(
            scale: targetScale,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: _disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.easeOutQuart,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.isChecked
                    ? effectiveColor
                    : effectiveColor.withValues(alpha: 0.035),
                border: Border.all(
                  color: effectiveColor.withValues(
                      alpha: widget.isChecked ? 0 : 0.82),
                  width: widget.isChecked ? 0 : 1.7,
                ),
                shape: BoxShape.circle,
                boxShadow: widget.isChecked
                    ? [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.28),
                          blurRadius: widget.isAnimating ? 12 : 7,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedBuilder(
                animation: _checkController,
                builder: (context, _) {
                  final progress = _disableAnimations
                      ? (widget.isChecked ? 1.0 : 0.0)
                      : Curves.easeOutQuart.transform(
                          _checkController.value.clamp(0.0, 1.0),
                        );

                  return Center(
                    child: CustomPaint(
                      size: const Size(14, 14),
                      painter: _MemoCheckPainter(
                        color: Colors.white,
                        progress: progress,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoCheckPainter extends CustomPainter {
  const _MemoCheckPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.55)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.82, size.height * 0.28);
    final metric = path.computeMetrics().first;
    final visiblePath = metric.extractPath(
      0,
      metric.length * progress.clamp(0.0, 1.0),
    );

    canvas.drawPath(
      visiblePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.35
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MemoCheckPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class _MemoActionPane extends ConsumerWidget {
  const _MemoActionPane({
    required this.extent,
    required this.memo,
    required this.onDone,
  });

  final double extent;
  final MemoTask memo;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: extent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9476F4).withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              Expanded(
                child: _MemoSwipeAction(
                  icon: const _CrushActionGlyph(),
                  label: 'Crush',
                  foreground: const Color(0xFF5C36E8),
                  colors: const [
                    Color(0xFFE8DFFF),
                    Color(0xFFD8C7FF),
                  ],
                  onTap: () async {
                    if (!memo.isDone) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('完成后才能粉碎归档')),
                      );
                      onDone();
                      return;
                    }
                    await ref.read(memoRepositoryProvider).archiveMemo(memo.id);
                    onDone();
                  },
                ),
              ),
              Container(width: 1, color: Colors.white.withValues(alpha: 0.30)),
              Expanded(
                child: _MemoSwipeAction(
                  icon: const _DeleteActionGlyph(),
                  label: 'Delete',
                  foreground: const Color(0xFFE54345),
                  colors: const [
                    Color(0xFFFFDEDF),
                    Color(0xFFFFC7C9),
                  ],
                  onTap: () async {
                    final confirmed = await _confirmMemoDelete(context, memo);
                    if (!confirmed) {
                      onDone();
                      return;
                    }
                    await ref
                        .read(memoRepositoryProvider)
                        .softDeleteMemo(memo.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('备忘已删除，不会写入回看记录')),
                      );
                    }
                    onDone();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmMemoDelete(BuildContext context, MemoTask memo) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('确认删除备忘？'),
        content: Text(
          memo.isDone
              ? '删除只会把这条备忘移出当前列表，不会生成“删除”回看记录。已有完成记录会继续保留。'
              : '删除只会把这条备忘移出当前列表，不会出现在回看记录里。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE54345),
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _MemoSwipeAction extends StatelessWidget {
  const _MemoSwipeAction({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.colors,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final Color foreground;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 9,
                top: 8,
                child: Container(
                  width: 22,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(child: icon),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SmileySans',
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrushActionGlyph extends StatelessWidget {
  const _CrushActionGlyph();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(42, 40),
      painter: _CrushActionPainter(),
    );
  }
}

class _DeleteActionGlyph extends StatelessWidget {
  const _DeleteActionGlyph();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(34, 36),
      painter: _DeleteActionPainter(),
    );
  }
}

class _CrushActionPainter extends CustomPainter {
  const _CrushActionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final purple = const Color(0xFF7B55F4);
    final white = Colors.white;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.76),
        width: size.width * 0.62,
        height: size.height * 0.16,
      ),
      Paint()
        ..color = purple.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    void shard(List<Offset> points, double alpha) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(
        path.shift(const Offset(0, 1.4)),
        Paint()
          ..color = purple.withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              white.withValues(alpha: 0.94),
              const Color(0xFFDCD0FF).withValues(alpha: alpha),
              purple.withValues(alpha: 0.34),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = white.withValues(alpha: 0.72),
      );
    }

    shard([
      Offset(size.width * 0.48, size.height * 0.14),
      Offset(size.width * 0.62, size.height * 0.40),
      Offset(size.width * 0.48, size.height * 0.58),
      Offset(size.width * 0.35, size.height * 0.35),
    ], 0.74);
    shard([
      Offset(size.width * 0.25, size.height * 0.28),
      Offset(size.width * 0.46, size.height * 0.44),
      Offset(size.width * 0.30, size.height * 0.62),
      Offset(size.width * 0.13, size.height * 0.48),
    ], 0.66);
    shard([
      Offset(size.width * 0.63, size.height * 0.36),
      Offset(size.width * 0.88, size.height * 0.45),
      Offset(size.width * 0.70, size.height * 0.64),
      Offset(size.width * 0.52, size.height * 0.51),
    ], 0.66);
    shard([
      Offset(size.width * 0.42, size.height * 0.57),
      Offset(size.width * 0.60, size.height * 0.66),
      Offset(size.width * 0.44, size.height * 0.83),
      Offset(size.width * 0.25, size.height * 0.70),
    ], 0.62);

    final sparklePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = purple.withValues(alpha: 0.62);
    for (final center in [
      Offset(size.width * 0.18, size.height * 0.22),
      Offset(size.width * 0.84, size.height * 0.22),
      Offset(size.width * 0.82, size.height * 0.76),
    ]) {
      canvas.drawLine(
          center.translate(-3, 0), center.translate(3, 0), sparklePaint);
      canvas.drawLine(
          center.translate(0, -3), center.translate(0, 3), sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrushActionPainter oldDelegate) => false;
}

class _DeleteActionPainter extends CustomPainter {
  const _DeleteActionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = const Color(0xFFE54345);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = red;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.34,
          size.width * 0.50,
          size.height * 0.52,
        ),
        Radius.circular(size.width * 0.07),
      ),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.19, size.height * 0.28),
      Offset(size.width * 0.81, size.height * 0.28),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.40,
          size.height * 0.15,
          size.width * 0.20,
          size.height * 0.13,
        ),
        Radius.circular(size.width * 0.04),
      ),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.39, size.height * 0.45),
      Offset(size.width * 0.39, size.height * 0.75),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.61, size.height * 0.45),
      Offset(size.width * 0.61, size.height * 0.75),
      stroke,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.34,
          size.width * 0.50,
          size.height * 0.52,
        ),
        Radius.circular(size.width * 0.07),
      ),
      Paint()
        ..color = red.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _DeleteActionPainter oldDelegate) => false;
}

class _DeadlinePill extends StatelessWidget {
  const _DeadlinePill({
    required this.label,
    required this.color,
    required this.isDone,
  });

  final String label;
  final Color color;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDone ? const Color(0xFF8D98A0) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );
  }
}

class _MemoStatusMark extends StatelessWidget {
  const _MemoStatusMark({
    required this.tone,
    required this.isDone,
    this.size = 68,
  });

  final _MemoTone tone;
  final bool isDone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? const Color(0xFF9BA6AD) : tone.color;
    return CustomPaint(
      size: Size.square(size),
      painter: _MemoStatusIconPainter(
        color: color,
        kind: isDone ? _MemoStatusIconKind.party : tone.kind,
      ),
    );
  }
}

class _MemoEmptyCard extends StatelessWidget {
  const _MemoEmptyCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1D221F).withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: const Color(0xFF8B5EF2)
                .withValues(alpha: isDark ? 0.24 : 0.12)),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF8B5EF2).withValues(alpha: isDark ? 0.12 : 0.09),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const EmptyState(
        icon: Icons.bookmark_add_outlined,
        title: '还没有 DDL',
        subtitle: '把必须在某天前完成的任务放在这里',
      ),
    );
  }
}

class _MemoTone {
  const _MemoTone({
    required this.color,
    required this.kind,
  });

  final Color color;
  final _MemoStatusIconKind kind;
}

_MemoTone _toneFor(MemoUrgency urgency) {
  return switch (urgency) {
    MemoUrgency.overdue => const _MemoTone(
        color: Color(0xFFFF595F), kind: _MemoStatusIconKind.alert),
    MemoUrgency.today || MemoUrgency.oneDay => const _MemoTone(
        color: Color(0xFFFF595F), kind: _MemoStatusIconKind.alert),
    MemoUrgency.twoDays => const _MemoTone(
        color: Color(0xFFFF9827), kind: _MemoStatusIconKind.clock),
    MemoUrgency.threeDays => const _MemoTone(
        color: Color(0xFFE3A300), kind: _MemoStatusIconKind.clock),
    MemoUrgency.later => const _MemoTone(
        color: Color(0xFF9278F7), kind: _MemoStatusIconKind.clipboard),
    MemoUrgency.done => const _MemoTone(
        color: Color(0xFF9AA5AD), kind: _MemoStatusIconKind.party),
  };
}

enum _MemoStatusIconKind { alert, clock, clipboard, party }

class _MemoStatusIconPainter extends CustomPainter {
  const _MemoStatusIconPainter({
    required this.color,
    required this.kind,
  });

  final Color color;
  final _MemoStatusIconKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    if (kind != _MemoStatusIconKind.alert) {
      _drawSparkles(canvas, s, color, kind);
    }
    switch (kind) {
      case _MemoStatusIconKind.alert:
        _drawAlert(canvas, center, s, color);
      case _MemoStatusIconKind.clock:
        _drawClock(canvas, center, s, color);
      case _MemoStatusIconKind.clipboard:
        _drawClipboard(canvas, center, s, color);
      case _MemoStatusIconKind.party:
        _drawParty(canvas, center, s, color);
    }
  }

  void _drawAlert(Canvas canvas, Offset center, double s, Color color) {
    final sparklePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, s * 0.018)
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.48);
    void sparkle(Offset c, double r) {
      canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), sparklePaint);
      canvas.drawLine(c.translate(0, -r), c.translate(0, r), sparklePaint);
    }

    sparkle(Offset(s * 0.18, s * 0.23), s * 0.045);
    sparkle(Offset(s * 0.83, s * 0.27), s * 0.040);
    sparkle(Offset(s * 0.74, s * 0.88), s * 0.038);
    sparkle(Offset(s * 0.18, s * 0.70), s * 0.030);

    final path = Path()
      ..moveTo(s * 0.50, s * 0.16)
      ..cubicTo(s * 0.55, s * 0.16, s * 0.58, s * 0.20, s * 0.62, s * 0.27)
      ..lineTo(s * 0.81, s * 0.61)
      ..cubicTo(s * 0.90, s * 0.78, s * 0.79, s * 0.87, s * 0.62, s * 0.85)
      ..lineTo(s * 0.38, s * 0.85)
      ..cubicTo(s * 0.21, s * 0.87, s * 0.10, s * 0.78, s * 0.19, s * 0.61)
      ..lineTo(s * 0.38, s * 0.27)
      ..cubicTo(s * 0.42, s * 0.20, s * 0.45, s * 0.16, s * 0.50, s * 0.16)
      ..close();

    _drawSoftShadow(canvas, path, color, s * 0.34);

    final fillRect = Rect.fromLTWH(s * 0.11, s * 0.12, s * 0.78, s * 0.74);
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.42, -0.56),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFFFD7DA).withValues(alpha: 0.70),
            color.withValues(alpha: 0.11),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(fillRect),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.046
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.42),
    );

    canvas.drawPath(
      Path()
        ..moveTo(s * 0.38, s * 0.40)
        ..quadraticBezierTo(s * 0.50, s * 0.32, s * 0.62, s * 0.40),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.026
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.70),
    );

    canvas.drawPath(
      Path()
        ..moveTo(s * 0.31, s * 0.69)
        ..quadraticBezierTo(s * 0.50, s * 0.77, s * 0.69, s * 0.69),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.34),
    );

    final markX = s * 0.50;
    final markPaint = Paint()
      ..color = color.withValues(alpha: 0.96)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.072;
    canvas.drawLine(
      Offset(markX, s * 0.42),
      Offset(markX, s * 0.59),
      markPaint,
    );
    canvas.drawCircle(Offset(markX, s * 0.69), s * 0.043, markPaint);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.014
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.58),
    );
  }

  void _drawClock(Canvas canvas, Offset center, double s, Color color) {
    final faceRect = Rect.fromCircle(center: center, radius: s * 0.30);

    canvas.drawCircle(
      center.translate(0, s * 0.035),
      s * 0.31,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.13),
    );
    canvas.drawCircle(
      center,
      s * 0.30,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.50),
          radius: 0.92,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.06),
          ],
        ).createShader(faceRect),
    );

    canvas.drawCircle(
      center,
      s * 0.30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.42),
            color.withValues(alpha: 0.82),
            Colors.white.withValues(alpha: 0.52),
          ],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      center,
      s * 0.235,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.010
        ..color = color.withValues(alpha: 0.15),
    );

    final handPaint = Paint()
      ..color = color.withValues(alpha: 0.94)
      ..strokeWidth = s * 0.032
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center.translate(0, -s * 0.16), handPaint);
    canvas.drawLine(center, center.translate(s * 0.13, s * 0.09), handPaint);
    canvas.drawCircle(center, s * 0.027, Paint()..color = color);

    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.026
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawArc(faceRect.deflate(s * 0.06), math.pi * 1.12, math.pi * 0.36,
        false, shine);
  }

  void _drawClipboard(Canvas canvas, Offset center, double s, Color color) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.29, s * 0.22, s * 0.42, s * 0.55),
      Radius.circular(s * 0.075),
    );
    final bodyRect = body.outerRect;

    canvas.drawRRect(
      body.shift(Offset(0, s * 0.030)),
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.10),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.62),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.055),
          ],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.030
        ..color = color.withValues(alpha: 0.42),
    );

    final clip = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.40, s * 0.16, s * 0.20, s * 0.16),
      Radius.circular(s * 0.045),
    );
    canvas.drawRRect(
      clip,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.88),
            color.withValues(alpha: 0.18),
          ],
        ).createShader(clip.outerRect),
    );
    canvas.drawRRect(
      clip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.026
        ..color = color.withValues(alpha: 0.48),
    );

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.62)
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(s * 0.39, s * 0.43), Offset(s * 0.61, s * 0.43), linePaint);
    canvas.drawLine(
        Offset(s * 0.39, s * 0.54), Offset(s * 0.62, s * 0.54), linePaint);
    canvas.drawLine(
        Offset(s * 0.39, s * 0.65), Offset(s * 0.56, s * 0.65), linePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.34, s * 0.28, s * 0.11, s * 0.42),
        Radius.circular(s * 0.04),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _drawParty(Canvas canvas, Offset center, double s, Color color) {
    final muted = color.withValues(alpha: 0.78);

    final confettiPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.024
      ..strokeCap = StrokeCap.round
      ..color = muted.withValues(alpha: 0.58);
    final confetti = <(Offset, Offset)>[
      (Offset(s * 0.55, s * 0.26), Offset(s * 0.61, s * 0.14)),
      (Offset(s * 0.64, s * 0.34), Offset(s * 0.76, s * 0.29)),
      (Offset(s * 0.56, s * 0.43), Offset(s * 0.73, s * 0.48)),
      (Offset(s * 0.45, s * 0.28), Offset(s * 0.45, s * 0.16)),
    ];
    for (final segment in confetti) {
      canvas.drawLine(segment.$1, segment.$2, confettiPaint);
    }
    canvas.drawCircle(Offset(s * 0.70, s * 0.20), s * 0.022,
        Paint()..color = muted.withValues(alpha: 0.50));
    canvas.drawCircle(Offset(s * 0.77, s * 0.40), s * 0.018,
        Paint()..color = muted.withValues(alpha: 0.42));

    final conePath = Path()
      ..moveTo(s * 0.23, s * 0.77)
      ..lineTo(s * 0.40, s * 0.33)
      ..lineTo(s * 0.62, s * 0.56)
      ..close();
    _drawSoftShadow(canvas, conePath, color, s * 0.22);
    canvas.drawPath(
      conePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.82),
            muted.withValues(alpha: 0.32),
            muted.withValues(alpha: 0.16),
          ],
        ).createShader(Rect.fromLTWH(s * 0.20, s * 0.30, s * 0.45, s * 0.50)),
    );
    canvas.drawPath(
      conePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.026
        ..strokeJoin = StrokeJoin.round
        ..color = muted.withValues(alpha: 0.62),
    );

    final stripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round
      ..color = muted.withValues(alpha: 0.48);
    canvas.drawLine(
        Offset(s * 0.34, s * 0.48), Offset(s * 0.50, s * 0.64), stripePaint);
    canvas.drawLine(
        Offset(s * 0.29, s * 0.61), Offset(s * 0.40, s * 0.73), stripePaint);

    final lip = Path()
      ..moveTo(s * 0.40, s * 0.33)
      ..quadraticBezierTo(s * 0.54, s * 0.40, s * 0.62, s * 0.56);
    canvas.drawPath(
      lip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.038
        ..strokeCap = StrokeCap.round
        ..color = muted.withValues(alpha: 0.58),
    );
  }

  void _drawSparkles(
    Canvas canvas,
    double s,
    Color color,
    _MemoStatusIconKind kind,
  ) {
    final sparkleColor = color.withValues(
        alpha: kind == _MemoStatusIconKind.party ? 0.46 : 0.50);
    final specs = switch (kind) {
      _MemoStatusIconKind.alert => const [
          _SparkleSpec(0.15, 0.24, 0.08),
          _SparkleSpec(0.82, 0.31, 0.07),
          _SparkleSpec(0.74, 0.85, 0.08),
          _SparkleSpec(0.19, 0.72, 0.05),
        ],
      _MemoStatusIconKind.clock => const [
          _SparkleSpec(0.14, 0.39, 0.08),
          _SparkleSpec(0.82, 0.22, 0.07),
          _SparkleSpec(0.83, 0.78, 0.08),
          _SparkleSpec(0.13, 0.70, 0.05),
        ],
      _MemoStatusIconKind.clipboard => const [
          _SparkleSpec(0.16, 0.24, 0.07),
          _SparkleSpec(0.82, 0.22, 0.06),
          _SparkleSpec(0.84, 0.66, 0.08),
          _SparkleSpec(0.18, 0.70, 0.05),
        ],
      _MemoStatusIconKind.party => const [
          _SparkleSpec(0.18, 0.25, 0.08),
          _SparkleSpec(0.82, 0.68, 0.07),
          _SparkleSpec(0.17, 0.72, 0.05),
          _SparkleSpec(0.75, 0.20, 0.05),
        ],
    };

    for (final spec in specs) {
      _drawTinySparkle(
        canvas,
        Offset(s * spec.x, s * spec.y),
        s * spec.scale,
        sparkleColor,
      );
    }
  }

  void _drawTinySparkle(
      Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.75, size * 0.16)
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
  }

  void _drawSoftShadow(Canvas canvas, Path path, Color color, double blurBase) {
    canvas.drawPath(
      path.shift(Offset(0, blurBase * 0.13)),
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurBase),
    );
  }

  @override
  bool shouldRepaint(covariant _MemoStatusIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.kind != kind;
  }
}

class _SparkleSpec {
  const _SparkleSpec(this.x, this.y, this.scale);

  final double x;
  final double y;
  final double scale;
}

String _urgencyLabel(MemoUrgency urgency, DateTime dueDate) {
  final today = dateOnly(DateTime.now());
  final daysLeft = dateOnly(dueDate).difference(today).inDays;
  return switch (urgency) {
    MemoUrgency.overdue => '已逾期 ${daysLeft.abs()} 天',
    MemoUrgency.today => '今天截止',
    MemoUrgency.oneDay => '剩 1 天',
    MemoUrgency.twoDays => '剩 2 天',
    MemoUrgency.threeDays => '剩 3 天',
    MemoUrgency.later => '剩 $daysLeft 天',
    MemoUrgency.done => '已完成',
  };
}

Future<void> showMemoEditor(BuildContext context, {MemoTask? memo}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (_) => _MemoEditorSheet(memo: memo),
  );
}

class _MemoEditorSheet extends ConsumerStatefulWidget {
  const _MemoEditorSheet({this.memo});

  final MemoTask? memo;

  @override
  ConsumerState<_MemoEditorSheet> createState() => _MemoEditorSheetState();
}

class _MemoEditorSheetState extends ConsumerState<_MemoEditorSheet> {
  late final TextEditingController _controller;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.memo?.content ?? '');
    _dueDate = widget.memo?.dueDate ??
        dateOnly(DateTime.now().add(const Duration(days: 1)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFEFC),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(34)),
              border: Border.all(color: const Color(0xFFE7E1F5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7257D8).withValues(alpha: 0.16),
                  blurRadius: 32,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8B2C8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.memo == null ? '添加备忘' : '编辑备忘',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'SmileySans',
                        color: const Color(0xFF223A56),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(
                    fontFamily: 'LXGWWenKaiScreen',
                    fontSize: 16,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    labelText: '内容',
                    filled: true,
                    fillColor: const Color(0xFFF9F7FD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE1D9F2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B5EF2),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8FC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7E1F3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF8B5EF2),
                    ),
                    title: const Text('截止日期'),
                    subtitle: Text(DateFormat('yyyy年MM月dd日').format(_dueDate)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: _dueDate,
                      );
                      if (picked != null) {
                        setState(() => _dueDate = dateOnly(picked));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () async {
                      if (widget.memo == null) {
                        await ref
                            .read(memoRepositoryProvider)
                            .addMemo(_controller.text, _dueDate);
                      } else {
                        await ref.read(memoRepositoryProvider).updateMemo(
                            widget.memo!.id, _controller.text, _dueDate);
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF35B96F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(widget.memo == null ? '添加' : '保存'),
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
