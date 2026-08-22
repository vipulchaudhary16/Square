import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expense/data/expense_model.dart';
import '../../groups/data/group_model.dart';
import '../../groups/data/group_repository.dart';
import '../data/group_analysis_model.dart';

final groupDetailsProvider = FutureProvider.autoDispose.family<GroupDetails, String>((ref, id) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupDetails(id);
});

final groupExpensesProvider = FutureProvider.autoDispose.family<List<GroupFeedItem>, String>((ref, arg) async {
  final parts = arg.split('|');
  final groupId = parts[0];
  final search = parts.length > 1 ? (parts[1].isEmpty ? null : parts[1]) : null;
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupExpenses(groupId, searchQuery: search);
});

/// Key shape: "groupId|startDate|endDate".
final groupAnalysisProvider = FutureProvider.autoDispose.family<GroupAnalysisSummary, String>((ref, key) async {
  final parts = key.split('|');
  final groupId = parts[0];
  final startDate = parts[1];
  final endDate = parts[2];
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupAnalysis(groupId, startDate: startDate, endDate: endDate);
});

/// Key shape: "groupId|startDate|endDate|categoryId|search" — categoryId/search may be
/// empty. Every expense in the group matching the filters, regardless of who's involved
/// — settlements dropped. Backs the "Total expense" tap on the group Reports tab, which
/// (unlike "Your share") isn't scoped to the current user.
final groupTotalExpensesProvider = FutureProvider.autoDispose.family<List<Expense>, String>((ref, key) async {
  final parts = key.split('|');
  final groupId = parts[0];
  final startDate = parts[1];
  final endDate = parts[2];
  final categoryId = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null;
  final search = parts.length > 4 ? parts[4] : '';
  final repository = ref.watch(groupRepositoryProvider);
  final items = await repository.getGroupExpenses(
    groupId,
    searchQuery: search,
    categoryId: categoryId,
    startDate: startDate,
    endDate: endDate,
  );
  return items.whereType<ExpenseFeedItem>().map((item) => item.expense).toList();
});

final groupsProvider = AsyncNotifierProvider<GroupsNotifier, List<Group>>(
  GroupsNotifier.new,
);

class GroupsNotifier extends AsyncNotifier<List<Group>> {
  @override
  Future<List<Group>> build() async {
    return _fetchGroups();
  }

  Future<List<Group>> _fetchGroups() async {
    final repository = ref.read(groupRepositoryProvider);
    return repository.getUserGroups();
  }

  Future<void> loadGroups() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGroups());
  }

  Future<bool> createGroup(String name, String description) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(groupRepositoryProvider);
      await repository.createGroup({'name': name, 'description': description});
      // Refetch to update list
      state = await AsyncValue.guard(() => _fetchGroups());
      return true;
    } catch (e) {
      // Restore state if possible or let the error propagate in state
      state = await AsyncValue.guard(
        () => _fetchGroups(),
      ); // revert or show error
      // Actually common pattern is to just set state to error or rethrow
      // But for UI feedback, returning false might be enough if state is updated
      return false;
    }
  }
}
