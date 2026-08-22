import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../ai_tools/domain/ai_models.dart';
import '../../document_scan/presentation/scan_providers.dart';
import '../domain/baby_name.dart';
import 'baby_names_providers.dart';

/// AI-powered baby-name search: the parents describe what they want (gender,
/// starting letter, origin/religion, a theme or meaning) and Mira suggests real
/// names with meanings they can save — a much bigger, personalised pool than the
/// built-in catalog.
class AiNameIdeasScreen extends ConsumerStatefulWidget {
  const AiNameIdeasScreen({super.key});

  @override
  ConsumerState<AiNameIdeasScreen> createState() => _AiNameIdeasScreenState();
}

class _AiNameIdeasScreenState extends ConsumerState<AiNameIdeasScreen> {
  final _startsWith = TextEditingController();
  final _origin = TextEditingController();
  final _theme = TextEditingController();
  String _gender = 'any';

  bool _busy = false;
  String? _error;
  NameIdeas? _result;

  @override
  void dispose() {
    _startsWith.dispose();
    _origin.dispose();
    _theme.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ideas = await ref.read(documentAiRepositoryProvider).babyNames(
            gender: _gender,
            startsWith: _startsWith.text.trim(),
            origin: _origin.text.trim(),
            theme: _theme.text.trim(),
          );
      if (mounted) setState(() => _result = ideas);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e is StateError ? e.message : 'Could not get name ideas.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(NameIdea idea) async {
    final crud = ref.read(favoriteNamesCrudProvider);
    if (crud == null) {
      context.showSnack('Start a pregnancy to save names.', isError: true);
      return;
    }
    final name = BabyName(
      name: idea.name,
      gender: NameGender.fromName(idea.gender),
      origin: idea.origin,
      meaning: idea.meaning,
    );
    await crud.upsert(FavoriteName.from(name));
    if (mounted) context.showSnack('Saved ${idea.name} to your names.');
  }

  @override
  Widget build(BuildContext context) {
    final favSlugs = ref.watch(favoriteSlugsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI name ideas')),
      body: _busy
          ? const LoadingView(message: 'Finding beautiful names…')
          : ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                  AppSpacing.lg, AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom),
              children: [
                AppCard(
                  color: context.colors.primaryContainer,
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: context.colors.onPrimaryContainer),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Tell me what you like and I’ll suggest names with '
                          'meanings.',
                          style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Gender', style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final g in const ['any', 'girl', 'boy', 'unisex'])
                      ChoiceChip(
                        label: Text(g[0].toUpperCase() + g.substring(1)),
                        selected: _gender == g,
                        onSelected: (_) => setState(() => _gender = g),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Starts with (optional, e.g. A)',
                  controller: _startsWith,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Origin / religion / culture (optional)',
                  controller: _origin,
                  hint: 'e.g. Sanskrit, Muslim, Sikh, modern',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Theme or meaning (optional)',
                  controller: _theme,
                  hint: 'e.g. nature, goddess, light, short & modern',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Suggest names',
                  icon: Icons.auto_awesome,
                  onPressed: _generate,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    color: context.colors.errorContainer,
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: context.colors.onErrorContainer),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(_error!,
                              style: context.textStyles.bodyMedium?.copyWith(
                                  color: context.colors.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  if (_result!.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(_result!.note,
                          style: context.textStyles.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: context.colors.onSurfaceVariant)),
                    ),
                  if (_result!.suggestions.isEmpty)
                    Text('No names came back — try different preferences.',
                        style: context.textStyles.bodyMedium)
                  else
                    for (final idea in _result!.suggestions)
                      _IdeaTile(
                        idea: idea,
                        saved: favSlugs.contains(_slug(idea.name)),
                        onSave: () => _save(idea),
                      ),
                ],
              ],
            ),
    );
  }

  static String _slug(String name) =>
      name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '-');
}

class _IdeaTile extends StatelessWidget {
  const _IdeaTile({
    required this.idea,
    required this.saved,
    required this.onSave,
  });

  final NameIdea idea;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(idea.name, style: context.textStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    [
                      idea.meaning,
                      if (idea.origin.isNotEmpty) idea.origin,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                  color: saved ? context.colors.error : null),
              onPressed: saved ? null : onSave,
            ),
          ],
        ),
      ),
    );
  }
}
