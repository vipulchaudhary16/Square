import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../groups_provider.dart';

class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(groupDetailsProvider(groupId));
    final currentUserId = ref.watch(authProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => AppErrorState(message: err.toString()),
        data: (details) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupDetailsProvider(groupId));
            try {
              await ref.read(groupDetailsProvider(groupId).future);
            } catch (_) {}
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              100,
            ),
            itemCount: details.members.length,
            itemBuilder: (context, index) {
              final member = details.members[index];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final ink = isDark ? AppColors.inkDark : AppColors.ink;
              final inkFaint = isDark
                  ? AppColors.inkFaintDark
                  : AppColors.inkFaint;
              final sunken = isDark
                  ? AppColors.surfaceRaisedDark
                  : AppColors.surfaceSunken;
              final isYou = member.id == currentUserId;
              final isAdmin = member.id == details.group.createdBy;

              return AppCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    InitialsAvatar(name: member.displayName),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName,
                            style: AppTypography.cardHeading.copyWith(
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.email,
                            style: AppTypography.bodyMuted.copyWith(
                              color: inkFaint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sunken,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Admin',
                          style: AppTypography.caption.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (isYou) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sunken,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'You',
                          style: AppTypography.caption.copyWith(
                            color: inkFaint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
