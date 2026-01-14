import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../groups/data/group_model.dart';
import '../../groups/data/group_repository.dart';

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
