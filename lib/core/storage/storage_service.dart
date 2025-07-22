import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../security/encryption_service.dart';
import '../../shared/models/wallet_model.dart';
import '../../shared/models/transaction_model.dart';

/// Comprehensive encrypted storage service using Hive
class StorageService {
  static const String _walletsBoxName = 'wallets';
  static const String _transactionsBoxName = 'transactions';
  static const String _settingsBoxName = 'settings';
  static const String _templatesBoxName = 'templates';
  static const String _categoriesBoxName = 'categories';
  static const String _tagsBoxName = 'tags';
  static const String _attachmentsBoxName = 'attachments';
  static const String _backupsBoxName = 'backups';

  late final EncryptionService _encryptionService;
  late final Box<WalletModel> _walletsBox;
  late final Box<TransactionModel> _transactionsBox;
  late final Box<dynamic> _settingsBox;
  late final Box<TransactionModel> _templatesBox;
  late final Box<String> _categoriesBox;
  late final Box<String> _tagsBox;
  late final Box<String> _attachmentsBox;
  late final Box<Map<String, dynamic>> _backupsBox;

  bool _isInitialized = false;

  /// Initialize the storage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      _registerAdapters();

      // Initialize encryption service
      _encryptionService = EncryptionService();
      await _encryptionService.initialize();

      // Get encryption key for Hive boxes
      final encryptionKey = await _getHiveEncryptionKey();

      // Open encrypted boxes
      _walletsBox = await Hive.openBox<WalletModel>(
        _walletsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _transactionsBox = await Hive.openBox<TransactionModel>(
        _transactionsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _settingsBox = await Hive.openBox<dynamic>(
        _settingsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _templatesBox = await Hive.openBox<TransactionModel>(
        _templatesBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _categoriesBox = await Hive.openBox<String>(
        _categoriesBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _tagsBox = await Hive.openBox<String>(
        _tagsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _attachmentsBox = await Hive.openBox<String>(
        _attachmentsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _backupsBox = await Hive.openBox<Map<String, dynamic>>(
        _backupsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _isInitialized = true;
    } catch (e) {
      throw StorageException('Failed to initialize storage service: $e');
    }
  }

  /// Register Hive type adapters
  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WalletModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WalletStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(RecurrencePatternAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(RecurrenceTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(WalletModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(TransactionCategoryAdapter());
    }
  }

  /// Get encryption key for Hive boxes
  Future<List<int>> _getHiveEncryptionKey() async {
    // Use a derived key from the encryption service
    final deviceId = _encryptionService.deviceId;
    final keyString = await _encryptionService.encrypt('hive_key_$deviceId');
    return keyString.codeUnits.take(32).toList();
  }

  // Wallet operations

  /// Save a wallet
  Future<void> saveWallet(WalletModel wallet) async {
    _ensureInitialized();
    try {
      await _walletsBox.put(wallet.id, wallet);
    } catch (e) {
      throw StorageException('Failed to save wallet: $e');
    }
  }

  /// Get a wallet by ID
  WalletModel? getWallet(String id) {
    _ensureInitialized();
    return _walletsBox.get(id);
  }

  /// Get all wallets
  List<WalletModel> getAllWallets({bool includeHidden = false, bool includeArchived = false}) {
    _ensureInitialized();
    final wallets = _walletsBox.values.toList();
    
    return wallets.where((wallet) {
      if (!includeHidden && wallet.isHidden) return false;
      if (!includeArchived && wallet.isArchived) return false;
      return true;
    }).toList();
  }

  /// Delete a wallet
  Future<void> deleteWallet(String id) async {
    _ensureInitialized();
    try {
      await _walletsBox.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete wallet: $e');
    }
  }

  /// Get wallets by type
  List<WalletModel> getWalletsByType(WalletType type) {
    _ensureInitialized();
    return _walletsBox.values.where((wallet) => wallet.type == type).toList();
  }

  // Transaction operations

  /// Save a transaction
  Future<void> saveTransaction(TransactionModel transaction) async {
    _ensureInitialized();
    try {
      await _transactionsBox.put(transaction.id, transaction);
      
      // Update wallet balance
      await _updateWalletBalance(transaction);
      
      // Add tags to global tags collection
      for (final tag in transaction.tags) {
        await _addTag(tag);
      }
    } catch (e) {
      throw StorageException('Failed to save transaction: $e');
    }
  }

  /// Get a transaction by ID
  TransactionModel? getTransaction(String id) {
    _ensureInitialized();
    return _transactionsBox.get(id);
  }

  /// Get all transactions
  List<TransactionModel> getAllTransactions({bool includeDeleted = false}) {
    _ensureInitialized();
    final transactions = _transactionsBox.values.toList();
    
    if (!includeDeleted) {
      return transactions.where((transaction) => !transaction.isDeleted).toList();
    }
    
    return transactions;
  }

  /// Get transactions by wallet
  List<TransactionModel> getTransactionsByWallet(String walletId, {bool includeDeleted = false}) {
    _ensureInitialized();
    final transactions = _transactionsBox.values.where((transaction) {
      if (!includeDeleted && transaction.isDeleted) return false;
      return transaction.walletId == walletId || transaction.toWalletId == walletId;
    }).toList();
    
    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Get transactions by filter
  List<TransactionModel> getTransactionsByFilter(TransactionFilter filter) {
    _ensureInitialized();
    final transactions = _transactionsBox.values.where((transaction) {
      return filter.matches(transaction);
    }).toList();
    
    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    _ensureInitialized();
    try {
      final transaction = _transactionsBox.get(id);
      if (transaction != null) {
        // Soft delete
        transaction.markAsDeleted();
        await _transactionsBox.put(id, transaction);
        
        // Update wallet balance
        await _updateWalletBalance(transaction, isDelete: true);
      }
    } catch (e) {
      throw StorageException('Failed to delete transaction: $e');
    }
  }

  /// Permanently delete a transaction
  Future<void> permanentlyDeleteTransaction(String id) async {
    _ensureInitialized();
    try {
      await _transactionsBox.delete(id);
    } catch (e) {
      throw StorageException('Failed to permanently delete transaction: $e');
    }
  }

  /// Update wallet balance based on transaction
  Future<void> _updateWalletBalance(TransactionModel transaction, {bool isDelete = false}) async {
    final wallet = getWallet(transaction.walletId);
    if (wallet == null) return;

    double balanceChange = transaction.signedAmount;
    if (isDelete) balanceChange = -balanceChange;

    wallet.updateBalance(wallet.balance + balanceChange);
    await saveWallet(wallet);

    // Handle transfers
    if (transaction.isTransfer && transaction.toWalletId != null) {
      final toWallet = getWallet(transaction.toWalletId!);
      if (toWallet != null) {
        double toBalanceChange = transaction.amount;
        if (isDelete) toBalanceChange = -toBalanceChange;
        
        toWallet.updateBalance(toWallet.balance + toBalanceChange);
        await saveWallet(toWallet);
      }
    }
  }

  // Template operations

  /// Save a transaction template
  Future<void> saveTemplate(TransactionModel template) async {
    _ensureInitialized();
    try {
      await _templatesBox.put(template.id, template);
    } catch (e) {
      throw StorageException('Failed to save template: $e');
    }
  }

  /// Get all templates
  List<TransactionModel> getAllTemplates() {
    _ensureInitialized();
    return _templatesBox.values.toList();
  }

  /// Delete a template
  Future<void> deleteTemplate(String id) async {
    _ensureInitialized();
    try {
      await _templatesBox.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete template: $e');
    }
  }

  // Settings operations

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      throw StorageException('Failed to save setting: $e');
    }
  }

  /// Get a setting
  T? getSetting<T>(String key, [T? defaultValue]) {
    _ensureInitialized();
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    _ensureInitialized();
    try {
      await _settingsBox.delete(key);
    } catch (e) {
      throw StorageException('Failed to delete setting: $e');
    }
  }

  // Tag operations

  /// Add a tag
  Future<void> _addTag(String tag) async {
    if (!_tagsBox.containsKey(tag)) {
      await _tagsBox.put(tag, tag);
    }
  }

  /// Get all tags
  List<String> getAllTags() {
    _ensureInitialized();
    return _tagsBox.values.toList();
  }

  /// Delete a tag
  Future<void> deleteTag(String tag) async {
    _ensureInitialized();
    try {
      await _tagsBox.delete(tag);
    } catch (e) {
      throw StorageException('Failed to delete tag: $e');
    }
  }

  // Attachment operations

  /// Save attachment path
  Future<void> saveAttachment(String id, String filePath) async {
    _ensureInitialized();
    try {
      await _attachmentsBox.put(id, filePath);
    } catch (e) {
      throw StorageException('Failed to save attachment: $e');
    }
  }

  /// Get attachment path
  String? getAttachment(String id) {
    _ensureInitialized();
    return _attachmentsBox.get(id);
  }

  /// Delete attachment
  Future<void> deleteAttachment(String id) async {
    _ensureInitialized();
    try {
      final filePath = _attachmentsBox.get(id);
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _attachmentsBox.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete attachment: $e');
    }
  }

  // Backup operations

  /// Create backup
  Future<Map<String, dynamic>> createBackup() async {
    _ensureInitialized();
    
    try {
      final backup = {
        'version': AppConstants.appVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'wallets': _walletsBox.values.map((w) => w.toJson()).toList(),
        'transactions': _transactionsBox.values.map((t) => t.toJson()).toList(),
        'templates': _templatesBox.values.map((t) => t.toJson()).toList(),
        'settings': Map<String, dynamic>.from(_settingsBox.toMap()),
        'tags': _tagsBox.values.toList(),
      };
      
      // Save backup to backups box
      final backupId = DateTime.now().millisecondsSinceEpoch.toString();
      await _backupsBox.put(backupId, backup);
      
      return backup;
    } catch (e) {
      throw StorageException('Failed to create backup: $e');
    }
  }

  /// Restore from backup
  Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    _ensureInitialized();
    
    try {
      // Clear existing data
      await _walletsBox.clear();
      await _transactionsBox.clear();
      await _templatesBox.clear();
      await _settingsBox.clear();
      await _tagsBox.clear();
      
      // Restore wallets
      if (backup['wallets'] != null) {
        for (final walletJson in backup['wallets']) {
          final wallet = WalletModel.fromJson(walletJson);
          await _walletsBox.put(wallet.id, wallet);
        }
      }
      
      // Restore transactions
      if (backup['transactions'] != null) {
        for (final transactionJson in backup['transactions']) {
          final transaction = TransactionModel.fromJson(transactionJson);
          await _transactionsBox.put(transaction.id, transaction);
        }
      }
      
      // Restore templates
      if (backup['templates'] != null) {
        for (final templateJson in backup['templates']) {
          final template = TransactionModel.fromJson(templateJson);
          await _templatesBox.put(template.id, template);
        }
      }
      
      // Restore settings
      if (backup['settings'] != null) {
        for (final entry in backup['settings'].entries) {
          await _settingsBox.put(entry.key, entry.value);
        }
      }
      
      // Restore tags
      if (backup['tags'] != null) {
        for (final tag in backup['tags']) {
          await _tagsBox.put(tag, tag);
        }
      }
    } catch (e) {
      throw StorageException('Failed to restore from backup: $e');
    }
  }

  /// Get all backups
  List<Map<String, dynamic>> getAllBackups() {
    _ensureInitialized();
    return _backupsBox.values.toList();
  }

  /// Delete backup
  Future<void> deleteBackup(String backupId) async {
    _ensureInitialized();
    try {
      await _backupsBox.delete(backupId);
    } catch (e) {
      throw StorageException('Failed to delete backup: $e');
    }
  }

  // Utility methods

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    _ensureInitialized();
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/hive');
      
      if (!await hiveDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in hiveDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Compact database
  Future<void> compactDatabase() async {
    _ensureInitialized();
    
    try {
      await _walletsBox.compact();
      await _transactionsBox.compact();
      await _settingsBox.compact();
      await _templatesBox.compact();
      await _categoriesBox.compact();
      await _tagsBox.compact();
      await _attachmentsBox.compact();
      await _backupsBox.compact();
    } catch (e) {
      throw StorageException('Failed to compact database: $e');
    }
  }

  /// Secure wipe of all data
  Future<void> secureWipe() async {
    _ensureInitialized();
    
    try {
      // Clear all boxes
      await _walletsBox.clear();
      await _transactionsBox.clear();
      await _settingsBox.clear();
      await _templatesBox.clear();
      await _categoriesBox.clear();
      await _tagsBox.clear();
      await _attachmentsBox.clear();
      await _backupsBox.clear();
      
      // Close all boxes
      await _walletsBox.close();
      await _transactionsBox.close();
      await _settingsBox.close();
      await _templatesBox.close();
      await _categoriesBox.close();
      await _tagsBox.close();
      await _attachmentsBox.close();
      await _backupsBox.close();
      
      // Delete Hive directory
      await Hive.deleteFromDisk();
      
      _isInitialized = false;
    } catch (e) {
      throw StorageException('Failed to perform secure wipe: $e');
    }
  }

  /// Check if storage is initialized
  bool get isInitialized => _isInitialized;

  /// Ensure storage is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StorageException('Storage service not initialized');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _walletsBox.close();
      await _transactionsBox.close();
      await _settingsBox.close();
      await _templatesBox.close();
      await _categoriesBox.close();
      await _tagsBox.close();
      await _attachmentsBox.close();
      await _backupsBox.close();
      _isInitialized = false;
    }
  }
}

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;
  
  const StorageException(this.message);
  
  @override
  String toString() => 'StorageException: $message';
}
