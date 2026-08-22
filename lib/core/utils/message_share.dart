import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';

/// Opens the device's messaging apps with pre-filled text — no backend needed.
/// Uses `wa.me` deep links for WhatsApp and the `sms:` scheme for SMS, so the
/// message opens ready for the user to press send (nothing is sent silently).
class MessageShare {
  MessageShare._();

  /// WhatsApp requires digits only, in international format without a leading
  /// '+' or separators. We keep whatever digits the user entered.
  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

  /// Opens WhatsApp with [text] pre-filled. If [phone] is given, targets that
  /// contact's chat; otherwise WhatsApp shows its own contact picker. Returns
  /// false if WhatsApp couldn't be opened (e.g. not installed).
  static Future<bool> whatsApp(String text, {String? phone}) async {
    final digits = phone == null ? '' : _digits(phone);
    final base = digits.isEmpty ? 'https://wa.me/?text=' : 'https://wa.me/$digits?text=';
    final uri = Uri.parse('$base${Uri.encodeComponent(text)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens the SMS app with [text] pre-filled, optionally addressed to [phone].
  static Future<bool> sms(String text, {String? phone}) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone == null ? '' : _digits(phone),
      queryParameters: {'body': text},
    );
    return launchUrl(uri);
  }

  /// Opens the email app with [subject] + [body].
  static Future<bool> email(String body, {required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    return launchUrl(uri);
  }
}

/// Presents a "Share via" bottom sheet (WhatsApp / SMS / Email) for [text].
///
/// When [phone] is provided, WhatsApp and SMS target that contact directly;
/// otherwise they open a picker so the user chooses who to send to. [subject] is
/// used for the email option (omit to hide email).
Future<void> showShareSheet(
  BuildContext context, {
  required String text,
  String? phone,
  String? subject,
  String title = 'Share via',
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Text(title, style: ctx.textStyles.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
            title: const Text('WhatsApp'),
            onTap: () => Navigator.pop(ctx, 'whatsapp'),
          ),
          ListTile(
            leading: const Icon(Icons.sms_outlined),
            title: const Text('SMS'),
            onTap: () => Navigator.pop(ctx, 'sms'),
          ),
          if (subject != null)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              onTap: () => Navigator.pop(ctx, 'email'),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  bool ok;
  switch (choice) {
    case 'whatsapp':
      ok = await MessageShare.whatsApp(text, phone: phone);
      if (!ok && context.mounted) {
        context.showSnack('Couldn’t open WhatsApp. Is it installed?',
            isError: true);
      }
      return;
    case 'sms':
      ok = await MessageShare.sms(text, phone: phone);
      if (!ok && context.mounted) {
        context.showSnack('Couldn’t open your messaging app.', isError: true);
      }
      return;
    case 'email':
      ok = await MessageShare.email(text, subject: subject ?? '');
      if (!ok && context.mounted) {
        context.showSnack('Couldn’t open your email app.', isError: true);
      }
      return;
  }
}
