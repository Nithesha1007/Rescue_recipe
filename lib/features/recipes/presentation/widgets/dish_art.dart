import 'package:flutter/material.dart';
import '../../../../core/domain/ingredient_emoji.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/recipe.dart';

/// Warm pattern painter for DishArt.
class _DishPatternPainter extends CustomPainter {
  final Color patternColor;

  _DishPatternPainter({required this.patternColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = patternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const double step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x + 14, y + 14), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DishPatternPainter oldDelegate) =>
      oldDelegate.patternColor != patternColor;
}

/// Instant offline vector/emoji illustration for recipes.
class DishArt extends StatelessWidget {
  final Recipe recipe;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const DishArt({
    super.key,
    required this.recipe,
    this.height = 180,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Derive gradient from cuisine / title
    final (startColor, endColor) = _getGradientColors(recipe.cuisine ?? '');

    // Main ingredient emojis
    final emojis = _getMainEmojis(recipe);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _DishPatternPainter(
                patternColor: AppColors.white.withValues(alpha: 0.12),
              ),
            ),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final emoji in emojis)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          emoji,
                          style: AppTypography.artEmoji,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _getGradientColors(String cuisine) {
    final lower = cuisine.toLowerCase();
    if (lower.contains('south indian')) {
      return (AppColors.dishArtAmber1, AppColors.dishArtAmber2);
    }
    if (lower.contains('north indian')) {
      return (AppColors.dishArtPink1, AppColors.dishArtPink2);
    }
    if (lower.contains('chinese')) {
      return (AppColors.dishArtRed1, AppColors.dishArtRed2);
    }
    if (lower.contains('continental') || lower.contains('italian')) {
      return (AppColors.dishArtGreen1, AppColors.dishArtGreen2);
    }
    // Default warm food gradient
    return (AppColors.dishArtWarm1, AppColors.dishArtWarm2);
  }

  List<String> _getMainEmojis(Recipe recipe) {
    final result = <String>[];
    for (final ing in recipe.ingredients) {
      if (ing.isPantryStaple) continue;
      final emoji = IngredientEmoji.forIngredient(ing.name);
      if (emoji != IngredientEmoji.fallback && !result.contains(emoji)) {
        result.add(emoji);
        if (result.length >= 2) break;
      }
    }
    if (result.isEmpty) {
      result.add('🍲');
    }
    return result;
  }
}
