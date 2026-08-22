import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/feature_flag_model.dart';
import '../data/feature_flags_repository.dart';

final featureFlagsRepositoryProvider = Provider(
  (ref) => FeatureFlagsRepository(ref.watch(apiClientProvider)),
);

class FeatureFlagsNotifier extends AsyncNotifier<List<FeatureFlag>> {
  @override
  Future<List<FeatureFlag>> build() async {
    return ref.read(featureFlagsRepositoryProvider).getFlags();
  }

  /// Returns the resolved boolean for a flag by key.
  /// Defaults to false when flags are loading or the key is not found.
  bool flagValue(String key) {
    final flags = state.value;
    if (flags == null) return false;
    for (final f in flags) {
      if (f.key == key) return f.value;
    }
    return false;
  }

  /// Optimistically toggles a flag, rolling back on API error.
  Future<void> toggle(String id, bool value) async {
    if (state.value == null) return;
    final previous = state;
    state = AsyncData(
      state.value!
          .map((f) => f.id == id ? f.copyWith(value: value) : f)
          .toList(),
    );
    try {
      final updated = await ref
          .read(featureFlagsRepositoryProvider)
          .updateFlag(id, value);
      state = AsyncData(updated);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final featureFlagsProvider =
    AsyncNotifierProvider<FeatureFlagsNotifier, List<FeatureFlag>>(
      FeatureFlagsNotifier.new,
    );
