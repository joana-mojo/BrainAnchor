import 'package:flutter/material.dart';

class HealthVaultScreen extends StatefulWidget {
  const HealthVaultScreen({super.key});

  @override
  State<HealthVaultScreen> createState() => _HealthVaultScreenState();
}

class _HealthVaultScreenState extends State<HealthVaultScreen> {
  final List<String> _categories = ['All', 'Prescriptions', 'Notes', 'Reports'];
  String _selectedCategory = 'All';

  // Dummy static data
  final List<Map<String, dynamic>> _documents = [
    {
      'name': 'Therapy_Session_Notes_01.pdf',
      'type': 'Notes',
      'date': 'Oct 12, 2026',
    },
    {
      'name': 'Dr_Smith_Prescription.pdf',
      'type': 'Prescriptions',
      'date': 'Oct 05, 2026',
    },
    {
      'name': 'Monthly_Mood_Report.pdf',
      'type': 'Reports',
      'date': 'Oct 01, 2026',
    },
  ];

  // Toggle this to true to see the empty state
  final bool _isEmpty = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Map<String, dynamic>> filteredDocs = _selectedCategory == 'All'
        ? _documents
        : _documents.where((d) => d['type'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Health Vault'),
            const SizedBox(width: 8),
            Icon(Icons.lock, size: 18, color: theme.colorScheme.primary),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Security Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your data is end-to-end encrypted and accessible only by you.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Upload Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    // Mock file picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening file picker...')),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.primary.withOpacity(0.05),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload Document',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, JPG, PNG',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 14, color: theme.colorScheme.onBackground.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'Encrypted before upload',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Categories Tabs
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onBackground.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onBackground,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Document List or Empty State
          Expanded(
            child: _isEmpty || filteredDocs.isEmpty
                ? _buildEmptyState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildDocumentCard(theme, filteredDocs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Icon(Icons.folder_open_outlined, size: 80, color: theme.colorScheme.secondary),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock, color: theme.colorScheme.primary, size: 30),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No records yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your first document securely.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(ThemeData theme, Map<String, dynamic> doc) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              doc['type'] == 'Prescriptions'
                  ? Icons.medication_outlined
                  : doc['type'] == 'Reports'
                      ? Icons.analytics_outlined
                      : Icons.description_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['name'],
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.lock, size: 12, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${doc['type']} • ${doc['date']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onBackground.withOpacity(0.6)),
            onSelected: (value) {},
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [Icon(Icons.visibility_outlined, size: 20), SizedBox(width: 8), Text('View')],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [Icon(Icons.download_outlined, size: 20), SizedBox(width: 8), Text('Download')],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
