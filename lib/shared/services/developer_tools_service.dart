import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/storage/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'backup_service.dart';
import 'versioning_service.dart';

/// Developer tools and offline DevTools panel service
class DeveloperToolsService {
  static final DeveloperToolsService _instance = DeveloperToolsService._internal();
  factory DeveloperToolsService() => _instance;
  DeveloperToolsService._internal();

  final StorageService _storage = StorageService();
  final BackupService _backupService = BackupService();
  final VersioningService _versioningService = VersioningService();

  bool _isEnabled = false;
  final List<DevLog> _logs = [];
  final List<PerformanceMetric> _performanceMetrics = [];
  DateTime? _sessionStartTime;

  /// Initialize developer tools
  Future<void> initialize() async {
    if (kDebugMode) {
      _isEnabled = true;
      _sessionStartTime = DateTime.now();
      await _loadDevSettings();
      _startPerformanceMonitoring();
    }
  }

  /// Check if developer tools are enabled
  bool get isEnabled => _isEnabled && kDebugMode;

  /// Enable developer tools (debug mode only)
  void enable() {
    if (kDebugMode) {
      _isEnabled = true;
      _sessionStartTime = DateTime.now();
    }
  }

  /// Disable developer tools
  void disable() {
    _isEnabled = false;
  }

  /// Log debug information
  void log(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? data}) {
    if (!isEnabled) return;

    final logEntry = DevLog(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      data: data,
      stackTrace: level == LogLevel.error ? StackTrace.current.toString() : null,
    );

    _logs.add(logEntry);
    
    // Keep only last 1000 logs
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }

    // Print to console in debug mode
    if (kDebugMode) {
      print('[${level.name.toUpperCase()}] ${DateTime.now()}: $message');
      if (data != null) {
        print('Data: ${json.encode(data)}');
      }
    }
  }

  /// Record performance metric
  void recordPerformance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    if (!isEnabled) return;

    final metric = PerformanceMetric(
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _performanceMetrics.add(metric);
    
    // Keep only last 500 metrics
    if (_performanceMetrics.length > 500) {
      _performanceMetrics.removeAt(0);
    }

    // Log slow operations
    if (duration.inMilliseconds > 1000) {
      log('Slow operation detected: $operation took ${duration.inMilliseconds}ms', 
          level: LogLevel.warning, data: metadata);
    }
  }

  /// Generate sample data for testing
  Future<void> generateSampleData({
    int walletCount = 3,
    int transactionsPerWallet = 50,
    int daysBack = 90,
  }) async {
    if (!isEnabled) return;

    log('Generating sample data: $walletCount wallets, $transactionsPerWallet transactions each');

    final random = Random();
    final categories = ['Food', 'Transport', 'Entertainment', 'Shopping', 'Bills', 'Healthcare', 'Education'];
    final merchants = ['Store A', 'Restaurant B', 'Gas Station C', 'Online Shop D', 'Pharmacy E'];
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD'];

    // Generate wallets
    for (int i = 0; i < walletCount; i++) {
      final wallet = Wallet(
        id: 'sample_wallet_$i',
        name: 'Sample Wallet ${i + 1}',
        description: 'Generated sample wallet for testing',
        currency: currencies[random.nextInt(currencies.length)],
        balance: random.nextDouble() * 5000,
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: daysBack)),
        updatedAt: DateTime.now(),
        tags: ['sample', 'test'],
      );

      await _storage.saveWallet(wallet);

      // Generate transactions for this wallet
      for (int j = 0; j < transactionsPerWallet; j++) {
        final daysAgo = random.nextInt(daysBack);
        final transaction = Transaction(
          id: 'sample_transaction_${i}_$j',
          walletId: wallet.id,
          type: random.nextBool() ? TransactionType.expense : TransactionType.income,
          amount: random.nextDouble() * 500 + 10,
          currency: wallet.currency,
          category: categories[random.nextInt(categories.length)],
          description: 'Sample transaction ${j + 1}',
          notes: random.nextBool() ? 'Generated sample note' : null,
          merchant: random.nextBool() ? merchants[random.nextInt(merchants.length)] : null,
          tags: random.nextBool() ? ['sample'] : [],
          date: DateTime.now().subtract(Duration(days: daysAgo)),
          isReconciled: random.nextBool(),
          attachmentIds: [],
          customFields: {},
          createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
          updatedAt: DateTime.now(),
        );

        await _storage.saveTransaction(transaction);
      }
    }

    log('Sample data generation completed');
  }

  /// Clear all sample data
  Future<void> clearSampleData() async {
    if (!isEnabled) return;

    log('Clearing sample data');

    final wallets = await _storage.getAllWallets();
    final transactions = await _storage.getAllTransactions();

    // Remove sample wallets and their transactions
    for (final wallet in wallets) {
      if (wallet.tags.contains('sample')) {
        await _storage.deleteWallet(wallet.id);
      }
    }

    for (final transaction in transactions) {
      if (transaction.id.startsWith('sample_')) {
        await _storage.deleteTransaction(transaction.id);
      }
    }

    log('Sample data cleared');
  }

  /// Get system information
  Future<SystemInfo> getSystemInfo() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();
    
    return SystemInfo(
      platform: Platform.operatingSystem,
      version: Platform.operatingSystemVersion,
      appDirectory: appDir.path,
      tempDirectory: tempDir.path,
      sessionDuration: _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!)
          : Duration.zero,
      memoryUsage: await _getMemoryUsage(),
      storageUsage: await _getStorageUsage(),
      isDebugMode: kDebugMode,
      isProfileMode: kProfileMode,
      isReleaseMode: kReleaseMode,
    );
  }

  /// Get database statistics
  Future<DatabaseStats> getDatabaseStats() async {
    final wallets = await _storage.getAllWallets();
    final transactions = await _storage.getAllTransactions();
    final templates = await _storage.getAllTemplates();

    final transactionsByType = <TransactionType, int>{};
    final transactionsByCategory = <String, int>{};
    var totalAmount = 0.0;

    for (final transaction in transactions) {
      transactionsByType[transaction.type] = 
          (transactionsByType[transaction.type] ?? 0) + 1;
      transactionsByCategory[transaction.category] = 
          (transactionsByCategory[transaction.category] ?? 0) + 1;
      totalAmount += transaction.amount;
    }

    return DatabaseStats(
      walletCount: wallets.length,
      transactionCount: transactions.length,
      templateCount: templates.length,
      transactionsByType: transactionsByType,
      transactionsByCategory: transactionsByCategory,
      totalTransactionAmount: totalAmount,
      averageTransactionAmount: transactions.isNotEmpty ? totalAmount / transactions.length : 0.0,
      oldestTransaction: transactions.isNotEmpty 
          ? transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      newestTransaction: transactions.isNotEmpty 
          ? transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    );
  }

  /// Export debug logs
  Future<String> exportDebugLogs() async {
    if (!isEnabled) throw Exception('Developer tools not enabled');

    final logsData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'sessionStart': _sessionStartTime?.toIso8601String(),
      'logs': _logs.map((log) => log.toJson()).toList(),
      'performanceMetrics': _performanceMetrics.map((metric) => metric.toJson()).toList(),
      'systemInfo': (await getSystemInfo()).toJson(),
      'databaseStats': (await getDatabaseStats()).toJson(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(logsData);
    
    final appDir = await getApplicationDocumentsDirectory();
    final debugDir = Directory('${appDir.path}/debug');
    if (!await debugDir.exists()) {
      await debugDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${debugDir.path}/debug_logs_$timestamp.json');
    await file.writeAsString(jsonString);

    log('Debug logs exported to: ${file.path}');
    return file.path;
  }

  /// Run database integrity check
  Future<IntegrityCheckResult> runIntegrityCheck() async {
    if (!isEnabled) throw Exception('Developer tools not enabled');

    log('Running database integrity check');

    final issues = <String>[];
    final warnings = <String>[];

    try {
      // Check wallet integrity
      final wallets = await _storage.getAllWallets();
      final walletIds = wallets.map((w) => w.id).toSet();

      // Check transaction integrity
      final transactions = await _storage.getAllTransactions();
      
      for (final transaction in transactions) {
        // Check if wallet exists
        if (!walletIds.contains(transaction.walletId)) {
          issues.add('Transaction ${transaction.id} references non-existent wallet ${transaction.walletId}');
        }

        // Check data consistency
        if (transaction.amount < 0) {
          issues.add('Transaction ${transaction.id} has negative amount');
        }

        if (transaction.createdAt.isAfter(transaction.updatedAt)) {
          warnings.add('Transaction ${transaction.id} has createdAt after updatedAt');
        }
      }

      // Check for duplicate IDs
      final transactionIds = transactions.map((t) => t.id).toList();
      final uniqueTransactionIds = transactionIds.toSet();
      if (transactionIds.length != uniqueTransactionIds.length) {
        issues.add('Duplicate transaction IDs found');
      }

      // Check wallet balances (simplified check)
      for (final wallet in wallets) {
        final walletTransactions = transactions.where((t) => t.walletId == wallet.id).toList();
        var calculatedBalance = 0.0;
        
        for (final transaction in walletTransactions) {
          if (transaction.type == TransactionType.income) {
            calculatedBalance += transaction.amount;
          } else if (transaction.type == TransactionType.expense) {
            calculatedBalance -= transaction.amount;
          }
        }

        final difference = (wallet.balance - calculatedBalance).abs();
        if (difference > 0.01) {
          warnings.add('Wallet ${wallet.id} balance mismatch: stored=${wallet.balance}, calculated=$calculatedBalance');
        }
      }

    } catch (e) {
      issues.add('Error during integrity check: $e');
    }

    final result = IntegrityCheckResult(
      isHealthy: issues.isEmpty,
      issues: issues,
      warnings: warnings,
      checkedAt: DateTime.now(),
    );

    log('Integrity check completed: ${issues.length} issues, ${warnings.length} warnings');
    return result;
  }

  /// Get performance analytics
  PerformanceAnalytics getPerformanceAnalytics() {
    if (!isEnabled) throw Exception('Developer tools not enabled');

    final operationStats = <String, OperationStats>{};
    
    for (final metric in _performanceMetrics) {
      if (!operationStats.containsKey(metric.operation)) {
        operationStats[metric.operation] = OperationStats(
          operation: metric.operation,
          count: 0,
          totalDuration: Duration.zero,
          minDuration: metric.duration,
          maxDuration: metric.duration,
        );
      }

      final stats = operationStats[metric.operation]!;
      operationStats[metric.operation] = OperationStats(
        operation: stats.operation,
        count: stats.count + 1,
        totalDuration: stats.totalDuration + metric.duration,
        minDuration: metric.duration < stats.minDuration ? metric.duration : stats.minDuration,
        maxDuration: metric.duration > stats.maxDuration ? metric.duration : stats.maxDuration,
      );
    }

    return PerformanceAnalytics(
      totalOperations: _performanceMetrics.length,
      operationStats: operationStats,
      sessionDuration: _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!)
          : Duration.zero,
    );
  }

  /// Clear logs and metrics
  void clearLogs() {
    if (!isEnabled) return;
    
    _logs.clear();
    _performanceMetrics.clear();
    log('Logs and metrics cleared');
  }

  /// Get recent logs
  List<DevLog> getRecentLogs({int limit = 100, LogLevel? level}) {
    if (!isEnabled) return [];

    var logs = _logs;
    
    if (level != null) {
      logs = logs.where((log) => log.level == level).toList();
    }

    return logs.reversed.take(limit).toList();
  }

  /// Create development snapshot
  Future<String> createDevSnapshot() async {
    if (!isEnabled) throw Exception('Developer tools not enabled');

    final snapshotId = await _versioningService.createSnapshot(
      name: 'Dev Snapshot ${DateTime.now().toIso8601String()}',
      description: 'Development snapshot created via DevTools',
    );

    log('Development snapshot created: $snapshotId');
    return snapshotId;
  }

  /// Simulate app crash for testing
  void simulateCrash() {
    if (!isEnabled) return;
    
    log('Simulating app crash', level: LogLevel.error);
    throw Exception('Simulated crash for testing purposes');
  }

  // Helper methods
  Future<void> _loadDevSettings() async {
    // Load any developer-specific settings
    final settings = _storage.getSetting<Map<String, dynamic>>('dev_settings') ?? {};
    
    // Apply settings if any
    log('Developer tools initialized with settings: $settings');
  }

  void _startPerformanceMonitoring() {
    // Start monitoring system performance
    log('Performance monitoring started');
  }

  Future<int> _getMemoryUsage() async {
    // This is a simplified implementation
    // In a real app, you'd use platform-specific APIs
    return 0;
  }

  Future<int> _getStorageUsage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      return await _calculateDirectorySize(appDir);
    } catch (e) {
      return 0;
    }
  }

  Future<int> _calculateDirectorySize(Directory directory) async {
    var totalSize = 0;
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      // Handle permission errors, etc.
    }
    
    return totalSize;
  }
}

/// Log level enum
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Development log entry
class DevLog {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? data;
  final String? stackTrace;

  const DevLog({
    required this.timestamp,
    required this.level,
    required this.message,
    this.data,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'message': message,
        'data': data,
        'stackTrace': stackTrace,
      };
}

/// Performance metric
class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'operation': operation,
        'duration': duration.inMilliseconds,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };
}

/// System information
class SystemInfo {
  final String platform;
  final String version;
  final String appDirectory;
  final String tempDirectory;
  final Duration sessionDuration;
  final int memoryUsage;
  final int storageUsage;
  final bool isDebugMode;
  final bool isProfileMode;
  final bool isReleaseMode;

  const SystemInfo({
    required this.platform,
    required this.version,
    required this.appDirectory,
    required this.tempDirectory,
    required this.sessionDuration,
    required this.memoryUsage,
    required this.storageUsage,
    required this.isDebugMode,
    required this.isProfileMode,
    required this.isReleaseMode,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'version': version,
        'appDirectory': appDirectory,
        'tempDirectory': tempDirectory,
        'sessionDuration': sessionDuration.inMilliseconds,
        'memoryUsage': memoryUsage,
        'storageUsage': storageUsage,
        'isDebugMode': isDebugMode,
        'isProfileMode': isProfileMode,
        'isReleaseMode': isReleaseMode,
      };
}

/// Database statistics
class DatabaseStats {
  final int walletCount;
  final int transactionCount;
  final int templateCount;
  final Map<TransactionType, int> transactionsByType;
  final Map<String, int> transactionsByCategory;
  final double totalTransactionAmount;
  final double averageTransactionAmount;
  final DateTime? oldestTransaction;
  final DateTime? newestTransaction;

  const DatabaseStats({
    required this.walletCount,
    required this.transactionCount,
    required this.templateCount,
    required this.transactionsByType,
    required this.transactionsByCategory,
    required this.totalTransactionAmount,
    required this.averageTransactionAmount,
    this.oldestTransaction,
    this.newestTransaction,
  });

  Map<String, dynamic> toJson() => {
        'walletCount': walletCount,
        'transactionCount': transactionCount,
        'templateCount': templateCount,
        'transactionsByType': transactionsByType.map((k, v) => MapEntry(k.name, v)),
        'transactionsByCategory': transactionsByCategory,
        'totalTransactionAmount': totalTransactionAmount,
        'averageTransactionAmount': averageTransactionAmount,
        'oldestTransaction': oldestTransaction?.toIso8601String(),
        'newestTransaction': newestTransaction?.toIso8601String(),
      };
}

/// Integrity check result
class IntegrityCheckResult {
  final bool isHealthy;
  final List<String> issues;
  final List<String> warnings;
  final DateTime checkedAt;

  const IntegrityCheckResult({
    required this.isHealthy,
    required this.issues,
    required this.warnings,
    required this.checkedAt,
  });
}

/// Operation statistics
class OperationStats {
  final String operation;
  final int count;
  final Duration totalDuration;
  final Duration minDuration;
  final Duration maxDuration;

  const OperationStats({
    required this.operation,
    required this.count,
    required this.totalDuration,
    required this.minDuration,
    required this.maxDuration,
  });

  Duration get averageDuration => Duration(
        milliseconds: count > 0 ? totalDuration.inMilliseconds ~/ count : 0,
      );
}

/// Performance analytics
class PerformanceAnalytics {
  final int totalOperations;
  final Map<String, OperationStats> operationStats;
  final Duration sessionDuration;

  const PerformanceAnalytics({
    required this.totalOperations,
    required this.operationStats,
    required this.sessionDuration,
  });
}
