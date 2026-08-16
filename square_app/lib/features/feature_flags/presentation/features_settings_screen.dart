import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../data/feature_flag_model.dart';
import 'feature_flags_provider.dart';

class FeaturesSettingsScreen extends ConsumerWidget {
  const FeaturesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Scaffold(
      appBar: AppBar(title: Text('Features', style: AppTypography.screenTitle.copyWith(color: ink))),
      body: flagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(
          message: 'Failed to load features',
          onRetry: () => ref.invalidate(featureFlagsProvider),
        ),
        data: (flags) {
          final userFlags = flags.where((f) => f.userToggleable).toList();

          if (userFlags.isEmpty) {
            return const AppEmptyState(icon: Icons.add_circle_outline, title: 'No configurable features');
          }

          final byCategory = <String, List<FeatureFlag>>{};
          for (final f in userFlags) {
            byCategory.putIfAbsent(f.category, () => []).add(f);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: byCategory.entries.expand((entry) {
              return [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.md),
                  child: Text(entry.key.toUpperCase(), style: AppTypography.label.copyWith(color: inkFaint)),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    children: [
                      for (int i = 0; i < entry.value.length; i++)
                        _FlagRow(
                          flag: entry.value[i],
                          isLast: i == entry.value.length - 1,
                          onChanged: (val) async {
                            try {
                              await ref.read(featureFlagsProvider.notifier).toggle(entry.value[i].id, val);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to update feature. Please try again.')),
                                );
                              }
                            }
                          },
                        ),
                    ],
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

class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.flag, required this.isLast, required this.onChanged});

  final FeatureFlag flag;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    return Container(
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: line))),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(flag.description, style: AppTypography.body.copyWith(color: ink, fontWeight: FontWeight.w500)),
          ),
          Switch(value: flag.value, onChanged: onChanged, activeTrackColor: ink),
        ],
      ),
    );
  }
}
