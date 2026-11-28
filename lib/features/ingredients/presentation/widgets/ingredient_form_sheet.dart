import 'package:flutter/material.dart';

import '../../../../core/domain/expiry_priority.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/utils/expiry_date_resolver.dart';
import 'quick_expiry_chips.dart';

class IngredientFormSheet extends StatefulWidget {
  const IngredientFormSheet({
    super.key,
    this.initial,
    required this.onSave,
  });

  final Ingredient? initial;
  final ValueChanged<Ingredient> onSave;

  static Future<Ingredient?> show(
    BuildContext context, {
    Ingredient? initial,
  }) {
    return showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => IngredientFormSheet(
        initial: initial,
        onSave: (ingredient) => Navigator.of(ctx).pop(ingredient),
      ),
    );
  }

  @override
  State<IngredientFormSheet> createState() => _IngredientFormSheetState();
}

class _IngredientFormSheetState extends State<IngredientFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _phraseController;

  DateTime? _selectedDate;
  String? _phraseResolvedPreview;
  bool _phraseUnrecognized = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameController = TextEditingController(text: init?.name ?? '');
    _quantityController = TextEditingController(
      text: init?.quantity != null
          ? (init!.quantity! % 1 == 0
              ? init.quantity!.toInt().toString()
              : init.quantity!.toString())
          : '',
    );
    _unitController = TextEditingController(text: init?.unit ?? '');
    _phraseController = TextEditingController();
    _selectedDate = init?.expiryDate;

    if (_selectedDate != null) {
      _phraseResolvedPreview = _formatDate(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _onPhraseChanged(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _phraseUnrecognized = false;
        _phraseResolvedPreview =
            _selectedDate != null ? _formatDate(_selectedDate!) : null;
      });
      return;
    }

    final DateTime? resolved = ExpiryDateResolver.resolve(trimmed);
    setState(() {
      if (resolved != null) {
        _selectedDate = resolved;
        _phraseUnrecognized = false;
        _phraseResolvedPreview =
            '${_formatDate(resolved)} (${ExpiryPriority.fromDate(resolved).label} priority)';
      } else {
        _phraseUnrecognized = true;
        _phraseResolvedPreview = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _selectedDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _phraseController.clear();
        _phraseUnrecognized = false;
        _phraseResolvedPreview = _formatDate(_selectedDate!);
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _phraseController.clear();
      _phraseUnrecognized = false;
      _phraseResolvedPreview = null;
    });
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final String name = _nameController.text.trim().toLowerCase();
    final double? qty = _quantityController.text.trim().isNotEmpty
        ? double.tryParse(_quantityController.text.trim())
        : null;
    final String? unit = _unitController.text.trim().isNotEmpty
        ? _unitController.text.trim().toLowerCase()
        : null;

    final Ingredient ingredient = (widget.initial != null)
        ? widget.initial!.copyWith(
            name: name,
            quantity: () => qty,
            unit: () => unit,
            expiryDate: () => _selectedDate,
          )
        : Ingredient(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: name,
            quantity: qty,
            unit: unit,
            expiryDate: _selectedDate,
            addedAt: DateTime.now(),
          );

    widget.onSave(ingredient);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.initial == null
                            ? 'Add Ingredient'
                            : 'Edit Ingredient',
                        style: text.titleLarge?.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredient name *',
                    hintText: 'e.g. Tomatoes, milk, spinach',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter an ingredient name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Quantity and Unit in a Row (optimized for 320dp & 1.5 text scale without truncation)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          hintText: 'e.g. 3, 500',
                        ),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Invalid';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'pcs, g, ml',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Quick Expiry Chips
                QuickExpiryChips(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      _phraseController.clear();
                      _phraseUnrecognized = false;
                      _phraseResolvedPreview =
                          date != null ? _formatDate(date) : null;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                // Natural language phrase resolver
                TextFormField(
                  controller: _phraseController,
                  decoration: InputDecoration(
                    labelText: 'Expiry phrase (optional)',
                    hintText: 'e.g. tomorrow, in 3 days, friday',
                    prefixIcon: const Icon(Icons.auto_awesome_outlined),
                    suffixIcon: _phraseController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _phraseController.clear();
                              _onPhraseChanged('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _onPhraseChanged,
                ),
                if (_phraseUnrecognized) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Could not understand this phrase. Please pick a date below or try "tomorrow", "in 3 days", "friday".',
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // Date picker button and preview
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _selectedDate == null
                              ? 'Pick expiry date'
                              : 'Date: ${_formatDate(_selectedDate!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: _pickDate,
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear expiry date',
                        onPressed: _clearDate,
                      ),
                    ],
                  ],
                ),
                if (_phraseResolvedPreview != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Resolved: $_phraseResolvedPreview',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                // Submit button
                AppButton(
                  label: widget.initial == null
                      ? 'Add to Kitchen'
                      : 'Save Changes',
                  icon: widget.initial == null ? Icons.add : Icons.check,
                  variant: AppButtonVariant.filled,
                  expand: true,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
