import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/shopping_item.dart';
import 'shopping_providers.dart';

/// Baby & mom shopping checklist grouped by category, with a progress bar and
/// custom items. A curated starting list the mother ticks off as she buys.
class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingItemsProvider);
    final bought = items.where((i) => i.bought).length;
    final progress = items.isEmpty ? 0.0 : bought / items.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping list')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustom(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$bought of ${items.length} bought',
                    style: context.textStyles.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final category in ShoppingCategory.values)
            _CategorySection(
              category: category,
              items: items.where((i) => i.category == category).toList(),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final crud = ref.read(shoppingCrudProvider);
    if (crud == null) {
      context.showSnack('Start a pregnancy to build your list.', isError: true);
      return;
    }
    final label = TextEditingController();
    var category = ShoppingCategory.baby;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add item', style: ctx.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Item',
                controller: label,
                prefixIcon: Icons.shopping_cart_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final c in ShoppingCategory.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: category == c,
                      onSelected: (_) => setState(() => category = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                  label: 'Add', onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      final text = label.text.trim();
      if (text.isNotEmpty) {
        await crud.upsert(
          ShoppingItem(
            id: const Uuid().v4(),
            label: text,
            category: category,
            custom: true,
          ),
        );
      }
    }
    label.dispose();
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.category, required this.items});
  final ShoppingCategory category;
  final List<ShoppingItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: category.label),
        for (final item in items)
          Dismissible(
            key: ValueKey(item.id),
            direction: item.custom
                ? DismissDirection.endToStart
                : DismissDirection.none,
            onDismissed: (_) => ref.read(shoppingCrudProvider)?.delete(item.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              color: context.colors.errorContainer,
              child: Icon(Icons.delete, color: context.colors.onErrorContainer),
            ),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: item.bought,
              title: Text(item.label),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => ref
                  .read(shoppingCrudProvider)
                  ?.upsert(item.copyWith(bought: v ?? false)),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
