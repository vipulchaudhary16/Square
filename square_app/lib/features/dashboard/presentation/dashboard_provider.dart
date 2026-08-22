import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../feature_flags/presentation/feature_flags_provider.dart';
import '../data/dashboard_cache.dart';
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
    // Paint the last-known data immediately (if any) so switching to this
    // tab doesn't flash a skeleton while the real fetch below is in flight.
    final cached = await DashboardCache.read();
    if (cached != null) state = AsyncData(cached);

    // Wait for flags — rebuilds automatically when flags change.
    final flags = await ref.watch(featureFlagsProvider.future);
    final showTrends = flags.any(
      (f) => f.key == 'show_expense_trends_chart' && f.value,
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final fresh = await ref
        .read(dashboardRepositoryProvider)
        .getDashboardData(token, includeTrends: showTrends);
    await DashboardCache.write(fresh);
    return fresh;
  }
}
