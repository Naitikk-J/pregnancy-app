import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import 'memory_providers.dart';

/// The user's profile avatar. Shows the on-device photo if one is set, else a
/// circular fallback with the first letter of [name]. Optionally tappable.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    required this.name,
    this.radius = 20,
    this.onTap,
    this.showEditBadge = false,
    super.key,
  });

  final String name;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(avatarPathProvider).valueOrNull;
    final letter =
        (name.trim().isEmpty ? '?' : name.trim()).characters.first.toUpperCase();

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: context.colors.primaryContainer,
      backgroundImage:
          path != null && File(path).existsSync() ? FileImage(File(path)) : null,
      child: path != null && File(path).existsSync()
          ? null
          : Text(
              letter,
              style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w600,
                color: context.colors.onPrimaryContainer,
              ),
            ),
    );

    if (showEditBadge) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.surface, width: 2),
              ),
              child: Icon(Icons.camera_alt,
                  size: radius * 0.5, color: context.colors.onPrimary),
            ),
          ),
        ],
      );
    }

    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}
