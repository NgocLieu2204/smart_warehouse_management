import 'package:flutter/material.dart';
import 'package:smart_warehouse_manager/views/chat/chat_screen.dart'; // Import màn hình chat

class FloatingChatbox extends StatefulWidget {
  final ValueNotifier<bool> isLoading;

  const FloatingChatbox({Key? key, required this.isLoading}) : super(key: key);

  @override
  _FloatingChatboxState createState() => _FloatingChatboxState();
}

class _FloatingChatboxState extends State<FloatingChatbox> {
  // Vị trí khởi đầu của chatbox
  Offset position = const Offset(20, 100); 

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.chat),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            position = details.offset;
          });
        },
        child: FloatingActionButton(
          onPressed: () {
            // >>> THAY ĐỔI CHÍNH Ở ĐÂY <<<
            // Điều hướng đến màn hình ChatScreen khi nhấn nút
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.isLoading,
            builder: (context, loading, child) {
              if (loading) {
                // Hiển thị hiệu ứng loading (3 chấm)
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                );
              }
              // Hiển thị icon chat mặc định
              return const Icon(Icons.chat, color: Colors.black);
            },
          ),
        ),
      ),
    );
  }
}