import 'package:flutter/material.dart';

class DoctorMessagesScreen extends StatelessWidget {
  const DoctorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> _chats = [
      {
        'name': 'John Doe (Anonymous)',
        'lastMessage': 'Thank you doctor, the exercises really helped.',
        'time': '11:45 AM',
        'unread': 1,
      },
      {
        'name': 'Emily Davis',
        'lastMessage': 'Can we reschedule to next week?',
        'time': 'Yesterday',
        'unread': 0,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: ListView.separated(
        itemCount: _chats.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: theme.colorScheme.onBackground.withOpacity(0.1)),
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
              child: Icon(Icons.person, color: theme.colorScheme.secondary),
            ),
            title: Text(
              chat['name'] as String,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                chat['lastMessage'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: chat['unread'] > 0 ? theme.colorScheme.secondary : theme.colorScheme.onBackground.withOpacity(0.5),
                    fontWeight: chat['unread'] > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (chat['unread'] > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${chat['unread']}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
            onTap: () {},
          );
        },
      ),
    );
  }
}
