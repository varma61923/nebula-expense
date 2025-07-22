import 'dart:convert';
import 'dart:math';
import '../../core/storage/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

/// Data versioning, audit logs, and snapshot/rollback service
class VersioningService {
  static final VersioningService _instance = VersioningService._internal();
  factory VersioningService() => _instance;
  VersioningService._internal();

  final StorageService _storage = StorageService();
  static const int maxAuditLogs = 10000;
  static const int maxSnapshots = 50;

  /// Log an audit entry
  Future<void> logAudit({
    required AuditAction action,
    required String entityType,
    required String entityId,
    String? description,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? userId,
  }) async {
    final auditLog = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      entityType: entityType,
      entityId: entityId,
      description: description,
      oldData: oldData,
      newData: newData,
      userId: userId ?? 'system',
      timestamp: DateTime.now(),
      ipAddress: null, // Not applicable for offline app
      userAgent: null, // Not applicable for offline app
    );

    await _saveAuditLog(auditLog);
  }

  /// Get audit logs with filtering
  Future<List<AuditLog>> getAuditLogs({
    String? entityType,
    String? entityId,
    AuditAction? action,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    int limit = 100,
    int offset = 0,
  }) async {
    final allLogs = await _getAllAuditLogs();
    
    var filteredLogs = allLogs.where((log) {
      if (entityType != null && log.entityType != entityType) return false;
      if (entityId != null && log.entityId != entityId) return false;
      if (action != null && log.action != action) return false;
      if (userId != null && log.userId != userId) return false;
      if (startDate != null && log.timestamp.isBefore(startDate)) return false;
      if (endDate != null && log.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();

    // Sort by timestamp (newest first)
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply pagination
    final startIndex = offset;
    final endIndex = min(startIndex + limit, filteredLogs.length);
    
    return filteredLogs.sublist(startIndex, endIndex);
  }

  /// Create a data snapshot
  Future<String> createSnapshot({
    required String name,
    String? description,
    bool includeAttachments = false,
  }) async {
    try {
      final snapshotId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Collect all data
      final wallets = await _storage.getAllWallets();
      final transactions = await _storage.getAllTransactions();
      final templates = await _storage.getAllTemplates();
      final categories = await _storage.getAllCategories();
      final tags = await _storage.getAllTags();
      final settings = _storage.getAllSettings();

      final snapshotData = {
        'wallets': wallets.map((w) => w.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'templates': templates.map((t) => t.toJson()).toList(),
        'categories': categories,
        'tags': tags,
        'settings': settings,
      };

      final snapshot = DataSnapshot(
        id: snapshotId,
        name: name,
        description: description,
        createdAt: DateTime.now(),
        dataSize: json.encode(snapshotData).length,
        walletCount: wallets.length,
        transactionCount: transactions.length,
        includesAttachments: includeAttachments,
        checksum: _calculateChecksum(snapshotData),
      );

      // Save snapshot metadata
      await _saveSnapshot(snapshot, snapshotData);
      
      // Log audit entry
      await logAudit(
        action: AuditAction.create,
        entityType: 'snapshot',
        entityId: snapshotId,
        description: 'Created snapshot: $name',
      );

      return snapshotId;
    } catch (e) {
      throw Exception('Failed to create snapshot: $e');
    }
  }

  /// Restore from a snapshot
  Future<void> restoreFromSnapshot({
    required String snapshotId,
    bool createBackupBeforeRestore = true,
  }) async {
    try {
      final snapshot = await _getSnapshot(snapshotId);
      if (snapshot == null) {
        throw Exception('Snapshot not found');
      }

      // Create backup before restore if requested
      if (createBackupBeforeRestore) {
        await createSnapshot(
          name: 'Auto-backup before restore',
          description: 'Automatic backup created before restoring snapshot: ${snapshot.name}',
        );
      }

      final snapshotData = await _getSnapshotData(snapshotId);
      if (snapshotData == null) {
        throw Exception('Snapshot data not found');
      }

      // Verify checksum
      final currentChecksum = _calculateChecksum(snapshotData);
      if (currentChecksum != snapshot.checksum) {
        throw Exception('Snapshot data integrity check failed');
      }

      // Clear existing data
      await _storage.clearAllData();

      // Restore data
      await _restoreSnapshotData(snapshotData);

      // Log audit entry
      await logAudit(
        action: AuditAction.restore,
        entityType: 'snapshot',
        entityId: snapshotId,
        description: 'Restored from snapshot: ${snapshot.name}',
      );
    } catch (e) {
      throw Exception('Failed to restore snapshot: $e');
    }
  }

  /// Get all snapshots
  Future<List<DataSnapshot>> getAllSnapshots() async {
    final snapshotsData = _storage.getSetting<List<dynamic>>('data_snapshots') ?? [];
    final snapshots = snapshotsData
        .map((data) => DataSnapshot.fromJson(Map<String, dynamic>.from(data)))
        .toList();
    
    // Sort by creation date (newest first)
    snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return snapshots;
  }

  /// Delete a snapshot
  Future<void> deleteSnapshot(String snapshotId) async {
    final snapshots = await getAllSnapshots();
    snapshots.removeWhere((s) => s.id == snapshotId);
    
    await _storage.saveSetting(
      'data_snapshots',
      snapshots.map((s) => s.toJson()).toList(),
    );

    // Delete snapshot data
    await _storage.deleteSetting('snapshot_data_$snapshotId');

    // Log audit entry
    await logAudit(
      action: AuditAction.delete,
      entityType: 'snapshot',
      entityId: snapshotId,
      description: 'Deleted snapshot',
    );
  }

  /// Compare two snapshots
  Future<SnapshotComparison> compareSnapshots({
    required String snapshot1Id,
    required String snapshot2Id,
  }) async {
    final snapshot1 = await _getSnapshot(snapshot1Id);
    final snapshot2 = await _getSnapshot(snapshot2Id);
    
    if (snapshot1 == null || snapshot2 == null) {
      throw Exception('One or both snapshots not found');
    }

    final data1 = await _getSnapshotData(snapshot1Id);
    final data2 = await _getSnapshotData(snapshot2Id);
    
    if (data1 == null || data2 == null) {
      throw Exception('Snapshot data not found');
    }

    return SnapshotComparison(
      snapshot1: snapshot1,
      snapshot2: snapshot2,
      walletChanges: _compareWallets(data1['wallets'], data2['wallets']),
      transactionChanges: _compareTransactions(data1['transactions'], data2['transactions']),
      settingChanges: _compareSettings(data1['settings'], data2['settings']),
    );
  }

  /// Get entity change history
  Future<List<AuditLog>> getEntityHistory({
    required String entityType,
    required String entityId,
    int limit = 50,
  }) async {
    return await getAuditLogs(
      entityType: entityType,
      entityId: entityId,
      limit: limit,
    );
  }

  /// Get audit statistics
  Future<AuditStatistics> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await getAuditLogs(
      startDate: startDate,
      endDate: endDate,
      limit: maxAuditLogs,
    );

    final actionCounts = <AuditAction, int>{};
    final entityTypeCounts = <String, int>{};
    final dailyActivity = <String, int>{};

    for (final log in logs) {
      actionCounts[log.action] = (actionCounts[log.action] ?? 0) + 1;
      entityTypeCounts[log.entityType] = (entityTypeCounts[log.entityType] ?? 0) + 1;
      
      final dateKey = '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
      dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
    }

    return AuditStatistics(
      totalLogs: logs.length,
      actionCounts: actionCounts,
      entityTypeCounts: entityTypeCounts,
      dailyActivity: dailyActivity,
      dateRange: logs.isNotEmpty 
          ? DateRange(
              start: logs.last.timestamp,
              end: logs.first.timestamp,
            )
          : null,
    );
  }

  /// Clean up old audit logs
  Future<void> cleanupAuditLogs({
    Duration? olderThan,
    int? keepLatest,
  }) async {
    final allLogs = await _getAllAuditLogs();
    var logsToKeep = allLogs;

    if (olderThan != null) {
      final cutoffDate = DateTime.now().subtract(olderThan);
      logsToKeep = logsToKeep.where((log) => log.timestamp.isAfter(cutoffDate)).toList();
    }

    if (keepLatest != null && logsToKeep.length > keepLatest) {
      logsToKeep.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      logsToKeep = logsToKeep.take(keepLatest).toList();
    }

    await _storage.saveSetting(
      'audit_logs',
      logsToKeep.map((log) => log.toJson()).toList(),
    );
  }

  /// Clean up old snapshots
  Future<void> cleanupSnapshots({
    Duration? olderThan,
    int? keepLatest,
  }) async {
    final allSnapshots = await getAllSnapshots();
    var snapshotsToDelete = <DataSnapshot>[];

    if (olderThan != null) {
      final cutoffDate = DateTime.now().subtract(olderThan);
      snapshotsToDelete.addAll(
        allSnapshots.where((snapshot) => snapshot.createdAt.isBefore(cutoffDate))
      );
    }

    if (keepLatest != null && allSnapshots.length > keepLatest) {
      allSnapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      snapshotsToDelete.addAll(allSnapshots.skip(keepLatest));
    }

    for (final snapshot in snapshotsToDelete) {
      await deleteSnapshot(snapshot.id);
    }
  }

  // Helper methods
  Future<void> _saveAuditLog(AuditLog auditLog) async {
    final logs = await _getAllAuditLogs();
    logs.insert(0, auditLog);

    // Keep only the latest logs
    if (logs.length > maxAuditLogs) {
      logs.removeRange(maxAuditLogs, logs.length);
    }

    await _storage.saveSetting(
      'audit_logs',
      logs.map((log) => log.toJson()).toList(),
    );
  }

  Future<List<AuditLog>> _getAllAuditLogs() async {
    final logsData = _storage.getSetting<List<dynamic>>('audit_logs') ?? [];
    return logsData
        .map((data) => AuditLog.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  Future<void> _saveSnapshot(DataSnapshot snapshot, Map<String, dynamic> data) async {
    final snapshots = await getAllSnapshots();
    snapshots.removeWhere((s) => s.id == snapshot.id);
    snapshots.insert(0, snapshot);

    // Keep only the latest snapshots
    if (snapshots.length > maxSnapshots) {
      final toDelete = snapshots.skip(maxSnapshots).toList();
      for (final old in toDelete) {
        await _storage.deleteSetting('snapshot_data_${old.id}');
      }
      snapshots.removeRange(maxSnapshots, snapshots.length);
    }

    await _storage.saveSetting(
      'data_snapshots',
      snapshots.map((s) => s.toJson()).toList(),
    );

    // Save snapshot data separately
    await _storage.saveSetting('snapshot_data_${snapshot.id}', data);
  }

  Future<DataSnapshot?> _getSnapshot(String snapshotId) async {
    final snapshots = await getAllSnapshots();
    try {
      return snapshots.firstWhere((s) => s.id == snapshotId);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getSnapshotData(String snapshotId) async {
    final data = _storage.getSetting<Map<String, dynamic>>('snapshot_data_$snapshotId');
    return data;
  }

  String _calculateChecksum(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    return jsonString.hashCode.toString();
  }

  Future<void> _restoreSnapshotData(Map<String, dynamic> data) async {
    // Restore wallets
    if (data.containsKey('wallets')) {
      final walletsData = data['wallets'] as List<dynamic>;
      for (final walletData in walletsData) {
        final wallet = Wallet.fromJson(Map<String, dynamic>.from(walletData));
        await _storage.saveWallet(wallet);
      }
    }

    // Restore transactions
    if (data.containsKey('transactions')) {
      final transactionsData = data['transactions'] as List<dynamic>;
      for (final transactionData in transactionsData) {
        final transaction = Transaction.fromJson(Map<String, dynamic>.from(transactionData));
        await _storage.saveTransaction(transaction);
      }
    }

    // Restore settings
    if (data.containsKey('settings')) {
      final settings = Map<String, dynamic>.from(data['settings']);
      for (final entry in settings.entries) {
        await _storage.saveSetting(entry.key, entry.value);
      }
    }
  }

  Map<String, dynamic> _compareWallets(List<dynamic>? wallets1, List<dynamic>? wallets2) {
    final w1 = wallets1?.map((w) => Wallet.fromJson(Map<String, dynamic>.from(w))).toList() ?? [];
    final w2 = wallets2?.map((w) => Wallet.fromJson(Map<String, dynamic>.from(w))).toList() ?? [];
    
    final w1Map = {for (var w in w1) w.id: w};
    final w2Map = {for (var w in w2) w.id: w};
    
    final added = w2Map.keys.where((id) => !w1Map.containsKey(id)).toList();
    final removed = w1Map.keys.where((id) => !w2Map.containsKey(id)).toList();
    final modified = <String>[];
    
    for (final id in w1Map.keys) {
      if (w2Map.containsKey(id) && w1Map[id]!.toJson().toString() != w2Map[id]!.toJson().toString()) {
        modified.add(id);
      }
    }
    
    return {
      'added': added,
      'removed': removed,
      'modified': modified,
    };
  }

  Map<String, dynamic> _compareTransactions(List<dynamic>? transactions1, List<dynamic>? transactions2) {
    final t1 = transactions1?.map((t) => Transaction.fromJson(Map<String, dynamic>.from(t))).toList() ?? [];
    final t2 = transactions2?.map((t) => Transaction.fromJson(Map<String, dynamic>.from(t))).toList() ?? [];
    
    final t1Map = {for (var t in t1) t.id: t};
    final t2Map = {for (var t in t2) t.id: t};
    
    final added = t2Map.keys.where((id) => !t1Map.containsKey(id)).toList();
    final removed = t1Map.keys.where((id) => !t2Map.containsKey(id)).toList();
    final modified = <String>[];
    
    for (final id in t1Map.keys) {
      if (t2Map.containsKey(id) && t1Map[id]!.toJson().toString() != t2Map[id]!.toJson().toString()) {
        modified.add(id);
      }
    }
    
    return {
      'added': added,
      'removed': removed,
      'modified': modified,
    };
  }

  Map<String, dynamic> _compareSettings(Map<String, dynamic>? settings1, Map<String, dynamic>? settings2) {
    final s1 = settings1 ?? {};
    final s2 = settings2 ?? {};
    
    final added = s2.keys.where((key) => !s1.containsKey(key)).toList();
    final removed = s1.keys.where((key) => !s2.containsKey(key)).toList();
    final modified = <String>[];
    
    for (final key in s1.keys) {
      if (s2.containsKey(key) && s1[key].toString() != s2[key].toString()) {
        modified.add(key);
      }
    }
    
    return {
      'added': added,
      'removed': removed,
      'modified': modified,
    };
  }
}

/// Audit action enum
enum AuditAction {
  create,
  read,
  update,
  delete,
  restore,
  backup,
  import,
  export,
  login,
  logout,
}

/// Audit log model
class AuditLog {
  final String id;
  final AuditAction action;
  final String entityType;
  final String entityId;
  final String? description;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String userId;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  const AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.description,
    this.oldData,
    this.newData,
    required this.userId,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.toString(),
        'entityType': entityType,
        'entityId': entityId,
        'description': description,
        'oldData': oldData,
        'newData': newData,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'ipAddress': ipAddress,
        'userAgent': userAgent,
      };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'],
        action: AuditAction.values.firstWhere(
          (e) => e.toString() == json['action'],
        ),
        entityType: json['entityType'],
        entityId: json['entityId'],
        description: json['description'],
        oldData: json['oldData'] != null 
            ? Map<String, dynamic>.from(json['oldData'])
            : null,
        newData: json['newData'] != null 
            ? Map<String, dynamic>.from(json['newData'])
            : null,
        userId: json['userId'],
        timestamp: DateTime.parse(json['timestamp']),
        ipAddress: json['ipAddress'],
        userAgent: json['userAgent'],
      );
}

/// Data snapshot model
class DataSnapshot {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final int dataSize;
  final int walletCount;
  final int transactionCount;
  final bool includesAttachments;
  final String checksum;

  const DataSnapshot({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.dataSize,
    required this.walletCount,
    required this.transactionCount,
    required this.includesAttachments,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'dataSize': dataSize,
        'walletCount': walletCount,
        'transactionCount': transactionCount,
        'includesAttachments': includesAttachments,
        'checksum': checksum,
      };

  factory DataSnapshot.fromJson(Map<String, dynamic> json) => DataSnapshot(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        dataSize: json['dataSize'],
        walletCount: json['walletCount'],
        transactionCount: json['transactionCount'],
        includesAttachments: json['includesAttachments'],
        checksum: json['checksum'],
      );
}

/// Snapshot comparison model
class SnapshotComparison {
  final DataSnapshot snapshot1;
  final DataSnapshot snapshot2;
  final Map<String, dynamic> walletChanges;
  final Map<String, dynamic> transactionChanges;
  final Map<String, dynamic> settingChanges;

  const SnapshotComparison({
    required this.snapshot1,
    required this.snapshot2,
    required this.walletChanges,
    required this.transactionChanges,
    required this.settingChanges,
  });
}

/// Audit statistics model
class AuditStatistics {
  final int totalLogs;
  final Map<AuditAction, int> actionCounts;
  final Map<String, int> entityTypeCounts;
  final Map<String, int> dailyActivity;
  final DateRange? dateRange;

  const AuditStatistics({
    required this.totalLogs,
    required this.actionCounts,
    required this.entityTypeCounts,
    required this.dailyActivity,
    this.dateRange,
  });
}

/// Date range model
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });
}
