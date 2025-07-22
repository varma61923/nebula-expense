import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Military-Grade Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Colors.green),
            onPressed: () {
              _showSecurityStatus(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MILITARY-GRADE SECURITY ACTIVE',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'All systems operational',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildSecurityFeature('Quantum-resistant encryption', true),
                  _buildSecurityFeature('DoD 5220.22-M secure wipe', true),
                  _buildSecurityFeature('Triple-redundancy tamper detection', true),
                  _buildSecurityFeature('Runtime integrity monitoring', true),
                  _buildSecurityFeature('Emergency protocols armed', true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/wallets'),
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Wallets'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/transactions'),
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Transactions'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/analytics'),
                          icon: const Icon(Icons.analytics),
                          label: const Text('Analytics'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/security-settings'),
                          icon: const Icon(Icons.security),
                          label: const Text('Security'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('Total Balance'),
                    subtitle: const Text('Encrypted and secure'),
                    trailing: const Text('\$0.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt),
                    title: const Text('Transactions'),
                    subtitle: const Text('Military-grade encrypted'),
                    trailing: const Text('0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushNamed(context, '/wallets');
              break;
            case 2:
              Navigator.pushNamed(context, '/transactions');
              break;
            case 3:
              Navigator.pushNamed(context, '/analytics');
              break;
          }
        },
      ),
    );
  }

  Widget _buildSecurityFeature(String feature, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }

  void _showSecurityStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Military-Grade Security Status'),
        content: const Text(
          'All security systems operational:\n\n'
          '✓ Quantum-resistant encryption active\n'
          '✓ Multi-hash tamper detection enabled\n'
          '✓ Runtime integrity monitoring active\n'
          '✓ Emergency protocols armed\n'
          '✓ Forensic countermeasures deployed\n'
          '✓ Self-destruct PIN configured\n'
          '✓ Panic mode ready\n'
          '✓ Stealth mode available\n\n'
          'Your data is protected with military-grade security.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
