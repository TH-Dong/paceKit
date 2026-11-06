import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../memo/memo_screen.dart';
import '../plan/plan_screen.dart';
import '../settings/settings_screen.dart';
import '../view/view_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _screens = <Widget>[
    PlanScreen(),
    MemoScreen(),
    ViewScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final destinations = <_NavDestination>[
      _NavDestination(
          Icons.event_available_outlined, Icons.event_available, strings.plans),
      _NavDestination(
          Icons.bookmark_border_rounded, Icons.bookmark_rounded, strings.memos),
      _NavDestination(Icons.bar_chart_rounded, Icons.bar_chart, strings.review),
      _NavDestination(
          Icons.settings_outlined, Icons.settings, strings.settings),
    ];
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: _PaceBottomNav(
          destinations: destinations,
          selectedIndex: _index,
          onSelected: (value) => setState(() => _index = value),
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _PaceBottomNav extends StatelessWidget {
  const _PaceBottomNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        height: 86,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(36),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _PaceBottomNavItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaceBottomNavItem extends StatelessWidget {
  const _PaceBottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = const Color(0xFF2EAF68);
    final color = selected ? active : colors.onSurface.withValues(alpha: 0.72);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: selected
                ? RadialGradient(
                    center: const Alignment(-0.32, -0.42),
                    radius: 1.05,
                    colors: [
                      isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.86),
                      active.withValues(alpha: 0.17),
                      active.withValues(alpha: 0.09),
                    ],
                  )
                : null,
            border: selected
                ? Border.all(color: active.withValues(alpha: 0.10))
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: active.withValues(alpha: 0.17),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    if (!isDark)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.72),
                        blurRadius: 7,
                        offset: const Offset(-2, -3),
                      ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (selected)
                Positioned(
                  top: 8,
                  left: 22,
                  right: 22,
                  child: Container(
                    height: 13,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(alpha: isDark ? 0.10 : 0.38),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? destination.selectedIcon : destination.icon,
                      color: color, size: selected ? 28 : 26),
                  const SizedBox(height: 4),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SmileySans',
                      color: color,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  right: 18,
                  bottom: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          Colors.white.withValues(alpha: isDark ? 0.16 : 0.46),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
