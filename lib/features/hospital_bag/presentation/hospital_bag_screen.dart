import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/hospital_bag_item.dart';
import 'hospital_bag_providers.dart';

/// Hospital-bag checklist grouped by who it's for, with a packing progress bar
/// and the ability to add custom items.
class HospitalBagScreen extends ConsumerWidget {
  const HospitalBagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(hospitalBagItemsProvider);
    final packed = items.where((i) => i.packed).length;
    final progress = items.isEmpty ? 0.0 : packed / items.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Hospital bag')),
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
                Text('$packed of ${items.length} packed',
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
          for (final category in HospitalBagCategory.values)
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
    final label = TextEditingController();
    var category = HospitalBagCategory.mother;

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
                prefixIcon: Icons.checklist,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final c in HospitalBagCategory.values)
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
        await ref.read(hospitalBagCrudProvider)?.upsert(
              HospitalBagItem(
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
  final HospitalBagCategory category;
  final List<HospitalBagItem> items;

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
            onDismissed: (_) =>
                ref.read(hospitalBagCrudProvider)?.delete(item.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              color: context.colors.errorContainer,
              child: Icon(Icons.delete, color: context.colors.onErrorContainer),
            ),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: item.packed,
              title: Text(item.label),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => ref
                  .read(hospitalBagCrudProvider)
                  ?.upsert(item.copyWith(packed: v ?? false)),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
