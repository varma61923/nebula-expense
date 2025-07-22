import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/pin_setup_screen.dart';
import '../screens/auth/pin_login_screen.dart';
import '../screens/auth/biometric_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/wallets/wallets_screen.dart';
import '../screens/wallets/wallet_detail_screen.dart';
import '../screens/wallets/add_wallet_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/transactions/transaction_detail_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/theme_settings_screen.dart';
import '../screens/settings/security_settings_screen.dart';
import '../screens/backup/backup_screen.dart';
import 'app_providers.dart';

/// Application router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = ref.read(isAuthenticatedProvider);
      final path = state.fullPath;
      
      // Allow splash screen always
      if (path == '/splash') return null;
      
      // If not authenticated, redirect to auth flow
      if (!isAuth && !path!.startsWith('/auth')) {
        return '/auth/login';
      }
      
      // If authenticated and trying to access auth, redirect to home
      if (isAuth && path!.startsWith('/auth')) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/auth',
        name: 'auth',
        redirect: (context, state) => '/auth/login',
      ),
      GoRoute(
        path: '/auth/login',
        name: 'auth_login',
        builder: (context, state) => const PinLoginScreen(),
      ),
      GoRoute(
        path: '/auth/setup',
        name: 'auth_setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/auth/biometric-setup',
        name: 'biometric_setup',
        builder: (context, state) => const BiometricSetupScreen(),
      ),
      
      // Main App Routes
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Wallets
          GoRoute(
            path: '/wallets',
            name: 'wallets',
            builder: (context, state) => const WalletsScreen(),
            routes: [
              GoRoute(
                path: '/add',
                name: 'add_wallet',
                builder: (context, state) => const AddWalletScreen(),
              ),
              GoRoute(
                path: '/:walletId',
                name: 'wallet_detail',
                builder: (context, state) {
                  final walletId = state.pathParameters['walletId']!;
                  return WalletDetailScreen(walletId: walletId);
                },
              ),
            ],
          ),
          
          // Transactions
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: '/add',
                name: 'add_transaction',
                builder: (context, state) {
                  final walletId = state.uri.queryParameters['walletId'];
                  return AddTransactionScreen(preselectedWalletId: walletId);
                },
              ),
              GoRoute(
                path: '/:transactionId',
                name: 'transaction_detail',
                builder: (context, state) {
                  final transactionId = state.pathParameters['transactionId']!;
                  return TransactionDetailScreen(transactionId: transactionId);
                },
              ),
            ],
          ),
          
          // Analytics
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          
          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: '/theme',
                name: 'theme_settings',
                builder: (context, state) => const ThemeSettingsScreen(),
              ),
              GoRoute(
                path: '/security',
                name: 'security_settings',
                builder: (context, state) => const SecuritySettingsScreen(),
              ),
              GoRoute(
                path: '/backup',
                name: 'backup_settings',
                builder: (context, state) => const BackupScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

/// Main shell with bottom navigation
class MainShell extends ConsumerWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

/// Main bottom navigation bar
class MainBottomNavigation extends ConsumerWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).fullPath;
    
    int getCurrentIndex() {
      if (currentRoute?.startsWith('/home') == true) return 0;
      if (currentRoute?.startsWith('/wallets') == true) return 1;
      if (currentRoute?.startsWith('/transactions') == true) return 2;
      if (currentRoute?.startsWith('/analytics') == true) return 3;
      if (currentRoute?.startsWith('/settings') == true) return 4;
      return 0;
    }
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: getCurrentIndex(),
        onTap: (index) {
          switch (index) {
            case 0:
              context.goNamed('home');
              break;
            case 1:
              context.goNamed('wallets');
              break;
            case 2:
              context.goNamed('transactions');
              break;
            case 3:
              context.goNamed('analytics');
              break;
            case 4:
              context.goNamed('settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Error screen for routing errors
class ErrorScreen extends StatelessWidget {
  final Exception? error;
  
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.goNamed('home');
              },
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
