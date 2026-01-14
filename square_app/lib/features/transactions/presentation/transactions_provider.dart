import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../expense/data/expense_model.dart';
import '../data/income_model.dart';
import '../data/investment_model.dart';
import '../data/loan_model.dart';
import '../data/transaction_repository.dart';

final transactionRepositoryProvider = Provider(
  (ref) => TransactionRepository(),
);

// State holding the list and pagination info
class TransactionState<T> {
  final List<T> items;
  final int total;
  final int page;
  final bool hasMore;

  TransactionState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = true,
  });

  TransactionState<T> copyWith({
    List<T>? items,
    int? total,
    int? page,
    bool? hasMore,
  }) {
    return TransactionState<T>(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Generic Notifier
class GenericTransactionNotifier<T> extends AsyncNotifier<TransactionState<T>> {
  final Future<Map<String, dynamic>> Function(
    String token, {
    int page,
    int limit,
  })
  _fetchFunction;
  final T Function(Map<String, dynamic> json) _fromJson;

  GenericTransactionNotifier(this._fetchFunction, this._fromJson);

  @override
  Future<TransactionState<T>> build() async {
    return _fetchData(1, isRefresh: true); // Initial load
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    // We don't set loading state here to avoid rebuilding everything.
    // Instead we just append data.
    // If we wanted a loading spinner at the bottom, we might need a separate 'isLoadingMore' state or handle it in UI.
    // For now, let's just fetch and update.

    try {
      final newState = await _fetchData(
        currentState.page + 1,
        currentItems: currentState.items,
      );
      state = AsyncValue.data(newState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final newState = await _fetchData(1, isRefresh: true);
      state = AsyncValue.data(newState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TransactionState<T>> _fetchData(
    int page, {
    bool isRefresh = false,
    List<T>? currentItems,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    // The repo is accessed via ref inside the lambda passed to constructor, so we don't need it here.

    final result = await _fetchFunction(token, page: page, limit: 10);

    final List<T> newData = (result['data'] as List)
        .map((e) => _fromJson(e))
        .toList();
    final int total = result['total'];

    final List<T> allItems = isRefresh
        ? newData
        : [...?currentItems, ...newData];
    final bool hasMore = allItems.length < total;

    return TransactionState<T>(
      items: allItems,
      total: total,
      page: page,
      hasMore: hasMore,
    );
  }

  // Create method for the specific type
  Future<void> create(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    // Use a separate create function defined by subclass or passed in
    await _createFunction(token, data);

    // Refresh list after creation
    await refresh();
  }

  // Abstract getter for create function
  Future<void> Function(String token, Map<String, dynamic> data)
  get _createFunction => (t, d) async {};
}

// Concrete implementations to allow Riverpod to instantiate them
class ExpensesNotifier extends GenericTransactionNotifier<Expense> {
  ExpensesNotifier()
    : super(
        (token, {page = 1, limit = 10}) => TransactionRepository().getExpenses(
          token,
          page: page,
          limit: limit,
        ),
        Expense.fromJson,
      );

  @override
  Future<Map<String, dynamic>> Function(String, {int page, int limit})
  get _fetchFunction =>
      (token, {page = 1, limit = 10}) => ref
          .read(transactionRepositoryProvider)
          .getExpenses(token, page: page, limit: limit);

  @override
  Future<void> Function(String, Map<String, dynamic>) get _createFunction =>
      (token, data) =>
          ref.read(transactionRepositoryProvider).createExpense(token, data);
}

class IncomesNotifier extends GenericTransactionNotifier<Income> {
  IncomesNotifier()
    : super((t, {page = 1, limit = 10}) async => {}, Income.fromJson);

  @override
  Future<Map<String, dynamic>> Function(String, {int page, int limit})
  get _fetchFunction =>
      (token, {page = 1, limit = 10}) => ref
          .read(transactionRepositoryProvider)
          .getIncomes(token, page: page, limit: limit);

  @override
  Future<void> Function(String, Map<String, dynamic>) get _createFunction =>
      (token, data) =>
          ref.read(transactionRepositoryProvider).createIncome(token, data);
}

class InvestmentsNotifier extends GenericTransactionNotifier<Investment> {
  InvestmentsNotifier()
    : super((t, {page = 1, limit = 10}) async => {}, Investment.fromJson);

  @override
  Future<Map<String, dynamic>> Function(String, {int page, int limit})
  get _fetchFunction =>
      (token, {page = 1, limit = 10}) => ref
          .read(transactionRepositoryProvider)
          .getInvestments(token, page: page, limit: limit);

  @override
  Future<void> Function(String, Map<String, dynamic>) get _createFunction =>
      (token, data) =>
          ref.read(transactionRepositoryProvider).createInvestment(token, data);
}

class LoansNotifier extends GenericTransactionNotifier<Loan> {
  LoansNotifier()
    : super((t, {page = 1, limit = 10}) async => {}, Loan.fromJson);

  @override
  Future<Map<String, dynamic>> Function(String, {int page, int limit})
  get _fetchFunction =>
      (token, {page = 1, limit = 10}) => ref
          .read(transactionRepositoryProvider)
          .getLoans(token, page: page, limit: limit);

  @override
  Future<void> Function(String, Map<String, dynamic>) get _createFunction =>
      (token, data) =>
          ref.read(transactionRepositoryProvider).createLoan(token, data);
}

final transactionsExpensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, TransactionState<Expense>>(
      ExpensesNotifier.new,
    );
final incomesProvider =
    AsyncNotifierProvider<IncomesNotifier, TransactionState<Income>>(
      IncomesNotifier.new,
    );
final investmentsProvider =
    AsyncNotifierProvider<InvestmentsNotifier, TransactionState<Investment>>(
      InvestmentsNotifier.new,
    );
final loansProvider =
    AsyncNotifierProvider<LoansNotifier, TransactionState<Loan>>(
      LoansNotifier.new,
    );
