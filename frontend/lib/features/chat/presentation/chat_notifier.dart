import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isThinking;

  ChatState({this.messages = const [], this.isThinking = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isThinking}) {
    return ChatState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState()) {
    _addInitialMessage();
  }

  void _addInitialMessage() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          text: 'Hello! How can I assist you with your interaction today?',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          suggestions: [
            'Start Healthcare interaction',
            'Start Finance interaction',
          ],
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final userMessage = ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isThinking: true,
    );

    // Simulate AI response
    await Future.delayed(const Duration(seconds: 1));

    final aiMessage = ChatMessage(
      text:
          'I understood that you want to "$text". Could you provide more details?',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      suggestions: ['Add Symptoms', 'Confirm Identity', 'Finish Interaction'],
    );
    state = state.copyWith(
      messages: [...state.messages, aiMessage],
      isThinking: false,
    );
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((
  ref,
) {
  return ChatNotifier();
});
