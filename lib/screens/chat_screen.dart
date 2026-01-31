import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String chatTitle;
  const ChatScreen({super.key, required this.chatTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  
  // Имитация базы данных сообщений
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Привет! Кто сегодня берет новые мячи?', 'sender': 'Иван', 'isMe': false, 'time': '10:00'},
    {'text': 'Я могу заехать в Спортмастер, взять Head Pro.', 'sender': 'Вы', 'isMe': true, 'time': '10:05'},
    {'text': 'Отлично, тогда с меня оплата корта.', 'sender': 'Сергей', 'isMe': false, 'time': '10:15'},
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': _controller.text,
        'sender': 'Вы',
        'isMe': true,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      _controller.clear();
    });
    
    // Имитация ответа от "системы" или другого игрока через 2 секунды
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
           _messages.add({
            'text': 'Окей, принято!',
            'sender': 'Олег',
            'isMe': false,
            'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          });
        });
        // Тут бы мы отправили ПУШ-УВЕДОМЛЕНИЕ всем участникам
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2538),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("4 участника • онлайн", style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white70),
            tooltip: "Уведомления чата включены",
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Пуш-уведомления для этого чата включены")));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessage(msg['text'], msg['sender'], msg['isMe'], msg['time']);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, String sender, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 260),
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
            if (!isMe) Text(sender, style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1C2538),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Написать сообщение...",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                fillColor: const Color(0xFF0A0E21),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF2979FF),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20), 
              onPressed: _sendMessage
            ),
          ),
        ],
      ),
    );
  }
}