import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/models/app_user.dart';
import '../../community/domain/community_post.dart';
import '../../community/presentation/community_providers.dart';
import 'admin_providers.dart';

/// Admin dashboard (works on mobile and Flutter web). Gated to the `admin`
/// role. Lets an admin see platform stats, provision/revoke doctors, and
/// moderate the community feed — all via Firestore, no server needed.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: !isAdmin
          ? const EmptyState(
              icon: Icons.lock_outline,
              title: 'Admins only',
              message: 'This area is for platform administrators.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                _StatsSection(),
                SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'Doctors & users'),
                _UsersSection(),
                SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'Community moderation'),
                _ModerationSection(),
              ],
            ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider).valueOrNull ?? const AdminStats();
    Widget tile(IconData i, String label, int v, Color c) => Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(i, color: c),
                const SizedBox(height: AppSpacing.sm),
                Text('$v', style: context.textStyles.headlineSmall),
                Text(label,
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
        );
    return Column(
      children: [
        Row(children: [
          tile(Icons.people_outline, 'Users', stats.users,
              context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          tile(Icons.medical_services_outlined, 'Doctors', stats.doctors,
              context.colors.secondary),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          tile(Icons.forum_outlined, 'Posts', stats.posts,
              context.colors.tertiary),
          const SizedBox(width: AppSpacing.md),
          tile(Icons.pregnant_woman, 'Pregnancies', stats.pregnancies,
              context.colors.primary),
        ]),
      ],
    );
  }
}

class _UsersSection extends ConsumerStatefulWidget {
  const _UsersSection();
  @override
  ConsumerState<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends ConsumerState<_UsersSection> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Column(
      children: [
        AppTextField(
          label: 'Search users',
          hint: 'Search by name or email',
          prefixIcon: Icons.search,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: AppSpacing.md),
        usersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load users: $e',
              style: TextStyle(color: context.colors.error)),
          data: (users) {
            final filtered = users.where((u) {
              if (_query.isEmpty) return true;
              final n = (u.displayName ?? '').toLowerCase();
              final e = (u.email ?? '').toLowerCase();
              return n.contains(_query) || e.contains(_query);
            }).take(60).toList();
            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('No matching users.'),
              );
            }
            return Column(
              children: [for (final u in filtered) _UserTile(user: u)],
            );
          },
        ),
      ],
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDoctor = user.role == UserRole.doctor;
    final isAdmin = user.role == UserRole.admin;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.colors.primaryContainer,
              child: Text(
                (user.displayName?.isNotEmpty == true
                        ? user.displayName![0]
                        : (user.email?.isNotEmpty == true ? user.email![0] : '?'))
                    .toUpperCase(),
                style: TextStyle(color: context.colors.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName ?? user.email ?? user.uid,
                      style: context.textStyles.titleSmall,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${user.role.label}${user.email != null ? ' · ${user.email}' : ''}',
                    style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isAdmin)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.xs),
                child: Chip(label: Text('Admin')),
              ),
            PopupMenuButton<String>(
              tooltip: 'Manage user',
              onSelected: (v) {
                switch (v) {
                  case 'doctor':
                    _setRole(context, ref,
                        isDoctor ? UserRole.mother : UserRole.doctor);
                  case 'disable':
                    _disable(context, ref, true);
                  case 'enable':
                    _disable(context, ref, false);
                  case 'delete':
                    _delete(context, ref);
                }
              },
              itemBuilder: (_) => [
                if (!isAdmin)
                  PopupMenuItem(
                    value: 'doctor',
                    child: Text(isDoctor ? 'Remove doctor role' : 'Make doctor'),
                  ),
                const PopupMenuItem(
                    value: 'disable', child: Text('Disable login')),
                const PopupMenuItem(
                    value: 'enable', child: Text('Enable login')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete account',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _disable(
      BuildContext context, WidgetRef ref, bool disabled) async {
    try {
      await ref
          .read(adminBackendProvider)
          .disableUser(user.uid, disabled: disabled);
      if (context.mounted) {
        context.showSnack(disabled ? 'Login disabled.' : 'Login enabled.');
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnack(
            e is StateError ? e.message : 'Could not update the account.',
            isError: true);
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this account?'),
        content: Text(
          'This permanently deletes ${user.displayName ?? user.email ?? 'this user'}\'s '
          'login and their pregnancy data. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminBackendProvider).deleteUser(user.uid);
      if (context.mounted) context.showSnack('Account deleted.');
    } catch (e) {
      if (context.mounted) {
        context.showSnack(
            e is StateError ? e.message : 'Could not delete the account.',
            isError: true);
      }
    }
  }

  Future<void> _setRole(
      BuildContext context, WidgetRef ref, UserRole role) async {
    try {
      await ref.read(adminActionsProvider).setUserRole(user.uid, role);
      if (context.mounted) {
        context.showSnack(role == UserRole.doctor
            ? '${user.displayName ?? 'User'} is now a doctor.'
            : 'Doctor role removed.');
      }
    } catch (_) {
      if (context.mounted) {
        context.showSnack('Could not update role.', isError: true);
      }
    }
  }
}

class _ModerationSection extends ConsumerWidget {
  const _ModerationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(communityFeedProvider);
    return feed.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Could not load posts: $e',
          style: TextStyle(color: context.colors.error)),
      data: (posts) {
        if (posts.isEmpty) return const Text('No posts yet.');
        return Column(
          children: [
            for (final p in posts.take(50)) _PostTile(post: p),
          ],
        );
      },
    );
  }
}

class _PostTile extends ConsumerWidget {
  const _PostTile({required this.post});
  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName.isEmpty ? 'Anonymous' : post.authorName,
                      style: context.textStyles.labelMedium
                          ?.copyWith(color: context.colors.primary)),
                  const SizedBox(height: 2),
                  Text(post.text,
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete post',
              icon: Icon(Icons.delete_outline, color: context.colors.error),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This removes it from the community feed for '
            'everyone. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(adminActionsProvider).deletePost(post.id);
        if (context.mounted) context.showSnack('Post removed.');
      } catch (_) {
        if (context.mounted) {
          context.showSnack('Could not delete.', isError: true);
        }
      }
    }
  }
}
