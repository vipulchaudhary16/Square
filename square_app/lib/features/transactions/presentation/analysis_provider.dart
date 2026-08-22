import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analysis_model.dart';
import 'transactions_provider.dart';

final analysisProvider = FutureProvider.autoDispose
    .family<AnalysisSummary, String>((ref, dateRangeKey) async {
      final parts = dateRangeKey.split('|');
      final startDate = parts[0];
      final endDate = parts[1];

      final repository = ref.watch(transactionRepositoryProvider);
      final json = await repository.getAnalysis(
        startDate: startDate,
        endDate: endDate,
      );
      return AnalysisSummary.fromJson(json);
    });
