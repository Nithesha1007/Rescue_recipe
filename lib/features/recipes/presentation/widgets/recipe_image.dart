import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/media_resolver.dart';
import 'dish_art.dart';

/// Renders real photo from MediaResolver (Pexels, TheMealDB, Wikipedia, AI),
/// fading smoothly over DishArt.
/// Fixed aspect ratio (16:9), no layout shift, offline-safe, displays visible credit when required.
class RecipeImage extends StatelessWidget {
  final Recipe recipe;
  final MediaResolutionResult? mediaResult;
  final String? photoUrl;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool enableHero;
  final bool showCreditBadge;

  const RecipeImage({
    super.key,
    required this.recipe,
    this.mediaResult,
    this.photoUrl,
    this.height,
    this.width,
    this.borderRadius,
    this.enableHero = true,
    this.showCreditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final photo = photoUrl ?? mediaResult?.url;
    final creditText = mediaResult?.creditText;

    Widget content = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DishArt(
            recipe: recipe,
            borderRadius: radius,
          ),
          if (photo != null && photo.isNotEmpty)
            ClipRRect(
              borderRadius: radius,
              child: CachedNetworkImage(
                imageUrl: photo,
                fit: BoxFit.cover,
                fadeInDuration: AppDurations.normal,
                placeholder: (context, url) => const SizedBox.shrink(),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          if (showCreditBadge && creditText != null)
            Positioned(
              bottom: AppSpacing.xs,
              right: AppSpacing.xs,
              child: GestureDetector(
                onTap: () {
                  final pUrl = mediaResult?.photographerUrl;
                  if (pUrl != null && pUrl.isNotEmpty) {
                    launchUrl(Uri.parse(pUrl), mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.black45,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    creditText,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
