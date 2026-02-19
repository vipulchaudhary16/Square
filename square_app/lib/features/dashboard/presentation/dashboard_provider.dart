import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    return _fetchData();
  }

  Future<DashboardData?> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return null;
    }

    final repository = ref.read(dashboardRepositoryProvider);
    return repository.getDashboardData(token);
  }
}
