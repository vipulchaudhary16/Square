import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../groups_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await ref
        .read(groupsProvider.notifier)
        .createGroup(_nameController.text.trim(), _descController.text.trim());
    setState(() => _isLoading = false);

    if (success && mounted) {
      context.pop(); // Go back to groups list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );
    } else if (mounted) {
      final error = ref.read(groupsProvider).error; // Check AsyncValue.error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Failed to create group')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Start a new group to track shared expenses with friends, family, or roommates.',
                style: TextStyle(
                  color: isDark ? AppColors.slate[400] : AppColors.slate[00],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              InputField(
                label: 'Group Name',
                controller: _nameController,
                hint: 'e.g. Trip to Vegas',
                prefixIcon: LucideIcons.users, // Or group icon
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              InputField(
                label: 'Description (Optional)',
                controller: _descController,
                hint: 'What is this group for?',
                prefixIcon: LucideIcons.fileText,
                maxLines: 3,
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Create Group',
                onPressed: _createGroup,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
