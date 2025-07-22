import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import '../../core/security/authentication_service.dart';
import '../../core/security/encryption_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/wallet_model.dart';
import '../../shared/models/transaction_model.dart';

// Core service providers
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden');
});

final authServiceProvider = Provider<AuthenticationService>((ref) {
  throw UnimplementedError('AuthenticationService must be overridden');
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  throw UnimplementedError('EncryptionService must be overridden');
});

// Theme providers
final currentThemeProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getSetting<String>('current_theme', AppTheme.neonNight) ?? AppTheme.neonNight;
});

final accessibilityModeProvider = StateProvider<String?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getSetting<String?>('accessibility_mode');
});

// Authentication providers
final isAuthenticatedProvider = StateProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});

final authenticationSetupProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isAuthenticationSetup();
});

final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isBiometricEnabled();
});

final stealthModeProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isStealthModeEnabled();
});

// Wallet providers
final walletsProvider = StateNotifierProvider<WalletsNotifier, List<WalletModel>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WalletsNotifier(storage);
});

final selectedWalletProvider = StateProvider<WalletModel?>((ref) => null);

final walletStatsProvider = Provider.family<WalletStats?, String>((ref, walletId) {
  final transactions = ref.watch(transactionsByWalletProvider(walletId));
  if (transactions.isEmpty) return null;
  
  return _calculateWalletStats(walletId, transactions);
});

// Transaction providers
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TransactionsNotifier(storage);
});

final transactionsByWalletProvider = Provider.family<List<TransactionModel>, String>((ref, walletId) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.where((t) => t.walletId == walletId && !t.isDeleted).toList();
});

final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final recent = transactions.where((t) => !t.isDeleted).toList();
  recent.sort((a, b) => b.date.compareTo(a.date));
  return recent.take(10).toList();
});

final transactionTemplatesProvider = StateNotifierProvider<TransactionTemplatesNotifier, List<TransactionModel>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TransactionTemplatesNotifier(storage);
});

// Filter providers
final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);
  return transactions.where((t) => filter.matches(t)).toList();
});

// Settings providers
final currencyProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getSetting<String>('default_currency', 'USD') ?? 'USD';
});

final autoLockTimeoutProvider = StateProvider<int>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getSetting<int>('auto_lock_timeout', 300) ?? 300; // 5 minutes
});

final notificationsEnabledProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getSetting<bool>('notifications_enabled', true) ?? true;
});

// Analytics providers
final totalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(walletsProvider);
  return wallets.fold(0.0, (sum, wallet) => sum + wallet.balance);
});

final monthlyExpensesProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  
  return transactions
      .where((t) => 
          t.type == TransactionType.expense && 
          t.date.isAfter(startOfMonth) && 
          !t.isDeleted)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  
  return transactions
      .where((t) => 
          t.type == TransactionType.income && 
          t.date.isAfter(startOfMonth) && 
          !t.isDeleted)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// State notifiers
class WalletsNotifier extends StateNotifier<List<WalletModel>> {
  final StorageService _storage;
  
  WalletsNotifier(this._storage) : super([]) {
    _loadWallets();
  }
  
  void _loadWallets() {
    state = _storage.getAllWallets();
  }
  
  Future<void> addWallet(WalletModel wallet) async {
    await _storage.saveWallet(wallet);
    state = [...state, wallet];
  }
  
  Future<void> updateWallet(WalletModel wallet) async {
    await _storage.saveWallet(wallet);
    state = [
      for (final w in state)
        if (w.id == wallet.id) wallet else w,
    ];
  }
  
  Future<void> deleteWallet(String walletId) async {
    await _storage.deleteWallet(walletId);
    state = state.where((w) => w.id != walletId).toList();
  }
  
  Future<void> refreshWallets() async {
    _loadWallets();
  }
}

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  final StorageService _storage;
  
  TransactionsNotifier(this._storage) : super([]) {
    _loadTransactions();
  }
  
  void _loadTransactions() {
    state = _storage.getAllTransactions();
  }
  
  Future<void> addTransaction(TransactionModel transaction) async {
    await _storage.saveTransaction(transaction);
    state = [...state, transaction];
  }
  
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _storage.saveTransaction(transaction);
    state = [
      for (final t in state)
        if (t.id == transaction.id) transaction else t,
    ];
  }
  
  Future<void> deleteTransaction(String transactionId) async {
    await _storage.deleteTransaction(transactionId);
    final transaction = state.firstWhere((t) => t.id == transactionId);
    transaction.markAsDeleted();
    state = [
      for (final t in state)
        if (t.id == transactionId) transaction else t,
    ];
  }
  
  Future<void> restoreTransaction(String transactionId) async {
    final transaction = state.firstWhere((t) => t.id == transactionId);
    transaction.restore();
    await _storage.saveTransaction(transaction);
    state = [
      for (final t in state)
        if (t.id == transactionId) transaction else t,
    ];
  }
  
  Future<void> refreshTransactions() async {
    _loadTransactions();
  }
}

class TransactionTemplatesNotifier extends StateNotifier<List<TransactionModel>> {
  final StorageService _storage;
  
  TransactionTemplatesNotifier(this._storage) : super([]) {
    _loadTemplates();
  }
  
  void _loadTemplates() {
    state = _storage.getAllTemplates();
  }
  
  Future<void> addTemplate(TransactionModel template) async {
    await _storage.saveTemplate(template);
    state = [...state, template];
  }
  
  Future<void> updateTemplate(TransactionModel template) async {
    await _storage.saveTemplate(template);
    state = [
      for (final t in state)
        if (t.id == template.id) template else t,
    ];
  }
  
  Future<void> deleteTemplate(String templateId) async {
    await _storage.deleteTemplate(templateId);
    state = state.where((t) => t.id != templateId).toList();
  }
  
  Future<void> refreshTemplates() async {
    _loadTemplates();
  }
}

// Helper functions
WalletStats _calculateWalletStats(String walletId, List<TransactionModel> transactions) {
  final income = transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
      
  final expenses = transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
      
  final categoryExpenses = <String, double>{};
  final monthlyExpenses = <String, double>{};
  
  for (final transaction in transactions.where((t) => t.type == TransactionType.expense)) {
    final category = transaction.category.toString();
    categoryExpenses[category] = (categoryExpenses[category] ?? 0) + transaction.amount;
    
    final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
    monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + transaction.amount;
  }
  
  return WalletStats(
    walletId: walletId,
    totalIncome: income,
    totalExpenses: expenses,
    currentBalance: income - expenses,
    transactionCount: transactions.length,
    lastTransactionDate: transactions.isNotEmpty 
        ? transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now(),
    categoryExpenses: categoryExpenses,
    monthlyExpenses: monthlyExpenses,
    averageTransactionAmount: transactions.isNotEmpty 
        ? transactions.fold(0.0, (sum, t) => sum + t.amount) / transactions.length
        : 0.0,
    calculatedAt: DateTime.now(),
  );
}
