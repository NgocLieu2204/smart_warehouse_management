import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatMessage {
  final String text;
  final bool isSentByMe;
  final bool isImage;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
    this.isImage = false,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;


  // Hàm gửi API
  Future<void> _sendMessageToAPI(String text) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/ask"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["need_more_info"] == true) {
          setState(() {
            _messages.insert(
              0,
              ChatMessage(
                text:
                    "🤖 Tôi cần thêm thông tin để trả lời.\n👉 ${data["suggestions"]?.join("\n👉 ") ?? "Vui lòng nhập chi tiết hơn."}",
                isSentByMe: false,
              ),
            );
          });
        } else {
          final reply = (data["response"] != null &&
                  data["response"].toString().trim().isNotEmpty)
              ? data["response"]
              : "🤖 Bot không tìm thấy câu trả lời.\n👉 Vui lòng nhập câu hỏi khác.";

          // ✅ Regex tìm link ảnh trong text
          final RegExp imgRegex =
              RegExp(r'(https?:\/\/[^\s]+\.(?:png|jpg|jpeg))');
          final matches = imgRegex.allMatches(reply);

          if (matches.isNotEmpty) {
            String replacedText = reply;
            for (var m in matches) {
              final url = m.group(0)!;
              // Thêm bubble text trước (nếu có nội dung ngoài link)
              replacedText = replacedText.replaceAll(url, "").trim();
              if (replacedText.isNotEmpty) {
                _messages.insert(
                  0,
                  ChatMessage(text: replacedText, isSentByMe: false),
                );
              }
              // Thêm bubble ảnh
              _messages.insert(
                0,
                ChatMessage(text: url, isSentByMe: false, isImage: true),
              );
            }
          } else {
            // Không có ảnh, chỉ text
            setState(() {
              _messages.insert(
                0,
                ChatMessage(text: reply, isSentByMe: false),
              );
            });
          }
        }
      } else {
        setState(() {
          _messages.insert(
              0, ChatMessage(text: "🤖 Lỗi server", isSentByMe: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.insert(
            0, ChatMessage(text: "🤖 Lỗi kết nối", isSentByMe: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isSentByMe: true));
    });

    _sendMessageToAPI(text);
  }
  @override
    void initState() {
      super.initState();
      _speech = stt.SpeechToText();
    }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print("STATUS: $val"),
        onError: (val) => print("ERROR: $val"),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
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
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (_, int index) {
                      if (_isLoading && index == 0) {
                        return _buildLoadingBubble();
                      }
                      final message = _messages[_isLoading ? index - 1 : index];
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
          const Icon(Icons.chat_bubble_outline,
              size: 60, color: Colors.black26),
          const SizedBox(height: 16),
          const Text(
            'Tôi có thể giúp gì cho bạn?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSuggestionChip("Tìm kiếm sản phẩm..."),
          _buildSuggestionChip("Tồn kho sản phẩm có SKU là DT001 ?"),
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
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.black54,
              ),
              onPressed: _listen,
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: message.isImage ? 0 : 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: message.isSentByMe
                  ? themeColor
                  : (message.isImage ? Colors.transparent : Colors.grey[300]),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: message.isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.text,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text("❌ Không tải được ảnh"),
                    ),
                  )
                : Text(
                    message.text,
                    style: TextStyle(
                        color:
                            message.isSentByMe ? Colors.white : Colors.black,
                        fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text("Đang trả lời..."),
          ],
        ),
      ),
    );
  }
}
