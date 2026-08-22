import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/baby_name.dart';
import 'baby_names_providers.dart';

/// Baby-name explorer: search and filter a curated catalog, and save
/// favourites to the pregnancy (synced across the mother's devices).
class BabyNamesScreen extends ConsumerStatefulWidget {
  const BabyNamesScreen({super.key});

  @override
  ConsumerState<BabyNamesScreen> createState() => _BabyNamesScreenState();
}

class _BabyNamesScreenState extends ConsumerState<BabyNamesScreen> {
  final _search = TextEditingController();
  NameGender? _gender;
  bool _savedOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BabyName> _filtered(Set<String> favSlugs) {
    final q = _search.text.trim().toLowerCase();
    return kBabyNames.where((n) {
      if (_gender != null && n.gender != _gender) return false;
      if (_savedOnly && !favSlugs.contains(n.slug)) return false;
      if (q.isNotEmpty &&
          !n.name.toLowerCase().contains(q) &&
          !n.meaning.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _toggle(BabyName n, bool saved) async {
    final crud = ref.read(favoriteNamesCrudProvider);
    if (crud == null) {
      context.showSnack('Start a pregnancy to save names.', isError: true);
      return;
    }
    if (saved) {
      await crud.delete(n.slug);
    } else {
      await crud.upsert(FavoriteName.from(n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favSlugs = ref.watch(favoriteSlugsProvider);
    final items = _filtered(favSlugs);

    return Scaffold(
      appBar: AppBar(title: const Text('Baby names')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.nameIdeasName),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI ideas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search names or meanings',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _search.clear()),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _gender == null,
                      onSelected: (_) => setState(() => _gender = null),
                    ),
                    for (final g in NameGender.values)
                      ChoiceChip(
                        label: Text(g.label),
                        selected: _gender == g,
                        onSelected: (_) => setState(() => _gender = g),
                      ),
                    FilterChip(
                      avatar: Icon(Icons.favorite,
                          size: 16,
                          color: _savedOnly ? context.colors.error : null),
                      label: const Text('Saved'),
                      selected: _savedOnly,
                      onSelected: (v) => setState(() => _savedOnly = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: 'No names match',
                    message: 'Try a different search, or ask AI for ideas.',
                    actionLabel: 'AI name ideas',
                    onAction: () => context.pushNamed(AppRoutes.nameIdeasName),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      final saved = favSlugs.contains(n.slug);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Text(n.name, style: context.textStyles.titleMedium),
                            const SizedBox(width: AppSpacing.sm),
                            _GenderTag(gender: n.gender),
                          ],
                        ),
                        subtitle: Text('${n.meaning} · ${n.origin}'),
                        trailing: IconButton(
                          icon: Icon(
                            saved ? Icons.favorite : Icons.favorite_border,
                            color: saved ? context.colors.error : null,
                          ),
                          onPressed: () => _toggle(n, saved),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GenderTag extends StatelessWidget {
  const _GenderTag({required this.gender});
  final NameGender gender;

  @override
  Widget build(BuildContext context) {
    final color = switch (gender) {
      NameGender.boy => context.colors.primary,
      NameGender.girl => context.colors.tertiary,
      NameGender.unisex => context.colors.secondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(gender.label,
          style: context.textStyles.labelSmall?.copyWith(color: color)),
    );
  }
}
