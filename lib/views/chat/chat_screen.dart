import 'package:flutter/material.dart';

// Model đơn giản để đại diện cho một tin nhắn
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

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isSentByMe: true));
      // TODO: Thêm logic để nhận phản hồi từ bot/AI
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy màu chính từ theme của ứng dụng
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // CHỈNH SỬA 1: Dùng màu theme cho AppBar
        backgroundColor: themeColor,
        elevation: 1,
        // Tự động điều chỉnh màu chữ và icon trên AppBar thành màu trắng
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

  // Giao diện ban đầu với các gợi ý
  Widget _buildInitialSuggestions() {
     // ... (Không thay đổi)
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
          _buildSuggestionChip("Tạo báo cáo tồn kho"),
        ],
      ),
    );
  }

   Widget _buildSuggestionChip(String text) {
     // ... (Không thay đổi)
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
  
  // Widget cho ô nhập tin nhắn
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
            // CHỈNH SỬA 2: Dùng màu theme cho nút gửi
            icon: Icon(Icons.send, color: themeColor),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  // Widget cho mỗi bong bóng chat
  Widget _buildMessageBubble(ChatMessage message, Color themeColor) {
    final align = message.isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    // CHỈNH SỬA 3: Dùng màu theme cho bong bóng chat của người gửi
    final color = message.isSentByMe ? themeColor : Colors.grey[300];
    final textColor = message.isSentByMe ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
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