import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/community_post.dart';
import 'community_providers.dart';

/// A single community post with its comments.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.post, super.key});
  final CommunityPost post;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _input.text.trim();
    final uid = ref.read(currentUidProvider);
    if (text.isEmpty || uid == null) return;
    _input.clear();
    await ref.read(communityRepositoryProvider).addComment(
          widget.post.id,
          CommunityComment(
            id: const Uuid().v4(),
            authorUid: uid,
            authorName: ref.read(authorNameProvider),
            text: text,
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final uid = ref.watch(currentUidProvider);
    final comments = ref.watch(postCommentsProvider(post.id));
    final isAuthor = uid != null && uid == post.authorUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (isAuthor)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(communityRepositoryProvider).deletePost(post.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: context.textStyles.titleSmall),
                      Text(
                        [
                          if (post.week != null) 'Week ${post.week}',
                          DateFormat('d MMM yyyy · HH:mm')
                              .format(post.createdAt),
                        ].join('  ·  '),
                        style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(post.text, style: context.textStyles.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'Comments'),
                comments.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Could not load comments: $e'),
                  data: (list) {
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text('No comments yet — say something kind.',
                            style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant)),
                      );
                    }
                    return Column(
                      children: [
                        for (final c in list)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: context.colors.secondaryContainer,
                              child: Text(
                                  c.authorName.characters.first.toUpperCase(),
                                  style: context.textStyles.labelMedium),
                            ),
                            title: Text(c.authorName,
                                style: context.textStyles.titleSmall),
                            subtitle: Text(c.text),
                            trailing: Text(
                              DateFormat('d MMM').format(c.createdAt),
                              style: context.textStyles.labelSmall?.copyWith(
                                  color: context.colors.onSurfaceVariant),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                      decoration: InputDecoration(
                        hintText: uid == null
                            ? 'Sign in to comment'
                            : 'Add a comment…',
                        enabled: uid != null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: uid == null ? null : _addComment,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
