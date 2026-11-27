import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/expiry_priority.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/ingredient_tile.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/priority_chip.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/ingredient.dart';
import '../cubit/inventory_cubit.dart';
import '../cubit/inventory_state.dart';
import '../widgets/ingredient_form_sheet.dart';

class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<InventoryCubit>();
    if (cubit.state is InventoryInitial) {
      cubit.loadIngredients();
    }
  }

  void _openAddSheet() {
    IngredientFormSheet.show(context).then((ingredient) {
      if (ingredient != null && mounted) {
        context.read<InventoryCubit>().add(ingredient);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Added ${ingredient.displayName}'),
            ),
          );
      }
    });
  }

  void _openEditSheet(Ingredient item) {
    IngredientFormSheet.show(context, initial: item).then((updated) {
      if (updated != null && mounted) {
        context.read<InventoryCubit>().update(updated);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Updated ${updated.displayName}'),
            ),
          );
      }
    });
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
            onPressed: () {
              context.read<InventoryCubit>().restore(item);
            },
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
            onPressed: () {
              context.read<InventoryCubit>().restore(item);
            },
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
            onPressed: () {
              context.read<InventoryCubit>().restore(item);
            },
          ),
        ),
      );
  }

  void _showItemOptions(Ingredient item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: ctx.text.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                minVerticalPadding: AppSpacing.md,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openEditSheet(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.low),
                title: const Text('Mark as used'),
                minVerticalPadding: AppSpacing.md,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _markUsed(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.critical),
                title: const Text(
                  'Mark as discarded',
                  style: TextStyle(color: AppColors.critical),
                ),
                minVerticalPadding: AppSpacing.md,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _markDiscarded(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.critical),
                title: const Text(
                  'Delete permanently',
                  style: TextStyle(color: AppColors.critical),
                ),
                minVerticalPadding: AppSpacing.md,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Kitchen'),
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
                      message:
                          'Add ingredients you have at home to track freshness and get rescue recipes.',
                      actionLabel: 'Add first ingredient',
                      onAction: _openAddSheet,
                    ),
                  ),
                ),
              ),
            );
          }

          final List<Ingredient> items = (state as InventoryLoaded).items;
          return _InventoryListView(
            items: items,
            onTapItem: _showItemOptions,
            onMarkUsed: _markUsed,
            onMarkDiscarded: _markDiscarded,
            onDelete: _delete,
            onEdit: _openEditSheet,
          );
        },
      ),
    );
  }
}

class _InventoryListView extends StatelessWidget {
  const _InventoryListView({
    required this.items,
    required this.onTapItem,
    required this.onMarkUsed,
    required this.onMarkDiscarded,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Ingredient> items;
  final ValueChanged<Ingredient> onTapItem;
  final ValueChanged<Ingredient> onMarkUsed;
  final ValueChanged<Ingredient> onMarkDiscarded;
  final ValueChanged<Ingredient> onDelete;
  final ValueChanged<Ingredient> onEdit;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Group items into five chronological / urgency buckets
    final List<Ingredient> expired = [];
    final List<Ingredient> useToday = [];
    final List<Ingredient> thisWeek = [];
    final List<Ingredient> later = [];
    final List<Ingredient> noDate = [];

    for (final item in items) {
      if (item.expiryDate == null) {
        noDate.add(item);
      } else {
        final days = item.daysLeft(today: todayDate);
        if (days == null || days < 0 || item.priority(today: todayDate) == ExpiryPriority.expired) {
          expired.add(item);
        } else if (days == 0 || item.priority(today: todayDate) == ExpiryPriority.critical) {
          useToday.add(item);
        } else if (days <= 7) {
          thisWeek.add(item);
        } else {
          later.add(item);
        }
      }
    }

    // Compute priority summary counts
    final Map<ExpiryPriority, int> counts = {
      for (final p in ExpiryPriority.values) p: 0,
    };
    for (final item in items) {
      final p = item.priority(today: todayDate);
      counts[p] = (counts[p] ?? 0) + 1;
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ContentContainer(
            vertical: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: '${items.length} ${items.length == 1 ? 'item' : 'items'} in inventory',
                  subtitle: 'Organized by expiry urgency.',
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final p in ExpiryPriority.values)
                      if ((counts[p] ?? 0) > 0)
                        PriorityChip(
                          priority: p,
                          label: '${p.label}: ${counts[p]}',
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverToBoxAdapter(
            child: ContentContainer(
              vertical: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (expired.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Expired (${expired.length})',
                      subtitle: 'Inspect carefully before cooking or discard.',
                      color: AppColors.expired,
                      items: expired,
                      today: todayDate,
                    ),
                  if (useToday.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Use today (${useToday.length})',
                      subtitle: 'Rescue priority items nearing end of shelf life.',
                      color: AppColors.critical,
                      items: useToday,
                      today: todayDate,
                    ),
                  if (thisWeek.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'This week (${thisWeek.length})',
                      subtitle: 'Plan upcoming meals with these ingredients.',
                      color: AppColors.orange,
                      items: thisWeek,
                      today: todayDate,
                    ),
                  if (later.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Later (${later.length})',
                      subtitle: 'Plenty of fresh days remaining.',
                      color: AppColors.low,
                      items: later,
                      today: todayDate,
                    ),
                  if (noDate.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'No date (${noDate.length})',
                      subtitle: 'Tap to add an estimated expiry date.',
                      color: AppColors.unknown,
                      items: noDate,
                      today: todayDate,
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const ExpiryDisclaimer(),
                  const SizedBox(height: AppSpacing.xxl * 2), // Extra padding for FAB
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required List<Ingredient> items,
    required DateTime today,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ResponsiveGrid(
            children: [
              for (final item in items)
                IngredientTile(
                  name: item.displayName,
                  quantityLabel: item.quantityLabel,
                  priority: item.priority(today: today),
                  daysLeft: item.daysLeft(today: today),
                  onTap: () => onTapItem(item),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Options',
                    onSelected: (val) {
                      switch (val) {
                        case 'edit':
                          onEdit(item);
                          break;
                        case 'use':
                          onMarkUsed(item);
                          break;
                        case 'discard':
                          onMarkDiscarded(item);
                          break;
                        case 'delete':
                          onDelete(item);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'use',
                        child: Text('Mark as used'),
                      ),
                      const PopupMenuItem(
                        value: 'discard',
                        child: Text(
                          'Mark as discarded',
                          style: TextStyle(color: AppColors.critical),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.critical),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
