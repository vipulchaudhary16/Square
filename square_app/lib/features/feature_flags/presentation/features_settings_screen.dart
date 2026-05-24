import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:square_app/core/theme/app_colors.dart';
import '../data/feature_flag_model.dart';
import 'feature_flags_provider.dart';

class FeaturesSettingsScreen extends ConsumerWidget {
  const FeaturesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Features'),
        backgroundColor: Colors.transparent,
      ),
      body: flagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load features',
            style: TextStyle(
              color: isDark ? AppColors.slate[400] : AppColors.slate[500],
            ),
          ),
        ),
        data: (flags) {
          final userFlags = flags.where((f) => f.userToggleable).toList();

          if (userFlags.isEmpty) {
            return Center(
              child: Text(
                'No configurable features',
                style: TextStyle(
                  color: isDark ? AppColors.slate[400] : AppColors.slate[500],
                ),
              ),
            );
          }

          final byCategory = <String, List<FeatureFlag>>{};
          for (final f in userFlags) {
            byCategory.putIfAbsent(f.category, () => []).add(f);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: byCategory.entries.expand((entry) {
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ...entry.value.map(
                  (flag) => SwitchListTile(
                    title: Text(
                      flag.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.slate[800],
                      ),
                    ),
                    value: flag.value,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) async {
                      try {
                        await ref.read(featureFlagsProvider.notifier).toggle(flag.id, val);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update feature. Please try again.')),
                          );
                        }
                      }
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ];
            }).toList(),
          );
        },
      ),
    );
  }
}
