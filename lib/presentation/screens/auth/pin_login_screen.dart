import 'package:flutter/material.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'MILITARY-GRADE SECURITY',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your secure PIN',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // PIN Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length 
                          ? Colors.green 
                          : Colors.grey.withOpacity(0.3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              
              // Keypad
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) {
                    return _buildKeypadButton('', () {});
                  } else if (index == 10) {
                    return _buildKeypadButton('0', () => _addDigit('0'));
                  } else if (index == 11) {
                    return _buildKeypadButton('⌫', () => _removeDigit(), isBackspace: true);
                  } else {
                    final digit = (index + 1).toString();
                    return _buildKeypadButton(digit, () => _addDigit(digit));
                  }
                },
              ),
              const SizedBox(height: 24),
              
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pin.length == 6 ? _authenticate : null,
                      icon: const Icon(Icons.login),
                      label: const Text('Authenticate'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        _showSecurityOptions(context);
                      },
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Use Biometrics'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String text, VoidCallback onPressed, {bool isBackspace = false}) {
    return ElevatedButton(
      onPressed: text.isEmpty ? null : onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
      ),
      child: text.isEmpty 
          ? null 
          : Text(
              text,
              style: TextStyle(
                fontSize: isBackspace ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  void _addDigit(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
      });
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _authenticate() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate authentication
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showSecurityOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Options'),
        content: const Text(
          'Military-grade security options:\n\n'
          '• Biometric authentication\n'
          '• Self-destruct PIN\n'
          '• Panic mode activation\n'
          '• Decoy PIN mode\n'
          '• Emergency protocols'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Demo Mode'),
          ),
        ],
      ),
    );
  }
}
