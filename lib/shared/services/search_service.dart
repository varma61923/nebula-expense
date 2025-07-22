import 'dart:math';
import '../../core/storage/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

/// Advanced search, filter, and sorting service for offline operations
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final StorageService _storage = StorageService();

  /// Full-text search across transactions
  Future<List<Transaction>> searchTransactions({
    required String query,
    String? walletId,
    List<TransactionType>? types,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    bool includeNotes = true,
    bool includeDescription = true,
    bool includeMerchant = true,
    bool includeCategory = true,
    bool caseSensitive = false,
  }) async {
    final allTransactions = await _storage.getAllTransactions();
    
    // Apply basic filters first
    var filteredTransactions = _applyBasicFilters(
      allTransactions,
      walletId: walletId,
      types: types,
      categories: categories,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      tags: tags,
    );

    if (query.trim().isEmpty) {
      return filteredTransactions;
    }

    // Perform full-text search
    final searchTerms = _parseSearchQuery(query, caseSensitive);
    final results = <Transaction>[];

    for (final transaction in filteredTransactions) {
      final score = _calculateSearchScore(
        transaction,
        searchTerms,
        includeNotes: includeNotes,
        includeDescription: includeDescription,
        includeMerchant: includeMerchant,
        includeCategory: includeCategory,
        caseSensitive: caseSensitive,
      );

      if (score > 0) {
        results.add(transaction);
      }
    }

    // Sort by relevance score (highest first)
    results.sort((a, b) {
      final scoreA = _calculateSearchScore(
        a,
        searchTerms,
        includeNotes: includeNotes,
        includeDescription: includeDescription,
        includeMerchant: includeMerchant,
        includeCategory: includeCategory,
        caseSensitive: caseSensitive,
      );
      final scoreB = _calculateSearchScore(
        b,
        searchTerms,
        includeNotes: includeNotes,
        includeDescription: includeDescription,
        includeMerchant: includeMerchant,
        includeCategory: includeCategory,
        caseSensitive: caseSensitive,
      );
      return scoreB.compareTo(scoreA);
    });

    return results;
  }

  /// Search wallets
  Future<List<Wallet>> searchWallets({
    required String query,
    bool caseSensitive = false,
  }) async {
    final allWallets = await _storage.getAllWallets();
    
    if (query.trim().isEmpty) {
      return allWallets;
    }

    final searchTerms = _parseSearchQuery(query, caseSensitive);
    final results = <Wallet>[];

    for (final wallet in allWallets) {
      if (_walletMatchesSearch(wallet, searchTerms, caseSensitive)) {
        results.add(wallet);
      }
    }

    return results;
  }

  /// Advanced filtering with multiple criteria
  Future<List<Transaction>> filterTransactions({
    String? walletId,
    List<TransactionType>? types,
    List<String>? categories,
    List<String>? subcategories,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    List<String>? merchants,
    List<String>? paymentMethods,
    bool? isReconciled,
    bool? isRecurring,
    bool? hasAttachments,
    Map<String, dynamic>? customFieldFilters,
  }) async {
    final allTransactions = await _storage.getAllTransactions();
    
    return _applyAdvancedFilters(
      allTransactions,
      walletId: walletId,
      types: types,
      categories: categories,
      subcategories: subcategories,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      tags: tags,
      merchants: merchants,
      paymentMethods: paymentMethods,
      isReconciled: isReconciled,
      isRecurring: isRecurring,
      hasAttachments: hasAttachments,
      customFieldFilters: customFieldFilters,
    );
  }

  /// Sort transactions by various criteria
  List<Transaction> sortTransactions(
    List<Transaction> transactions, {
    required SortCriteria criteria,
    required SortOrder order,
  }) {
    final sorted = List<Transaction>.from(transactions);

    switch (criteria) {
      case SortCriteria.date:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortCriteria.amount:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortCriteria.description:
        sorted.sort((a, b) => a.description.compareTo(b.description));
        break;
      case SortCriteria.category:
        sorted.sort((a, b) => a.category.compareTo(b.category));
        break;
      case SortCriteria.merchant:
        sorted.sort((a, b) => (a.merchant ?? '').compareTo(b.merchant ?? ''));
        break;
      case SortCriteria.type:
        sorted.sort((a, b) => a.type.toString().compareTo(b.type.toString()));
        break;
      case SortCriteria.createdAt:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortCriteria.updatedAt:
        sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
    }

    if (order == SortOrder.descending) {
      return sorted.reversed.toList();
    }

    return sorted;
  }

  /// Get search suggestions based on transaction history
  Future<SearchSuggestions> getSearchSuggestions({
    String? walletId,
    int maxSuggestions = 10,
  }) async {
    final transactions = walletId != null
        ? await _storage.getTransactionsByWallet(walletId)
        : await _storage.getAllTransactions();

    final descriptions = <String>{};
    final merchants = <String>{};
    final categories = <String>{};
    final tags = <String>{};

    for (final transaction in transactions) {
      descriptions.add(transaction.description);
      if (transaction.merchant != null) merchants.add(transaction.merchant!);
      categories.add(transaction.category);
      tags.addAll(transaction.tags);
    }

    return SearchSuggestions(
      descriptions: descriptions.take(maxSuggestions).toList(),
      merchants: merchants.take(maxSuggestions).toList(),
      categories: categories.take(maxSuggestions).toList(),
      tags: tags.take(maxSuggestions).toList(),
    );
  }

  /// Get popular search terms
  Future<List<String>> getPopularSearchTerms({
    String? walletId,
    int maxTerms = 20,
  }) async {
    final transactions = walletId != null
        ? await _storage.getTransactionsByWallet(walletId)
        : await _storage.getAllTransactions();

    final termFrequency = <String, int>{};

    for (final transaction in transactions) {
      final words = _extractWords(transaction.description);
      for (final word in words) {
        if (word.length > 2) {
          termFrequency[word] = (termFrequency[word] ?? 0) + 1;
        }
      }
    }

    final sortedTerms = termFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTerms
        .take(maxTerms)
        .map((e) => e.key)
        .toList();
  }

  /// Save search query to history
  Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final history = await getSearchHistory();
    history.removeWhere((item) => item.query == query);
    history.insert(0, SearchHistoryItem(
      query: query,
      timestamp: DateTime.now(),
    ));

    // Keep only last 50 searches
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    await _storage.saveSetting(
      'search_history',
      history.map((item) => item.toJson()).toList(),
    );
  }

  /// Get search history
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final historyData = _storage.getSetting<List<dynamic>>('search_history') ?? [];
    return historyData
        .map((data) => SearchHistoryItem.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await _storage.deleteSetting('search_history');
  }

  /// Get quick filters for UI
  Future<QuickFilters> getQuickFilters({String? walletId}) async {
    final transactions = walletId != null
        ? await _storage.getTransactionsByWallet(walletId)
        : await _storage.getAllTransactions();

    final categories = transactions.map((t) => t.category).toSet().toList()..sort();
    final merchants = transactions
        .where((t) => t.merchant != null)
        .map((t) => t.merchant!)
        .toSet()
        .toList()..sort();
    final paymentMethods = transactions
        .where((t) => t.paymentMethod != null)
        .map((t) => t.paymentMethod!)
        .toSet()
        .toList()..sort();
    final tags = transactions
        .expand((t) => t.tags)
        .toSet()
        .toList()..sort();

    final amounts = transactions.map((t) => t.amount).toList()..sort();
    final minAmount = amounts.isNotEmpty ? amounts.first : 0.0;
    final maxAmount = amounts.isNotEmpty ? amounts.last : 0.0;

    final dates = transactions.map((t) => t.date).toList()..sort();
    final minDate = dates.isNotEmpty ? dates.first : DateTime.now();
    final maxDate = dates.isNotEmpty ? dates.last : DateTime.now();

    return QuickFilters(
      categories: categories,
      merchants: merchants,
      paymentMethods: paymentMethods,
      tags: tags,
      minAmount: minAmount,
      maxAmount: maxAmount,
      minDate: minDate,
      maxDate: maxDate,
    );
  }

  // Helper methods
  List<Transaction> _applyBasicFilters(
    List<Transaction> transactions, {
    String? walletId,
    List<TransactionType>? types,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
  }) {
    return transactions.where((transaction) {
      if (walletId != null && transaction.walletId != walletId) return false;
      if (types != null && !types.contains(transaction.type)) return false;
      if (categories != null && !categories.contains(transaction.category)) return false;
      if (startDate != null && transaction.date.isBefore(startDate)) return false;
      if (endDate != null && transaction.date.isAfter(endDate)) return false;
      if (minAmount != null && transaction.amount < minAmount) return false;
      if (maxAmount != null && transaction.amount > maxAmount) return false;
      if (tags != null && !tags.any((tag) => transaction.tags.contains(tag))) return false;
      return true;
    }).toList();
  }

  List<Transaction> _applyAdvancedFilters(
    List<Transaction> transactions, {
    String? walletId,
    List<TransactionType>? types,
    List<String>? categories,
    List<String>? subcategories,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    List<String>? merchants,
    List<String>? paymentMethods,
    bool? isReconciled,
    bool? isRecurring,
    bool? hasAttachments,
    Map<String, dynamic>? customFieldFilters,
  }) {
    return transactions.where((transaction) {
      if (walletId != null && transaction.walletId != walletId) return false;
      if (types != null && !types.contains(transaction.type)) return false;
      if (categories != null && !categories.contains(transaction.category)) return false;
      if (subcategories != null && !subcategories.contains(transaction.subcategory)) return false;
      if (startDate != null && transaction.date.isBefore(startDate)) return false;
      if (endDate != null && transaction.date.isAfter(endDate)) return false;
      if (minAmount != null && transaction.amount < minAmount) return false;
      if (maxAmount != null && transaction.amount > maxAmount) return false;
      if (tags != null && !tags.any((tag) => transaction.tags.contains(tag))) return false;
      if (merchants != null && !merchants.contains(transaction.merchant)) return false;
      if (paymentMethods != null && !paymentMethods.contains(transaction.paymentMethod)) return false;
      if (isReconciled != null && transaction.isReconciled != isReconciled) return false;
      if (isRecurring != null && transaction.isRecurring != isRecurring) return false;
      if (hasAttachments != null && transaction.attachmentIds.isNotEmpty != hasAttachments) return false;
      
      if (customFieldFilters != null) {
        for (final entry in customFieldFilters.entries) {
          if (transaction.customFields[entry.key] != entry.value) return false;
        }
      }
      
      return true;
    }).toList();
  }

  List<String> _parseSearchQuery(String query, bool caseSensitive) {
    final normalizedQuery = caseSensitive ? query : query.toLowerCase();
    return normalizedQuery.split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
  }

  double _calculateSearchScore(
    Transaction transaction,
    List<String> searchTerms, {
    required bool includeNotes,
    required bool includeDescription,
    required bool includeMerchant,
    required bool includeCategory,
    required bool caseSensitive,
  }) {
    double score = 0.0;

    final searchableText = _buildSearchableText(
      transaction,
      includeNotes: includeNotes,
      includeDescription: includeDescription,
      includeMerchant: includeMerchant,
      includeCategory: includeCategory,
      caseSensitive: caseSensitive,
    );

    for (final term in searchTerms) {
      if (searchableText.contains(term)) {
        score += 1.0;
        
        // Boost score for exact matches in important fields
        if (includeDescription && _fieldContains(transaction.description, term, caseSensitive)) {
          score += 2.0;
        }
        if (includeCategory && _fieldContains(transaction.category, term, caseSensitive)) {
          score += 1.5;
        }
        if (includeMerchant && transaction.merchant != null && 
            _fieldContains(transaction.merchant!, term, caseSensitive)) {
          score += 1.5;
        }
      }
    }

    return score;
  }

  String _buildSearchableText(
    Transaction transaction, {
    required bool includeNotes,
    required bool includeDescription,
    required bool includeMerchant,
    required bool includeCategory,
    required bool caseSensitive,
  }) {
    final parts = <String>[];

    if (includeDescription) parts.add(transaction.description);
    if (includeCategory) parts.add(transaction.category);
    if (transaction.subcategory != null) parts.add(transaction.subcategory!);
    if (includeMerchant && transaction.merchant != null) parts.add(transaction.merchant!);
    if (includeNotes && transaction.notes != null) parts.add(transaction.notes!);
    if (transaction.location != null) parts.add(transaction.location!);
    if (transaction.paymentMethod != null) parts.add(transaction.paymentMethod!);
    parts.addAll(transaction.tags);

    final text = parts.join(' ');
    return caseSensitive ? text : text.toLowerCase();
  }

  bool _fieldContains(String field, String term, bool caseSensitive) {
    final normalizedField = caseSensitive ? field : field.toLowerCase();
    return normalizedField.contains(term);
  }

  bool _walletMatchesSearch(Wallet wallet, List<String> searchTerms, bool caseSensitive) {
    final searchableText = [
      wallet.name,
      wallet.description ?? '',
      wallet.currency,
      ...wallet.tags,
    ].join(' ');

    final normalizedText = caseSensitive ? searchableText : searchableText.toLowerCase();

    return searchTerms.any((term) => normalizedText.contains(term));
  }

  List<String> _extractWords(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }
}

/// Sort criteria enum
enum SortCriteria {
  date,
  amount,
  description,
  category,
  merchant,
  type,
  createdAt,
  updatedAt,
}

/// Sort order enum
enum SortOrder {
  ascending,
  descending,
}

/// Search suggestions model
class SearchSuggestions {
  final List<String> descriptions;
  final List<String> merchants;
  final List<String> categories;
  final List<String> tags;

  const SearchSuggestions({
    required this.descriptions,
    required this.merchants,
    required this.categories,
    required this.tags,
  });
}

/// Search history item
class SearchHistoryItem {
  final String query;
  final DateTime timestamp;

  const SearchHistoryItem({
    required this.query,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) => SearchHistoryItem(
        query: json['query'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// Quick filters model
class QuickFilters {
  final List<String> categories;
  final List<String> merchants;
  final List<String> paymentMethods;
  final List<String> tags;
  final double minAmount;
  final double maxAmount;
  final DateTime minDate;
  final DateTime maxDate;

  const QuickFilters({
    required this.categories,
    required this.merchants,
    required this.paymentMethods,
    required this.tags,
    required this.minAmount,
    required this.maxAmount,
    required this.minDate,
    required this.maxDate,
  });
}
