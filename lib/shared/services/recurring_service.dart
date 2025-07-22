import 'dart:async';
import 'dart:convert';
import '../../core/storage/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'notification_service.dart';

/// Service for managing recurring transactions and transaction templates
class RecurringService {
  static final RecurringService _instance = RecurringService._internal();
  factory RecurringService() => _instance;
  RecurringService._internal();

  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();
  
  Timer? _recurringTimer;
  bool _isInitialized = false;

  /// Initialize the recurring service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start the recurring transaction processor
      await _startRecurringProcessor();
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize recurring service: $e');
    }
  }

  /// Start the recurring transaction processor
  Future<void> _startRecurringProcessor() async {
    // Process immediately on startup
    await _processRecurringTransactions();
    
    // Set up timer to process every hour
    _recurringTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _processRecurringTransactions(),
    );
  }

  /// Process all due recurring transactions
  Future<void> _processRecurringTransactions() async {
    try {
      final recurringTransactions = await getAllRecurringTransactions();
      final now = DateTime.now();

      for (final recurring in recurringTransactions) {
        if (recurring.isActive && _isDue(recurring, now)) {
          await _createRecurringTransaction(recurring);
          await _updateNextDueDate(recurring);
          
          // Schedule notification for next occurrence
          await _scheduleRecurringNotification(recurring);
        }
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking the timer
      print('Error processing recurring transactions: $e');
    }
  }

  /// Check if a recurring transaction is due
  bool _isDue(Transaction recurring, DateTime now) {
    if (recurring.nextDueDate == null) return false;
    
    return now.isAfter(recurring.nextDueDate!) || 
           now.isAtSameMomentAs(recurring.nextDueDate!);
  }

  /// Create a transaction from a recurring template
  Future<void> _createRecurringTransaction(Transaction recurring) async {
    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      walletId: recurring.walletId,
      type: recurring.type,
      amount: recurring.amount,
      currency: recurring.currency,
      category: recurring.category,
      subcategory: recurring.subcategory,
      description: '${recurring.description} (Auto)',
      notes: recurring.notes,
      tags: recurring.tags,
      date: DateTime.now(),
      location: recurring.location,
      merchant: recurring.merchant,
      paymentMethod: recurring.paymentMethod,
      isReconciled: false,
      attachmentIds: [], // Don't copy attachments for auto-generated transactions
      customFields: recurring.customFields,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // Clear recurring fields for the new transaction
      isRecurring: false,
      recurrenceRule: null,
      nextDueDate: null,
      recurringEndDate: null,
      parentRecurringId: recurring.id,
    );

    await _storage.saveTransaction(newTransaction);
  }

  /// Update the next due date for a recurring transaction
  Future<void> _updateNextDueDate(Transaction recurring) async {
    if (recurring.recurrenceRule == null) return;

    final nextDate = _calculateNextDueDate(
      recurring.nextDueDate ?? DateTime.now(),
      recurring.recurrenceRule!,
    );

    // Check if we've passed the end date
    if (recurring.recurringEndDate != null && 
        nextDate.isAfter(recurring.recurringEndDate!)) {
      // Deactivate the recurring transaction
      final updatedRecurring = recurring.copyWith(
        isActive: false,
        nextDueDate: null,
        updatedAt: DateTime.now(),
      );
      await _storage.saveTransaction(updatedRecurring);
      return;
    }

    final updatedRecurring = recurring.copyWith(
      nextDueDate: nextDate,
      updatedAt: DateTime.now(),
    );
    await _storage.saveTransaction(updatedRecurring);
  }

  /// Calculate the next due date based on recurrence rule
  DateTime _calculateNextDueDate(DateTime currentDate, RecurrenceRule rule) {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return currentDate.add(Duration(days: rule.interval));
      
      case RecurrenceFrequency.weekly:
        return currentDate.add(Duration(days: 7 * rule.interval));
      
      case RecurrenceFrequency.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + rule.interval,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
      
      case RecurrenceFrequency.yearly:
        return DateTime(
          currentDate.year + rule.interval,
          currentDate.month,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
      
      case RecurrenceFrequency.custom:
        // For custom frequencies, use the custom interval in days
        return currentDate.add(Duration(days: rule.customIntervalDays ?? 1));
    }
  }

  /// Schedule notification for recurring transaction
  Future<void> _scheduleRecurringNotification(Transaction recurring) async {
    if (recurring.nextDueDate == null) return;

    final notificationTime = recurring.nextDueDate!.subtract(
      const Duration(hours: 1), // Notify 1 hour before
    );

    if (notificationTime.isAfter(DateTime.now())) {
      await _notificationService.scheduleRecurringTransactionReminder(
        id: 'recurring_${recurring.id}',
        title: 'Recurring Transaction Due',
        body: '${recurring.description} - ${recurring.amount} ${recurring.currency}',
        scheduledDate: notificationTime,
        transactionId: recurring.id,
      );
    }
  }

  /// Create a new recurring transaction
  Future<String> createRecurringTransaction({
    required String walletId,
    required TransactionType type,
    required double amount,
    required String currency,
    required String category,
    required String description,
    required RecurrenceRule recurrenceRule,
    required DateTime startDate,
    String? subcategory,
    String? notes,
    List<String>? tags,
    String? location,
    String? merchant,
    String? paymentMethod,
    DateTime? endDate,
    Map<String, dynamic>? customFields,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final nextDueDate = _calculateNextDueDate(startDate, recurrenceRule);
    
    final recurring = Transaction(
      id: id,
      walletId: walletId,
      type: type,
      amount: amount,
      currency: currency,
      category: category,
      subcategory: subcategory,
      description: description,
      notes: notes,
      tags: tags ?? [],
      date: startDate,
      location: location,
      merchant: merchant,
      paymentMethod: paymentMethod,
      isReconciled: false,
      attachmentIds: [],
      customFields: customFields ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRecurring: true,
      recurrenceRule: recurrenceRule,
      nextDueDate: nextDueDate,
      recurringEndDate: endDate,
      isActive: true,
    );

    await _storage.saveTransaction(recurring);
    await _scheduleRecurringNotification(recurring);
    
    return id;
  }

  /// Update a recurring transaction
  Future<void> updateRecurringTransaction(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final existing = await _storage.getTransaction(id);
    if (existing == null || !existing.isRecurring) {
      throw Exception('Recurring transaction not found');
    }

    final updated = existing.copyWith(
      walletId: updates['walletId'] ?? existing.walletId,
      type: updates['type'] ?? existing.type,
      amount: updates['amount'] ?? existing.amount,
      currency: updates['currency'] ?? existing.currency,
      category: updates['category'] ?? existing.category,
      subcategory: updates['subcategory'] ?? existing.subcategory,
      description: updates['description'] ?? existing.description,
      notes: updates['notes'] ?? existing.notes,
      tags: updates['tags'] ?? existing.tags,
      location: updates['location'] ?? existing.location,
      merchant: updates['merchant'] ?? existing.merchant,
      paymentMethod: updates['paymentMethod'] ?? existing.paymentMethod,
      customFields: updates['customFields'] ?? existing.customFields,
      recurrenceRule: updates['recurrenceRule'] ?? existing.recurrenceRule,
      recurringEndDate: updates['recurringEndDate'] ?? existing.recurringEndDate,
      isActive: updates['isActive'] ?? existing.isActive,
      updatedAt: DateTime.now(),
    );

    // Recalculate next due date if recurrence rule changed
    if (updates.containsKey('recurrenceRule') && updated.recurrenceRule != null) {
      final nextDate = _calculateNextDueDate(
        updated.nextDueDate ?? DateTime.now(),
        updated.recurrenceRule!,
      );
      final finalUpdated = updated.copyWith(nextDueDate: nextDate);
      await _storage.saveTransaction(finalUpdated);
      await _scheduleRecurringNotification(finalUpdated);
    } else {
      await _storage.saveTransaction(updated);
    }
  }

  /// Delete a recurring transaction
  Future<void> deleteRecurringTransaction(String id) async {
    final existing = await _storage.getTransaction(id);
    if (existing == null || !existing.isRecurring) {
      throw Exception('Recurring transaction not found');
    }

    await _storage.deleteTransaction(id);
    
    // Cancel notification
    await _notificationService.cancelNotification('recurring_$id');
  }

  /// Pause a recurring transaction
  Future<void> pauseRecurringTransaction(String id) async {
    await updateRecurringTransaction(id, {'isActive': false});
    await _notificationService.cancelNotification('recurring_$id');
  }

  /// Resume a recurring transaction
  Future<void> resumeRecurringTransaction(String id) async {
    await updateRecurringTransaction(id, {'isActive': true});
    
    final recurring = await _storage.getTransaction(id);
    if (recurring != null) {
      await _scheduleRecurringNotification(recurring);
    }
  }

  /// Get all recurring transactions
  Future<List<Transaction>> getAllRecurringTransactions() async {
    final allTransactions = await _storage.getAllTransactions();
    return allTransactions.where((t) => t.isRecurring).toList();
  }

  /// Get recurring transactions for a specific wallet
  Future<List<Transaction>> getRecurringTransactionsByWallet(String walletId) async {
    final recurring = await getAllRecurringTransactions();
    return recurring.where((t) => t.walletId == walletId).toList();
  }

  /// Get active recurring transactions
  Future<List<Transaction>> getActiveRecurringTransactions() async {
    final recurring = await getAllRecurringTransactions();
    return recurring.where((t) => t.isActive).toList();
  }

  /// Get upcoming recurring transactions (next 30 days)
  Future<List<Transaction>> getUpcomingRecurringTransactions({int days = 30}) async {
    final recurring = await getActiveRecurringTransactions();
    final cutoffDate = DateTime.now().add(Duration(days: days));
    
    return recurring
        .where((t) => t.nextDueDate != null && t.nextDueDate!.isBefore(cutoffDate))
        .toList()
      ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
  }

  /// Create a transaction template
  Future<String> createTemplate({
    required String name,
    required String walletId,
    required TransactionType type,
    required double amount,
    required String currency,
    required String category,
    required String description,
    String? subcategory,
    String? notes,
    List<String>? tags,
    String? location,
    String? merchant,
    String? paymentMethod,
    Map<String, dynamic>? customFields,
  }) async {
    final template = TransactionTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      walletId: walletId,
      type: type,
      amount: amount,
      currency: currency,
      category: category,
      subcategory: subcategory,
      description: description,
      notes: notes,
      tags: tags ?? [],
      location: location,
      merchant: merchant,
      paymentMethod: paymentMethod,
      customFields: customFields ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.saveTemplate(template);
    return template.id;
  }

  /// Update a transaction template
  Future<void> updateTemplate(String id, Map<String, dynamic> updates) async {
    final existing = await _storage.getTemplate(id);
    if (existing == null) {
      throw Exception('Template not found');
    }

    final updated = existing.copyWith(
      name: updates['name'] ?? existing.name,
      walletId: updates['walletId'] ?? existing.walletId,
      type: updates['type'] ?? existing.type,
      amount: updates['amount'] ?? existing.amount,
      currency: updates['currency'] ?? existing.currency,
      category: updates['category'] ?? existing.category,
      subcategory: updates['subcategory'] ?? existing.subcategory,
      description: updates['description'] ?? existing.description,
      notes: updates['notes'] ?? existing.notes,
      tags: updates['tags'] ?? existing.tags,
      location: updates['location'] ?? existing.location,
      merchant: updates['merchant'] ?? existing.merchant,
      paymentMethod: updates['paymentMethod'] ?? existing.paymentMethod,
      customFields: updates['customFields'] ?? existing.customFields,
      updatedAt: DateTime.now(),
    );

    await _storage.saveTemplate(updated);
  }

  /// Delete a transaction template
  Future<void> deleteTemplate(String id) async {
    await _storage.deleteTemplate(id);
  }

  /// Get all transaction templates
  Future<List<TransactionTemplate>> getAllTemplates() async {
    return await _storage.getAllTemplates();
  }

  /// Get templates for a specific wallet
  Future<List<TransactionTemplate>> getTemplatesByWallet(String walletId) async {
    final templates = await getAllTemplates();
    return templates.where((t) => t.walletId == walletId).toList();
  }

  /// Create transaction from template
  Future<String> createTransactionFromTemplate(
    String templateId, {
    double? overrideAmount,
    DateTime? overrideDate,
    String? overrideNotes,
    Map<String, dynamic>? additionalFields,
  }) async {
    final template = await _storage.getTemplate(templateId);
    if (template == null) {
      throw Exception('Template not found');
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      walletId: template.walletId,
      type: template.type,
      amount: overrideAmount ?? template.amount,
      currency: template.currency,
      category: template.category,
      subcategory: template.subcategory,
      description: template.description,
      notes: overrideNotes ?? template.notes,
      tags: template.tags,
      date: overrideDate ?? DateTime.now(),
      location: template.location,
      merchant: template.merchant,
      paymentMethod: template.paymentMethod,
      isReconciled: false,
      attachmentIds: [],
      customFields: {
        ...template.customFields,
        ...?additionalFields,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRecurring: false,
    );

    await _storage.saveTransaction(transaction);
    return transaction.id;
  }

  /// Get template usage statistics
  Future<Map<String, int>> getTemplateUsageStats() async {
    final transactions = await _storage.getAllTransactions();
    final templates = await getAllTemplates();
    
    final usage = <String, int>{};
    
    for (final template in templates) {
      final count = transactions
          .where((t) => t.description == template.description &&
                      t.category == template.category &&
                      t.amount == template.amount)
          .length;
      usage[template.id] = count;
    }
    
    return usage;
  }

  /// Get recurring transaction statistics
  Future<RecurringStats> getRecurringStats() async {
    final recurring = await getAllRecurringTransactions();
    final active = recurring.where((t) => t.isActive).length;
    final paused = recurring.where((t) => !t.isActive).length;
    
    final upcoming = await getUpcomingRecurringTransactions();
    final overdue = recurring
        .where((t) => t.isActive && 
                     t.nextDueDate != null && 
                     t.nextDueDate!.isBefore(DateTime.now()))
        .length;

    return RecurringStats(
      total: recurring.length,
      active: active,
      paused: paused,
      upcoming: upcoming.length,
      overdue: overdue,
    );
  }

  /// Dispose resources
  void dispose() {
    _recurringTimer?.cancel();
    _isInitialized = false;
  }
}

/// Transaction template model
class TransactionTemplate {
  final String id;
  final String name;
  final String walletId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String category;
  final String? subcategory;
  final String description;
  final String? notes;
  final List<String> tags;
  final String? location;
  final String? merchant;
  final String? paymentMethod;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionTemplate({
    required this.id,
    required this.name,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.category,
    this.subcategory,
    required this.description,
    this.notes,
    required this.tags,
    this.location,
    this.merchant,
    this.paymentMethod,
    required this.customFields,
    required this.createdAt,
    required this.updatedAt,
  });

  TransactionTemplate copyWith({
    String? name,
    String? walletId,
    TransactionType? type,
    double? amount,
    String? currency,
    String? category,
    String? subcategory,
    String? description,
    String? notes,
    List<String>? tags,
    String? location,
    String? merchant,
    String? paymentMethod,
    Map<String, dynamic>? customFields,
    DateTime? updatedAt,
  }) {
    return TransactionTemplate(
      id: id,
      name: name ?? this.name,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'walletId': walletId,
        'type': type.toString(),
        'amount': amount,
        'currency': currency,
        'category': category,
        'subcategory': subcategory,
        'description': description,
        'notes': notes,
        'tags': tags,
        'location': location,
        'merchant': merchant,
        'paymentMethod': paymentMethod,
        'customFields': customFields,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TransactionTemplate.fromJson(Map<String, dynamic> json) => TransactionTemplate(
        id: json['id'],
        name: json['name'],
        walletId: json['walletId'],
        type: TransactionType.values.firstWhere(
          (e) => e.toString() == json['type'],
        ),
        amount: json['amount'].toDouble(),
        currency: json['currency'],
        category: json['category'],
        subcategory: json['subcategory'],
        description: json['description'],
        notes: json['notes'],
        tags: List<String>.from(json['tags'] ?? []),
        location: json['location'],
        merchant: json['merchant'],
        paymentMethod: json['paymentMethod'],
        customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

/// Recurring transaction statistics
class RecurringStats {
  final int total;
  final int active;
  final int paused;
  final int upcoming;
  final int overdue;

  const RecurringStats({
    required this.total,
    required this.active,
    required this.paused,
    required this.upcoming,
    required this.overdue,
  });
}
