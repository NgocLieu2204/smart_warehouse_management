import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isSentByMe;

  ChatMessage({required this.text, required this.isSentByMe});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];

  // Hàm gửi API
  // Hàm gửi API
Future<void> _sendMessageToAPI(String text) async {
  try {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/ask"), // gửi đến ai_agent
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Nếu không có key response thì fallback
      final reply = (data["response"] != null && data["response"].toString().trim().isNotEmpty)
          ? data["response"]
          : "🤖 Bot không tìm thấy câu trả lời";

      setState(() {
        _messages.insert(0, ChatMessage(text: reply, isSentByMe: false));
      });
    } else {
      // Trường hợp lỗi server
      setState(() {
        _messages.insert(0, ChatMessage(text: "🤖 Lỗi server", isSentByMe: false));
      });
    }
  } catch (e) {
    // Trường hợp lỗi kết nối hoặc exception khác
    setState(() {
      _messages.insert(0, ChatMessage(text: "🤖 Lỗi kết nối", isSentByMe: false));
    });
  }
}



  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isSentByMe: true));
    });

    // Gửi API sau khi gửi tin nhắn
    _sendMessageToAPI(text);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 1,
        title: const Text('Chat AI Agent'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _messages.isEmpty
                ? _buildInitialSuggestions()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (_, int index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, themeColor);
                    },
                  ),
          ),
          _buildTextComposer(themeColor),
        ],
      ),
    );
  }

  Widget _buildInitialSuggestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.black26),
          const SizedBox(height: 16),
          const Text(
            'Tôi có thể giúp gì cho bạn?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSuggestionChip("Tìm kiếm sản phẩm..."),
          _buildSuggestionChip("Giao dịch gần nhất do student01 thực hiện?"),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ActionChip(
        label: Text(text),
        onPressed: () => _handleSubmitted(text),
        backgroundColor: Colors.grey[200],
        labelStyle: const TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildTextComposer(Color themeColor) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black54),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng tạo ảnh (Demo).')),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: "Hỏi AI Agent...",
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: themeColor),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Color themeColor) {
    final align =
        message.isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isSentByMe ? themeColor : Colors.grey[300];
    final textColor = message.isSentByMe ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
