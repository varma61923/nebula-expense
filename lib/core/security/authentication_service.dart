import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import 'encryption_service.dart';

/// Comprehensive authentication service with PIN, biometrics, and security features
class AuthenticationService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final LocalAuthentication _localAuth = LocalAuthentication();
  final EncryptionService _encryptionService = EncryptionService();

  // Storage keys
  static const String _pinHashKey = 'user_pin_hash';
  static const String _pinSaltKey = 'user_pin_salt';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const String _decoyPinHashKey = 'decoy_pin_hash';
  static const String _decoyPinSaltKey = 'decoy_pin_salt';
  static const String _stealthModeKey = 'stealth_mode_enabled';
  static const String _selfDestructPinKey = 'self_destruct_pin';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const String _authMethodKey = 'preferred_auth_method';

  bool _isAuthenticated = false;
  Timer? _lockoutTimer;
  Timer? _autoLockTimer;

  /// Initialize authentication service
  Future<void> initialize() async {
    await _encryptionService.initialize();
    await _checkLockoutStatus();
  }

  /// Check if user has set up authentication
  Future<bool> isAuthenticationSetup() async {
    final pinHash = await _secureStorage.read(key: _pinHashKey);
    return pinHash != null;
  }

  /// Set up PIN authentication
  Future<void> setupPin(String pin) async {
    if (pin.length < 4 || pin.length > 8) {
      throw AuthenticationException('PIN must be between 4-8 digits');
    }

    final salt = EncryptionService.generateSalt();
    final pinHash = _hashPin(pin, salt);

    await _secureStorage.write(key: _pinHashKey, value: pinHash);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _resetFailedAttempts();
  }

  /// Set up decoy PIN for stealth mode
  Future<void> setupDecoyPin(String decoyPin) async {
    if (decoyPin.length < 4 || decoyPin.length > 8) {
      throw AuthenticationException('Decoy PIN must be between 4-8 digits');
    }

    final salt = EncryptionService.generateSalt();
    final pinHash = _hashPin(decoyPin, salt);

    await _secureStorage.write(key: _decoyPinHashKey, value: pinHash);
    await _secureStorage.write(key: _decoyPinSaltKey, value: salt);
  }

  /// Set up self-destruct PIN
  Future<void> setupSelfDestructPin(String destructPin) async {
    if (destructPin.length < 6) {
      throw AuthenticationException('Self-destruct PIN must be at least 6 digits');
    }

    final encrypted = await _encryptionService.encrypt(destructPin);
    await _secureStorage.write(key: _selfDestructPinKey, value: encrypted);
  }

  /// Authenticate with PIN
  Future<AuthenticationResult> authenticateWithPin(String pin) async {
    if (await _isLockedOut()) {
      return AuthenticationResult.lockedOut;
    }

    // Check for self-destruct PIN first
    if (await _isSelfDestructPin(pin)) {
      await _performSelfDestruct();
      return AuthenticationResult.selfDestruct;
    }

    // Check for decoy PIN
    if (await _isDecoyPin(pin)) {
      _isAuthenticated = true;
      await _resetFailedAttempts();
      return AuthenticationResult.decoySuccess;
    }

    // Check main PIN
    if (await _isValidPin(pin)) {
      _isAuthenticated = true;
      await _resetFailedAttempts();
      await _updateLastAuthTime();
      _startAutoLockTimer();
      return AuthenticationResult.success;
    }

    // Failed authentication
    await _incrementFailedAttempts();
    return AuthenticationResult.failed;
  }

  /// Authenticate with biometrics
  Future<AuthenticationResult> authenticateWithBiometrics() async {
    if (!await isBiometricEnabled()) {
      return AuthenticationResult.notAvailable;
    }

    if (await _isLockedOut()) {
      return AuthenticationResult.lockedOut;
    }

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return AuthenticationResult.notAvailable;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return AuthenticationResult.notAvailable;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: AppConstants.biometricReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        _isAuthenticated = true;
        await _resetFailedAttempts();
        await _updateLastAuthTime();
        _startAutoLockTimer();
        return AuthenticationResult.success;
      }

      return AuthenticationResult.failed;
    } catch (e) {
      if (e is PlatformException) {
        switch (e.code) {
          case 'NotAvailable':
            return AuthenticationResult.notAvailable;
          case 'NotEnrolled':
            return AuthenticationResult.notEnrolled;
          case 'LockedOut':
            return AuthenticationResult.lockedOut;
          default:
            return AuthenticationResult.failed;
        }
      }
      return AuthenticationResult.failed;
    }
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        throw AuthenticationException('Biometric authentication not available');
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        throw AuthenticationException('No biometric methods enrolled');
      }
    }

    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Enable/disable stealth mode
  Future<void> setStealthMode(bool enabled) async {
    await _secureStorage.write(key: _stealthModeKey, value: enabled.toString());
  }

  /// Check if stealth mode is enabled
  Future<bool> isStealthModeEnabled() async {
    final enabled = await _secureStorage.read(key: _stealthModeKey);
    return enabled == 'true';
  }

  /// Change PIN
  Future<void> changePin(String currentPin, String newPin) async {
    if (!await _isValidPin(currentPin)) {
      throw AuthenticationException('Current PIN is incorrect');
    }

    await setupPin(newPin);
    await _encryptionService.changeMasterKey(newPin);
  }

  /// Lock the application
  void lock() {
    _isAuthenticated = false;
    _autoLockTimer?.cancel();
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Get failed attempts count
  Future<int> getFailedAttempts() async {
    final attempts = await _secureStorage.read(key: _failedAttemptsKey);
    return int.tryParse(attempts ?? '0') ?? 0;
  }

  /// Get remaining lockout time in seconds
  Future<int> getRemainingLockoutTime() async {
    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) return 0;

    final lockoutTime = DateTime.tryParse(lockoutTimeStr);
    if (lockoutTime == null) return 0;

    final now = DateTime.now();
    final difference = lockoutTime.difference(now).inSeconds;
    return difference > 0 ? difference : 0;
  }

  /// Start auto-lock timer
  void _startAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(const Duration(minutes: 5), () {
      lock();
    });
  }

  /// Reset auto-lock timer
  void resetAutoLockTimer() {
    if (_isAuthenticated) {
      _startAutoLockTimer();
    }
  }

  // Private methods

  Future<bool> _isValidPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);

    if (storedHash == null || salt == null) return false;

    final pinHash = _hashPin(pin, salt);
    return pinHash == storedHash;
  }

  Future<bool> _isDecoyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _decoyPinHashKey);
    final salt = await _secureStorage.read(key: _decoyPinSaltKey);

    if (storedHash == null || salt == null) return false;

    final pinHash = _hashPin(pin, salt);
    return pinHash == storedHash;
  }

  Future<bool> _isSelfDestructPin(String pin) async {
    final encryptedPin = await _secureStorage.read(key: _selfDestructPinKey);
    if (encryptedPin == null) return false;

    try {
      final decryptedPin = await _encryptionService.decrypt(encryptedPin);
      return pin == decryptedPin;
    } catch (e) {
      return false;
    }
  }

  String _hashPin(String pin, String salt) {
    final combined = pin + salt + _encryptionService.deviceId;
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _incrementFailedAttempts() async {
    final currentAttempts = await getFailedAttempts();
    final newAttempts = currentAttempts + 1;

    await _secureStorage.write(key: _failedAttemptsKey, value: newAttempts.toString());

    if (newAttempts >= AppConstants.maxPinAttempts) {
      final lockoutTime = DateTime.now().add(
        Duration(minutes: AppConstants.lockoutDurationMinutes),
      );
      await _secureStorage.write(key: _lockoutTimeKey, value: lockoutTime.toIso8601String());
    }
  }

  Future<void> _resetFailedAttempts() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockoutTimeKey);
  }

  Future<bool> _isLockedOut() async {
    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) return false;

    final lockoutTime = DateTime.tryParse(lockoutTimeStr);
    if (lockoutTime == null) return false;

    return DateTime.now().isBefore(lockoutTime);
  }

  Future<void> _checkLockoutStatus() async {
    if (await _isLockedOut()) {
      final remainingTime = await getRemainingLockoutTime();
      _lockoutTimer = Timer(Duration(seconds: remainingTime), () {
        _resetFailedAttempts();
      });
    }
  }

  Future<void> _updateLastAuthTime() async {
    final now = DateTime.now().toIso8601String();
    await _secureStorage.write(key: _lastAuthTimeKey, value: now);
  }

  Future<void> _performSelfDestruct() async {
    try {
      // Secure wipe of all data
      await _encryptionService.selfDestruct();
      await _secureStorage.deleteAll();
      
      // Clear any cached data
      _isAuthenticated = false;
      _autoLockTimer?.cancel();
      _lockoutTimer?.cancel();
    } catch (e) {
      throw AuthenticationException('Self-destruct failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _autoLockTimer?.cancel();
    _lockoutTimer?.cancel();
  }
}

/// Authentication result enum
enum AuthenticationResult {
  success,
  failed,
  lockedOut,
  notAvailable,
  notEnrolled,
  decoySuccess,
  selfDestruct,
}

/// Custom exception for authentication operations
class AuthenticationException implements Exception {
  final String message;
  
  const AuthenticationException(this.message);
  
  @override
  String toString() => 'AuthenticationException: $message';
}
