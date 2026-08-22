import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/message_share.dart';
import '../../../core/widgets/widgets.dart';

/// A scrollable, monospace view of a generated text report with Copy and Share
/// actions (WhatsApp / SMS / Email). Shared by the movement and health reports.
class ReportView extends StatelessWidget {
  const ReportView({
    required this.report,
    required this.emailSubject,
    super.key,
  });

  final String report;
  final String emailSubject;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: report));
    if (context.mounted) context.showSnack('Report copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              child: SelectableText(
                report,
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12, height: 1.4),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Copy',
                    icon: Icons.copy,
                    variant: AppButtonVariant.tonal,
                    onPressed: () => _copy(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Share',
                    icon: Icons.share_outlined,
                    onPressed: () => showShareSheet(
                      context,
                      text: report,
                      subject: emailSubject,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
