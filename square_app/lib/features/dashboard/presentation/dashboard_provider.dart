import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../feature_flags/presentation/feature_flags_provider.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_model.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData?>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardData?> {
  @override
  Future<DashboardData?> build() async {
    // Wait for flags — rebuilds automatically when flags change.
    final flags = await ref.watch(featureFlagsProvider.future);
    final showTrends =
        flags.any((f) => f.key == 'show_expense_trends_chart' && f.value);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    return ref
        .read(dashboardRepositoryProvider)
        .getDashboardData(token, includeTrends: showTrends);
  }
}
