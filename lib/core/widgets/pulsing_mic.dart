import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// States for the PulsingMic widget representing current audio activity.
enum PulsingMicState {
  idle,
  listening,
  speaking,
  paused,
}

/// A microphone icon widget with pulsating visual ring feedback.
/// Respects [MediaQuery.disableAnimationsOf(context)] to disable animations for accessibility.
class PulsingMic extends StatefulWidget {
  final PulsingMicState state;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;

  const PulsingMic({
    super.key,
    required this.state,
    this.onTap,
    this.size = 64.0,
    this.tooltip,
  });

  @override
  State<PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<PulsingMic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _handleStateAnimation();
  }

  @override
  void didUpdateWidget(covariant PulsingMic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _handleStateAnimation();
    }
  }

  void _handleStateAnimation() {
    if (widget.state == PulsingMicState.listening) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final theme = Theme.of(context);

    final (Color primaryColor, Color iconColor, IconData iconData) =
        switch (widget.state) {
      PulsingMicState.listening => (
          AppColors.orange,
          theme.colorScheme.onPrimary,
          Icons.mic_rounded,
        ),
      PulsingMicState.speaking => (
          AppColors.forest,
          theme.colorScheme.onSecondary,
          Icons.volume_up_rounded,
        ),
      PulsingMicState.paused => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          Icons.mic_off_rounded,
        ),
      PulsingMicState.idle => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          Icons.mic_none_rounded,
        ),
    };

    Widget buttonContent = Material(
      color: primaryColor,
      shape: const CircleBorder(),
      elevation: widget.state == PulsingMicState.listening ? 6 : 2,
      shadowColor: primaryColor.withValues(alpha: 0.4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Icon(
              iconData,
              color: iconColor,
              size: widget.size * 0.48,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      buttonContent = Tooltip(
        message: widget.tooltip!,
        child: buttonContent,
      );
    }

    if (disableAnimations || widget.state != PulsingMicState.listening) {
      return SizedBox(
        width: widget.size * 1.4,
        height: widget.size * 1.4,
        child: Center(child: buttonContent),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size * 1.4,
          height: widget.size * 1.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(
                      alpha: _opacityAnimation.value,
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: buttonContent,
    );
  }
}
