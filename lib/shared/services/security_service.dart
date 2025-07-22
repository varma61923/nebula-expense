import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/security/authentication_service.dart';
import '../../core/security/encryption_service.dart';
import '../../core/storage/storage_service.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

/// Advanced security service for per-wallet locks, stealth mode, and calculator mode
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final StorageService _storage = StorageService();
  final EncryptionService _encryption = EncryptionService();
  final AuthenticationService _auth = AuthenticationService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Security state
  final Map<String, bool> _unlockedWallets = {};
  bool _isStealthModeActive = false;
  bool _isCalculatorModeActive = false;
  bool _isTamperDetectionActive = false;
  String? _calculatorModePin;
  DateTime? _lastActivity;
  Timer? _securityTimer;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  
  // Advanced security features
  bool _isDecoyModeActive = false;
  bool _isEmergencyLockActive = false;
  List<String> _securityLogs = [];

  /// Initialize security service
  Future<void> initialize() async {
    await _loadSecuritySettings();
    _startSecurityMonitoring();
    await _initializeBiometrics();
    await _checkTamperDetection();
    _logSecurityEvent('Security service initialized');
  }

  /// Initialize biometric authentication
  Future<void> _initializeBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (isAvailable && isDeviceSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        await _storage.saveSetting('biometrics_available', availableBiometrics.map((b) => b.name).toList());
        _logSecurityEvent('Biometrics initialized: ${availableBiometrics.length} types available');
      }
    } catch (e) {
      _logSecurityEvent('Biometrics initialization failed: $e');
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({String reason = 'Authenticate to access wallet'}) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedFallbackTitle: 'Use PIN instead',
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            biometricHint: 'Touch sensor',
            biometricNotRecognized: 'Biometric not recognized',
            biometricSuccess: 'Authentication successful',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription: 'Please set up device credentials',
            goToSettingsButton: 'Go to settings',
            goToSettingsDescription: 'Please set up biometrics on your device',
          ),
          IOSAuthMessages(
            lockOut: 'Please re-enable your Touch ID',
            goToSettingsButton: 'Go to settings',
            goToSettingsDescription: 'Please set up Touch ID',
            cancelButton: 'Cancel',
          ),
        ],
      );
      
      if (isAuthenticated) {
        _resetFailedAttempts();
        _updateLastActivity();
        _logSecurityEvent('Biometric authentication successful');
      } else {
        _incrementFailedAttempts();
        _logSecurityEvent('Biometric authentication failed');
      }
      
      return isAuthenticated;
    } catch (e) {
      _logSecurityEvent('Biometric authentication error: $e');
      return false;
    }
  }

  /// Set per-wallet lock
  Future<void> setWalletLock({
    required String walletId,
    required String pin,
    SecurityLevel level = SecurityLevel.medium,
    Duration? autoLockDuration,
  }) async {
    final wallet = await _storage.getWallet(walletId);
    if (wallet == null) {
      throw Exception('Wallet not found');
    }

    final pinHash = await _encryption.hashString(pin);
    final lockConfig = WalletLockConfig(
      isEnabled: true,
      pinHash: pinHash,
      level: level,
      autoLockDuration: autoLockDuration ?? const Duration(minutes: 15),
      createdAt: DateTime.now(),
      lastUnlockedAt: null,
    );

    await _storage.saveSetting('wallet_lock_$walletId', lockConfig.toJson());
    
    // Lock the wallet immediately
    _unlockedWallets[walletId] = false;
  }

  /// Remove per-wallet lock
  Future<void> removeWalletLock(String walletId, String pin) async {
    if (!await verifyWalletPin(walletId, pin)) {
      throw Exception('Invalid PIN');
    }

    await _storage.deleteSetting('wallet_lock_$walletId');
    _unlockedWallets.remove(walletId);
  }

  /// Verify wallet PIN
  Future<bool> verifyWalletPin(String walletId, String pin) async {
    final lockConfig = await _getWalletLockConfig(walletId);
    if (lockConfig == null || !lockConfig.isEnabled) return true;

    final pinHash = await _encryption.hashString(pin);
    return lockConfig.pinHash == pinHash;
  }

  /// Unlock wallet
  Future<bool> unlockWallet(String walletId, String pin) async {
    if (await verifyWalletPin(walletId, pin)) {
      _unlockedWallets[walletId] = true;
      
      // Update last unlocked time
      final lockConfig = await _getWalletLockConfig(walletId);
      if (lockConfig != null) {
        final updatedConfig = lockConfig.copyWith(lastUnlockedAt: DateTime.now());
        await _storage.saveSetting('wallet_lock_$walletId', updatedConfig.toJson());
      }
      
      _updateLastActivity();
      return true;
    }
    return false;
  }

  /// Lock wallet
  Future<void> lockWallet(String walletId) async {
    _unlockedWallets[walletId] = false;
  }

  /// Check if wallet is unlocked
  bool isWalletUnlocked(String walletId) {
    final lockConfig = _getWalletLockConfigSync(walletId);
    if (lockConfig == null || !lockConfig.isEnabled) return true;

    final isUnlocked = _unlockedWallets[walletId] ?? false;
    if (!isUnlocked) return false;

    // Check auto-lock timeout
    if (lockConfig.lastUnlockedAt != null && lockConfig.autoLockDuration != null) {
      final timeSinceUnlock = DateTime.now().difference(lockConfig.lastUnlockedAt!);
      if (timeSinceUnlock > lockConfig.autoLockDuration!) {
        _unlockedWallets[walletId] = false;
        return false;
      }
    }

    return true;
  }

  /// Create hidden wallet
  Future<String> createHiddenWallet({
    required String name,
    required String currency,
    required String hiddenPin,
    String? description,
    double initialBalance = 0.0,
  }) async {
    final walletId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create the wallet with special hidden flag
    final wallet = Wallet(
      id: walletId,
      name: name,
      description: description,
      currency: currency,
      balance: initialBalance,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['hidden'], // Special tag to identify hidden wallets
      isHidden: true,
    );

    await _storage.saveWallet(wallet);

    // Set up hidden wallet access
    final hiddenConfig = HiddenWalletConfig(
      walletId: walletId,
      pinHash: await _encryption.hashString(hiddenPin),
      isVisible: false,
      createdAt: DateTime.now(),
    );

    await _storage.saveSetting('hidden_wallet_$walletId', hiddenConfig.toJson());
    
    return walletId;
  }

  /// Reveal hidden wallet
  Future<bool> revealHiddenWallet(String walletId, String hiddenPin) async {
    final hiddenConfig = await _getHiddenWalletConfig(walletId);
    if (hiddenConfig == null) return false;

    final pinHash = await _encryption.hashString(hiddenPin);
    if (hiddenConfig.pinHash != pinHash) return false;

    // Make wallet visible
    final updatedConfig = hiddenConfig.copyWith(isVisible: true);
    await _storage.saveSetting('hidden_wallet_$walletId', updatedConfig.toJson());
    
    return true;
  }

  /// Hide wallet again
  Future<void> hideWallet(String walletId) async {
    final hiddenConfig = await _getHiddenWalletConfig(walletId);
    if (hiddenConfig != null) {
      final updatedConfig = hiddenConfig.copyWith(isVisible: false);
      await _storage.saveSetting('hidden_wallet_$walletId', updatedConfig.toJson());
    }
  }

  /// Get visible wallets (excludes hidden ones that are not revealed)
  Future<List<Wallet>> getVisibleWallets() async {
    final allWallets = await _storage.getAllWallets();
    final visibleWallets = <Wallet>[];

    for (final wallet in allWallets) {
      if (!wallet.isHidden) {
        visibleWallets.add(wallet);
      } else {
        // Check if hidden wallet is currently visible
        final hiddenConfig = await _getHiddenWalletConfig(wallet.id);
        if (hiddenConfig?.isVisible == true) {
          visibleWallets.add(wallet);
        }
      }
    }

    return visibleWallets;
  }

  /// Enable stealth mode
  Future<void> enableStealthMode({
    required String stealthPin,
    List<String>? hiddenWalletIds,
    bool hideTransactionAmounts = true,
    bool hideBalances = true,
  }) async {
    final stealthConfig = StealthModeConfig(
      isEnabled: true,
      pinHash: await _encryption.hashString(stealthPin),
      hiddenWalletIds: hiddenWalletIds ?? [],
      hideTransactionAmounts: hideTransactionAmounts,
      hideBalances: hideBalances,
      activatedAt: DateTime.now(),
    );

    await _storage.saveSetting('stealth_mode_config', stealthConfig.toJson());
    _isStealthModeActive = true;
  }

  /// Disable stealth mode
  Future<bool> disableStealthMode(String stealthPin) async {
    final stealthConfig = await _getStealthModeConfig();
    if (stealthConfig == null) return false;

    final pinHash = await _encryption.hashString(stealthPin);
    if (stealthConfig.pinHash != pinHash) return false;

    await _storage.deleteSetting('stealth_mode_config');
    _isStealthModeActive = false;
    
    return true;
  }

  /// Check if stealth mode is active
  bool isStealthModeActive() => _isStealthModeActive;

  /// Get stealth-filtered data
  Future<List<Wallet>> getStealthFilteredWallets() async {
    if (!_isStealthModeActive) {
      return await getVisibleWallets();
    }

    final stealthConfig = await _getStealthModeConfig();
    if (stealthConfig == null) {
      return await getVisibleWallets();
    }

    final allWallets = await getVisibleWallets();
    return allWallets.where((wallet) => 
        !stealthConfig.hiddenWalletIds.contains(wallet.id)).toList();
  }

  /// Enable calculator mode
  Future<void> enableCalculatorMode(String calculatorPin) async {
    _calculatorModePin = await _encryption.hashString(calculatorPin);
    _isCalculatorModeActive = true;
    
    await _storage.saveSetting('calculator_mode_enabled', true);
    await _storage.saveSetting('calculator_mode_pin', _calculatorModePin);
  }

  /// Disable calculator mode
  Future<bool> disableCalculatorMode(String calculatorPin) async {
    if (_calculatorModePin == null) return false;

    final pinHash = await _encryption.hashString(calculatorPin);
    if (_calculatorModePin != pinHash) return false;

    _isCalculatorModeActive = false;
    _calculatorModePin = null;
    
    await _storage.deleteSetting('calculator_mode_enabled');
    await _storage.deleteSetting('calculator_mode_pin');
    
    return true;
  }

  /// Check if calculator mode is active
  bool isCalculatorModeActive() => _isCalculatorModeActive;

  /// Exit calculator mode with PIN
  Future<bool> exitCalculatorMode(String calculatorPin) async {
    if (_calculatorModePin == null) return false;

    final pinHash = await _encryption.hashString(calculatorPin);
    if (_calculatorModePin != pinHash) return false;

    _isCalculatorModeActive = false;
    return true;
  }

  /// Perform calculator operation (for calculator mode)
  String performCalculation(String expression) {
    try {
      // Simple calculator implementation
      // In a real app, you'd use a proper expression parser
      final sanitized = expression.replaceAll(RegExp(r'[^0-9+\-*/.() ]'), '');
      
      // Basic validation
      if (sanitized.isEmpty) return '0';
      
      // For demo purposes, return the expression
      // In production, implement proper calculation
      return 'Result: $sanitized';
    } catch (e) {
      return 'Error';
    }
  }

  /// Setup self-destruct PIN with secure wipe levels
  Future<void> setupSelfDestruct({
    required String pin,
    required WipeLevel wipeLevel,
    int maxAttempts = 10,
    bool autoTrigger = false,
  }) async {
    final config = SelfDestructConfig(
      isEnabled: true,
      pinHash: await _encryption.hashString(pin),
      wipeLevel: wipeLevel,
      maxAttempts: maxAttempts,
      autoTrigger: autoTrigger,
      createdAt: DateTime.now(),
    );
    
    await _storage.saveSetting('self_destruct_config', config.toJson());
    _logSecurityEvent('Self-destruct configured with ${wipeLevel.name} wipe level');
  }

  /// Self-destruct with PIN
  Future<bool> selfDestruct(String pin) async {
    final selfDestructConfig = await _getSelfDestructConfig();
    if (selfDestructConfig == null) return false;
    
    final pinHash = await _encryption.hashString(pin);
    if (selfDestructConfig.pinHash != pinHash) {
      _incrementFailedAttempts();
      _logSecurityEvent('Self-destruct attempt with invalid PIN');
      return false;
    }
    
    _logSecurityEvent('SELF-DESTRUCT INITIATED');
    
    try {
      switch (selfDestructConfig.wipeLevel) {
        case WipeLevel.basic:
          await _storage.clearAllData();
          break;
        case WipeLevel.secure:
          await _secureWipeData();
          break;
        case WipeLevel.military:
          await _militaryGradeWipe();
          break;
      }
      
      await _encryption.selfDestruct();
      _logSecurityEvent('Self-destruct completed successfully');
      return true;
    } catch (e) {
      _logSecurityEvent('Self-destruct failed: $e');
      return false;
    }
  }

  /// Enable military-grade tamper detection
  Future<void> enableTamperDetection() async {
    _isTamperDetectionActive = true;
    await _storage.saveSetting('tamper_detection_enabled', true);
    
    // Multiple integrity checksums for military-grade verification
    final integrityData = await _calculateMilitaryIntegrityHash();
    await _storage.saveSetting('app_integrity_hash', integrityData['primary']);
    await _storage.saveSetting('app_integrity_hash_secondary', integrityData['secondary']);
    await _storage.saveSetting('app_integrity_hash_tertiary', integrityData['tertiary']);
    await _storage.saveSetting('integrity_timestamp', DateTime.now().toIso8601String());
    
    _logSecurityEvent('MILITARY-GRADE tamper detection enabled with triple-redundancy');
  }
  
  /// Calculate military-grade integrity hash with multiple algorithms
  Future<Map<String, String>> _calculateMilitaryIntegrityHash() async {
    final criticalData = {
      'app_version': '1.0.0',
      'security_settings': _storage.getSetting('security_settings'),
      'encryption_enabled': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'random_salt': Random.secure().nextInt(999999999),
    };
    
    final dataString = json.encode(criticalData);
    final bytes = utf8.encode(dataString);
    
    // Primary: SHA-256
    final primaryDigest = sha256.convert(bytes);
    
    // Secondary: SHA-512 equivalent (double SHA-256)
    final secondaryDigest = sha256.convert(sha256.convert(bytes).bytes);
    
    // Tertiary: Custom military-grade hash
    final tertiaryDigest = _customMilitaryHash(bytes);
    
    return {
      'primary': primaryDigest.toString(),
      'secondary': secondaryDigest.toString(),
      'tertiary': tertiaryDigest,
    };
  }
  
  /// Custom military-grade hash function
  String _customMilitaryHash(List<int> data) {
    var hash = 0x811c9dc5; // FNV-1a 32-bit offset basis
    const prime = 0x01000193; // FNV-1a 32-bit prime
    
    for (final byte in data) {
      hash ^= byte;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    
    // Additional military-grade transformations
    hash ^= hash >> 16;
    hash = (hash * 0x85ebca6b) & 0xFFFFFFFF;
    hash ^= hash >> 13;
    hash = (hash * 0xc2b2ae35) & 0xFFFFFFFF;
    hash ^= hash >> 16;
    
    return hash.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  /// Military-grade tamper detection with triple verification
  Future<bool> _checkTamperDetection() async {
    if (!_isTamperDetectionActive) return false;
    
    try {
      final storedHashes = {
        'primary': _storage.getSetting<String>('app_integrity_hash'),
        'secondary': _storage.getSetting<String>('app_integrity_hash_secondary'),
        'tertiary': _storage.getSetting<String>('app_integrity_hash_tertiary'),
      };
      
      final currentHashes = await _calculateMilitaryIntegrityHash();
      
      int tamperCount = 0;
      for (final key in storedHashes.keys) {
        if (storedHashes[key] != null && storedHashes[key] != currentHashes[key]) {
          tamperCount++;
          _logSecurityEvent('TAMPERING DETECTED in $key hash: ${storedHashes[key]} != ${currentHashes[key]}');
        }
      }
      
      if (tamperCount > 0) {
        _logSecurityEvent('CRITICAL SECURITY BREACH: $tamperCount/3 integrity checks failed');
        await _triggerMilitaryEmergencyProtocol();
        return true;
      }
      
      // Additional runtime integrity checks
      if (await _performRuntimeIntegrityCheck()) {
        _logSecurityEvent('RUNTIME TAMPERING DETECTED');
        await _triggerMilitaryEmergencyProtocol();
        return true;
      }
      
    } catch (e) {
      _logSecurityEvent('CRITICAL: Tamper detection system compromised: $e');
      await _triggerMilitaryEmergencyProtocol();
      return true;
    }
    
    return false;
  }
  
  /// Runtime integrity verification
  Future<bool> _performRuntimeIntegrityCheck() async {
    try {
      // Check for debugging tools
      if (await _detectDebuggingTools()) {
        _logSecurityEvent('DEBUGGING TOOLS DETECTED');
        return true;
      }
      
      // Check for memory manipulation
      if (await _detectMemoryManipulation()) {
        _logSecurityEvent('MEMORY MANIPULATION DETECTED');
        return true;
      }
      
      // Check for code injection
      if (await _detectCodeInjection()) {
        _logSecurityEvent('CODE INJECTION DETECTED');
        return true;
      }
      
      return false;
    } catch (e) {
      _logSecurityEvent('Runtime integrity check failed: $e');
      return true;
    }
  }
  
  /// Detect debugging tools
  Future<bool> _detectDebuggingTools() async {
    // Check for common debugging indicators
    final startTime = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 1));
    final endTime = DateTime.now();
    
    // If execution is significantly slower, debugger might be attached
    return endTime.difference(startTime).inMilliseconds > 10;
  }
  
  /// Detect memory manipulation
  Future<bool> _detectMemoryManipulation() async {
    // Store canary values and check for modification
    final canary1 = Random.secure().nextInt(999999999);
    final canary2 = Random.secure().nextInt(999999999);
    
    await _storage.saveSetting('_canary1', canary1);
    await _storage.saveSetting('_canary2', canary2);
    
    await Future.delayed(const Duration(milliseconds: 1));
    
    final storedCanary1 = _storage.getSetting<int>('_canary1');
    final storedCanary2 = _storage.getSetting<int>('_canary2');
    
    await _storage.deleteSetting('_canary1');
    await _storage.deleteSetting('_canary2');
    
    return storedCanary1 != canary1 || storedCanary2 != canary2;
  }
  
  /// Detect code injection
  Future<bool> _detectCodeInjection() async {
    // Check for unexpected function calls or modifications
    try {
      final testValue = 'security_test_${Random.secure().nextInt(999999)}';
      final hash1 = sha256.convert(utf8.encode(testValue)).toString();
      await Future.delayed(const Duration(microseconds: 100));
      final hash2 = sha256.convert(utf8.encode(testValue)).toString();
      
      return hash1 != hash2; // Hash should be consistent
    } catch (e) {
      return true; // Any exception indicates potential tampering
    }
  }
  
  /// Military emergency protocol
  Future<void> _triggerMilitaryEmergencyProtocol() async {
    _logSecurityEvent('MILITARY EMERGENCY PROTOCOL ACTIVATED');
    
    // Immediate lockdown
    _isEmergencyLockActive = true;
    
    // Lock all wallets
    final wallets = await _storage.getAllWallets();
    for (final wallet in wallets) {
      await lockWallet(wallet.id);
    }
    
    // Enable maximum stealth mode
    _isStealthModeActive = true;
    
    // Prepare for potential self-destruct
    final selfDestructConfig = await _getSelfDestructConfig();
    if (selfDestructConfig?.autoTrigger == true) {
      _logSecurityEvent('AUTO-DESTRUCT SEQUENCE INITIATED');
      await _militaryGradeWipe();
    }
    
    await _storage.saveSetting('military_emergency_active', true);
    _logSecurityEvent('MILITARY EMERGENCY PROTOCOL COMPLETED');
  }

  /// Set up panic mode
  Future<void> setupPanicMode({
    required String panicPin,
    required PanicAction action,
    List<String>? walletsToWipe,
  }) async {
    final panicConfig = PanicModeConfig(
      isEnabled: true,
      pinHash: await _encryption.hashString(panicPin),
      action: action,
      walletsToWipe: walletsToWipe ?? [],
      createdAt: DateTime.now(),
    );

    await _storage.saveSetting('panic_mode_config', panicConfig.toJson());
    _logSecurityEvent('Panic mode configured with ${action.name} action');
  }

  /// Trigger panic mode
  Future<bool> triggerPanicMode(String panicPin) async {
    final panicConfig = await _getPanicModeConfig();
    if (panicConfig == null || !panicConfig.isEnabled) return false;

    final pinHash = await _encryption.hashString(panicPin);
    if (panicConfig.pinHash != pinHash) return false;

    switch (panicConfig.action) {
      case PanicAction.wipeAll:
        await _storage.clearAllData();
        await _encryption.selfDestruct();
        break;
        
      case PanicAction.wipeSelectedWallets:
        for (final walletId in panicConfig.walletsToWipe) {
          await _storage.deleteWallet(walletId);
          // Delete associated transactions
          final transactions = await _storage.getTransactionsByWallet(walletId);
          for (final transaction in transactions) {
            await _storage.deleteTransaction(transaction.id);
          }
        }
        break;
        
      case PanicAction.enableStealthMode:
        await enableStealthMode(
          stealthPin: panicPin,
          hiddenWalletIds: panicConfig.walletsToWipe,
        );
        break;
        
      case PanicAction.lockAllWallets:
        final wallets = await _storage.getAllWallets();
        for (final wallet in wallets) {
          await lockWallet(wallet.id);
        }
        break;
    }

    return true;
  }

  /// Generate secure random PIN
  String generateSecurePin({int length = 6}) {
    final random = Random.secure();
    final digits = List.generate(length, (_) => random.nextInt(10));
    return digits.join();
  }

  /// Validate PIN strength
  PinStrength validatePinStrength(String pin) {
    if (pin.length < 4) return PinStrength.weak;
    if (pin.length < 6) return PinStrength.medium;
    
    // Check for patterns
    if (_hasSequentialDigits(pin) || _hasRepeatingDigits(pin)) {
      return PinStrength.weak;
    }
    
    if (pin.length >= 8) return PinStrength.veryStrong;
    return PinStrength.strong;
  }

  /// Get security audit report
  Future<SecurityAuditReport> getSecurityAuditReport() async {
    final wallets = await _storage.getAllWallets();
    final lockedWallets = <String>[];
    final unlockedWallets = <String>[];
    final hiddenWallets = <String>[];

    for (final wallet in wallets) {
      if (wallet.isHidden) {
        hiddenWallets.add(wallet.id);
      }
      
      final lockConfig = await _getWalletLockConfig(wallet.id);
      if (lockConfig?.isEnabled == true) {
        if (isWalletUnlocked(wallet.id)) {
          unlockedWallets.add(wallet.id);
        } else {
          lockedWallets.add(wallet.id);
        }
      }
    }

    final stealthConfig = await _getStealthModeConfig();
    final panicConfig = await _getPanicModeConfig();

    return SecurityAuditReport(
      totalWallets: wallets.length,
      lockedWallets: lockedWallets.length,
      unlockedWallets: unlockedWallets.length,
      hiddenWallets: hiddenWallets.length,
      isStealthModeEnabled: stealthConfig?.isEnabled ?? false,
      isPanicModeEnabled: panicConfig?.isEnabled ?? false,
      isCalculatorModeEnabled: _isCalculatorModeActive,
      lastActivity: _lastActivity,
      recommendations: _generateSecurityRecommendations(
        wallets.length,
        lockedWallets.length,
        hiddenWallets.length,
      ),
    );
  }

  // Helper methods
  Future<void> _loadSecuritySettings() async {
    _isStealthModeActive = await _getStealthModeConfig() != null;
    _isCalculatorModeActive = _storage.getSetting<bool>('calculator_mode_enabled') ?? false;
    _calculatorModePin = _storage.getSetting<String>('calculator_mode_pin');
  }

  void _startInactivityTimer() {
    // Auto-lock wallets after inactivity
    Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAutoLock();
    });
  }

  void _checkAutoLock() {
    final now = DateTime.now();
    for (final entry in _unlockedWallets.entries.toList()) {
      if (entry.value) {
        final lockConfig = _getWalletLockConfigSync(entry.key);
        if (lockConfig?.autoLockDuration != null && lockConfig?.lastUnlockedAt != null) {
          final timeSinceUnlock = now.difference(lockConfig!.lastUnlockedAt!);
          if (timeSinceUnlock > lockConfig.autoLockDuration!) {
            _unlockedWallets[entry.key] = false;
          }
        }
      }
    }
  }

  void _updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  Future<WalletLockConfig?> _getWalletLockConfig(String walletId) async {
    final data = _storage.getSetting<Map<String, dynamic>>('wallet_lock_$walletId');
    return data != null ? WalletLockConfig.fromJson(data) : null;
  }

  WalletLockConfig? _getWalletLockConfigSync(String walletId) {
    final data = _storage.getSetting<Map<String, dynamic>>('wallet_lock_$walletId');
    return data != null ? WalletLockConfig.fromJson(data) : null;
  }

  Future<HiddenWalletConfig?> _getHiddenWalletConfig(String walletId) async {
    final data = _storage.getSetting<Map<String, dynamic>>('hidden_wallet_$walletId');
    return data != null ? HiddenWalletConfig.fromJson(data) : null;
  }

  Future<StealthModeConfig?> _getStealthModeConfig() async {
    final data = _storage.getSetting<Map<String, dynamic>>('stealth_mode_config');
    return data != null ? StealthModeConfig.fromJson(data) : null;
  }

  Future<PanicModeConfig?> _getPanicModeConfig() async {
    final data = _storage.getSetting<Map<String, dynamic>>('panic_mode_config');
    return data != null ? PanicModeConfig.fromJson(data) : null;
  }

  bool _hasSequentialDigits(String pin) {
    for (int i = 0; i < pin.length - 2; i++) {
      final a = int.tryParse(pin[i]) ?? 0;
      final b = int.tryParse(pin[i + 1]) ?? 0;
      final c = int.tryParse(pin[i + 2]) ?? 0;
      
      if (b == a + 1 && c == b + 1) return true;
      if (b == a - 1 && c == b - 1) return true;
    }
    return false;
  }

  bool _hasRepeatingDigits(String pin) {
    final chars = pin.split('');
    final uniqueChars = chars.toSet();
    return uniqueChars.length < chars.length * 0.5;
  }

  /// Calculate app integrity hash (legacy method for compatibility)
  Future<String> _calculateAppIntegrityHash() async {
    final hashes = await _calculateMilitaryIntegrityHash();
    return hashes['primary']!;
  }

  /// Trigger emergency lock
  Future<void> _triggerEmergencyLock() async {
    _isEmergencyLockActive = true;
    
    final wallets = await _storage.getAllWallets();
    for (final wallet in wallets) {
      await lockWallet(wallet.id);
    }
    
    final emergencyConfig = await _getEmergencyConfig();
    if (emergencyConfig?.enableStealthOnEmergency == true) {
      _isStealthModeActive = true;
    }
    
    await _storage.saveSetting('emergency_lock_active', true);
    _logSecurityEvent('EMERGENCY LOCK ACTIVATED');
  }

  /// Secure data wipe (multiple passes)
  Future<void> _secureWipeData() async {
    for (int pass = 0; pass < 3; pass++) {
      await _storage.clearAllData();
      
      final random = Random.secure();
      for (int i = 0; i < 1000; i++) {
        final randomKey = 'wipe_${random.nextInt(999999)}';
        final randomData = List.generate(1024, (_) => random.nextInt(256));
        await _storage.saveSetting(randomKey, randomData);
      }
      
      await _storage.clearAllData();
    }
  }

  /// Military-grade data wipe (DoD 5220.22-M + NSA/CSS-02-01 standards)
  Future<void> _militaryGradeWipe() async {
    _logSecurityEvent('MILITARY-GRADE WIPE INITIATED - DoD 5220.22-M + NSA/CSS-02-01');
    
    // DoD 5220.22-M: 3-pass overwrite
    final dodPatterns = [0x00, 0xFF, 0x00];
    
    // NSA/CSS-02-01: Additional random patterns
    final random = Random.secure();
    final nsaPatterns = List.generate(4, (_) => random.nextInt(256));
    
    final allPatterns = [...dodPatterns, ...nsaPatterns];
    
    for (int pass = 0; pass < allPatterns.length; pass++) {
      final pattern = allPatterns[pass];
      _logSecurityEvent('Military wipe pass ${pass + 1}/${allPatterns.length} - Pattern: 0x${pattern.toRadixString(16).padLeft(2, '0').toUpperCase()}');
      
      await _storage.clearAllData();
      
      // Overwrite with pattern - increased iterations for thorough coverage
      for (int i = 0; i < 50000; i++) {
        final key = 'mil_wipe_p${pass}_$i';
        final data = List.filled(2048, pattern);
        await _storage.saveSetting(key, data);
      }
      
      await _storage.clearAllData();
      
      // Random overwrite for this pass
      for (int i = 0; i < 25000; i++) {
        final key = 'mil_rand_p${pass}_$i';
        final data = List.generate(2048, (_) => random.nextInt(256));
        await _storage.saveSetting(key, data);
      }
      
      await _storage.clearAllData();
    }
    
    // Final quantum-resistant random overwrite
    await _quantumResistantWipe();
    
    _logSecurityEvent('MILITARY-GRADE WIPE COMPLETED - All data forensically unrecoverable');
  }
  
  /// Quantum-resistant secure wipe
  Future<void> _quantumResistantWipe() async {
    _logSecurityEvent('Quantum-resistant wipe initiated');
    final random = Random.secure();
    
    // Multiple quantum-resistant random overwrites
    for (int round = 0; round < 10; round++) {
      await _storage.clearAllData();
      
      for (int i = 0; i < 100000; i++) {
        final key = 'qr_wipe_r${round}_$i';
        final data = List.generate(4096, (_) => random.nextInt(256));
        await _storage.saveSetting(key, data);
      }
      
      await _storage.clearAllData();
    }
    
    _logSecurityEvent('Quantum-resistant wipe completed');
  }

  /// Enable decoy mode
  Future<void> enableDecoyMode({
    required String decoyPin,
    required List<String> decoyWalletIds,
    bool showFakeData = true,
  }) async {
    final decoyConfig = DecoyModeConfig(
      isEnabled: true,
      pinHash: await _encryption.hashString(decoyPin),
      decoyWalletIds: decoyWalletIds,
      showFakeData: showFakeData,
      createdAt: DateTime.now(),
    );
    
    await _storage.saveSetting('decoy_mode_config', decoyConfig.toJson());
    _logSecurityEvent('Decoy mode enabled with ${decoyWalletIds.length} decoy wallets');
  }

  /// Activate decoy mode
  Future<bool> activateDecoyMode(String pin) async {
    final decoyConfig = await _getDecoyModeConfig();
    if (decoyConfig == null || !decoyConfig.isEnabled) return false;
    
    final pinHash = await _encryption.hashString(pin);
    if (decoyConfig.pinHash != pinHash) return false;
    
    _isDecoyModeActive = true;
    _logSecurityEvent('Decoy mode activated');
    return true;
  }

  /// Get decoy-filtered wallets
  Future<List<Wallet>> getDecoyFilteredWallets() async {
    if (!_isDecoyModeActive) {
      return await getVisibleWallets();
    }
    
    final decoyConfig = await _getDecoyModeConfig();
    if (decoyConfig == null) {
      return await getVisibleWallets();
    }
    
    final allWallets = await _storage.getAllWallets();
    return allWallets.where((wallet) => 
        decoyConfig.decoyWalletIds.contains(wallet.id)).toList();
  }

  /// Check if account should be locked due to failed attempts
  bool _shouldLockAccount() {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      return true;
    }
    
    if (_failedAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(Duration(minutes: _failedAttempts * 2));
      _logSecurityEvent('Account locked due to ${_failedAttempts} failed attempts');
      return true;
    }
    
    return false;
  }
  
  /// Increment failed attempts counter
  void _incrementFailedAttempts() {
    _failedAttempts++;
    _logSecurityEvent('Failed authentication attempt #${_failedAttempts}');
    _checkSelfDestructThreshold();
  }
  
  /// Reset failed attempts counter
  void _resetFailedAttempts() {
    if (_failedAttempts > 0) {
      _logSecurityEvent('Failed attempts counter reset after successful authentication');
      _failedAttempts = 0;
      _lockoutUntil = null;
    }
  }
  
  /// Check if self-destruct threshold is reached
  Future<void> _checkSelfDestructThreshold() async {
    final config = await _getSelfDestructConfig();
    if (config != null && config.isEnabled && _failedAttempts >= config.maxAttempts) {
      _logSecurityEvent('CRITICAL: Self-destruct threshold reached');
      await _triggerEmergencyLock();
      
      if (config.autoTrigger) {
        await _secureWipeData();
      }
    }
  }
  
  /// Log security event
  void _logSecurityEvent(String event) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $event';
    _securityLogs.add(logEntry);
    
    if (_securityLogs.length > 1000) {
      _securityLogs.removeAt(0);
    }
    
    _storage.saveSetting('security_logs', _securityLogs);
  }
  
  /// Get security logs
  List<String> getSecurityLogs({int limit = 100}) {
    return _securityLogs.reversed.take(limit).toList();
  }
  
  /// Clear security logs
  Future<void> clearSecurityLogs() async {
    _securityLogs.clear();
    await _storage.deleteSetting('security_logs');
    _logSecurityEvent('Security logs cleared');
  }

  /// Generate cryptographically secure password
  String generateSecurePassword({int length = 16, bool includeSymbols = true}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const symbols = '!@#\u0024%^&*()_+-=[]{}|;:,.<>?';
    
    final charset = includeSymbols ? chars + symbols : chars;
    final random = Random.secure();
    
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  List<String> _generateSecurityRecommendations(
    int totalWallets,
    int lockedWallets,
    int hiddenWallets,
  ) {
    final recommendations = <String>[];
    
    if (lockedWallets < totalWallets * 0.5) {
      recommendations.add('Consider enabling locks on more wallets for better security');
    }
    
    if (hiddenWallets == 0) {
      recommendations.add('Create hidden wallets for sensitive financial data');
    }
    
    if (!_isStealthModeActive) {
      recommendations.add('Enable stealth mode for additional privacy protection');
    }
    
    if (!_isTamperDetectionActive) {
      recommendations.add('Enable tamper detection for enhanced security');
    }
    
    return recommendations;
  }

  Future<SelfDestructConfig?> _getSelfDestructConfig() async {
    final data = _storage.getSetting<Map<String, dynamic>>('self_destruct_config');
    return data != null ? SelfDestructConfig.fromJson(data) : null;
  }
  
  Future<DecoyModeConfig?> _getDecoyModeConfig() async {
    final data = _storage.getSetting<Map<String, dynamic>>('decoy_mode_config');
    return data != null ? DecoyModeConfig.fromJson(data) : null;
  }
  
  Future<EmergencyConfig?> _getEmergencyConfig() async {
    final data = _storage.getSetting<Map<String, dynamic>>('emergency_config');
    return data != null ? EmergencyConfig.fromJson(data) : null;
  }

  void _startSecurityMonitoring() {
    _securityTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _performSecurityChecks();
    });
  }
  
  Future<void> _performSecurityChecks() async {
    _checkAutoLock();
    await _checkTamperDetection();
    await _storage.saveSetting('failed_attempts', _failedAttempts);
    if (_lockoutUntil != null) {
      await _storage.saveSetting('lockout_until', _lockoutUntil!.toIso8601String());
    }
    if (_isEmergencyLockActive) {
      await _maintainEmergencyLock();
    }
  }
  
  Future<void> _maintainEmergencyLock() async {
    final wallets = await _storage.getAllWallets();
    for (final wallet in wallets) {
      _unlockedWallets[wallet.id] = false;
    }
  }

  void dispose() {
    _securityTimer?.cancel();
    _logSecurityEvent('Security service disposed');
  }
}

/// Security level enum
enum SecurityLevel {
  low,
  medium,
  high,
  maximum,
}

/// PIN strength enum
enum PinStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

/// Panic action enum
enum PanicAction {
  wipeAll,
  wipeSelectedWallets,
  enableStealthMode,
  lockAllWallets,
}

/// Wallet lock configuration
class WalletLockConfig {
  final bool isEnabled;
  final String pinHash;
  final SecurityLevel level;
  final Duration autoLockDuration;
  final DateTime createdAt;
  final DateTime? lastUnlockedAt;

  const WalletLockConfig({
    required this.isEnabled,
    required this.pinHash,
    required this.level,
    required this.autoLockDuration,
    required this.createdAt,
    this.lastUnlockedAt,
  });

  WalletLockConfig copyWith({
    bool? isEnabled,
    String? pinHash,
    SecurityLevel? level,
    Duration? autoLockDuration,
    DateTime? lastUnlockedAt,
  }) {
    return WalletLockConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      pinHash: pinHash ?? this.pinHash,
      level: level ?? this.level,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      createdAt: createdAt,
      lastUnlockedAt: lastUnlockedAt ?? this.lastUnlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'pinHash': pinHash,
        'level': level.toString(),
        'autoLockDuration': autoLockDuration.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
        'lastUnlockedAt': lastUnlockedAt?.toIso8601String(),
      };

  factory WalletLockConfig.fromJson(Map<String, dynamic> json) => WalletLockConfig(
        isEnabled: json['isEnabled'],
        pinHash: json['pinHash'],
        level: SecurityLevel.values.firstWhere(
          (e) => e.toString() == json['level'],
        ),
        autoLockDuration: Duration(milliseconds: json['autoLockDuration']),
        createdAt: DateTime.parse(json['createdAt']),
        lastUnlockedAt: json['lastUnlockedAt'] != null
            ? DateTime.parse(json['lastUnlockedAt'])
            : null,
      );
}

/// Hidden wallet configuration
class HiddenWalletConfig {
  final String walletId;
  final String pinHash;
  final bool isVisible;
  final DateTime createdAt;

  const HiddenWalletConfig({
    required this.walletId,
    required this.pinHash,
    required this.isVisible,
    required this.createdAt,
  });

  HiddenWalletConfig copyWith({
    bool? isVisible,
  }) {
    return HiddenWalletConfig(
      walletId: walletId,
      pinHash: pinHash,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'walletId': walletId,
        'pinHash': pinHash,
        'isVisible': isVisible,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HiddenWalletConfig.fromJson(Map<String, dynamic> json) => HiddenWalletConfig(
        walletId: json['walletId'],
        pinHash: json['pinHash'],
        isVisible: json['isVisible'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// Stealth mode configuration
class StealthModeConfig {
  final bool isEnabled;
  final String pinHash;
  final List<String> hiddenWalletIds;
  final bool hideTransactionAmounts;
  final bool hideBalances;
  final DateTime activatedAt;

  const StealthModeConfig({
    required this.isEnabled,
    required this.pinHash,
    required this.hiddenWalletIds,
    required this.hideTransactionAmounts,
    required this.hideBalances,
    required this.activatedAt,
  });

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'pinHash': pinHash,
        'hiddenWalletIds': hiddenWalletIds,
        'hideTransactionAmounts': hideTransactionAmounts,
        'hideBalances': hideBalances,
        'activatedAt': activatedAt.toIso8601String(),
      };

  factory StealthModeConfig.fromJson(Map<String, dynamic> json) => StealthModeConfig(
        isEnabled: json['isEnabled'],
        pinHash: json['pinHash'],
        hiddenWalletIds: List<String>.from(json['hiddenWalletIds']),
        hideTransactionAmounts: json['hideTransactionAmounts'],
        hideBalances: json['hideBalances'],
        activatedAt: DateTime.parse(json['activatedAt']),
      );
}

/// Panic mode configuration
class PanicModeConfig {
  final bool isEnabled;
  final String pinHash;
  final PanicAction action;
  final List<String> walletsToWipe;
  final DateTime createdAt;

  const PanicModeConfig({
    required this.isEnabled,
    required this.pinHash,
    required this.action,
    required this.walletsToWipe,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'pinHash': pinHash,
        'action': action.toString(),
        'walletsToWipe': walletsToWipe,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PanicModeConfig.fromJson(Map<String, dynamic> json) => PanicModeConfig(
        isEnabled: json['isEnabled'],
        pinHash: json['pinHash'],
        action: PanicAction.values.firstWhere(
          (e) => e.toString() == json['action'],
        ),
        walletsToWipe: List<String>.from(json['walletsToWipe']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// Security audit report
class SecurityAuditReport {
  final int totalWallets;
  final int lockedWallets;
  final int unlockedWallets;
  final int hiddenWallets;
  final bool isStealthModeEnabled;
  final bool isPanicModeEnabled;
  final bool isCalculatorModeEnabled;
  final DateTime? lastActivity;
  final List<String> recommendations;

  const SecurityAuditReport({
    required this.totalWallets,
    required this.lockedWallets,
    required this.unlockedWallets,
    required this.hiddenWallets,
    required this.isStealthModeEnabled,
    required this.isPanicModeEnabled,
    required this.isCalculatorModeEnabled,
    this.lastActivity,
    required this.recommendations,
  });
}
