import 'package:flutter/material.dart';
import '../../../../core/domain/ingredient_emoji.dart';
import '../../../../core/domain/ingredient_vocabulary.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/utils/ingredient_catalog.dart';

/// Full-height guided Add Ingredient bottom sheet with autocomplete,
/// category browse grid, quantity stepper with unit chips, expiry quick chips,
/// typical shelf life guidance (never auto-applied), and storage location chips.
class AddIngredientSheet extends StatefulWidget {
  const AddIngredientSheet({
    super.key,
    required this.onAdd,
  });

  final Future<void> Function(Ingredient ingredient, bool addAnother) onAdd;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(Ingredient ingredient, bool addAnother) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddIngredientSheet(onAdd: onAdd),
    );
  }

  @override
  State<AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<AddIngredientSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _phraseController;
  late final TabController _tabController;

  double _quantity = 1.0;
  bool _hasQuantity = true;
  String _selectedUnit = 'pcs';
  DateTime? _selectedExpiryDate;
  StorageLocation _selectedStorage = StorageLocation.pantry;
  String? _didYouMeanSuggestion;
  bool _isSaving = false;

  static const List<String> _unitChips = [
    'pcs', 'g', 'kg', 'ml', 'l', 'cup', 'tbsp', 'tsp', 'pack'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phraseController = TextEditingController();
    _tabController = TabController(length: IngredientCategory.values.length, vsync: this);

    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _phraseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      final suggestion = IngredientCatalog.findDidYouMean(text);
      final defaultUnit = IngredientCatalog.getDefaultUnit(text);
      setState(() {
        _didYouMeanSuggestion = suggestion;
        _selectedUnit = defaultUnit;
      });
    } else {
      setState(() {
        _didYouMeanSuggestion = null;
      });
    }
  }

  void _selectIngredient(String canonicalName) {
    _nameController.text = canonicalName;
    setState(() {
      _selectedUnit = IngredientCatalog.getDefaultUnit(canonicalName);
      _didYouMeanSuggestion = null;
    });
  }

  Future<void> _submit(bool addAnother) async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    final canonicalName = IngredientVocabulary.resolve(rawName);

    final ingredient = Ingredient(
      id: 'ing_${DateTime.now().millisecondsSinceEpoch}',
      name: canonicalName,
      quantity: _hasQuantity ? _quantity : null,
      unit: _hasQuantity ? _selectedUnit : null,
      expiryDate: _selectedExpiryDate,
      addedAt: DateTime.now(),
      status: IngredientStatus.active,
      storage: _selectedStorage,
    );

    await widget.onAdd(ingredient, addAnother);

    if (mounted) {
      if (addAnother) {
        setState(() {
          _isSaving = false;
          _nameController.clear();
          _phraseController.clear();
          _quantity = 1.0;
          _selectedExpiryDate = null;
          _didYouMeanSuggestion = null;
        });
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final currentName = _nameController.text.trim();
    final canonicalDisplay = currentName.isNotEmpty
        ? IngredientVocabulary.resolve(currentName)
        : 'New Ingredient';
    final emoji = IngredientEmoji.get(currentName.isNotEmpty ? currentName : 'food');
    final shelfLifeDays = currentName.isNotEmpty
        ? IngredientCatalog.getTypicalShelfLifeDays(currentName)
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      maxChildSize: 0.96,
      minChildSize: 0.50,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            children: [
              // Sheet Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              // Header Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            canonicalDisplay.isNotEmpty
                                ? canonicalDisplay[0].toUpperCase() + canonicalDisplay.substring(1)
                                : 'Add Ingredient',
                            style: text.titleLarge?.copyWith(
                              fontFamily: AppTypography.headingFont,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _hasQuantity
                                ? '$_quantity $_selectedUnit • ${_selectedStorage.displayName}'
                                : 'As needed • ${_selectedStorage.displayName}',
                            style: text.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Form Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Name Field
                    TextField(
                      controller: _nameController,
                      autofocus: false,
                      decoration: InputDecoration(
                        labelText: 'Ingredient name',
                        hintText: 'e.g. Tomatoes, Thakkali, Pyaaz',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),

                    // "Did you mean?" chip
                    if (_didYouMeanSuggestion != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          avatar: const Icon(Icons.auto_fix_high_rounded, size: 14, color: AppColors.orange),
                          label: Text('Did you mean $_didYouMeanSuggestion?'),
                          labelStyle: text.labelSmall?.copyWith(color: AppColors.orangeDark),
                          onPressed: () => _selectIngredient(_didYouMeanSuggestion!),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Category Browse Tabs
                    Text('Browse Categories', style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.xs),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.orange,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: AppColors.orange,
                      tabs: IngredientCategory.values.map((cat) {
                        return Tab(text: '${cat.emoji} ${cat.displayName}');
                      }).toList(),
                    ),
                    SizedBox(
                      height: 100,
                      child: TabBarView(
                        controller: _tabController,
                        children: IngredientCategory.values.map((cat) {
                          final items = IngredientCatalog.getIngredientsForCategory(cat);
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final itemEmoji = IngredientEmoji.get(item);
                              final isSelected = currentName.toLowerCase() == item.toLowerCase();
                              return GestureDetector(
                                onTap: () => _selectIngredient(item),
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: AppSpacing.sm, top: AppSpacing.xs, bottom: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.orange.withValues(alpha: 0.15)
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: isSelected ? AppColors.orange : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(itemEmoji, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(height: 4),
                                      Text(
                                        item,
                                        style: text.labelSmall?.copyWith(fontSize: 10),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Quantity Stepper and Unit Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quantity', style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text('Specify quantity', style: text.labelSmall),
                            Switch(
                              value: _hasQuantity,
                              activeThumbColor: AppColors.orange,
                              onChanged: (val) => setState(() => _hasQuantity = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_hasQuantity) ...[
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove_rounded),
                            onPressed: _quantity > 0.5 ? () => setState(() => _quantity -= 0.5) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Text(
                              _quantity % 1 == 0 ? _quantity.toInt().toString() : _quantity.toStringAsFixed(1),
                              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () => setState(() => _quantity += 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _unitChips.map((u) {
                            final isSel = _selectedUnit == u;
                            return Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.xs),
                              child: ChoiceChip(
                                label: Text(u),
                                selected: isSel,
                                selectedColor: AppColors.orange,
                                labelStyle: TextStyle(
                                  color: isSel ? AppColors.white : theme.colorScheme.onSurface,
                                ),
                                onSelected: (_) => setState(() => _selectedUnit = u),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Expiry Date Selection
                    Text('Expiry Date', style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ActionChip(
                          label: const Text('Today'),
                          onPressed: () => setState(() => _selectedExpiryDate = DateTime.now()),
                        ),
                        ActionChip(
                          label: const Text('Tomorrow'),
                          onPressed: () => setState(() => _selectedExpiryDate = DateTime.now().add(const Duration(days: 1))),
                        ),
                        ActionChip(
                          label: const Text('+3 days'),
                          onPressed: () => setState(() => _selectedExpiryDate = DateTime.now().add(const Duration(days: 3))),
                        ),
                        ActionChip(
                          label: const Text('+1 week'),
                          onPressed: () => setState(() => _selectedExpiryDate = DateTime.now().add(const Duration(days: 7))),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.calendar_today_rounded, size: 14),
                          label: Text(_selectedExpiryDate != null
                              ? '${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}'
                              : 'Pick date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedExpiryDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 7)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _selectedExpiryDate = picked);
                            }
                          },
                        ),
                        if (_selectedExpiryDate != null)
                          ActionChip(
                            label: const Text('Clear'),
                            onPressed: () => setState(() => _selectedExpiryDate = null),
                          ),
                      ],
                    ),

                    // Shelf life advisory chip (tap required, never auto-applied)
                    if (shelfLifeDays != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          avatar: const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.amber),
                          label: Text('Typical shelf life ~$shelfLifeDays days (General guide, not safety guarantee)'),
                          labelStyle: text.labelSmall,
                          onPressed: () {
                            setState(() {
                              _selectedExpiryDate = DateTime.now().add(Duration(days: shelfLifeDays));
                            });
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Storage Location Selection
                    Text('Storage Location', style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: StorageLocation.values.map((loc) {
                        final isSel = _selectedStorage == loc;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text('${loc.emoji} ${loc.displayName}'),
                              selected: isSel,
                              selectedColor: AppColors.orange,
                              labelStyle: TextStyle(
                                color: isSel ? AppColors.white : theme.colorScheme.onSurface,
                              ),
                              onSelected: (_) => setState(() => _selectedStorage = loc),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Action Buttons: Add another / Add and close
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Add another',
                            variant: AppButtonVariant.outlined,
                            onPressed: currentName.isNotEmpty && !_isSaving ? () => _submit(true) : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            label: 'Add and close',
                            variant: AppButtonVariant.filled,
                            onPressed: currentName.isNotEmpty && !_isSaving ? () => _submit(false) : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
