import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared app background used across screens (same look as login page).
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isLight ? const Color(0xFFF7F8FB) : AppTheme.backgroundColor,
            isLight
                ? const Color(0xFFFFFFFF)
                : AppTheme.surfaceColor.withOpacity(0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -120,
            top: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(isLight ? 0.12 : 0.15),
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    AppTheme.secondaryColor.withOpacity(isLight ? 0.10 : 0.12),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

