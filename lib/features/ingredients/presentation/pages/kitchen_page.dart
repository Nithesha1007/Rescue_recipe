import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/expiry_priority.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/freshness_ring.dart';
import '../../../../core/widgets/ingredient_tile.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/priority_chip.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../recipes/domain/services/media_resolver.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/utils/glued_ingredient_splitter.dart';
import '../cubit/inventory_cubit.dart';
import '../cubit/inventory_state.dart';
import '../widgets/add_ingredient_sheet.dart';
import '../widgets/ingredient_form_sheet.dart';

class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  String _selectedStorageTab = 'All'; // All, Fridge, Freezer, Pantry
  ExpiryPriority? _selectedPriorityFilter;
  String _searchQuery = '';
  bool _isGridMode = false;
  final Set<String> _selectedItemIds = {};
  bool _isMultiSelectMode = false;

  final Map<String, String?> _ingredientPhotoCache = {};

  @override
  void initState() {
    super.initState();
    final cubit = context.read<InventoryCubit>();
    if (cubit.state is InventoryInitial) {
      cubit.loadIngredients();
    }
  }

  void _openAddSheet() {
    AddIngredientSheet.show(
      context,
      onAdd: (ingredient, addAnother) async {
        await context.read<InventoryCubit>().add(ingredient);
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('Added ${ingredient.displayName}')),
            );
        }
      },
    );
  }

  void _openEditSheet(Ingredient item) {
    IngredientFormSheet.show(context, initial: item).then((updated) {
      if (updated != null && mounted) {
        context.read<InventoryCubit>().update(updated);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Updated ${updated.displayName}')),
          );
      }
    });
  }

  void _splitGluedItem(Ingredient item) {
    final splitItems = GluedIngredientSplitter.split(item);
    if (splitItems.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find multiple recognizable ingredients to split.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Split Ingredients'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split "${item.name}" into ${splitItems.length} items?'),
            const SizedBox(height: 12),
            for (final s in splitItems)
              Text('• ${s.name} (${s.quantity != null ? "${s.quantity} " : ""}${s.unit ?? ""})'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dlgCtx).pop();
              final cubit = context.read<InventoryCubit>();
              await cubit.delete(item.id);
              await cubit.addMany(splitItems);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Split into ${splitItems.length} separate ingredients!')),
                );
              }
            },
            child: const Text('Split Items'),
          ),
        ],
      ),
    );
  }

  void _markUsed(Ingredient item) {
    HapticFeedback.lightImpact();
    context.read<InventoryCubit>().markUsed(item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Marked ${item.displayName} as used!'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.orange,
            onPressed: () => context.read<InventoryCubit>().restore(item),
          ),
        ),
      );
  }

  void _markDiscarded(Ingredient item) {
    HapticFeedback.mediumImpact();
    context.read<InventoryCubit>().markDiscarded(item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Marked ${item.displayName} as discarded.'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.orange,
            onPressed: () => context.read<InventoryCubit>().restore(item),
          ),
        ),
      );
  }

  void _delete(Ingredient item) {
    HapticFeedback.heavyImpact();
    context.read<InventoryCubit>().delete(item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted ${item.displayName}.'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.orange,
            onPressed: () => context.read<InventoryCubit>().restore(item),
          ),
        ),
      );
  }

  void _moveStorage(Ingredient item, StorageLocation newStorage) {
    final updated = item.copyWith(storage: newStorage);
    context.read<InventoryCubit>().update(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved ${item.displayName} to ${newStorage.displayName}')),
    );
  }

  void _bulkMarkUsed(List<Ingredient> items) {
    final cubit = context.read<InventoryCubit>();
    for (final id in _selectedItemIds) {
      cubit.markUsed(id);
    }
    final count = _selectedItemIds.length;
    setState(() {
      _selectedItemIds.clear();
      _isMultiSelectMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked $count items as used!')),
    );
  }

  void _bulkMarkDiscarded(List<Ingredient> items) {
    final cubit = context.read<InventoryCubit>();
    for (final id in _selectedItemIds) {
      cubit.markDiscarded(id);
    }
    final count = _selectedItemIds.length;
    setState(() {
      _selectedItemIds.clear();
      _isMultiSelectMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked $count items as discarded.')),
    );
  }

  void _bulkDelete(List<Ingredient> items) {
    final cubit = context.read<InventoryCubit>();
    for (final id in _selectedItemIds) {
      cubit.delete(id);
    }
    final count = _selectedItemIds.length;
    setState(() {
      _selectedItemIds.clear();
      _isMultiSelectMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted $count items.')),
    );
  }

  void _fetchPhotoIfNeeded(String ingredientName) {
    if (_ingredientPhotoCache.containsKey(ingredientName)) return;
    if (sl.isRegistered<MediaResolver>()) {
      sl<MediaResolver>().resolveIngredientMedia(ingredientName: ingredientName).then((res) {
        if (mounted && res != null) {
          setState(() => _ingredientPhotoCache[ingredientName] = res.url);
        }
      });
    }
  }

  void _showItemActionSheet(BuildContext context, Ingredient item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    PriorityChip(priority: item.priority(), dense: true),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit ingredient'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openEditSheet(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outlined),
                title: const Text('Move storage location'),
                subtitle: Text('Current: ${item.storage.displayName}'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showMoveStorageDialog(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_split_rounded, color: AppColors.orange),
                title: const Text('Split into separate items'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _splitGluedItem(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.low),
                title: const Text('Mark as used'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _markUsed(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.critical),
                title: const Text('Mark as discarded', style: TextStyle(color: AppColors.critical)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _markDiscarded(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.critical),
                title: const Text('Delete permanently', style: TextStyle(color: AppColors.critical)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _delete(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveStorageDialog(BuildContext context, Ingredient item) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => SimpleDialog(
        title: Text('Move ${item.displayName} to:'),
        children: StorageLocation.values.map((loc) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.of(dlgCtx).pop();
              _moveStorage(item, loc);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(loc.emoji, style: AppTypography.mediumEmoji),
                  const SizedBox(width: AppSpacing.md),
                  Text(loc.displayName),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('${_selectedItemIds.length} selected')
            : const Text('My Kitchen'),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() {
                  _selectedItemIds.clear();
                  _isMultiSelectMode = false;
                }),
              )
            : null,
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.low),
              tooltip: 'Mark used',
              onPressed: _selectedItemIds.isNotEmpty
                  ? () {
                      final state = context.read<InventoryCubit>().state;
                      if (state is InventoryLoaded) _bulkMarkUsed(state.items);
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.critical),
              tooltip: 'Mark discarded',
              onPressed: _selectedItemIds.isNotEmpty
                  ? () {
                      final state = context.read<InventoryCubit>().state;
                      if (state is InventoryLoaded) _bulkMarkDiscarded(state.items);
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.critical),
              tooltip: 'Delete',
              onPressed: _selectedItemIds.isNotEmpty
                  ? () {
                      final state = context.read<InventoryCubit>().state;
                      if (state is InventoryLoaded) _bulkDelete(state.items);
                    }
                  : null,
            ),
          ] else ...[
            IconButton(
              icon: Icon(_isGridMode ? Icons.view_list_rounded : Icons.grid_view_rounded),
              tooltip: _isGridMode ? 'List view' : 'Grid view',
              onPressed: () => setState(() => _isGridMode = !_isGridMode),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add ingredient'),
      ),
      body: BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading || state is InventoryInitial) {
            return const ContentContainer(
              vertical: AppSpacing.xl,
              child: LoadingSkeletonList(count: 4),
            );
          }

          if (state is InventoryError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<InventoryCubit>().loadIngredients(),
            );
          }

          if (state is InventoryEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: EmptyState(
                      icon: Icons.kitchen_outlined,
                      title: 'Your kitchen is empty',
                      message: 'Add ingredients or tap suggestions below to get started.',
                      actionLabel: 'Add first ingredient',
                      onAction: _openAddSheet,
                      extraContent: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            ActionChip(
                              avatar: const Text('🍅'),
                              label: const Text('Add Tomatoes'),
                              onPressed: () {
                                context.read<InventoryCubit>().add(Ingredient(
                                  id: 'ing_${DateTime.now().millisecondsSinceEpoch}',
                                  name: 'tomato',
                                  quantity: 2,
                                  unit: 'pcs',
                                  expiryDate: DateTime.now().add(const Duration(days: 3)),
                                  addedAt: DateTime.now(),
                                  storage: StorageLocation.fridge,
                                ));
                              },
                            ),
                            ActionChip(
                              avatar: const Text('🧅'),
                              label: const Text('Add Onions'),
                              onPressed: () {
                                context.read<InventoryCubit>().add(Ingredient(
                                  id: 'ing_${DateTime.now().millisecondsSinceEpoch}',
                                  name: 'onion',
                                  quantity: 3,
                                  unit: 'pcs',
                                  expiryDate: DateTime.now().add(const Duration(days: 7)),
                                  addedAt: DateTime.now(),
                                  storage: StorageLocation.pantry,
                                ));
                              },
                            ),
                            ActionChip(
                              avatar: const Text('🥬'),
                              label: const Text('Add Spinach'),
                              onPressed: () {
                                context.read<InventoryCubit>().add(Ingredient(
                                  id: 'ing_${DateTime.now().millisecondsSinceEpoch}',
                                  name: 'spinach',
                                  quantity: 100,
                                  unit: 'g',
                                  expiryDate: DateTime.now().add(const Duration(days: 2)),
                                  addedAt: DateTime.now(),
                                  storage: StorageLocation.fridge,
                                ));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          if (state is InventoryLoaded) {
            return _buildLoadedView(context, state.items);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, List<Ingredient> allItems) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // Prefetch ingredient photos
    for (final item in allItems) {
      _fetchPhotoIfNeeded(item.name);
    }

    // Filter by storage tab
    var filtered = allItems;
    if (_selectedStorageTab != 'All') {
      filtered = filtered.where((i) {
        return i.storage.displayName.toLowerCase() == _selectedStorageTab.toLowerCase();
      }).toList();
    }

    // Filter by priority
    if (_selectedPriorityFilter != null) {
      filtered = filtered.where((i) => i.priority(today: todayDate) == _selectedPriorityFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((i) => i.name.toLowerCase().contains(q) || i.displayName.toLowerCase().contains(q)).toList();
    }

    // Urgent count for summary card
    final urgentCount = allItems.where((i) {
      final p = i.priority(today: todayDate);
      return p == ExpiryPriority.critical || p == ExpiryPriority.high;
    }).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Card with mini priority bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${allItems.length} items • $urgentCount need rescue soon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Mini priority bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            if (urgentCount > 0)
                              Expanded(
                                flex: urgentCount,
                                child: Container(color: AppColors.critical),
                              ),
                            Expanded(
                              flex: (allItems.length - urgentCount).clamp(1, 999),
                              child: Container(color: AppColors.low),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Storage Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: ['All', 'Fridge', 'Freezer', 'Pantry'].map((tab) {
                final isSel = _selectedStorageTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSel,
                    selectedColor: AppColors.orange,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                    onSelected: (_) => setState(() => _selectedStorageTab = tab),
                  ),
                );
              }).toList(),
            ),
          ),

          // Priority Filter Chips & Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search kitchen...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('All Priorities'),
                        backgroundColor: _selectedPriorityFilter == null ? AppColors.orange.withValues(alpha: 0.15) : null,
                        onPressed: () => setState(() => _selectedPriorityFilter = null),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ...ExpiryPriority.values.map((p) {
                        final isSel = _selectedPriorityFilter == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            label: Text(p.label),
                            selected: isSel,
                            selectedColor: AppColors.orange,
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.white : null,
                            ),
                            onSelected: (_) => setState(() => _selectedPriorityFilter = isSel ? null : p),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items Content: Grid or List
          if (_isGridMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: filtered.map((item) {
                      final days = item.daysLeft(today: todayDate);
                      final isSelected = _selectedItemIds.contains(item.id);

                      return SizedBox(
                        width: itemWidth,
                        child: GestureDetector(
                          onTap: () {
                            if (_isMultiSelectMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedItemIds.remove(item.id);
                                  if (_selectedItemIds.isEmpty) _isMultiSelectMode = false;
                                } else {
                                  _selectedItemIds.add(item.id);
                                }
                              });
                            } else {
                              _showItemActionSheet(context, item);
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _isMultiSelectMode = true;
                              _selectedItemIds.add(item.id);
                            });
                          },
                          child: Card(
                            color: isSelected ? AppColors.orange.withValues(alpha: 0.12) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              side: BorderSide(
                                color: isSelected ? AppColors.orange : Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FreshnessRing(
                                    daysLeft: days,
                                    ingredientName: item.name,
                                    photoUrl: _ingredientPhotoCache[item.name],
                                    size: 48,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    item.displayName,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.quantityLabel,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  PriorityChip(priority: item.priority(today: todayDate), dense: true),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            )
          else
            Column(
              children: filtered.map((item) {
                final days = item.daysLeft(today: todayDate);
                final isSelected = _selectedItemIds.contains(item.id);

                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    color: AppColors.low,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: const Icon(Icons.check_circle_outline, color: AppColors.white),
                  ),
                  secondaryBackground: Container(
                    color: AppColors.critical,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: const Icon(Icons.delete_sweep_outlined, color: AppColors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _markUsed(item);
                    } else {
                      _markDiscarded(item);
                    }
                    return false;
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    child: InkWell(
                      onLongPress: () {
                        setState(() {
                          _isMultiSelectMode = true;
                          _selectedItemIds.add(item.id);
                        });
                      },
                      onTap: () {
                        if (_isMultiSelectMode) {
                          setState(() {
                            if (isSelected) {
                              _selectedItemIds.remove(item.id);
                              if (_selectedItemIds.isEmpty) _isMultiSelectMode = false;
                            } else {
                              _selectedItemIds.add(item.id);
                            }
                          });
                        } else {
                          _showItemActionSheet(context, item);
                        }
                      },
                      child: IngredientTile(
                        name: item.displayName,
                        quantityLabel: item.quantityLabel,
                        priority: item.priority(today: todayDate),
                        daysLeft: days,
                        photoUrl: _ingredientPhotoCache[item.name],
                        storageIcon: item.storage.emoji,
                        onAddExpiry: () => _openEditSheet(item),
                        trailing: _isMultiSelectMode
                            ? Checkbox(
                                value: isSelected,
                                activeColor: AppColors.orange,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedItemIds.add(item.id);
                                    } else {
                                      _selectedItemIds.remove(item.id);
                                      if (_selectedItemIds.isEmpty) _isMultiSelectMode = false;
                                    }
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.more_vert_rounded),
                                onPressed: () => _showItemActionSheet(context, item),
                              ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: ExpiryDisclaimer(),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
