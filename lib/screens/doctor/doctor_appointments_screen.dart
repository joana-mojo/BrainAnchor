import 'package:flutter/material.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Dummy Calendar View stub
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
                    Text(
                      'April 2026',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                    final isToday = day == 'Wed';
                    return Column(
                      children: [
                        Text(
                          day,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isToday ? theme.colorScheme.primary : theme.colorScheme.onBackground.withOpacity(0.5),
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isToday ? theme.colorScheme.primary : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            ['13', '14', '15', '16', '17', '18', '19'][['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(day)],
                            style: TextStyle(
                              color: isToday ? Colors.white : theme.colorScheme.onBackground,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Appointment List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AppointmentTile(
                  name: 'John Doe (Anonymous)',
                  time: '10:00 AM - 11:00 AM',
                  type: 'First Consultation',
                  status: 'Upcoming',
                ),
                _AppointmentTile(
                  name: 'Emily Davis',
                  time: '1:30 PM - 2:30 PM',
                  type: 'Follow-up Session',
                  status: 'Upcoming',
                ),
                _AppointmentTile(
                  name: 'Michael Smith',
                  time: '4:00 PM - 5:00 PM',
                  type: 'Therapy Session',
                  status: 'Upcoming',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final String name;
  final String time;
  final String type;
  final String status;

  const _AppointmentTile({
    required this.name,
    required this.time,
    required this.type,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.background,
                  child: Icon(Icons.person, color: theme.colorScheme.onBackground.withOpacity(0.5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        type,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
