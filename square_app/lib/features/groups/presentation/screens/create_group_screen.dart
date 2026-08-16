import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_icon_button.dart';
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
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
        leading: AppIconButton(icon: Icons.arrow_back, onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Start a new group to track shared expenses with friends, family, or roommates.',
                style: AppTypography.body.copyWith(color: inkFaint),
              ),
              const SizedBox(height: AppSpacing.xxl),
              InputField(
                label: 'Group Name',
                controller: _nameController,
                hint: 'e.g. Trip to Vegas',
                prefixIcon: Icons.people_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              InputField(
                label: 'Description (Optional)',
                controller: _descController,
                hint: 'What is this group for?',
                prefixIcon: Icons.edit,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xxxl),
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
