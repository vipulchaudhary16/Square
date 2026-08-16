import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/input_field.dart';
import '../contacts_provider.dart';
import '../../data/contact_model.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  final Contact? contact;
  const AddContactScreen({super.key, this.contact});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedLinkedUserId;
  bool _isLoading = false;
  bool _showSearch = false;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phone ?? '';
      _emailController.text = widget.contact!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isLoading || _nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      Contact contact;
      if (_isEditing) {
        contact = await ref.read(contactsProvider.notifier).updateContact(
              widget.contact!.id,
              name: _nameController.text.trim(),
              phone: _phoneController.text.isEmpty ? null : _phoneController.text,
              email: _emailController.text.isEmpty ? null : _emailController.text,
            );
      } else {
        contact = await ref.read(contactsProvider.notifier).create(
              name: _nameController.text.trim(),
              phone: _phoneController.text.isEmpty ? null : _phoneController.text,
              email: _emailController.text.isEmpty ? null : _emailController.text,
              linkedUserId: _selectedLinkedUserId,
            );
      }
      if (mounted) context.pop(contact);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final canSave = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contact' : 'New Contact'),
        centerTitle: true,
        leading: AppIconButton(icon: Icons.close, onPressed: () => context.pop()),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : GhostButton(
                  text: 'Save',
                  compact: true,
                  onPressed: canSave ? _save : null,
                ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            InputField(
              label: 'Name',
              hint: 'Full name',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: AppSpacing.lg),
            InputField(
              label: 'Phone (optional)',
              hint: 'Phone number',
              controller: _phoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            InputField(
              label: 'Email (optional)',
              hint: 'Email address',
              controller: _emailController,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            if (!_isEditing) ...[
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: () => setState(() => _showSearch = !_showSearch),
                child: Row(
                  children: [
                    Icon(
                      _showSearch ? Icons.keyboard_arrow_up : Icons.search,
                      size: 14,
                      color: inkFaint,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _showSearch ? 'Hide search' : 'Search existing contacts',
                      style: AppTypography.bodyMuted.copyWith(color: inkFaint),
                    ),
                  ],
                ),
              ),
              if (_showSearch) ...[
                const SizedBox(height: AppSpacing.md),
                InputField(
                  label: 'Search',
                  hint: 'Search by name, phone, or email…',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SearchResults(
                  query: _searchController.text,
                  onSelect: (c) => context.pop(c),
                  onLinkPlatformUser: (u) async {
                    _nameController.text = u.name;
                    _emailController.text = u.email;
                    _phoneController.text = u.mobileNumber ?? '';
                    setState(() => _selectedLinkedUserId = u.id);
                    await _save();
                  },
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final ValueChanged<Contact> onSelect;
  final ValueChanged<PlatformUserResult> onLinkPlatformUser;

  const _SearchResults({
    required this.query,
    required this.onSelect,
    required this.onLinkPlatformUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    if (query.length < 2) {
      return Text(
        'Type at least 2 characters to search',
        style: AppTypography.caption.copyWith(color: inkFaint),
      );
    }
    final result = ref.watch(contactSearchProvider(query));
    return result.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e', style: AppTypography.caption.copyWith(color: AppColors.negative)),
      data: (data) {
        if (data.contacts.isEmpty && data.platformUsers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('No results for "$query"', style: AppTypography.bodyMuted.copyWith(color: inkFaint)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.contacts.isNotEmpty) ...[
              _sectionLabel('YOUR CONTACTS', inkFaint),
              ...data.contacts.map((c) => _tile(
                    ink,
                    inkFaint,
                    c.name,
                    c.phone ?? c.email ?? '',
                    null,
                    onTap: () => onSelect(c),
                  )),
            ],
            if (data.platformUsers.isNotEmpty) ...[
              _sectionLabel('ON PLATFORM', inkFaint),
              ...data.platformUsers.map((u) => _tile(
                    ink,
                    inkFaint,
                    u.name,
                    u.email,
                    AppColors.positive,
                    onTap: () => onLinkPlatformUser(u),
                  )),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String label, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(label, style: AppTypography.label.copyWith(color: color)),
      );

  Widget _tile(Color ink, Color inkFaint, String name, String sub, Color? subColor, {required VoidCallback onTap}) {
    final accent = AppColors.categoryAccent(name);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: AppTypography.bodyEmphasis.copyWith(color: accent, fontSize: 13),
          ),
        ),
      ),
      title: Text(name, style: AppTypography.bodyEmphasis.copyWith(color: ink, fontSize: 13)),
      subtitle: Text(sub, style: AppTypography.caption.copyWith(color: subColor ?? inkFaint)),
      onTap: onTap,
    );
  }
}
