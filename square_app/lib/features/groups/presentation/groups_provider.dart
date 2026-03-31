import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../groups/data/group_model.dart';
import '../../groups/data/group_repository.dart';
import '../../expense/data/expense_model.dart';

final groupDetailsProvider = FutureProvider.autoDispose.family<GroupDetails, String>((ref, id) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupDetails(id);
});

final groupExpensesProvider = FutureProvider.autoDispose.family<List<Expense>, String>((ref, arg) async {
  final parts = arg.split('|');
  final groupId = parts[0];
  final search = parts.length > 1 ? (parts[1].isEmpty ? null : parts[1]) : null;
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupExpenses(groupId, searchQuery: search);
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
