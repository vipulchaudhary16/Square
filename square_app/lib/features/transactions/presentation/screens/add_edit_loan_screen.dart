import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/category_picker_sheet.dart';
import '../../../contacts/data/contact_model.dart';
import '../transactions_provider.dart';

class AddEditLoanScreen extends ConsumerStatefulWidget {
  const AddEditLoanScreen({super.key});

  @override
  ConsumerState<AddEditLoanScreen> createState() => _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends ConsumerState<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Contact? _selectedContact;
  String _interestMode = 'none';
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;
  String? _selectedCategoryId;
  String _selectedCategoryName = 'Category';

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    final result = await context.push<Contact>('/contacts/add');
    if (result != null) setState(() => _selectedContact = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = {
        'contact_id': _selectedContact!.id,
        'amount': double.parse(_amountController.text),
        'date': _selectedDate.toUtc().toIso8601String(),
        'interest_mode': _interestMode,
        'description': _descriptionController.text,
        'category_id': _selectedCategoryId ?? '',
        if (_dueDate != null) 'due_date': _dueDate!.toUtc().toIso8601String(),
      };
      await ref.read(loansProvider.notifier).create(data);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan added')),
        );
      }
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text('Add Loan',
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
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickContact,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate[900]
                          : AppColors.slate[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.user,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedContact?.name ?? 'Select contact',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedContact != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedContact != null
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark
                                        ? AppColors.slate[500]
                                        : AppColors.slate[400])),
                          ),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 16,
                            color: isDark ? Colors.white24 : Colors.black26),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFieldRow(
                  icon: LucideIcons.indianRupee,
                  iconColor: isDark
                      ? AppColors.slate[400]!
                      : AppColors.slate[600]!,
                  isDark: isDark,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.slate[500]
                              : AppColors.slate[400]),
                      border: InputBorder.none,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05)),
                const SizedBox(height: 12),
                _buildInterestModeSelector(isDark),
                const SizedBox(height: 12),
                Divider(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05)),
                const SizedBox(height: 12),
                _buildFieldRow(
                  icon: LucideIcons.fileText,
                  iconColor: isDark ? Colors.white54 : Colors.black38,
                  isDark: isDark,
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: null,
                    minLines: 2,
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Description (optional)',
                      hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.slate[500]
                              : AppColors.slate[400],
                          fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 180),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: _buildFloatingDock(isDark),
    );
  }

  Widget _buildInterestModeSelector(bool isDark) {
    final modes = [
      ('none', 'No interest'),
      ('from_start', 'Interest from start'),
      ('penalty', 'Penalty after due date'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Interest',
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 0.06)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: modes
              .map((m) => ChoiceChip(
                    label: Text(m.$2,
                        style: const TextStyle(fontSize: 12)),
                    selected: _interestMode == m.$1,
                    onSelected: (_) =>
                        setState(() => _interestMode = m.$1),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFieldRow(
      {required IconData icon,
      required Color iconColor,
      required Widget child,
      required bool isDark}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildFloatingDock(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildDockItem(
            LucideIcons.calendar,
            DateFormat('MMM dd').format(_selectedDate),
            isDark,
            () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          _buildDockItem(
            LucideIcons.calendarClock,
            _dueDate != null
                ? 'Due ${DateFormat('MMM dd').format(_dueDate!)}'
                : 'Due date',
            isDark,
            () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ??
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          _buildDockItem(
            LucideIcons.tag,
            _selectedCategoryName,
            isDark,
            () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CategoryPickerSheet(
                selectedId: _selectedCategoryId,
                appliesTo: 'loan',
                onSelected: (id, name) => setState(() {
                  _selectedCategoryId = id;
                  _selectedCategoryName = name;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem(
      IconData icon, String label, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.black54),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
