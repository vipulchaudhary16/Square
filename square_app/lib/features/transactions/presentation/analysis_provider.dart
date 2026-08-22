import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/analysis_model.dart';
import 'transactions_provider.dart';

final analysisProvider = FutureProvider.autoDispose.family<AnalysisSummary, String>((ref, dateRangeKey) async {
  final parts = dateRangeKey.split('|');
  final startDate = parts[0];
  final endDate = parts[1];

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('Not authenticated');

  final repository = ref.watch(transactionRepositoryProvider);
  final json = await repository.getAnalysis(token, startDate: startDate, endDate: endDate);
  return AnalysisSummary.fromJson(json);
});
