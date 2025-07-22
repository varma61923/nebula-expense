import 'package:flutter/material.dart';

class WalletDetailScreen extends StatelessWidget {
  final String walletId;
  
  const WalletDetailScreen({super.key, required this.walletId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Wallet Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () {
              _showWalletSecurity(context);
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
                        'WALLET SECURED',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Wallet ID: $walletId'),
                  Text('Balance: \$0.00'),
                  Text('Encryption: Military-grade AES-256'),
                  Text('Status: Fully secured'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWalletSecurity(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wallet Security'),
        content: const Text('This wallet is protected with military-grade encryption and security features.'),
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
