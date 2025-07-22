/// Core application constants for the offline expense tracker
class AppConstants {
  // App Information
  static const String appName = 'Nebula Expense';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Advanced Military-Grade Offline Expense Tracker with Quantum-Resistant Security';
  
  // Security Constants
  static const String encryptionAlgorithm = 'AES-256-CBC';
  static const int keyDerivationIterations = 100000;
  static const int saltLength = 32;
  static const int ivLength = 16;
  static const int keyLength = 32;
  
  // Storage Constants
  static const String databaseName = 'expense_tracker_db';
  static const String secureStorageKey = 'expense_tracker_secure';
  static const String preferencesKey = 'expense_tracker_prefs';
  
  // Authentication Constants
  static const int maxPinAttempts = 5;
  static const int lockoutDurationMinutes = 30;
  static const String biometricReason = 'Authenticate to access your expense tracker';
  
  // UI Constants
  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultElevation = 8.0;
  
  // Animation Constants
  static const int defaultAnimationDuration = 300;
  static const int fastAnimationDuration = 150;
  static const int slowAnimationDuration = 600;
  
  // File Constants
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedDocumentFormats = ['pdf', 'txt', 'doc', 'docx'];
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Currency Constants
  static const String defaultCurrency = 'USD';
  static const List<String> popularCurrencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY', 'INR', 'KRW'
  ];
  
  // Chart Constants
  static const int maxChartDataPoints = 100;
  static const List<String> chartColors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
    '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
  ];
  
  // Backup Constants
  static const String backupFileExtension = '.etb'; // Expense Tracker Backup
  static const String exportFileExtension = '.csv';
  static const int maxBackupRetention = 30; // days
  
  // Performance Constants
  static const int maxColdStartTimeMs = 1000; // 1 second requirement
  static const int maxDatabaseQueryTimeMs = 100;
  static const int maxUIRenderTimeMs = 16; // 60 FPS
  
  // Feature Flags
  static const bool enableBiometrics = true;
  static const bool enableHiddenWallets = true;
  static const bool enableStealthMode = true;
  static const bool enableAdvancedCharts = true;
  static const bool enableCLIInterface = true;
  
  // Privacy Constants
  static const bool enableTelemetry = false; // Always false for offline app
  static const bool enableAnalytics = false; // Always false for offline app
  static const bool enableCrashReporting = false; // Always false for offline app
  
  // Development Constants
  static const bool isDebugMode = false;
  static const bool enableLogging = true;
  static const String logLevel = 'INFO';
}

/// Application-wide enums
enum AuthenticationMethod {
  pin,
  biometric,
  pattern,
  password,
}

enum ThemeMode {
  light,
  dark,
  system,
  custom,
}

enum WalletType {
  personal,
  business,
  savings,
  investment,
  hidden,
}

enum TransactionType {
  income,
  expense,
  transfer,
}

enum TransactionCategory {
  // Income Categories
  salary,
  freelance,
  investment,
  gift,
  bonus,
  other_income,
  
  // Expense Categories
  food,
  transport,
  shopping,
  entertainment,
  bills,
  healthcare,
  education,
  travel,
  insurance,
  other_expense,
}

enum ChartType {
  pie,
  donut,
  bar,
  line,
  area,
  radar,
  heatmap,
  sunburst,
}

enum ExportFormat {
  json,
  csv,
  pdf,
  excel,
  encrypted,
}

enum BackupType {
  full,
  incremental,
  differential,
}

enum SecurityLevel {
  basic,
  standard,
  high,
  maximum,
}
