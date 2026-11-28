import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../../domain/entities/diet_tag.dart';

class RecipeFilterBottomSheet extends StatefulWidget {
  const RecipeFilterBottomSheet({
    super.key,
    required this.initialTime,
    required this.initialDiet,
    required this.initialCuisine,
    required this.initialExclude,
    required this.onApply,
  });

  final int? initialTime;
  final DietTag initialDiet;
  final CuisineTag initialCuisine;
  final String? initialExclude;
  final void Function({
    int? maxMinutes,
    DietTag? diet,
    CuisineTag? cuisine,
    String? excludeIngredient,
    bool reset,
  }) onApply;

  @override
  State<RecipeFilterBottomSheet> createState() => _RecipeFilterBottomSheetState();
}

class _RecipeFilterBottomSheetState extends State<RecipeFilterBottomSheet> {
  late int? _time;
  late DietTag _diet;
  late CuisineTag _cuisine;
  late final TextEditingController _excludeController;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _diet = widget.initialDiet;
    _cuisine = widget.initialCuisine;
    _excludeController = TextEditingController(text: widget.initialExclude ?? '');
  }

  @override
  void dispose() {
    _excludeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Recipes',
                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    widget.onApply(reset: true);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),

            // Time Limit
            Text('Max Cooking Time', style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [null, 15, 30, 45].map((mins) {
                final selected = _time == mins;
                return ChoiceChip(
                  label: Text(mins == null ? 'Any time' : '≤ $mins min'),
                  selected: selected,
                  selectedColor: AppColors.orange,
                  onSelected: (val) {
                    setState(() => _time = mins);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Dietary tag
            Text('Dietary Filter', style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: DietTag.values.map((d) {
                final selected = _diet == d;
                return ChoiceChip(
                  label: Text(d.displayName),
                  selected: selected,
                  selectedColor: AppColors.orange,
                  onSelected: (val) {
                    if (val) setState(() => _diet = d);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Cuisine Tag
            Text('Cuisine Preference', style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: CuisineTag.values.map((c) {
                final selected = _cuisine == c;
                return ChoiceChip(
                  label: Text(c.displayName),
                  selected: selected,
                  selectedColor: AppColors.orange,
                  onSelected: (val) {
                    if (val) setState(() => _cuisine = c);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Exclude ingredient
            Text('Exclude Ingredient', style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _excludeController,
              decoration: const InputDecoration(
                hintText: 'e.g. onion, mushrooms, dairy',
                prefixIcon: Icon(Icons.block_rounded, size: AppSizes.iconSm),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              label: 'Apply Filters',
              variant: AppButtonVariant.filled,
              onPressed: () {
                final excl = _excludeController.text.trim();
                widget.onApply(
                  maxMinutes: _time,
                  diet: _diet,
                  cuisine: _cuisine,
                  excludeIngredient: excl.isEmpty ? null : excl,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
