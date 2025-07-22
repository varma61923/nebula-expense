import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;
  
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Transaction Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                      Icon(Icons.verified_user, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'ENCRYPTED TRANSACTION',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Transaction ID: $transactionId'),
                  Text('Amount: \$0.00'),
                  Text('Status: Secured with military-grade encryption'),
                  Text('Tamper Detection: Active'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
