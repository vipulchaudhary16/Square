import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/group_model.dart';
import '../../data/group_repository.dart';
import '../groups_provider.dart';

/// Replaces the old "search a user and tap + to add them" flow: a group
/// admin generates an expiring, email-targeted link here; the invited
/// person joins on their own by opening it — nobody gets added without
/// taking that step themselves.
class GroupInvitationsScreen extends ConsumerStatefulWidget {
  const GroupInvitationsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupInvitationsScreen> createState() =>
      _GroupInvitationsScreenState();
}

class _GroupInvitationsScreenState
    extends ConsumerState<GroupInvitationsScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(groupInvitesProvider(widget.groupId));
    try {
      await ref.read(groupInvitesProvider(widget.groupId).future);
    } catch (_) {}
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final invite = await ref
          .read(groupRepositoryProvider)
          .createInvite(widget.groupId, email);
      _emailController.clear();
      await Clipboard.setData(ClipboardData(text: invite.link));
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite sent — link copied to clipboard'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send invite: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _revoke(GroupInvite invite) async {
    try {
      await ref.read(groupRepositoryProvider).revokeInvite(invite.id);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to revoke: $e')));
      }
    }
  }

  Future<void> _copyLink(GroupInvite invite) async {
    await Clipboard.setData(ClipboardData(text: invite.link));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(groupInvitesProvider(widget.groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Invite someone',
              style: AppTypography.sectionHeading.copyWith(color: ink),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Generates an expiring link (48h) — they join by opening it.',
              style: AppTypography.bodyMuted.copyWith(color: inkFaint),
            ),
            const SizedBox(height: AppSpacing.md),
            InputField(
              label: 'Email address',
              hint: 'friend@example.com',
              controller: _emailController,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'Send invite',
              icon: Icons.link,
              isLoading: _isSending,
              onPressed: _sendInvite,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Sent invitations',
              style: AppTypography.sectionHeading.copyWith(color: ink),
            ),
            const SizedBox(height: AppSpacing.sm),
            invitesAsync.when(
              loading: () =>
                  const Column(children: [AppSkeletonRow(), AppSkeletonRow()]),
              error: (err, stack) =>
                  AppErrorState(message: err.toString(), onRetry: _refresh),
              data: (invites) {
                if (invites.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: AppEmptyState(
                      icon: Icons.mail_outline,
                      title: 'No invitations yet',
                    ),
                  );
                }
                return Column(
                  children: invites
                      .map(
                        (invite) => _InviteRow(
                          invite: invite,
                          onRevoke: () => _revoke(invite),
                          onCopyLink: () => _copyLink(invite),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({
    required this.invite,
    required this.onRevoke,
    required this.onCopyLink,
  });

  final GroupInvite invite;
  final VoidCallback onRevoke;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final isPending = invite.status == 'pending';

    final status = switch (invite.status) {
      'accepted' => AppChipStatus.positive,
      'revoked' => AppChipStatus.negative,
      'expired' => AppChipStatus.negative,
      _ => AppChipStatus.warning,
    };

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.email,
                  style: AppTypography.cardHeading.copyWith(color: ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    AppChip(
                      label:
                          invite.status[0].toUpperCase() +
                          invite.status.substring(1),
                      status: status,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isPending
                          ? 'Expires ${DateFormat('dd MMM').format(invite.expiresAt)}'
                          : DateFormat('dd MMM').format(invite.createdAt),
                      style: AppTypography.caption.copyWith(color: inkFaint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isPending) ...[
            AppIconButton(
              icon: Icons.copy_outlined,
              iconSize: 16,
              onPressed: onCopyLink,
            ),
            AppIconButton(icon: Icons.close, iconSize: 16, onPressed: onRevoke),
          ],
        ],
      ),
    );
  }
}
