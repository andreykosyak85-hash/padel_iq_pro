import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String chatTitle;
  const ChatScreen({super.key, required this.chatTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2538),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chatTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("онлайн: 4 игрока", style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMessage("Привет! Кто сегодня берет новые мячи?", "Иван", false),
                _buildMessage("Я могу заехать в Спортмастер, взять Head Pro.", "Андрей (Ты)", true),
                _buildMessage("Отлично, тогда с меня оплата корта.", "Сергей", false),
                _buildMessage("Ребята, не опаздывайте, разминка в 18:50!", "Иван", false),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, String sender, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2979FF) : const Color(0xFF1C2538),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe) Text(sender, style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1C2538),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Написать сообщение...",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                fillColor: const Color(0xFF0A0E21),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF2979FF),
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () {}),
          ),
        ],
      ),
    );
  }
}