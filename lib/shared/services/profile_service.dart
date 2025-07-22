import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/security/encryption_service.dart';
import '../../core/storage/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'backup_service.dart';

/// Multi-profile management and offline transfer service
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final StorageService _storage = StorageService();
  final EncryptionService _encryption = EncryptionService();
  final BackupService _backupService = BackupService();

  String? _currentProfileId;
  UserProfile? _currentProfile;

  /// Initialize the profile service
  Future<void> initialize() async {
    await _loadCurrentProfile();
  }

  /// Create a new user profile
  Future<String> createProfile({
    required String name,
    required String pin,
    String? description,
    String? avatarPath,
    Map<String, dynamic>? preferences,
    bool setAsCurrent = true,
  }) async {
    final profileId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final profile = UserProfile(
      id: profileId,
      name: name,
      description: description,
      avatarPath: avatarPath,
      preferences: preferences ?? {},
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      isActive: true,
      dataPath: await _getProfileDataPath(profileId),
    );

    // Create profile directory
    final profileDir = Directory(profile.dataPath);
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    // Save profile metadata
    await _saveProfile(profile);
    
    // Set up profile authentication
    await _setProfilePin(profileId, pin);

    if (setAsCurrent) {
      await switchToProfile(profileId);
    }

    return profileId;
  }

  /// Switch to a different profile
  Future<void> switchToProfile(String profileId) async {
    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found');
    }

    // Save current profile state if switching from another profile
    if (_currentProfile != null) {
      await _saveCurrentProfileState();
    }

    // Load new profile
    _currentProfileId = profileId;
    _currentProfile = profile;
    
    // Update last accessed time
    final updatedProfile = profile.copyWith(lastAccessedAt: DateTime.now());
    await _saveProfile(updatedProfile);
    _currentProfile = updatedProfile;

    // Initialize storage service for this profile
    await _storage.initializeForProfile(profile.dataPath);
    
    // Save current profile setting
    await _saveCurrentProfileSetting(profileId);
  }

  /// Get current profile
  UserProfile? getCurrentProfile() => _currentProfile;

  /// Get current profile ID
  String? getCurrentProfileId() => _currentProfileId;

  /// Get all profiles
  Future<List<UserProfile>> getAllProfiles() async {
    final profilesData = _storage.getSetting<List<dynamic>>('user_profiles') ?? [];
    final profiles = profilesData
        .map((data) => UserProfile.fromJson(Map<String, dynamic>.from(data)))
        .toList();
    
    // Sort by last accessed (most recent first)
    profiles.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
    
    return profiles;
  }

  /// Get a specific profile
  Future<UserProfile?> getProfile(String profileId) async {
    final profiles = await getAllProfiles();
    try {
      return profiles.firstWhere((p) => p.id == profileId);
    } catch (e) {
      return null;
    }
  }

  /// Update profile information
  Future<void> updateProfile(String profileId, Map<String, dynamic> updates) async {
    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found');
    }

    final updatedProfile = profile.copyWith(
      name: updates['name'] ?? profile.name,
      description: updates['description'] ?? profile.description,
      avatarPath: updates['avatarPath'] ?? profile.avatarPath,
      preferences: updates['preferences'] ?? profile.preferences,
      isActive: updates['isActive'] ?? profile.isActive,
      lastAccessedAt: DateTime.now(),
    );

    await _saveProfile(updatedProfile);
    
    if (_currentProfileId == profileId) {
      _currentProfile = updatedProfile;
    }
  }

  /// Delete a profile
  Future<void> deleteProfile(String profileId) async {
    if (_currentProfileId == profileId) {
      throw Exception('Cannot delete the currently active profile');
    }

    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found');
    }

    // Delete profile data directory
    final profileDir = Directory(profile.dataPath);
    if (await profileDir.exists()) {
      await profileDir.delete(recursive: true);
    }

    // Remove from profiles list
    final profiles = await getAllProfiles();
    profiles.removeWhere((p) => p.id == profileId);
    
    await _storage.saveSetting(
      'user_profiles',
      profiles.map((p) => p.toJson()).toList(),
    );

    // Delete profile PIN
    await _deleteProfilePin(profileId);
  }

  /// Verify profile PIN
  Future<bool> verifyProfilePin(String profileId, String pin) async {
    try {
      final storedPinHash = _storage.getSetting<String>('profile_pin_$profileId');
      if (storedPinHash == null) return false;
      
      final pinHash = await _encryption.hashString(pin);
      return storedPinHash == pinHash;
    } catch (e) {
      return false;
    }
  }

  /// Change profile PIN
  Future<void> changeProfilePin(String profileId, String oldPin, String newPin) async {
    if (!await verifyProfilePin(profileId, oldPin)) {
      throw Exception('Invalid current PIN');
    }

    await _setProfilePin(profileId, newPin);
  }

  /// Export profile data
  Future<String> exportProfile({
    required String profileId,
    required String password,
    bool includeAttachments = true,
    String? customPath,
  }) async {
    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found');
    }

    // Switch to profile temporarily to export its data
    final originalProfileId = _currentProfileId;
    await switchToProfile(profileId);

    try {
      final exportPath = await _backupService.createFullBackup(
        password: password,
        includeAttachments: includeAttachments,
        customPath: customPath,
      );

      return exportPath;
    } finally {
      // Switch back to original profile
      if (originalProfileId != null) {
        await switchToProfile(originalProfileId);
      }
    }
  }

  /// Import profile data
  Future<String> importProfile({
    required String backupFilePath,
    required String password,
    required String profileName,
    required String profilePin,
    bool overwriteExisting = false,
  }) async {
    // Create new profile
    final profileId = await createProfile(
      name: profileName,
      pin: profilePin,
      setAsCurrent: false,
    );

    try {
      // Switch to new profile
      await switchToProfile(profileId);

      // Import data
      await _backupService.restoreFromBackup(
        filePath: backupFilePath,
        password: password,
        overwriteExisting: overwriteExisting,
      );

      return profileId;
    } catch (e) {
      // Clean up failed profile
      await deleteProfile(profileId);
      rethrow;
    }
  }

  /// Transfer data between profiles
  Future<void> transferData({
    required String fromProfileId,
    required String toProfileId,
    required List<String> walletIds,
    DateTime? startDate,
    DateTime? endDate,
    bool moveData = false, // true = move, false = copy
  }) async {
    final fromProfile = await getProfile(fromProfileId);
    final toProfile = await getProfile(toProfileId);
    
    if (fromProfile == null || toProfile == null) {
      throw Exception('Source or destination profile not found');
    }

    // Get data from source profile
    final originalProfileId = _currentProfileId;
    await switchToProfile(fromProfileId);

    final walletsToTransfer = <Wallet>[];
    final transactionsToTransfer = <Transaction>[];

    for (final walletId in walletIds) {
      final wallet = await _storage.getWallet(walletId);
      if (wallet != null) {
        walletsToTransfer.add(wallet);
        
        // Get transactions for this wallet
        var transactions = await _storage.getTransactionsByWallet(walletId);
        
        // Filter by date range if specified
        if (startDate != null) {
          transactions = transactions.where((t) => 
              t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)).toList();
        }
        if (endDate != null) {
          transactions = transactions.where((t) => 
              t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate)).toList();
        }
        
        transactionsToTransfer.addAll(transactions);
      }
    }

    // Switch to destination profile and save data
    await switchToProfile(toProfileId);

    for (final wallet in walletsToTransfer) {
      await _storage.saveWallet(wallet);
    }

    for (final transaction in transactionsToTransfer) {
      await _storage.saveTransaction(transaction);
    }

    // Remove data from source if moving
    if (moveData) {
      await switchToProfile(fromProfileId);
      
      for (final transaction in transactionsToTransfer) {
        await _storage.deleteTransaction(transaction.id);
      }
      
      for (final wallet in walletsToTransfer) {
        // Only delete wallet if it has no remaining transactions
        final remainingTransactions = await _storage.getTransactionsByWallet(wallet.id);
        if (remainingTransactions.isEmpty) {
          await _storage.deleteWallet(wallet.id);
        }
      }
    }

    // Switch back to original profile
    if (originalProfileId != null) {
      await switchToProfile(originalProfileId);
    }
  }

  /// Get profile statistics
  Future<ProfileStatistics> getProfileStatistics(String profileId) async {
    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found');
    }

    final originalProfileId = _currentProfileId;
    await switchToProfile(profileId);

    try {
      final wallets = await _storage.getAllWallets();
      final transactions = await _storage.getAllTransactions();
      final templates = await _storage.getAllTemplates();

      var totalBalance = 0.0;
      for (final wallet in wallets) {
        totalBalance += wallet.balance;
      }

      final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
      final income = transactions.where((t) => t.type == TransactionType.income).toList();

      final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
      final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);

      return ProfileStatistics(
        profile: profile,
        walletCount: wallets.length,
        transactionCount: transactions.length,
        templateCount: templates.length,
        totalBalance: totalBalance,
        totalExpenses: totalExpenses,
        totalIncome: totalIncome,
        dataSize: await _calculateProfileDataSize(profile.dataPath),
      );
    } finally {
      if (originalProfileId != null) {
        await switchToProfile(originalProfileId);
      }
    }
  }

  /// Merge profiles
  Future<void> mergeProfiles({
    required String sourceProfileId,
    required String targetProfileId,
    bool deleteSourceAfterMerge = false,
  }) async {
    final sourceProfile = await getProfile(sourceProfileId);
    final targetProfile = await getProfile(targetProfileId);
    
    if (sourceProfile == null || targetProfile == null) {
      throw Exception('Source or target profile not found');
    }

    if (sourceProfileId == targetProfileId) {
      throw Exception('Cannot merge profile with itself');
    }

    // Get all wallets from source profile
    final originalProfileId = _currentProfileId;
    await switchToProfile(sourceProfileId);
    
    final sourceWallets = await _storage.getAllWallets();
    final sourceTransactions = await _storage.getAllTransactions();
    final sourceTemplates = await _storage.getAllTemplates();

    // Switch to target profile and merge data
    await switchToProfile(targetProfileId);

    // Merge wallets (rename if conflicts)
    for (final wallet in sourceWallets) {
      var walletToSave = wallet;
      
      // Check for name conflicts
      final existingWallets = await _storage.getAllWallets();
      if (existingWallets.any((w) => w.name == wallet.name)) {
        walletToSave = wallet.copyWith(
          name: '${wallet.name} (Merged)',
          updatedAt: DateTime.now(),
        );
      }
      
      await _storage.saveWallet(walletToSave);
    }

    // Merge transactions
    for (final transaction in sourceTransactions) {
      await _storage.saveTransaction(transaction);
    }

    // Merge templates
    for (final template in sourceTemplates) {
      await _storage.saveTemplate(template);
    }

    // Delete source profile if requested
    if (deleteSourceAfterMerge) {
      await deleteProfile(sourceProfileId);
    }

    // Switch back to original profile
    if (originalProfileId != null && originalProfileId != sourceProfileId) {
      await switchToProfile(originalProfileId);
    } else if (originalProfileId == sourceProfileId) {
      // If we were on the source profile, switch to target
      await switchToProfile(targetProfileId);
    }
  }

  /// Get profile usage analytics
  Future<ProfileUsageAnalytics> getProfileUsageAnalytics(String profileId) async {
    final profile = await getProfile(profileId);
    if (profile == null) {
      throw Exception('Profile not found');
    }

    final originalProfileId = _currentProfileId;
    await switchToProfile(profileId);

    try {
      final transactions = await _storage.getAllTransactions();
      
      // Calculate usage patterns
      final dailyActivity = <DateTime, int>{};
      final hourlyActivity = <int, int>{};
      final categoryUsage = <String, int>{};

      for (final transaction in transactions) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        dailyActivity[date] = (dailyActivity[date] ?? 0) + 1;
        
        final hour = transaction.date.hour;
        hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
        
        categoryUsage[transaction.category] = (categoryUsage[transaction.category] ?? 0) + 1;
      }

      final mostActiveDay = dailyActivity.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      final mostActiveHour = hourlyActivity.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      final topCategory = categoryUsage.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      return ProfileUsageAnalytics(
        profile: profile,
        totalSessions: dailyActivity.length,
        averageTransactionsPerDay: transactions.length / max(dailyActivity.length, 1),
        mostActiveDay: mostActiveDay.key,
        mostActiveHour: mostActiveHour.key,
        topCategory: topCategory.key,
        dailyActivity: dailyActivity,
        hourlyActivity: hourlyActivity,
        categoryUsage: categoryUsage,
      );
    } finally {
      if (originalProfileId != null) {
        await switchToProfile(originalProfileId);
      }
    }
  }

  // Helper methods
  Future<void> _loadCurrentProfile() async {
    final currentProfileId = _storage.getSetting<String>('current_profile_id');
    if (currentProfileId != null) {
      try {
        await switchToProfile(currentProfileId);
      } catch (e) {
        // If loading fails, clear the setting
        await _storage.deleteSetting('current_profile_id');
      }
    }
  }

  Future<String> _getProfileDataPath(String profileId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/profiles/$profileId';
  }

  Future<void> _saveProfile(UserProfile profile) async {
    final profiles = await getAllProfiles();
    profiles.removeWhere((p) => p.id == profile.id);
    profiles.insert(0, profile);
    
    await _storage.saveSetting(
      'user_profiles',
      profiles.map((p) => p.toJson()).toList(),
    );
  }

  Future<void> _setProfilePin(String profileId, String pin) async {
    final pinHash = await _encryption.hashString(pin);
    await _storage.saveSetting('profile_pin_$profileId', pinHash);
  }

  Future<void> _deleteProfilePin(String profileId) async {
    await _storage.deleteSetting('profile_pin_$profileId');
  }

  Future<void> _saveCurrentProfileState() async {
    // This could save any temporary state if needed
    // For now, just update the last accessed time
    if (_currentProfile != null) {
      final updatedProfile = _currentProfile!.copyWith(
        lastAccessedAt: DateTime.now(),
      );
      await _saveProfile(updatedProfile);
    }
  }

  Future<void> _saveCurrentProfileSetting(String profileId) async {
    await _storage.saveSetting('current_profile_id', profileId);
  }

  Future<int> _calculateProfileDataSize(String dataPath) async {
    try {
      final directory = Directory(dataPath);
      if (!await directory.exists()) return 0;
      
      var totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}

/// User profile model
class UserProfile {
  final String id;
  final String name;
  final String? description;
  final String? avatarPath;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final bool isActive;
  final String dataPath;

  const UserProfile({
    required this.id,
    required this.name,
    this.description,
    this.avatarPath,
    required this.preferences,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.isActive,
    required this.dataPath,
  });

  UserProfile copyWith({
    String? name,
    String? description,
    String? avatarPath,
    Map<String, dynamic>? preferences,
    DateTime? lastAccessedAt,
    bool? isActive,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarPath: avatarPath ?? this.avatarPath,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isActive: isActive ?? this.isActive,
      dataPath: dataPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'avatarPath': avatarPath,
        'preferences': preferences,
        'createdAt': createdAt.toIso8601String(),
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
        'isActive': isActive,
        'dataPath': dataPath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        avatarPath: json['avatarPath'],
        preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
        createdAt: DateTime.parse(json['createdAt']),
        lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
        isActive: json['isActive'] ?? true,
        dataPath: json['dataPath'],
      );
}

/// Profile statistics model
class ProfileStatistics {
  final UserProfile profile;
  final int walletCount;
  final int transactionCount;
  final int templateCount;
  final double totalBalance;
  final double totalExpenses;
  final double totalIncome;
  final int dataSize;

  const ProfileStatistics({
    required this.profile,
    required this.walletCount,
    required this.transactionCount,
    required this.templateCount,
    required this.totalBalance,
    required this.totalExpenses,
    required this.totalIncome,
    required this.dataSize,
  });
}

/// Profile usage analytics model
class ProfileUsageAnalytics {
  final UserProfile profile;
  final int totalSessions;
  final double averageTransactionsPerDay;
  final DateTime mostActiveDay;
  final int mostActiveHour;
  final String topCategory;
  final Map<DateTime, int> dailyActivity;
  final Map<int, int> hourlyActivity;
  final Map<String, int> categoryUsage;

  const ProfileUsageAnalytics({
    required this.profile,
    required this.totalSessions,
    required this.averageTransactionsPerDay,
    required this.mostActiveDay,
    required this.mostActiveHour,
    required this.topCategory,
    required this.dailyActivity,
    required this.hourlyActivity,
    required this.categoryUsage,
  });
}
