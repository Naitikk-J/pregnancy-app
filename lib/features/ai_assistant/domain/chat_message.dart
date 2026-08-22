import 'package:equatable/equatable.dart';

/// Who authored a chat turn.
enum ChatRole { user, assistant }

/// A single message in an AI-assistant conversation. Held in memory for the
/// session — chat history is intentionally not persisted to Firestore.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.pending = false,
    this.isError = false,
  });

  final String id;
  final ChatRole role;
  final String text;

  /// True while the assistant reply is still being fetched (typing indicator).
  final bool pending;

  /// True when this assistant turn represents a delivery failure.
  final bool isError;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? text, bool? pending, bool? isError}) =>
      ChatMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        pending: pending ?? this.pending,
        isError: isError ?? this.isError,
      );

  @override
  List<Object?> get props => [id, role, text, pending, isError];
}
