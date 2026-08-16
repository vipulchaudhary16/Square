import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/menu_button.dart';
import '../contacts_provider.dart';
import '../../data/contact_model.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        actions: [
          AppIconButton(icon: Icons.person_add_outlined, onPressed: () => context.push('/contacts/add')),
          const SizedBox(width: AppSpacing.xs),
          const MenuButton(),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: contacts.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 6,
          itemBuilder: (_, __) => const AppSkeletonRow(),
        ),
        error: (e, _) => AppErrorState(message: e.toString(), onRetry: () => ref.invalidate(contactsProvider)),
        data: (list) => list.isEmpty
            ? _buildEmpty(context)
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(contactsProvider);
                  await ref.read(contactsProvider.future);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ContactRow(contact: list[i]),
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: AppEmptyState(
        icon: Icons.contact_page_outlined,
        title: 'No contacts yet',
        actionLabel: 'Add first contact',
        onAction: () => context.push('/contacts/add'),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final Contact contact;

  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final accent = AppColors.categoryAccent(contact.name);

    return AppInteractiveCard(
      onTap: () => context.push('/contacts/${contact.id}'),
      showChevron: true,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? 0.22 : 0.12), shape: BoxShape.circle),
            child: Center(
              child: Text(contact.initials, style: AppTypography.bodyEmphasis.copyWith(color: accent)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: AppTypography.cardHeading.copyWith(color: ink)),
                const SizedBox(height: 2),
                contact.onPlatform
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: AppColors.positive),
                          const SizedBox(width: 4),
                          Text('On platform', style: AppTypography.caption.copyWith(color: AppColors.positive)),
                        ],
                      )
                    : Text(
                        contact.phone ?? contact.email ?? '',
                        style: AppTypography.caption.copyWith(color: inkFaint),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
