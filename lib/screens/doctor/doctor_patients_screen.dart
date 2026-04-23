import 'package:flutter/material.dart';

class DoctorPatientsScreen extends StatelessWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> _patients = [
      {'name': 'John Doe', 'isAnonymous': true, 'lastSession': 'Today, 10:00 AM'},
      {'name': 'Emily Davis', 'isAnonymous': false, 'lastSession': '2 Days Ago'},
      {'name': 'Michael Smith', 'isAnonymous': false, 'lastSession': 'Last Week'},
      {'name': 'Jane (Anonymous)', 'isAnonymous': true, 'lastSession': '1 Month Ago'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _patients.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final patient = _patients[index];
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.onBackground.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  patient['isAnonymous'] ? Icons.privacy_tip : Icons.person,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                patient['name'] as String,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Last session: ${patient['lastSession']}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                // View specific secure info
              },
            ),
          );
        },
      ),
    );
  }
}
