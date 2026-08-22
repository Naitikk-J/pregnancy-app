import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';

/// A small, consistent "this is AI, educational only" note shown at the bottom
/// of every AI tool result.
class AiDisclaimer extends StatelessWidget {
  const AiDisclaimer(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome,
            size: 14, color: context.colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text.isEmpty
                ? 'AI-generated and educational only — always confirm with your doctor.'
                : text,
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
