import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../contacts_provider.dart';
import '../../data/contact_model.dart';
import '../../../../../shared/widgets/menu_button.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text(
          'Contacts',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.userPlus,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () => context.push('/contacts/add'),
          ),
          const MenuButton(),
        ],
      ),
      body: contacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? _buildEmpty(context, isDark)
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(contactsProvider);
                  await ref.read(contactsProvider.future);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      _ContactTile(contact: list[i], isDark: isDark),
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.users,
              size: 48,
              color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 12),
          Text('No contacts yet',
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push('/contacts/add'),
            child: const Text('Add first contact'),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final bool isDark;

  const _ContactTile({required this.contact, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isDark ? AppColors.slate[700] : AppColors.slate[200],
        child: Text(
          contact.initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: contact.onPlatform
          ? Text('On platform',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600]))
          : Text(contact.phone ?? contact.email ?? '',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38)),
      trailing: Icon(LucideIcons.chevronRight,
          size: 16,
          color: isDark ? Colors.white24 : Colors.black26),
      onTap: () => context.push('/contacts/${contact.id}'),
    );
  }
}
