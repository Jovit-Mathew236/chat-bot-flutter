import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class HuggingFaceService {
  static const String _apiBaseUrl =
      'https://api-inference.huggingface.co/models/meta-llama/Llama-3.2-1B';
  final String _apiToken;
  List<Map<String, String>> conversationHistory =
      []; // Holds the conversation history

  HuggingFaceService(this._apiToken);

  // Get response from the model based on the current conversation
  Future<String> getResponse(String message) async {
    if (message.trim().isEmpty) {
      return 'Please enter a valid message';
    }

    try {
      // Add the new user message to the conversation history
      conversationHistory.add({'role': 'user', 'content': message});

      // Build the payload with conversation history
      final payload = {
        'inputs': conversationHistory.map((entry) => entry['content']).toList(),
        'parameters': {
          'max_new_tokens': 250,
          'temperature': 0.7,
          'top_p': 0.9,
        }
      };

      // Make the API call
      final response = await http
          .post(
            Uri.parse(_apiBaseUrl),
            headers: {
              'Authorization': 'Bearer $_apiToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('API request timed out'),
          );

      // Handle the response from the model
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String botResponse = '';

        // Check for AI response
        if (data is List && data.isNotEmpty) {
          botResponse =
              data[0]['generated_text'] ?? 'No response from the model';
        } else if (data is Map) {
          botResponse = data['generated_text'] ?? 'Unexpected response format';
        }

        // Add the bot's response to the conversation history
        conversationHistory.add({'role': 'assistant', 'content': botResponse});
        return botResponse;
      } else {
        return 'Error ${response.statusCode}: ${_getErrorMessage(response.body)}';
      }
    } catch (e) {
      return 'Connection error: ${e.toString()}';
    }
  }

  // Helper to extract error messages
  String _getErrorMessage(String responseBody) {
    try {
      final errorData = jsonDecode(responseBody);
      return errorData['error'] ??
          errorData['message'] ??
          'Unknown error occurred';
    } catch (e) {
      return responseBody;
    }
  }

  // Optionally, clear the conversation history if needed
  void clearConversationHistory() {
    conversationHistory.clear();
  }
}
