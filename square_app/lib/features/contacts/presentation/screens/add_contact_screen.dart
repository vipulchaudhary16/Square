import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../contacts_provider.dart';
import '../../data/contact_model.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  final Contact? contact;
  const AddContactScreen({super.key, this.contact});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _emailController   = TextEditingController();
  final _searchController  = TextEditingController();

  String? _selectedLinkedUserId;
  bool _isLoading   = false;
  bool _showSearch  = false;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text  = widget.contact!.name;
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
              name:  _nameController.text.trim(),
              phone: _phoneController.text.isEmpty ? null : _phoneController.text,
              email: _emailController.text.isEmpty ? null : _emailController.text,
            );
      } else {
        contact = await ref.read(contactsProvider.notifier).create(
              name:         _nameController.text.trim(),
              phone:        _phoneController.text.isEmpty ? null : _phoneController.text,
              email:        _emailController.text.isEmpty ? null : _emailController.text,
              linkedUserId: _selectedLinkedUserId,
            );
      }
      if (mounted) context.pop(contact);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSave = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Contact' : 'New Contact',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : Colors.black54),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: (canSave && !_isLoading) ? _save : null,
            child: _isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canSave
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _field(_nameController, 'Name *', LucideIcons.user, isDark,
                      autofocus: true),
                  const SizedBox(height: 12),
                  _field(_phoneController, 'Phone (optional)', LucideIcons.phone,
                      isDark),
                  const SizedBox(height: 12),
                  _field(_emailController, 'Email (optional)', LucideIcons.mail,
                      isDark),

                  // Search existing — only for new contacts
                  if (!_isEditing) ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() => _showSearch = !_showSearch),
                      child: Row(
                        children: [
                          Icon(
                            _showSearch
                                ? LucideIcons.chevronUp
                                : LucideIcons.search,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showSearch
                                ? 'Hide search'
                                : 'Search existing contacts',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showSearch) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, phone, or email…',
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      _SearchResults(
                        query: _searchController.text,
                        isDark: isDark,
                        onSelect: (c) => context.pop(c),
                        onLinkPlatformUser: (u) async {
                          _nameController.text  = u.name;
                          _emailController.text = u.email;
                          _phoneController.text = u.mobileNumber ?? '';
                          setState(() => _selectedLinkedUserId = u.id);
                          await _save();
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    bool isDark, {
    bool autofocus = false,
  }) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final bool isDark;
  final ValueChanged<Contact> onSelect;
  final ValueChanged<PlatformUserResult> onLinkPlatformUser;

  const _SearchResults({
    required this.query,
    required this.isDark,
    required this.onSelect,
    required this.onLinkPlatformUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.length < 2) {
      return Text(
        'Type at least 2 characters to search',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      );
    }
    final result = ref.watch(contactSearchProvider(query));
    return result.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (data) {
        if (data.contacts.isEmpty && data.platformUsers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No results for "$query"',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.contacts.isNotEmpty) ...[
              _sectionLabel('YOUR CONTACTS', isDark),
              ...data.contacts.map((c) => _tile(
                    c.name,
                    c.phone ?? c.email ?? '',
                    null,
                    isDark,
                    onTap: () => onSelect(c),
                  )),
            ],
            if (data.platformUsers.isNotEmpty) ...[
              _sectionLabel('ON PLATFORM', isDark),
              ...data.platformUsers.map((u) => _tile(
                    u.name,
                    u.email,
                    Colors.green[600],
                    isDark,
                    onTap: () => onLinkPlatformUser(u),
                  )),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      );

  Widget _tile(String name, String sub, Color? subColor, bool isDark,
      {required VoidCallback onTap}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isDark ? AppColors.slate[700] : AppColors.slate[200],
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      title: Text(name, style: const TextStyle(fontSize: 13)),
      subtitle: Text(sub,
          style: TextStyle(fontSize: 11, color: subColor ?? Colors.grey)),
      onTap: onTap,
    );
  }
}
