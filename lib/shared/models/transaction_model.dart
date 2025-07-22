import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'transaction_model.g.dart';

/// Transaction type enum
@HiveType(typeId: 10)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer,
}

/// Transaction category enum
@HiveType(typeId: 11)
enum TransactionCategory {
  @HiveField(0)
  food,
  @HiveField(1)
  transport,
  @HiveField(2)
  entertainment,
  @HiveField(3)
  shopping,
  @HiveField(4)
  bills,
  @HiveField(5)
  healthcare,
  @HiveField(6)
  education,
  @HiveField(7)
  travel,
  @HiveField(8)
  investment,
  @HiveField(9)
  salary,
  @HiveField(10)
  business,
  @HiveField(11)
  other,
}

/// Transaction model for expense tracking
@HiveType(typeId: 2)
@JsonSerializable()
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String currency;

  @HiveField(5)
  TransactionType type;

  @HiveField(6)
  TransactionCategory category;

  @HiveField(7)
  String walletId;

  @HiveField(8)
  String? toWalletId; // For transfers

  @HiveField(9)
  DateTime date;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  @HiveField(12)
  List<String> tags;

  @HiveField(13)
  String? notes;

  @HiveField(14)
  List<String> attachments; // File paths

  @HiveField(15)
  Map<String, dynamic> metadata;

  @HiveField(16)
  String? location;

  @HiveField(17)
  String? merchant;

  @HiveField(18)
  String? paymentMethod;

  @HiveField(19)
  bool isRecurring;

  @HiveField(20)
  RecurrencePattern? recurrencePattern;

  @HiveField(21)
  String? parentTransactionId; // For recurring transactions

  @HiveField(22)
  bool isTemplate;

  @HiveField(23)
  String? templateName;

  @HiveField(24)
  bool isDeleted;

  @HiveField(25)
  DateTime? deletedAt;

  @HiveField(26)
  String? exchangeRate; // For currency conversions

  @HiveField(27)
  double? originalAmount; // Original amount before conversion

  @HiveField(28)
  String? originalCurrency;

  TransactionModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.amount,
    required this.currency,
    required this.type,
    required this.category,
    required this.walletId,
    this.toWalletId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.notes,
    this.attachments = const [],
    this.metadata = const {},
    this.location,
    this.merchant,
    this.paymentMethod,
    this.isRecurring = false,
    this.recurrencePattern,
    this.parentTransactionId,
    this.isTemplate = false,
    this.templateName,
    this.isDeleted = false,
    this.deletedAt,
    this.exchangeRate,
    this.originalAmount,
    this.originalCurrency,
  });

  /// Create a copy of the transaction with updated fields
  TransactionModel copyWith({
    String? title,
    String? description,
    double? amount,
    String? currency,
    TransactionType? type,
    TransactionCategory? category,
    String? walletId,
    String? toWalletId,
    DateTime? date,
    DateTime? updatedAt,
    List<String>? tags,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    String? location,
    String? merchant,
    String? paymentMethod,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
    String? parentTransactionId,
    bool? isTemplate,
    String? templateName,
    bool? isDeleted,
    DateTime? deletedAt,
    String? exchangeRate,
    double? originalAmount,
    String? originalCurrency,
  }) {
    return TransactionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      category: category ?? this.category,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      location: location ?? this.location,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      isTemplate: isTemplate ?? this.isTemplate,
      templateName: templateName ?? this.templateName,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrency: originalCurrency ?? this.originalCurrency,
    );
  }

  /// Get signed amount (negative for expenses, positive for income)
  double get signedAmount {
    switch (type) {
      case TransactionType.expense:
        return -amount;
      case TransactionType.income:
        return amount;
      case TransactionType.transfer:
        return 0.0; // Transfers don't affect net worth
    }
  }

  /// Check if transaction is a transfer
  bool get isTransfer => type == TransactionType.transfer && toWalletId != null;

  /// Check if transaction has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Add a tag to the transaction
  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      updatedAt = DateTime.now();
    }
  }

  /// Remove a tag from the transaction
  void removeTag(String tag) {
    tags.remove(tag);
    updatedAt = DateTime.now();
  }

  /// Add an attachment to the transaction
  void addAttachment(String filePath) {
    if (!attachments.contains(filePath)) {
      attachments.add(filePath);
      updatedAt = DateTime.now();
    }
  }

  /// Remove an attachment from the transaction
  void removeAttachment(String filePath) {
    attachments.remove(filePath);
    updatedAt = DateTime.now();
  }

  /// Mark transaction as deleted (soft delete)
  void markAsDeleted() {
    isDeleted = true;
    deletedAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Restore deleted transaction
  void restore() {
    isDeleted = false;
    deletedAt = null;
    updatedAt = DateTime.now();
  }

  /// Check if transaction is valid
  bool get isValid {
    return id.isNotEmpty &&
           title.isNotEmpty &&
           amount > 0 &&
           currency.isNotEmpty &&
           walletId.isNotEmpty &&
           (type != TransactionType.transfer || toWalletId != null);
  }

  /// Get category display name
  String get categoryDisplayName {
    return category.toString().split('.').last.replaceAll('_', ' ').toUpperCase();
  }

  /// Get type display name
  String get typeDisplayName {
    return type.toString().split('.').last.toUpperCase();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  /// Create from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);

  /// Create a default transaction
  factory TransactionModel.createDefault({
    required String id,
    required String title,
    required double amount,
    required TransactionType type,
    required String walletId,
    String currency = AppConstants.defaultCurrency,
    TransactionCategory category = TransactionCategory.other,
    DateTime? date,
  }) {
    final now = DateTime.now();
    return TransactionModel(
      id: id,
      title: title,
      amount: amount,
      currency: currency,
      type: type,
      category: category,
      walletId: walletId,
      date: date ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a transfer transaction
  factory TransactionModel.createTransfer({
    required String id,
    required String title,
    required double amount,
    required String fromWalletId,
    required String toWalletId,
    String currency = AppConstants.defaultCurrency,
    DateTime? date,
  }) {
    final now = DateTime.now();
    return TransactionModel(
      id: id,
      title: title,
      amount: amount,
      currency: currency,
      type: TransactionType.transfer,
      category: TransactionCategory.other, // Default category for transfers
      walletId: fromWalletId,
      toWalletId: toWalletId,
      date: date ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a template transaction
  factory TransactionModel.createTemplate({
    required String id,
    required String templateName,
    required String title,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    String currency = AppConstants.defaultCurrency,
  }) {
    final now = DateTime.now();
    return TransactionModel(
      id: id,
      title: title,
      amount: amount,
      currency: currency,
      type: type,
      category: category,
      walletId: '', // Templates don't have a specific wallet
      date: now,
      createdAt: now,
      updatedAt: now,
      isTemplate: true,
      templateName: templateName,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Recurrence pattern for recurring transactions
@HiveType(typeId: 3)
@JsonSerializable()
class RecurrencePattern {
  @HiveField(0)
  final RecurrenceType type;

  @HiveField(1)
  final int interval; // Every X days/weeks/months/years

  @HiveField(2)
  final DateTime? endDate;

  @HiveField(3)
  final int? maxOccurrences;

  @HiveField(4)
  final List<int>? daysOfWeek; // For weekly recurrence (1-7, Monday-Sunday)

  @HiveField(5)
  final int? dayOfMonth; // For monthly recurrence

  @HiveField(6)
  final List<int>? monthsOfYear; // For yearly recurrence (1-12)

  RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.endDate,
    this.maxOccurrences,
    this.daysOfWeek,
    this.dayOfMonth,
    this.monthsOfYear,
  });

  /// Calculate next occurrence date
  DateTime getNextOccurrence(DateTime lastDate) {
    switch (type) {
      case RecurrenceType.daily:
        return lastDate.add(Duration(days: interval));
      case RecurrenceType.weekly:
        return lastDate.add(Duration(days: 7 * interval));
      case RecurrenceType.monthly:
        return DateTime(lastDate.year, lastDate.month + interval, dayOfMonth ?? lastDate.day);
      case RecurrenceType.yearly:
        return DateTime(lastDate.year + interval, lastDate.month, lastDate.day);
    }
  }

  /// Check if recurrence should continue
  bool shouldContinue(DateTime currentDate, int occurrenceCount) {
    if (endDate != null && currentDate.isAfter(endDate!)) {
      return false;
    }
    if (maxOccurrences != null && occurrenceCount >= maxOccurrences!) {
      return false;
    }
    return true;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$RecurrencePatternToJson(this);

  /// Create from JSON
  factory RecurrencePattern.fromJson(Map<String, dynamic> json) => _$RecurrencePatternFromJson(json);
}

/// Recurrence type enum
@HiveType(typeId: 4)
enum RecurrenceType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}

/// Transaction filter model
class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<TransactionType>? types;
  final List<TransactionCategory>? categories;
  final List<String>? walletIds;
  final List<String>? tags;
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery;
  final bool includeDeleted;

  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.types,
    this.categories,
    this.walletIds,
    this.tags,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.includeDeleted = false,
  });

  /// Check if transaction matches filter
  bool matches(TransactionModel transaction) {
    // Check deleted status
    if (!includeDeleted && transaction.isDeleted) return false;

    // Check date range
    if (startDate != null && transaction.date.isBefore(startDate!)) return false;
    if (endDate != null && transaction.date.isAfter(endDate!)) return false;

    // Check types
    if (types != null && !types!.contains(transaction.type)) return false;

    // Check categories
    if (categories != null && !categories!.contains(transaction.category)) return false;

    // Check wallets
    if (walletIds != null && !walletIds!.contains(transaction.walletId)) return false;

    // Check tags
    if (tags != null && !tags!.any((tag) => transaction.tags.contains(tag))) return false;

    // Check amount range
    if (minAmount != null && transaction.amount < minAmount!) return false;
    if (maxAmount != null && transaction.amount > maxAmount!) return false;

    // Check search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!transaction.title.toLowerCase().contains(query) &&
          !transaction.description.toLowerCase().contains(query) &&
          !(transaction.notes?.toLowerCase().contains(query) ?? false) &&
          !(transaction.merchant?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
    }

    return true;
  }
}
