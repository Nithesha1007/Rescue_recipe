import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StaggeredEntry extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final double verticalOffset;

  const StaggeredEntry({
    super.key,
    required this.index,
    required this.child,
    this.duration = AppDurations.normal,
    this.verticalOffset = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final delayMs = (index * 40).clamp(0, 300);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, verticalOffset * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
