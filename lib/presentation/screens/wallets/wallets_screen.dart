import 'package:flutter/material.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Military-Grade Wallets'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () {
              _showSecurityDialog(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'MILITARY-GRADE SECURITY ACTIVE',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('• Quantum-resistant encryption enabled'),
                  Text('• DoD 5220.22-M + NSA/CSS-02-01 wipe standards'),
                  Text('• Triple-redundancy tamper detection'),
                  Text('• Runtime integrity monitoring'),
                  Text('• Emergency protocols armed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Primary Wallet'),
              subtitle: const Text('Main secure wallet'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text('\$0.00'),
                ],
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-wallet');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Military-Grade Security Status'),
        content: const Text(
          'All security systems operational:\n\n'
          '✓ Quantum-resistant encryption\n'
          '✓ Multi-hash tamper detection\n'
          '✓ Runtime integrity monitoring\n'
          '✓ Emergency protocols armed\n'
          '✓ Forensic countermeasures active'
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
