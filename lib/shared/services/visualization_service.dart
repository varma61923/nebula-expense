import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/storage/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'currency_service.dart';

/// Advanced visualization service for charts, heatmaps, and analytics
class VisualizationService {
  static final VisualizationService _instance = VisualizationService._internal();
  factory VisualizationService() => _instance;
  VisualizationService._internal();

  final StorageService _storage = StorageService();

  /// Generate expense trend chart data
  Future<LineChartData> generateExpenseTrendChart({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    ChartPeriod period = ChartPeriod.month,
  }) async {
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      types: [TransactionType.expense],
    );

    final groupedData = _groupTransactionsByPeriod(transactions, period);
    final spots = <FlSpot>[];
    
    var index = 0.0;
    for (final entry in groupedData.entries) {
      var total = 0.0;
      for (final transaction in entry.value) {
        if (currency != null && transaction.currency != currency) {
          total += CurrencyService.convert(
            amount: transaction.amount,
            fromCurrency: transaction.currency,
            toCurrency: currency,
          );
        } else {
          total += transaction.amount;
        }
      }
      spots.add(FlSpot(index, total));
      index++;
    }

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) => Text(
              _formatCurrency(value, currency ?? 'USD'),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              _formatPeriodLabel(value.toInt(), groupedData.keys.toList(), period),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  /// Generate category distribution pie chart
  Future<PieChartData> generateCategoryPieChart({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    TransactionType type = TransactionType.expense,
  }) async {
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      types: [type],
    );

    final categoryTotals = <String, double>{};
    
    for (final transaction in transactions) {
      var amount = transaction.amount;
      if (currency != null && transaction.currency != currency) {
        amount = CurrencyService.convert(
          amount: amount,
          fromCurrency: transaction.currency,
          toCurrency: currency,
        );
      }
      categoryTotals[transaction.category] = (categoryTotals[transaction.category] ?? 0) + amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = _generateColors(sortedCategories.length);
    final sections = <PieChartSectionData>[];
    
    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final percentage = (entry.value / categoryTotals.values.fold(0.0, (a, b) => a + b)) * 100;
      
      sections.add(PieChartSectionData(
        color: colors[i],
        value: entry.value,
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
    );
  }

  /// Generate monthly comparison bar chart
  Future<BarChartData> generateMonthlyComparisonChart({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
  }) async {
    final expenses = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      types: [TransactionType.expense],
    );

    final income = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      types: [TransactionType.income],
    );

    final expensesByMonth = _groupTransactionsByPeriod(expenses, ChartPeriod.month);
    final incomeByMonth = _groupTransactionsByPeriod(income, ChartPeriod.month);

    final barGroups = <BarChartGroupData>[];
    final allMonths = {...expensesByMonth.keys, ...incomeByMonth.keys}.toList()..sort();

    for (int i = 0; i < allMonths.length; i++) {
      final month = allMonths[i];
      
      var expenseTotal = 0.0;
      var incomeTotal = 0.0;

      if (expensesByMonth.containsKey(month)) {
        for (final transaction in expensesByMonth[month]!) {
          var amount = transaction.amount;
          if (currency != null && transaction.currency != currency) {
            amount = CurrencyService.convert(
              amount: amount,
              fromCurrency: transaction.currency,
              toCurrency: currency,
            );
          }
          expenseTotal += amount;
        }
      }

      if (incomeByMonth.containsKey(month)) {
        for (final transaction in incomeByMonth[month]!) {
          var amount = transaction.amount;
          if (currency != null && transaction.currency != currency) {
            amount = CurrencyService.convert(
              amount: amount,
              fromCurrency: transaction.currency,
              toCurrency: currency,
            );
          }
          incomeTotal += amount;
        }
      }

      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: incomeTotal,
            color: Colors.green,
            width: 15,
          ),
          BarChartRodData(
            toY: expenseTotal,
            color: Colors.red,
            width: 15,
          ),
        ],
      ));
    }

    return BarChartData(
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) => Text(
              _formatCurrency(value, currency ?? 'USD'),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              _formatMonthLabel(allMonths[value.toInt()]),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      gridData: const FlGridData(show: true),
    );
  }

  /// Generate spending heatmap data
  Future<List<List<HeatmapCell>>> generateSpendingHeatmap({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    HeatmapType type = HeatmapType.dailySpending,
  }) async {
    final transactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      types: [TransactionType.expense],
    );

    switch (type) {
      case HeatmapType.dailySpending:
        return _generateDailySpendingHeatmap(transactions, currency);
      case HeatmapType.hourlyActivity:
        return _generateHourlyActivityHeatmap(transactions);
      case HeatmapType.categoryByMonth:
        return _generateCategoryByMonthHeatmap(transactions, currency);
    }
  }

  /// Generate analytics summary
  Future<AnalyticsSummary> generateAnalyticsSummary({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
  }) async {
    final allTransactions = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    final expenses = allTransactions.where((t) => t.type == TransactionType.expense).toList();
    final income = allTransactions.where((t) => t.type == TransactionType.income).toList();

    var totalExpenses = 0.0;
    var totalIncome = 0.0;

    for (final transaction in expenses) {
      var amount = transaction.amount;
      if (currency != null && transaction.currency != currency) {
        amount = CurrencyService.convert(
          amount: amount,
          fromCurrency: transaction.currency,
          toCurrency: currency,
        );
      }
      totalExpenses += amount;
    }

    for (final transaction in income) {
      var amount = transaction.amount;
      if (currency != null && transaction.currency != currency) {
        amount = CurrencyService.convert(
          amount: amount,
          fromCurrency: transaction.currency,
          toCurrency: currency,
        );
      }
      totalIncome += amount;
    }

    final netIncome = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (netIncome / totalIncome) * 100 : 0.0;

    // Calculate averages
    final days = _calculateDaysBetween(startDate, endDate);
    final dailyExpenseAverage = days > 0 ? totalExpenses / days : 0.0;
    final dailyIncomeAverage = days > 0 ? totalIncome / days : 0.0;

    // Top categories
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      var amount = expense.amount;
      if (currency != null && expense.currency != currency) {
        amount = CurrencyService.convert(
          amount: amount,
          fromCurrency: expense.currency,
          toCurrency: currency,
        );
      }
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + amount;
    }

    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Spending trends
    final monthlyExpenses = _groupTransactionsByPeriod(expenses, ChartPeriod.month);
    final trend = _calculateTrend(monthlyExpenses, currency);

    return AnalyticsSummary(
      totalExpenses: totalExpenses,
      totalIncome: totalIncome,
      netIncome: netIncome,
      savingsRate: savingsRate,
      dailyExpenseAverage: dailyExpenseAverage,
      dailyIncomeAverage: dailyIncomeAverage,
      transactionCount: allTransactions.length,
      topCategories: topCategories.take(5).toList(),
      spendingTrend: trend,
      currency: currency ?? 'USD',
    );
  }

  /// Generate budget vs actual chart
  Future<BarChartData> generateBudgetVsActualChart({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
  }) async {
    final expenses = await _getFilteredTransactions(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      types: [TransactionType.expense],
    );

    // Get wallet budgets
    final wallets = walletId != null 
        ? [await _storage.getWallet(walletId)].where((w) => w != null).cast<Wallet>().toList()
        : await _storage.getAllWallets();

    final categoryActuals = <String, double>{};
    final categoryBudgets = <String, double>{};

    // Calculate actual spending by category
    for (final expense in expenses) {
      var amount = expense.amount;
      if (currency != null && expense.currency != currency) {
        amount = CurrencyService.convert(
          amount: amount,
          fromCurrency: expense.currency,
          toCurrency: currency,
        );
      }
      categoryActuals[expense.category] = (categoryActuals[expense.category] ?? 0) + amount;
    }

    // Get budget data from wallets
    for (final wallet in wallets) {
      if (wallet.budgetLimits != null) {
        for (final entry in wallet.budgetLimits!.entries) {
          var budgetAmount = entry.value;
          if (currency != null && wallet.currency != currency) {
            budgetAmount = CurrencyService.convert(
              amount: budgetAmount,
              fromCurrency: wallet.currency,
              toCurrency: currency,
            );
          }
          categoryBudgets[entry.key] = (categoryBudgets[entry.key] ?? 0) + budgetAmount;
        }
      }
    }

    final allCategories = {...categoryActuals.keys, ...categoryBudgets.keys}.toList()..sort();
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < allCategories.length; i++) {
      final category = allCategories[i];
      final actual = categoryActuals[category] ?? 0.0;
      final budget = categoryBudgets[category] ?? 0.0;

      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: budget,
            color: Colors.blue.withOpacity(0.7),
            width: 15,
          ),
          BarChartRodData(
            toY: actual,
            color: actual > budget ? Colors.red : Colors.green,
            width: 15,
          ),
        ],
      ));
    }

    return BarChartData(
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) => Text(
              _formatCurrency(value, currency ?? 'USD'),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              allCategories[value.toInt()],
              style: const TextStyle(fontSize: 8),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      gridData: const FlGridData(show: true),
    );
  }

  // Helper methods
  Future<List<Transaction>> _getFilteredTransactions({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
    List<TransactionType>? types,
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

    if (types != null) {
      transactions = transactions.where((t) => types.contains(t.type)).toList();
    }

    return transactions;
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByPeriod(
    List<Transaction> transactions,
    ChartPeriod period,
  ) {
    final grouped = <DateTime, List<Transaction>>{};

    for (final transaction in transactions) {
      DateTime key;
      switch (period) {
        case ChartPeriod.day:
          key = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
          break;
        case ChartPeriod.week:
          final daysFromMonday = transaction.date.weekday - 1;
          key = DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day - daysFromMonday,
          );
          break;
        case ChartPeriod.month:
          key = DateTime(transaction.date.year, transaction.date.month);
          break;
        case ChartPeriod.year:
          key = DateTime(transaction.date.year);
          break;
      }

      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    return grouped;
  }

  List<Color> _generateColors(int count) {
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      final hue = (i * 360 / count) % 360;
      colors.add(HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor());
    }
    return colors;
  }

  String _formatCurrency(double value, String currency) {
    return CurrencyService.formatAmount(
      amount: value,
      currencyCode: currency,
      showSymbol: true,
    );
  }

  String _formatPeriodLabel(int index, List<DateTime> periods, ChartPeriod period) {
    if (index >= periods.length) return '';
    
    final date = periods[index];
    switch (period) {
      case ChartPeriod.day:
        return '${date.day}/${date.month}';
      case ChartPeriod.week:
        return 'W${_getWeekOfYear(date)}';
      case ChartPeriod.month:
        return '${date.month}/${date.year}';
      case ChartPeriod.year:
        return '${date.year}';
    }
  }

  String _formatMonthLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  List<List<HeatmapCell>> _generateDailySpendingHeatmap(
    List<Transaction> transactions,
    String? currency,
  ) {
    final dailyTotals = <DateTime, double>{};
    
    for (final transaction in transactions) {
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      var amount = transaction.amount;
      if (currency != null && transaction.currency != currency) {
        amount = CurrencyService.convert(
          amount: amount,
          fromCurrency: transaction.currency,
          toCurrency: currency,
        );
      }
      dailyTotals[date] = (dailyTotals[date] ?? 0) + amount;
    }

    // Generate 7x52 grid (days of week x weeks)
    final heatmap = <List<HeatmapCell>>[];
    final now = DateTime.now();
    final startDate = DateTime(now.year, 1, 1);
    
    for (int week = 0; week < 52; week++) {
      final weekData = <HeatmapCell>[];
      for (int day = 0; day < 7; day++) {
        final date = startDate.add(Duration(days: week * 7 + day));
        final amount = dailyTotals[DateTime(date.year, date.month, date.day)] ?? 0.0;
        
        weekData.add(HeatmapCell(
          date: date,
          value: amount,
          intensity: _calculateIntensity(amount, dailyTotals.values),
        ));
      }
      heatmap.add(weekData);
    }

    return heatmap;
  }

  List<List<HeatmapCell>> _generateHourlyActivityHeatmap(List<Transaction> transactions) {
    final hourlyActivity = <int, Map<int, int>>{};
    
    for (final transaction in transactions) {
      final hour = transaction.date.hour;
      final dayOfWeek = transaction.date.weekday;
      
      hourlyActivity.putIfAbsent(dayOfWeek, () => {});
      hourlyActivity[dayOfWeek]![hour] = (hourlyActivity[dayOfWeek]![hour] ?? 0) + 1;
    }

    // Generate 7x24 grid (days of week x hours)
    final heatmap = <List<HeatmapCell>>[];
    final allCounts = hourlyActivity.values.expand((day) => day.values).toList();
    
    for (int day = 1; day <= 7; day++) {
      final dayData = <HeatmapCell>[];
      for (int hour = 0; hour < 24; hour++) {
        final count = hourlyActivity[day]?[hour] ?? 0;
        
        dayData.add(HeatmapCell(
          date: DateTime(2024, 1, day, hour),
          value: count.toDouble(),
          intensity: _calculateIntensity(count.toDouble(), allCounts.map((c) => c.toDouble())),
        ));
      }
      heatmap.add(dayData);
    }

    return heatmap;
  }

  List<List<HeatmapCell>> _generateCategoryByMonthHeatmap(
    List<Transaction> transactions,
    String? currency,
  ) {
    final categoryMonthTotals = <String, Map<int, double>>{};
    
    for (final transaction in transactions) {
      final month = transaction.date.month;
      var amount = transaction.amount;
      if (currency != null && transaction.currency != currency) {
        amount = CurrencyService.convert(
          amount: amount,
          fromCurrency: transaction.currency,
          toCurrency: currency,
        );
      }
      
      categoryMonthTotals.putIfAbsent(transaction.category, () => {});
      categoryMonthTotals[transaction.category]![month] = 
          (categoryMonthTotals[transaction.category]![month] ?? 0) + amount;
    }

    final categories = categoryMonthTotals.keys.toList()..sort();
    final allAmounts = categoryMonthTotals.values.expand((month) => month.values).toList();
    
    final heatmap = <List<HeatmapCell>>[];
    
    for (final category in categories) {
      final categoryData = <HeatmapCell>[];
      for (int month = 1; month <= 12; month++) {
        final amount = categoryMonthTotals[category]?[month] ?? 0.0;
        
        categoryData.add(HeatmapCell(
          date: DateTime(2024, month),
          value: amount,
          intensity: _calculateIntensity(amount, allAmounts),
          label: category,
        ));
      }
      heatmap.add(categoryData);
    }

    return heatmap;
  }

  double _calculateIntensity(double value, Iterable<double> allValues) {
    if (allValues.isEmpty || value == 0) return 0.0;
    
    final maxValue = allValues.reduce(max);
    return maxValue > 0 ? value / maxValue : 0.0;
  }

  int _calculateDaysBetween(DateTime? startDate, DateTime? endDate) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();
    return end.difference(start).inDays + 1;
  }

  SpendingTrend _calculateTrend(
    Map<DateTime, List<Transaction>> monthlyExpenses,
    String? currency,
  ) {
    if (monthlyExpenses.length < 2) {
      return SpendingTrend.stable;
    }

    final sortedMonths = monthlyExpenses.keys.toList()..sort();
    final monthlyTotals = <double>[];

    for (final month in sortedMonths) {
      var total = 0.0;
      for (final transaction in monthlyExpenses[month]!) {
        var amount = transaction.amount;
        if (currency != null && transaction.currency != currency) {
          amount = CurrencyService.convert(
            amount: amount,
            fromCurrency: transaction.currency,
            toCurrency: currency,
          );
        }
        total += amount;
      }
      monthlyTotals.add(total);
    }

    // Simple trend calculation
    final firstHalf = monthlyTotals.take(monthlyTotals.length ~/ 2).toList();
    final secondHalf = monthlyTotals.skip(monthlyTotals.length ~/ 2).toList();

    final firstAverage = firstHalf.fold(0.0, (a, b) => a + b) / firstHalf.length;
    final secondAverage = secondHalf.fold(0.0, (a, b) => a + b) / secondHalf.length;

    final changePercent = ((secondAverage - firstAverage) / firstAverage) * 100;

    if (changePercent > 10) return SpendingTrend.increasing;
    if (changePercent < -10) return SpendingTrend.decreasing;
    return SpendingTrend.stable;
  }
}

/// Chart period enum
enum ChartPeriod {
  day,
  week,
  month,
  year,
}

/// Heatmap type enum
enum HeatmapType {
  dailySpending,
  hourlyActivity,
  categoryByMonth,
}

/// Spending trend enum
enum SpendingTrend {
  increasing,
  decreasing,
  stable,
}

/// Heatmap cell model
class HeatmapCell {
  final DateTime date;
  final double value;
  final double intensity;
  final String? label;

  const HeatmapCell({
    required this.date,
    required this.value,
    required this.intensity,
    this.label,
  });
}

/// Analytics summary model
class AnalyticsSummary {
  final double totalExpenses;
  final double totalIncome;
  final double netIncome;
  final double savingsRate;
  final double dailyExpenseAverage;
  final double dailyIncomeAverage;
  final int transactionCount;
  final List<MapEntry<String, double>> topCategories;
  final SpendingTrend spendingTrend;
  final String currency;

  const AnalyticsSummary({
    required this.totalExpenses,
    required this.totalIncome,
    required this.netIncome,
    required this.savingsRate,
    required this.dailyExpenseAverage,
    required this.dailyIncomeAverage,
    required this.transactionCount,
    required this.topCategories,
    required this.spendingTrend,
    required this.currency,
  });
}
