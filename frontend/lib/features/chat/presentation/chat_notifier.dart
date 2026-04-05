import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
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
  final ApiClient _apiClient;

  ChatNotifier(this._apiClient) : super(ChatState()) {
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

    // Real AI response from Python backend
    final aiAnswer = await _apiClient.askAssistant("Rahul", "Dr. Smith", text);

    final aiMessage = ChatMessage(
      text: aiAnswer,
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

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatNotifier(apiClient);
});
