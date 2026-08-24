import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/pregnancy_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/community_post.dart';
import 'community_providers.dart';
import 'post_detail_screen.dart';

/// The community feed — a shared space where moms post updates and support
/// each other. Posting requires a signed-in account.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(communityFeedProvider);
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _composePost(context, ref),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Post'),
      ),
      body: feed.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load the feed',
          message: '$e',
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: Icons.forum_outlined,
              title: 'No posts yet',
              message: 'Be the first to share how you’re feeling or ask the '
                  'community a question.',
              actionLabel: 'Write a post',
              onAction: () => _composePost(context, ref),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final post in posts)
                _PostCard(post: post, uid: uid),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Future<void> _composePost(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      context.showSnack('Please sign in to post.', isError: true);
      return;
    }
    final controller = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: ctx.sheetPadding(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share with the community', style: ctx.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'What’s on your mind?',
              controller: controller,
              prefixIcon: Icons.notes,
              maxLines: 5,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Be kind and respectful. Avoid sharing personal medical '
                'details you’d rather keep private.',
                style: ctx.textStyles.bodySmall
                    ?.copyWith(color: ctx.colors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Post', onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );

    if (ok == true) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final pregnancy = ref.read(activePregnancyProvider).valueOrNull;
        final week = pregnancy == null
            ? null
            : PregnancyCalculator.currentWeek(pregnancy.lmpDate);
        await ref.read(communityRepositoryProvider).createPost(
              CommunityPost(
                id: const Uuid().v4(),
                authorUid: uid,
                authorName: ref.read(authorNameProvider),
                text: text,
                createdAt: DateTime.now(),
                week: week,
              ),
            );
      }
    }
    controller.dispose();
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.uid});
  final CommunityPost post;
  final String? uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = uid != null && post.likedBy_(uid!);
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: context.colors.primaryContainer,
                child: Text(
                  post.authorName.characters.first.toUpperCase(),
                  style: context.textStyles.labelLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: context.textStyles.titleSmall),
                    Text(
                      [
                        if (post.week != null) 'Week ${post.week}',
                        DateFormat('d MMM · HH:mm').format(post.createdAt),
                      ].join('  ·  '),
                      style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(post.text, style: context.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? context.colors.error : null, size: 20),
                onPressed: uid == null
                    ? null
                    : () => ref.read(communityRepositoryProvider).toggleLike(
                          postId: post.id,
                          uid: uid!,
                          liked: liked,
                        ),
              ),
              Text('${post.likeCount}', style: context.textStyles.bodySmall),
              const SizedBox(width: AppSpacing.lg),
              Icon(Icons.chat_bubble_outline,
                  size: 18, color: context.colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text('${post.commentCount}', style: context.textStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
