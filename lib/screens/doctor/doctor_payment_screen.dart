import 'package:flutter/material.dart';

class DoctorPaymentScreen extends StatelessWidget {
  const DoctorPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dummy Transaction Data
    final List<Map<String, dynamic>> transactions = [
      {'patient': 'John Doe', 'date': 'Oct 21, 2026', 'amount': 'PHP 1,500', 'status': 'Completed'},
      {'patient': 'Jane Smith', 'date': 'Oct 20, 2026', 'amount': 'PHP 1,500', 'status': 'Pending'},
      {'patient': 'Alex Johnson', 'date': 'Oct 18, 2026', 'amount': 'PHP 1,500', 'status': 'Completed'},
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Payment & Earnings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your income and payout methods',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // A. Earnings Overview (Financial Dashboard Style)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary.withOpacity(0.9), theme.colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('PHP 24,500.00', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricColumn(theme, 'Pending', 'PHP 1,500.00'),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildMetricColumn(theme, 'Completed', '32 Sessions'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing Withdrawal...')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Withdraw Funds', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // B. Payment Methods
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Payment Methods', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                 TextButton.icon(
                   onPressed: () {},
                   icon: const Icon(Icons.add, size: 18),
                   label: const Text('Add New'),
                 ),
               ],
            ),
            const SizedBox(height: 8),
            _buildPayoutMethodCard(theme, 'GCash', '0917 •••• 1234', Icons.account_balance_wallet_outlined),
            const SizedBox(height: 12),
            _buildPayoutMethodCard(theme, 'BDO Bank Transfer', '•••• •••• 9876', Icons.account_balance_outlined),
            const SizedBox(height: 32),

            // C. Transaction History
            Text('Recent Transactions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...transactions.map((tx) => _buildTransactionItem(theme, tx)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(ThemeData theme, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPayoutMethodCard(ThemeData theme, String name, String details, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onBackground.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(details, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.6))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onBackground.withOpacity(0.6)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(ThemeData theme, Map<String, dynamic> tx) {
    final isCompleted = tx['status'] == 'Completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCompleted ? Colors.green.shade50 : Colors.amber.shade50,
            child: Icon(
              isCompleted ? Icons.check : Icons.access_time, 
              color: isCompleted ? Colors.green : Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['patient'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(tx['date'], style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.6))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tx['amount'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                tx['status'], 
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green : Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
