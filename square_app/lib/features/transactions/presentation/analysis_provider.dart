import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analysis_model.dart';
import 'transactions_provider.dart';

/// Key shape: "startDate|endDate|compareStartDate|compareEndDate" — the
/// compare dates may be empty (no period-over-period comparison, e.g. for a
/// custom range).
final analysisProvider = FutureProvider.autoDispose
    .family<AnalysisSummary, String>((ref, dateRangeKey) async {
      final parts = dateRangeKey.split('|');
      final startDate = parts[0];
      final endDate = parts[1];
      final compareStartDate = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
      final compareEndDate = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null;

      final repository = ref.watch(transactionRepositoryProvider);
      final json = await repository.getAnalysis(
        startDate: startDate,
        endDate: endDate,
        compareStartDate: compareStartDate,
        compareEndDate: compareEndDate,
      );
      return AnalysisSummary.fromJson(json);
    });
