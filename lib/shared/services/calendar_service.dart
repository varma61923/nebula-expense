import 'dart:math';
import '../../core/storage/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

/// Service for calendar timeline and smart grouping features
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final StorageService _storage = StorageService();

  /// Get transactions grouped by date
  Future<Map<DateTime, List<Transaction>>> getTransactionsByDate({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    final grouped = <DateTime, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      grouped.putIfAbsent(date, () => []).add(transaction);
    }

    // Sort transactions within each day
    for (final dayTransactions in grouped.values) {
      dayTransactions.sort((a, b) => b.date.compareTo(a.date));
    }

    return grouped;
  }

  /// Get transactions grouped by week
  Future<Map<DateTime, List<Transaction>>> getTransactionsByWeek({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    final grouped = <DateTime, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final weekStart = _getWeekStart(transaction.date);
      grouped.putIfAbsent(weekStart, () => []).add(transaction);
    }

    return grouped;
  }

  /// Get transactions grouped by month
  Future<Map<DateTime, List<Transaction>>> getTransactionsByMonth({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    final grouped = <DateTime, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final monthStart = DateTime(transaction.date.year, transaction.date.month);
      grouped.putIfAbsent(monthStart, () => []).add(transaction);
    }

    return grouped;
  }

  /// Get smart groups based on patterns
  Future<Map<String, List<Transaction>>> getSmartGroups({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    return {
      'High Amount': _getHighAmountTransactions(transactions),
      'Frequent Merchants': _getFrequentMerchantTransactions(transactions),
      'Similar Amounts': _getSimilarAmountTransactions(transactions),
      'Weekend Spending': _getWeekendTransactions(transactions),
      'Late Night': _getLateNightTransactions(transactions),
      'Recurring Patterns': _getRecurringPatternTransactions(transactions),
    };
  }

  /// Get calendar events (transactions + recurring)
  Future<List<CalendarEvent>> getCalendarEvents({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) async {
    final events = <CalendarEvent>[];

    // Add existing transactions
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    for (final transaction in transactions) {
      events.add(CalendarEvent(
        id: transaction.id,
        title: transaction.description,
        amount: transaction.amount,
        currency: transaction.currency,
        date: transaction.date,
        type: CalendarEventType.transaction,
        category: transaction.category,
        isRecurring: transaction.isRecurring,
      ));
    }

    // Add upcoming recurring transactions
    final recurringTransactions = await _storage.getAllTransactions();
    final recurring = recurringTransactions.where((t) => 
        t.isRecurring && 
        t.isActive &&
        (walletId == null || t.walletId == walletId)
    ).toList();

    for (final recurringTransaction in recurring) {
      final upcomingDates = _getUpcomingRecurringDates(
        recurringTransaction,
        startDate,
        endDate,
      );

      for (final date in upcomingDates) {
        events.add(CalendarEvent(
          id: '${recurringTransaction.id}_$date',
          title: '${recurringTransaction.description} (Scheduled)',
          amount: recurringTransaction.amount,
          currency: recurringTransaction.currency,
          date: date,
          type: CalendarEventType.scheduled,
          category: recurringTransaction.category,
          isRecurring: true,
        ));
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  /// Get spending patterns
  Future<SpendingPatterns> getSpendingPatterns({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();

    return SpendingPatterns(
      dailyAverage: _calculateDailyAverage(expenses),
      weeklyAverage: _calculateWeeklyAverage(expenses),
      monthlyAverage: _calculateMonthlyAverage(expenses),
      peakSpendingDay: _getPeakSpendingDay(expenses),
      peakSpendingHour: _getPeakSpendingHour(expenses),
      categoryDistribution: _getCategoryDistribution(expenses),
      merchantFrequency: _getMerchantFrequency(expenses),
      seasonalTrends: _getSeasonalTrends(expenses),
    );
  }

  // Helper methods
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

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  List<Transaction> _getHighAmountTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) return [];
    
    final amounts = transactions.map((t) => t.amount).toList()..sort();
    final threshold = amounts.length > 10 ? amounts[amounts.length - 5] : amounts.last;
    
    return transactions.where((t) => t.amount >= threshold).toList();
  }

  List<Transaction> _getFrequentMerchantTransactions(List<Transaction> transactions) {
    final merchantCounts = <String, int>{};
    
    for (final transaction in transactions) {
      if (transaction.merchant != null && transaction.merchant!.isNotEmpty) {
        merchantCounts[transaction.merchant!] = (merchantCounts[transaction.merchant!] ?? 0) + 1;
      }
    }

    final frequentMerchants = merchantCounts.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .toSet();

    return transactions.where((t) => 
        t.merchant != null && frequentMerchants.contains(t.merchant)).toList();
  }

  List<Transaction> _getSimilarAmountTransactions(List<Transaction> transactions) {
    final groups = <double, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final roundedAmount = (transaction.amount / 10).round() * 10.0;
      groups.putIfAbsent(roundedAmount, () => []).add(transaction);
    }

    final similarGroups = groups.values.where((group) => group.length >= 3);
    return similarGroups.expand((group) => group).toList();
  }

  List<Transaction> _getWeekendTransactions(List<Transaction> transactions) {
    return transactions.where((t) => 
        t.date.weekday == DateTime.saturday || t.date.weekday == DateTime.sunday).toList();
  }

  List<Transaction> _getLateNightTransactions(List<Transaction> transactions) {
    return transactions.where((t) => t.date.hour >= 22 || t.date.hour <= 6).toList();
  }

  List<Transaction> _getRecurringPatternTransactions(List<Transaction> transactions) {
    // Simple pattern detection based on similar amounts and descriptions
    final patterns = <String, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final key = '${transaction.description}_${transaction.amount.round()}';
      patterns.putIfAbsent(key, () => []).add(transaction);
    }

    return patterns.values
        .where((group) => group.length >= 3)
        .expand((group) => group)
        .toList();
  }

  List<DateTime> _getUpcomingRecurringDates(
    Transaction recurring,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dates = <DateTime>[];
    var currentDate = recurring.nextDueDate ?? DateTime.now();

    while (currentDate.isBefore(endDate) && dates.length < 100) {
      if (currentDate.isAfter(startDate) || currentDate.isAtSameMomentAs(startDate)) {
        dates.add(currentDate);
      }

      if (recurring.recurrenceRule != null) {
        currentDate = _calculateNextDate(currentDate, recurring.recurrenceRule!);
      } else {
        break;
      }
    }

    return dates;
  }

  DateTime _calculateNextDate(DateTime current, RecurrenceRule rule) {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: rule.interval));
      case RecurrenceFrequency.weekly:
        return current.add(Duration(days: 7 * rule.interval));
      case RecurrenceFrequency.monthly:
        return DateTime(current.year, current.month + rule.interval, current.day);
      case RecurrenceFrequency.yearly:
        return DateTime(current.year + rule.interval, current.month, current.day);
      case RecurrenceFrequency.custom:
        return current.add(Duration(days: rule.customIntervalDays ?? 1));
    }
  }

  double _calculateDailyAverage(List<Transaction> expenses) {
    if (expenses.isEmpty) return 0.0;
    
    final total = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final days = expenses.map((t) => DateTime(t.date.year, t.date.month, t.date.day)).toSet().length;
    
    return days > 0 ? total / days : 0.0;
  }

  double _calculateWeeklyAverage(List<Transaction> expenses) {
    if (expenses.isEmpty) return 0.0;
    
    final total = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final weeks = expenses.map((t) => _getWeekStart(t.date)).toSet().length;
    
    return weeks > 0 ? total / weeks : 0.0;
  }

  double _calculateMonthlyAverage(List<Transaction> expenses) {
    if (expenses.isEmpty) return 0.0;
    
    final total = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final months = expenses.map((t) => DateTime(t.date.year, t.date.month)).toSet().length;
    
    return months > 0 ? total / months : 0.0;
  }

  int _getPeakSpendingDay(List<Transaction> expenses) {
    final dayCounts = <int, double>{};
    
    for (final expense in expenses) {
      dayCounts[expense.date.weekday] = (dayCounts[expense.date.weekday] ?? 0) + expense.amount;
    }

    return dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int _getPeakSpendingHour(List<Transaction> expenses) {
    final hourCounts = <int, double>{};
    
    for (final expense in expenses) {
      hourCounts[expense.date.hour] = (hourCounts[expense.date.hour] ?? 0) + expense.amount;
    }

    return hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<String, double> _getCategoryDistribution(List<Transaction> expenses) {
    final distribution = <String, double>{};
    
    for (final expense in expenses) {
      distribution[expense.category] = (distribution[expense.category] ?? 0) + expense.amount;
    }

    return distribution;
  }

  Map<String, int> _getMerchantFrequency(List<Transaction> expenses) {
    final frequency = <String, int>{};
    
    for (final expense in expenses) {
      if (expense.merchant != null && expense.merchant!.isNotEmpty) {
        frequency[expense.merchant!] = (frequency[expense.merchant!] ?? 0) + 1;
      }
    }

    return frequency;
  }

  Map<String, double> _getSeasonalTrends(List<Transaction> expenses) {
    final seasons = <String, double>{
      'Spring': 0.0,
      'Summer': 0.0,
      'Autumn': 0.0,
      'Winter': 0.0,
    };

    for (final expense in expenses) {
      final season = _getSeason(expense.date.month);
      seasons[season] = seasons[season]! + expense.amount;
    }

    return seasons;
  }

  String _getSeason(int month) {
    switch (month) {
      case 3:
      case 4:
      case 5:
        return 'Spring';
      case 6:
      case 7:
      case 8:
        return 'Summer';
      case 9:
      case 10:
      case 11:
        return 'Autumn';
      default:
        return 'Winter';
    }
  }
}

/// Calendar event model
class CalendarEvent {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final CalendarEventType type;
  final String category;
  final bool isRecurring;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.type,
    required this.category,
    required this.isRecurring,
  });
}

/// Calendar event type
enum CalendarEventType {
  transaction,
  scheduled,
  reminder,
}

/// Spending patterns model
class SpendingPatterns {
  final double dailyAverage;
  final double weeklyAverage;
  final double monthlyAverage;
  final int peakSpendingDay;
  final int peakSpendingHour;
  final Map<String, double> categoryDistribution;
  final Map<String, int> merchantFrequency;
  final Map<String, double> seasonalTrends;

  const SpendingPatterns({
    required this.dailyAverage,
    required this.weeklyAverage,
    required this.monthlyAverage,
    required this.peakSpendingDay,
    required this.peakSpendingHour,
    required this.categoryDistribution,
    required this.merchantFrequency,
    required this.seasonalTrends,
  });
}
