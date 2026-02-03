import 'package:flutter/material.dart';

import 'glass_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32),
            const SizedBox(width: 12),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ],
      ),
    );
  }
}
