import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.all(compact ? 10 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primary, size: compact ? 24 : 30),
          SizedBox(height: compact ? 6 : 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: (compact
                    ? Theme.of(context).textTheme.bodyMedium
                    : Theme.of(context).textTheme.titleMedium)
                ?.copyWith(
              fontFamily: 'SmileySans',
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: compact ? 3 : 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
