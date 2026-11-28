import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/recipe.dart';
import 'dish_art.dart';

/// Renders real photo from Wikipedia if resolved, fading smoothly over DishArt.
/// Fixed aspect ratio (16:9), no layout shift, offline-safe.
class RecipeImage extends StatelessWidget {
  final Recipe recipe;
  final String? photoUrl;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool enableHero;

  const RecipeImage({
    super.key,
    required this.recipe,
    this.photoUrl,
    this.height,
    this.width,
    this.borderRadius,
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    Widget content = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DishArt(
            recipe: recipe,
            borderRadius: radius,
          ),
          if (photoUrl != null && photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: radius,
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                fadeInDuration: AppDurations.normal,
                placeholder: (context, url) => const SizedBox.shrink(),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );

    if (enableHero) {
      content = Hero(
        tag: 'recipe_image_${recipe.id}',
        child: content,
      );
    }

    return content;
  }
}
