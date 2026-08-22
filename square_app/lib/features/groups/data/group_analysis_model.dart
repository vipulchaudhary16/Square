import '../../transactions/data/analysis_model.dart';

class GroupAnalysisSummary {
  final AnalysisSide totalExpense;
  final AnalysisSide yourShare;

  GroupAnalysisSummary({required this.totalExpense, required this.yourShare});

  factory GroupAnalysisSummary.fromJson(Map<String, dynamic> json) {
    return GroupAnalysisSummary(
      totalExpense: AnalysisSide.fromJson(json['total_expense'] ?? {}),
      yourShare: AnalysisSide.fromJson(json['your_share'] ?? {}),
    );
  }
}
