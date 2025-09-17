
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: const [
                  _ReceivedMessage(
                    text: 'Hi I am in the vicinity',
                  ),
                  SizedBox(height: 12),
                  _SentMessage(
                    text: 'When will you reach',
                  ),
                  SizedBox(height: 12),
                  _ReceivedMessage(
                    text: 'where are you',
                  ),
                ],
              ),
            ),
            // Message input field
            _MessageInputField(),
          ],
        ),
      ),
    );
  }
}

// Widget for a sent message bubble (right side)
class _SentMessage extends StatelessWidget {
  final String text;
  const _SentMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C5E4A), // Dark green
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

// Widget for a received message bubble (left side)
class _ReceivedMessage extends StatelessWidget {
  final String text;
  const _ReceivedMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with online indicator
        Stack(
          children: [
             CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person_outline, color: Colors.black),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        // Message bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// Widget for the text input field at the bottom
class _MessageInputField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Dark grey
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.grey),
            onPressed: () { /* Handle add button press */ },
          ),
          const Expanded(
            child: TextField(
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'When will you reach',
                hintStyle: TextStyle(color: Colors.black),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.grey),
            onPressed: () { /* Handle send button press */ },
          ),
        ],
      ),
    );
  }
}
