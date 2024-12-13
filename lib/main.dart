import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'GroqService.dart'; // Import your new service
import 'package:flutter_dotenv/flutter_dotenv.dart';

// void main() {
//   runApp(MyApp());
// }
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await dotenv.load(fileName: ".env.local"); // Load environment variables

  final String apiKey =
      dotenv.env['groqApiKey'] ?? 'default_api_key'; // Get API key
  runApp(MyApp(apiKey: apiKey)); // Pass API key to MyApp
}

class MyApp extends StatefulWidget {
  final String apiKey;

  const MyApp({super.key, required this.apiKey});
  // const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme(bool isOn) {
    setState(() {
      _themeMode = isOn ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat App',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChatScreen(toggleTheme: _toggleTheme, apiKey: widget.apiKey),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  final String apiKey;

  const ChatScreen({Key? key, required this.toggleTheme, required this.apiKey})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final GroqChatService _groqChatService;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _groqChatService = GroqChatService(widget.apiKey);
    _groqChatService.startChat();
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add("You: ${_controller.text}");
      _isLoading = true;
    });

    String response = await _groqChatService.sendMessage(_controller.text);

    setState(() {
      _messages.add("AI: $response");
      _isLoading = false;
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your assistant'),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode),
            onPressed: () {
              widget.toggleTheme(false);
            },
          ),
          Switch(
            value: Theme.of(context).brightness == Brightness.light,
            onChanged: widget.toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.light_mode),
            onPressed: () {
              widget.toggleTheme(true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CupertinoActivityIndicator(
                radius: 15,
                color: Theme.of(context).primaryColor,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isUserMessage = message.startsWith("You:");

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.deepPurple[300] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isUserMessage ? Radius.circular(15) : Radius.zero,
            bottomRight: isUserMessage ? Radius.zero : Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUserMessage ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

// class GroqChatService {
//   // Simulating a service for sending and receiving messages from Groq (you can replace this with actual API calls)
//   Future<String> sendMessage(String message) async {
//     await Future.delayed(Duration(seconds: 1)); // Simulating a delay
//     return "This is the response from Groq for: '$message'";
//   }

//   void startChat() {
//     // Initialize or start a chat session if needed
//   }
// }
