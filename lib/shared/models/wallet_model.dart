import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'wallet_model.g.dart';

/// Wallet model for multi-wallet expense tracking
@HiveType(typeId: 0)
@JsonSerializable()
class WalletModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String currency;

  @HiveField(4)
  double balance;

  @HiveField(5)
  WalletType type;

  @HiveField(6)
  String colorHex;

  @HiveField(7)
  String iconName;

  @HiveField(8)
  bool isHidden;

  @HiveField(9)
  bool isLocked;

  @HiveField(10)
  String? lockPin;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13)
  Map<String, dynamic> metadata;

  @HiveField(14)
  double initialBalance;

  @HiveField(15)
  String? parentWalletId;

  @HiveField(16)
  List<String> tags;

  @HiveField(17)
  bool isArchived;

  @HiveField(18)
  String? notes;

  @HiveField(19)
  Map<String, double> budgetLimits;

  WalletModel({
    required this.id,
    required this.name,
    this.description = '',
    this.currency = AppConstants.defaultCurrency,
    this.balance = 0.0,
    this.type = WalletType.personal,
    this.colorHex = '#4A90E2',
    this.iconName = 'wallet',
    this.isHidden = false,
    this.isLocked = false,
    this.lockPin,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
    this.initialBalance = 0.0,
    this.parentWalletId,
    this.tags = const [],
    this.isArchived = false,
    this.notes,
    this.budgetLimits = const {},
  });

  /// Create a copy of the wallet with updated fields
  WalletModel copyWith({
    String? name,
    String? description,
    String? currency,
    double? balance,
    WalletType? type,
    String? colorHex,
    String? iconName,
    bool? isHidden,
    bool? isLocked,
    String? lockPin,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    double? initialBalance,
    String? parentWalletId,
    List<String>? tags,
    bool? isArchived,
    String? notes,
    Map<String, double>? budgetLimits,
  }) {
    return WalletModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isHidden: isHidden ?? this.isHidden,
      isLocked: isLocked ?? this.isLocked,
      lockPin: lockPin ?? this.lockPin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
      initialBalance: initialBalance ?? this.initialBalance,
      parentWalletId: parentWalletId ?? this.parentWalletId,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
      budgetLimits: budgetLimits ?? this.budgetLimits,
    );
  }

  /// Calculate total income for this wallet
  double get totalIncome => balance - initialBalance;

  /// Check if wallet has a budget limit for a category
  bool hasBudgetLimit(String category) => budgetLimits.containsKey(category);

  /// Get budget limit for a category
  double getBudgetLimit(String category) => budgetLimits[category] ?? 0.0;

  /// Set budget limit for a category
  void setBudgetLimit(String category, double limit) {
    budgetLimits[category] = limit;
    updatedAt = DateTime.now();
  }

  /// Remove budget limit for a category
  void removeBudgetLimit(String category) {
    budgetLimits.remove(category);
    updatedAt = DateTime.now();
  }

  /// Add a tag to the wallet
  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      updatedAt = DateTime.now();
    }
  }

  /// Remove a tag from the wallet
  void removeTag(String tag) {
    tags.remove(tag);
    updatedAt = DateTime.now();
  }

  /// Update wallet balance
  void updateBalance(double newBalance) {
    balance = newBalance;
    updatedAt = DateTime.now();
  }

  /// Add to wallet balance
  void addToBalance(double amount) {
    balance += amount;
    updatedAt = DateTime.now();
  }

  /// Subtract from wallet balance
  void subtractFromBalance(double amount) {
    balance -= amount;
    updatedAt = DateTime.now();
  }

  /// Check if wallet is accessible (not hidden and not locked)
  bool get isAccessible => !isHidden && !isLocked;

  /// Validate wallet data
  bool get isValid {
    return id.isNotEmpty &&
           name.isNotEmpty &&
           currency.isNotEmpty &&
           colorHex.isNotEmpty &&
           iconName.isNotEmpty;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$WalletModelToJson(this);

  /// Create from JSON
  factory WalletModel.fromJson(Map<String, dynamic> json) => _$WalletModelFromJson(json);

  /// Create a default wallet
  factory WalletModel.createDefault({
    required String id,
    required String name,
    String currency = AppConstants.defaultCurrency,
    WalletType type = WalletType.personal,
  }) {
    final now = DateTime.now();
    return WalletModel(
      id: id,
      name: name,
      currency: currency,
      type: type,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a hidden wallet
  factory WalletModel.createHidden({
    required String id,
    required String name,
    required String lockPin,
    String currency = AppConstants.defaultCurrency,
  }) {
    final now = DateTime.now();
    return WalletModel(
      id: id,
      name: name,
      currency: currency,
      type: WalletType.hidden,
      isHidden: true,
      isLocked: true,
      lockPin: lockPin,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  String toString() {
    return 'WalletModel(id: $id, name: $name, balance: $balance, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Wallet statistics model
@HiveType(typeId: 1)
@JsonSerializable()
class WalletStats {
  @HiveField(0)
  final String walletId;

  @HiveField(1)
  final double totalIncome;

  @HiveField(2)
  final double totalExpenses;

  @HiveField(3)
  final double currentBalance;

  @HiveField(4)
  final int transactionCount;

  @HiveField(5)
  final DateTime lastTransactionDate;

  @HiveField(6)
  final Map<String, double> categoryExpenses;

  @HiveField(7)
  final Map<String, double> monthlyExpenses;

  @HiveField(8)
  final double averageTransactionAmount;

  @HiveField(9)
  final DateTime calculatedAt;

  WalletStats({
    required this.walletId,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
    required this.transactionCount,
    required this.lastTransactionDate,
    required this.categoryExpenses,
    required this.monthlyExpenses,
    required this.averageTransactionAmount,
    required this.calculatedAt,
  });

  /// Net worth (income - expenses)
  double get netWorth => totalIncome - totalExpenses;

  /// Savings rate as percentage
  double get savingsRate {
    if (totalIncome == 0) return 0.0;
    return (netWorth / totalIncome) * 100;
  }

  /// Most expensive category
  String get topExpenseCategory {
    if (categoryExpenses.isEmpty) return '';
    return categoryExpenses.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Average monthly expenses
  double get averageMonthlyExpenses {
    if (monthlyExpenses.isEmpty) return 0.0;
    return monthlyExpenses.values.reduce((a, b) => a + b) / monthlyExpenses.length;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$WalletStatsToJson(this);

  /// Create from JSON
  factory WalletStats.fromJson(Map<String, dynamic> json) => _$WalletStatsFromJson(json);
}
