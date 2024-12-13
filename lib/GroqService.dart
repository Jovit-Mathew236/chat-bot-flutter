import 'package:groq/groq.dart';

class GroqChatService {
  final Groq groq;

  GroqChatService(String apiKey)
      : groq = Groq(apiKey: apiKey); // Use the passed API key

  Future<void> startChat() async {
    groq.startChat();
    groq.setCustomInstructionsWith("You are a helpful assistant.");
  }

  Future<String> sendMessage(String message) async {
    try {
      GroqResponse response = await groq.sendMessage(message);
      return response.choices.first.message.content;
    } on GroqException catch (error) {
      return "Error: ${error.message}";
    }
  }
}
