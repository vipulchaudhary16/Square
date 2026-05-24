import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../contacts_provider.dart';
import '../../data/contact_model.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedLinkedUserId;
  bool _isLoading = false;
  bool _showManualForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_isLoading) return;
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final contact = await ref.read(contactsProvider.notifier).create(
            name: _nameController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            linkedUserId: _selectedLinkedUserId,
          );
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
    final searchResult =
        ref.watch(contactSearchProvider(_searchController.text));

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text('Add Contact',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.x,
              color: isDark ? Colors.white70 : Colors.black54),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_showManualForm)
            TextButton(
              onPressed: _isLoading ? null : _saveContact,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (_searchController.text.length >= 2)
              searchResult.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (result) => _buildSearchResults(result, isDark),
              )
            else if (_showManualForm)
              _buildManualForm(isDark)
            else
              TextButton.icon(
                onPressed: () => setState(() => _showManualForm = true),
                icon: const Icon(LucideIcons.userPlus),
                label: const Text('Add manually'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ContactSearchResult result, bool isDark) {
    return Expanded(
      child: ListView(
        children: [
          if (result.contacts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('YOUR CONTACTS',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            ...result.contacts.map((c) => _buildContactTile(
                c.name, c.phone ?? c.email ?? '', null, isDark,
                onTap: () => context.pop(c))),
          ],
          if (result.platformUsers.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('ON PLATFORM',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            ...result.platformUsers.map((u) => _buildContactTile(
                u.name, u.email, Colors.green[600], isDark,
                onTap: () async {
                  _nameController.text = u.name;
                  _emailController.text = u.email;
                  _phoneController.text = u.mobileNumber ?? '';
                  setState(() {
                    _selectedLinkedUserId = u.id;
                    _showManualForm = true;
                  });
                  await _saveContact();
                })),
          ],
          if (result.contacts.isEmpty && result.platformUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  Text('No results for "${_searchController.text}"',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _nameController.text = _searchController.text;
                      setState(() => _showManualForm = true);
                    },
                    child: Text('Add "${_searchController.text}" manually'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualForm(bool isDark) {
    return Expanded(
      child: ListView(
        children: [
          _field(_nameController, 'Name *', LucideIcons.user, isDark),
          const SizedBox(height: 12),
          _field(_phoneController, 'Phone (optional)', LucideIcons.phone, isDark),
          const SizedBox(height: 12),
          _field(_emailController, 'Email (optional)', LucideIcons.mail, isDark),
        ],
      ),
    );
  }

  Widget _buildContactTile(
      String name, String sub, Color? subColor, bool isDark,
      {required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDark ? AppColors.slate[700] : AppColors.slate[200],
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      title: Text(name),
      subtitle: Text(sub,
          style: TextStyle(fontSize: 12, color: subColor ?? Colors.grey)),
      onTap: onTap,
    );
  }

  Widget _field(
      TextEditingController ctrl, String hint, IconData icon, bool isDark) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
