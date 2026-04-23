import 'package:flutter/material.dart';

class PatientAiCheckerScreen extends StatefulWidget {
  const PatientAiCheckerScreen({super.key});

  @override
  State<PatientAiCheckerScreen> createState() => _PatientAiCheckerScreenState();
}

class _PatientAiCheckerScreenState extends State<PatientAiCheckerScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'text': 'Hello! I am BrainAnchor AI. How have you been feeling lately? Are you experiencing any particular stress or anxiety?'
    },
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add({'isBot': false, 'text': _controller.text.trim()});
      _controller.clear();
    });

    // Simulate bot response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          'isBot': true,
          'text': 'I understand. Thank you for sharing. Could you tell me more about how this affects your sleep or daily routine?'
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Symptom Check'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isBot = message['isBot'] as bool;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isBot) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          child: Icon(Icons.psychology, size: 20, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isBot ? theme.colorScheme.surface : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomLeft: isBot ? const Radius.circular(0) : const Radius.circular(20),
                              bottomRight: !isBot ? const Radius.circular(0) : const Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            message['text'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isBot ? theme.colorScheme.onBackground : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (!isBot) const SizedBox(width: 24), // Offset for user messages
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
