import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/security/encryption_service.dart';
import '../../core/storage/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'attachment_service.dart';

/// Comprehensive backup, export, and import service
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final StorageService _storage = StorageService();
  final EncryptionService _encryption = EncryptionService();
  final AttachmentService _attachmentService = AttachmentService();

  /// Create a full backup with all data
  Future<String> createFullBackup({
    required String password,
    bool includeAttachments = true,
    String? customPath,
  }) async {
    try {
      final backupData = await _collectAllData(includeAttachments);
      final backupJson = json.encode(backupData);
      
      // Encrypt the backup
      final encryptedData = await _encryption.encryptString(backupJson, password);
      
      // Create backup file
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'expense_tracker_backup_$timestamp.etb';
      
      final file = customPath != null 
          ? File('$customPath/$fileName')
          : await _getBackupFile(fileName);
      
      await file.writeAsBytes(encryptedData);
      
      // Save backup metadata
      await _saveBackupMetadata(BackupMetadata(
        id: timestamp,
        fileName: fileName,
        filePath: file.path,
        createdAt: DateTime.now(),
        size: encryptedData.length,
        includesAttachments: includeAttachments,
        walletCount: backupData['wallets']?.length ?? 0,
        transactionCount: backupData['transactions']?.length ?? 0,
        isEncrypted: true,
      ));
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  /// Restore from a full backup
  Future<void> restoreFromBackup({
    required String filePath,
    required String password,
    bool overwriteExisting = false,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final encryptedData = await file.readAsBytes();
      final decryptedJson = await _encryption.decryptString(encryptedData, password);
      final backupData = json.decode(decryptedJson) as Map<String, dynamic>;

      if (!overwriteExisting) {
        // Check if data exists
        final existingWallets = await _storage.getAllWallets();
        final existingTransactions = await _storage.getAllTransactions();
        
        if (existingWallets.isNotEmpty || existingTransactions.isNotEmpty) {
          throw Exception('Data already exists. Use overwriteExisting=true to replace.');
        }
      }

      await _restoreData(backupData, overwriteExisting);
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  /// Export transactions to CSV
  Future<String> exportToCSV({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    String? customPath,
  }) async {
    try {
      final transactions = await _getFilteredTransactions(
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
      );

      final csvData = _convertTransactionsToCSV(transactions);
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'transactions_export_$timestamp.csv';
      
      final file = customPath != null 
          ? File('$customPath/$fileName')
          : await _getExportFile(fileName);
      
      await file.writeAsString(csvData);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  /// Export transactions to JSON
  Future<String> exportToJSON({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeWallets = true,
    bool includeAttachments = false,
    String? customPath,
  }) async {
    try {
      final exportData = <String, dynamic>{};
      
      if (includeWallets) {
        final wallets = walletId != null 
            ? [await _storage.getWallet(walletId)].where((w) => w != null).cast<Wallet>().toList()
            : await _storage.getAllWallets();
        exportData['wallets'] = wallets.map((w) => w.toJson()).toList();
      }

      final transactions = await _getFilteredTransactions(
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
      );
      exportData['transactions'] = transactions.map((t) => t.toJson()).toList();

      if (includeAttachments) {
        final attachmentIds = transactions
            .expand((t) => t.attachmentIds)
            .toSet()
            .toList();
        
        final attachments = <Map<String, dynamic>>[];
        for (final id in attachmentIds) {
          final attachment = await _attachmentService.getAttachment(id);
          if (attachment != null) {
            attachments.add(attachment);
          }
        }
        exportData['attachments'] = attachments;
      }

      exportData['exportInfo'] = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'transactions_export_$timestamp.json';
      
      final file = customPath != null 
          ? File('$customPath/$fileName')
          : await _getExportFile(fileName);
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export JSON: $e');
    }
  }

  /// Import transactions from CSV
  Future<ImportResult> importFromCSV({
    required String filePath,
    String? targetWalletId,
    bool skipDuplicates = true,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Import file not found');
      }

      final csvContent = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvContent);
      
      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      final headers = csvData.first.map((h) => h.toString().toLowerCase()).toList();
      final transactions = <Transaction>[];
      final errors = <String>[];
      
      for (int i = 1; i < csvData.length; i++) {
        try {
          final row = csvData[i];
          final transaction = _parseCSVRow(headers, row, targetWalletId);
          
          if (skipDuplicates && await _isDuplicateTransaction(transaction)) {
            continue;
          }
          
          transactions.add(transaction);
        } catch (e) {
          errors.add('Row ${i + 1}: $e');
        }
      }

      // Save transactions
      for (final transaction in transactions) {
        await _storage.saveTransaction(transaction);
      }

      return ImportResult(
        totalRows: csvData.length - 1,
        importedCount: transactions.length,
        skippedCount: (csvData.length - 1) - transactions.length,
        errors: errors,
      );
    } catch (e) {
      throw Exception('Failed to import CSV: $e');
    }
  }

  /// Import from JSON
  Future<ImportResult> importFromJSON({
    required String filePath,
    bool skipDuplicates = true,
    bool importWallets = true,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Import file not found');
      }

      final jsonContent = await file.readAsString();
      final importData = json.decode(jsonContent) as Map<String, dynamic>;
      
      int importedWallets = 0;
      int importedTransactions = 0;
      final errors = <String>[];

      // Import wallets first
      if (importWallets && importData.containsKey('wallets')) {
        final walletsData = importData['wallets'] as List<dynamic>;
        
        for (final walletData in walletsData) {
          try {
            final wallet = Wallet.fromJson(Map<String, dynamic>.from(walletData));
            
            if (skipDuplicates && await _storage.getWallet(wallet.id) != null) {
              continue;
            }
            
            await _storage.saveWallet(wallet);
            importedWallets++;
          } catch (e) {
            errors.add('Wallet import error: $e');
          }
        }
      }

      // Import transactions
      if (importData.containsKey('transactions')) {
        final transactionsData = importData['transactions'] as List<dynamic>;
        
        for (final transactionData in transactionsData) {
          try {
            final transaction = Transaction.fromJson(Map<String, dynamic>.from(transactionData));
            
            if (skipDuplicates && await _isDuplicateTransaction(transaction)) {
              continue;
            }
            
            await _storage.saveTransaction(transaction);
            importedTransactions++;
          } catch (e) {
            errors.add('Transaction import error: $e');
          }
        }
      }

      return ImportResult(
        totalRows: (importData['wallets']?.length ?? 0) + (importData['transactions']?.length ?? 0),
        importedCount: importedWallets + importedTransactions,
        skippedCount: 0,
        errors: errors,
      );
    } catch (e) {
      throw Exception('Failed to import JSON: $e');
    }
  }

  /// Create encrypted ZIP backup
  Future<String> createEncryptedZipBackup({
    required String password,
    bool includeAttachments = true,
    String? customPath,
  }) async {
    try {
      final archive = Archive();
      
      // Add main data
      final backupData = await _collectAllData(false); // Don't include attachment data in JSON
      final backupJson = const JsonEncoder.withIndent('  ').convert(backupData);
      final dataFile = ArchiveFile('data.json', backupJson.length, backupJson.codeUnits);
      archive.addFile(dataFile);

      // Add attachments if requested
      if (includeAttachments) {
        final attachments = await _attachmentService.getAllAttachments();
        
        for (final attachment in attachments) {
          try {
            final attachmentData = await _attachmentService.getAttachmentData(attachment['id']);
            if (attachmentData != null) {
              final fileName = 'attachments/${attachment['id']}_${attachment['fileName']}';
              final file = ArchiveFile(fileName, attachmentData.length, attachmentData);
              archive.addFile(file);
            }
          } catch (e) {
            // Skip failed attachments
            continue;
          }
        }
      }

      // Compress and encrypt
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('Failed to create ZIP archive');
      }

      final encryptedData = await _encryption.encryptBytes(Uint8List.fromList(zipData), password);
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'expense_tracker_backup_$timestamp.zip.enc';
      
      final file = customPath != null 
          ? File('$customPath/$fileName')
          : await _getBackupFile(fileName);
      
      await file.writeAsBytes(encryptedData);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to create encrypted ZIP backup: $e');
    }
  }

  /// Get all backup metadata
  Future<List<BackupMetadata>> getAllBackups() async {
    final backupsData = _storage.getSetting<List<dynamic>>('backup_metadata') ?? [];
    return backupsData
        .map((data) => BackupMetadata.fromJson(Map<String, dynamic>.from(data)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Delete backup
  Future<void> deleteBackup(String backupId) async {
    final backups = await getAllBackups();
    final backup = backups.firstWhere((b) => b.id == backupId);
    
    // Delete file
    final file = File(backup.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Remove from metadata
    backups.removeWhere((b) => b.id == backupId);
    await _storage.saveSetting(
      'backup_metadata',
      backups.map((b) => b.toJson()).toList(),
    );
  }

  /// Verify backup integrity
  Future<bool> verifyBackup({
    required String filePath,
    required String password,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final encryptedData = await file.readAsBytes();
      final decryptedJson = await _encryption.decryptString(encryptedData, password);
      final backupData = json.decode(decryptedJson) as Map<String, dynamic>;

      // Basic validation
      return backupData.containsKey('wallets') && 
             backupData.containsKey('transactions') &&
             backupData.containsKey('backupInfo');
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  Future<Map<String, dynamic>> _collectAllData(bool includeAttachments) async {
    final wallets = await _storage.getAllWallets();
    final transactions = await _storage.getAllTransactions();
    final templates = await _storage.getAllTemplates();
    final categories = await _storage.getAllCategories();
    final tags = await _storage.getAllTags();
    
    final data = <String, dynamic>{
      'backupInfo': {
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'includesAttachments': includeAttachments,
      },
      'wallets': wallets.map((w) => w.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'templates': templates.map((t) => t.toJson()).toList(),
      'categories': categories,
      'tags': tags,
      'settings': _storage.getAllSettings(),
    };

    if (includeAttachments) {
      final attachments = await _attachmentService.getAllAttachments();
      data['attachments'] = attachments;
    }

    return data;
  }

  Future<void> _restoreData(Map<String, dynamic> backupData, bool overwrite) async {
    if (overwrite) {
      await _storage.clearAllData();
    }

    // Restore wallets
    if (backupData.containsKey('wallets')) {
      final walletsData = backupData['wallets'] as List<dynamic>;
      for (final walletData in walletsData) {
        final wallet = Wallet.fromJson(Map<String, dynamic>.from(walletData));
        await _storage.saveWallet(wallet);
      }
    }

    // Restore transactions
    if (backupData.containsKey('transactions')) {
      final transactionsData = backupData['transactions'] as List<dynamic>;
      for (final transactionData in transactionsData) {
        final transaction = Transaction.fromJson(Map<String, dynamic>.from(transactionData));
        await _storage.saveTransaction(transaction);
      }
    }

    // Restore other data...
    if (backupData.containsKey('settings')) {
      final settings = Map<String, dynamic>.from(backupData['settings']);
      for (final entry in settings.entries) {
        await _storage.saveSetting(entry.key, entry.value);
      }
    }
  }

  Future<List<Transaction>> _getFilteredTransactions({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var transactions = await _storage.getAllTransactions();

    if (walletId != null) {
      transactions = transactions.where((t) => t.walletId == walletId).toList();
    }

    if (startDate != null) {
      transactions = transactions.where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)).toList();
    }

    if (endDate != null) {
      transactions = transactions.where((t) => t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate)).toList();
    }

    return transactions;
  }

  String _convertTransactionsToCSV(List<Transaction> transactions) {
    final headers = [
      'ID', 'Date', 'Type', 'Amount', 'Currency', 'Category', 'Subcategory',
      'Description', 'Notes', 'Merchant', 'Payment Method', 'Tags', 'Location',
      'Wallet ID', 'Is Reconciled', 'Is Recurring'
    ];

    final rows = transactions.map((t) => [
      t.id,
      t.date.toIso8601String(),
      t.type.toString(),
      t.amount,
      t.currency,
      t.category,
      t.subcategory ?? '',
      t.description,
      t.notes ?? '',
      t.merchant ?? '',
      t.paymentMethod ?? '',
      t.tags.join(';'),
      t.location ?? '',
      t.walletId,
      t.isReconciled,
      t.isRecurring,
    ]).toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  Transaction _parseCSVRow(List<String> headers, List<dynamic> row, String? targetWalletId) {
    final data = <String, dynamic>{};
    
    for (int i = 0; i < headers.length && i < row.length; i++) {
      data[headers[i]] = row[i];
    }

    return Transaction(
      id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      walletId: targetWalletId ?? data['wallet id']?.toString() ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
      currency: data['currency']?.toString() ?? 'USD',
      category: data['category']?.toString() ?? 'Other',
      subcategory: data['subcategory']?.toString(),
      description: data['description']?.toString() ?? '',
      notes: data['notes']?.toString(),
      merchant: data['merchant']?.toString(),
      paymentMethod: data['payment method']?.toString(),
      tags: data['tags']?.toString().split(';').where((t) => t.isNotEmpty).toList() ?? [],
      location: data['location']?.toString(),
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      isReconciled: data['is reconciled']?.toString().toLowerCase() == 'true',
      isRecurring: data['is recurring']?.toString().toLowerCase() == 'true',
      attachmentIds: [],
      customFields: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<bool> _isDuplicateTransaction(Transaction transaction) async {
    final existing = await _storage.getTransaction(transaction.id);
    return existing != null;
  }

  Future<File> _getBackupFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return File('${backupDir.path}/$fileName');
  }

  Future<File> _getExportFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return File('${exportDir.path}/$fileName');
  }

  Future<void> _saveBackupMetadata(BackupMetadata metadata) async {
    final backups = await getAllBackups();
    backups.removeWhere((b) => b.id == metadata.id);
    backups.insert(0, metadata);
    
    // Keep only last 50 backups
    if (backups.length > 50) {
      backups.removeRange(50, backups.length);
    }
    
    await _storage.saveSetting(
      'backup_metadata',
      backups.map((b) => b.toJson()).toList(),
    );
  }
}

/// Backup metadata model
class BackupMetadata {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int size;
  final bool includesAttachments;
  final int walletCount;
  final int transactionCount;
  final bool isEncrypted;

  const BackupMetadata({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.size,
    required this.includesAttachments,
    required this.walletCount,
    required this.transactionCount,
    required this.isEncrypted,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'createdAt': createdAt.toIso8601String(),
        'size': size,
        'includesAttachments': includesAttachments,
        'walletCount': walletCount,
        'transactionCount': transactionCount,
        'isEncrypted': isEncrypted,
      };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
        id: json['id'],
        fileName: json['fileName'],
        filePath: json['filePath'],
        createdAt: DateTime.parse(json['createdAt']),
        size: json['size'],
        includesAttachments: json['includesAttachments'],
        walletCount: json['walletCount'],
        transactionCount: json['transactionCount'],
        isEncrypted: json['isEncrypted'],
      );
}

/// Import result model
class ImportResult {
  final int totalRows;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;

  const ImportResult({
    required this.totalRows,
    required this.importedCount,
    required this.skippedCount,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => importedCount > 0 && errors.isEmpty;
}
