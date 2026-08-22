import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/chat_message.dart';
import 'ai_providers.dart';

/// Conversational AI assistant ("Mira"). Answers general pregnancy questions
/// via a server-side Claude proxy — educational only, never medical advice.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  static const _suggestions = [
    'What foods should I avoid this trimester?',
    'Is it normal to feel tired all the time?',
    'Safe exercises for me right now?',
    'How can I ease morning sickness?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _input.clear();
    await ref.read(chatControllerProvider.notifier).send(text);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatControllerProvider);
    final busy = messages.any((m) => m.pending);
    ref.listen(chatControllerProvider, (_, __) => _scrollToEnd());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Mira'),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(chatControllerProvider.notifier).reset(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _Bubble(message: messages[i]),
                  ),
          ),
          _Disclaimer(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: busy ? null : _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about your pregnancy…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: busy ? null : () => _send(_input.text),
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

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onPick});
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(Icons.auto_awesome,
            size: 56, color: context.colors.primary),
        const SizedBox(height: AppSpacing.md),
        Text('Hi, I’m Mira 👋',
            textAlign: TextAlign.center,
            style: context.textStyles.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your caring pregnancy companion. Ask me anything — I’ll share '
          'general guidance, but always check with your doctor for medical '
          'decisions.',
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final s in _AiAssistantScreenState._suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => onPick(s),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 18, color: context.colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(s, style: context.textStyles.bodyMedium)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bg = isUser
        ? context.colors.primary
        : message.isError
            ? context.colors.errorContainer
            : context.colors.surfaceContainerHighest;
    final fg = isUser
        ? context.colors.onPrimary
        : message.isError
            ? context.colors.onErrorContainer
            : context.colors.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.78),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: message.pending
            ? const _Typing()
            : SelectableText(message.text,
                style: context.textStyles.bodyMedium?.copyWith(color: fg)),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Mira is typing…',
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Text(
        'Mira gives general information, not medical advice. For any concern, '
        'contact your doctor.',
        textAlign: TextAlign.center,
        style: context.textStyles.labelSmall
            ?.copyWith(color: context.colors.onSurfaceVariant),
      ),
    );
  }
}
