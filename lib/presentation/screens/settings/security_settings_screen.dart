import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricsEnabled = false;
  bool _stealthModeEnabled = false;
  bool _tamperDetectionEnabled = false;
  bool _panicModeEnabled = false;
  bool _selfDestructEnabled = false;
  bool _decoyModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
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
                    'Advanced Security Features',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Biometric Authentication'),
                    subtitle: const Text('Use fingerprint or face recognition'),
                    value: _biometricsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricsEnabled = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Stealth Mode'),
                    subtitle: const Text('Hide sensitive information'),
                    value: _stealthModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _stealthModeEnabled = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Tamper Detection'),
                    subtitle: const Text('Detect app integrity violations'),
                    value: _tamperDetectionEnabled,
                    onChanged: (value) {
                      setState(() {
                        _tamperDetectionEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Features',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Panic Mode'),
                    subtitle: const Text('Quick emergency actions'),
                    value: _panicModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _panicModeEnabled = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Self-Destruct PIN'),
                    subtitle: const Text('Secure data wipe with PIN'),
                    value: _selfDestructEnabled,
                    onChanged: (value) {
                      setState(() {
                        _selfDestructEnabled = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Decoy Mode'),
                    subtitle: const Text('Show fake data when needed'),
                    value: _decoyModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _decoyModeEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Actions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showSetupDialog('Setup Self-Destruct PIN');
                    },
                    icon: const Icon(Icons.warning),
                    label: const Text('Setup Self-Destruct'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showSetupDialog('Setup Panic Mode');
                    },
                    icon: const Icon(Icons.emergency),
                    label: const Text('Setup Panic Mode'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showSetupDialog('Setup Decoy Mode');
                    },
                    icon: const Icon(Icons.visibility_off),
                    label: const Text('Setup Decoy Mode'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetupDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This feature is ready for configuration. Advanced security setup will be available in the production version.'),
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
