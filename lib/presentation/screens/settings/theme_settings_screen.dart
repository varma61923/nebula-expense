import 'package:flutter/material.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
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
                  Text(
                    'Futuristic Themes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Cyberpunk'),
                    subtitle: const Text('Dark neon theme'),
                    leading: const CircleAvatar(backgroundColor: Colors.purple),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text('Glassmorphic'),
                    subtitle: const Text('Translucent glass effect'),
                    leading: const CircleAvatar(backgroundColor: Colors.blue),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text('Neumorphic'),
                    subtitle: const Text('Soft UI design'),
                    leading: const CircleAvatar(backgroundColor: Colors.grey),
                    onTap: () {},
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
