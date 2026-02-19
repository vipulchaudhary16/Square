import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/expense_model.dart';
import '../expense_provider.dart';
import '../../../groups/presentation/groups_provider.dart';
import '../../../groups/data/group_model.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Fields
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late DateTime _selectedDate;

  // Group Logic
  bool _isGroupExpense = false;
  String? _selectedGroupId;
  Group? _selectedGroup;

  // Split Logic
  String _splitType = 'EQUAL'; // EQUAL, EXACT, PERCENT
  Map<String, double> _splits = {}; // userId -> amount/percent
  List<String> _selectedParticipants = []; // userIds

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.expense?.category ?? '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();

    // Initialize Group State if editing
    if (widget.expense?.groupId != null) {
      _isGroupExpense = true;
      _selectedGroupId = widget.expense!.groupId;
      _splitType = widget.expense!.splitType ?? 'EQUAL';
      _splits = widget.expense!.splits ?? {};
      _selectedParticipants = widget.expense!.participants;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // ... Date Picker ...
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // Logic to handle group selection
  void _onGroupSelected(String? groupId) {
    if (groupId == null) return;
    final groupsAsync = ref.read(groupsProvider);
    final groups = groupsAsync.value ?? [];

    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => Group(
        id: '',
        name: '',
        description: '',
        createdAt: DateTime.now(),
        members: [],
      ),
    );

    setState(() {
      _selectedGroupId = groupId;
      _selectedGroup = group;
      // Default: select all members
      _selectedParticipants = group.members.map((m) => m.id).toList();
      _splits = {};
    });
  }

  void _onSplitTypeChanged(String? type) {
    if (type == null) return;
    setState(() {
      _splitType = type;
      _splits = {}; // Reset splits when type changes
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());

    // Validate Splits
    if (_isGroupExpense) {
      if (_selectedGroupId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a group')));
        return;
      }
      if (_selectedParticipants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one participant')),
        );
        return;
      }

      if (_splitType == 'EXACT') {
        final totalSplit = _splits.values.fold(0.0, (sum, val) => sum + val);
        if ((totalSplit - amount).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Total split amount must equal expense amount'),
            ),
          );
          return;
        }
      }

      if (_splitType == 'PERCENT') {
        final totalPercent = _splits.values.fold(0.0, (sum, val) => sum + val);
        if ((totalPercent - 100).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Total percentage must equal 100%')),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final expenseData = {
        'description': _descriptionController.text.trim(),
        'amount': amount,
        'category': _categoryController.text.trim().isEmpty
            ? 'General'
            : _categoryController.text.trim(),
        'date': _selectedDate.toUtc().toIso8601String(),
        'participants': _isGroupExpense ? _selectedParticipants : [],

        // Group Fields
        if (_isGroupExpense) 'group_id': _selectedGroupId,
        if (_isGroupExpense) 'split_type': _splitType,
        if (_isGroupExpense) 'splits': _splits,
      };

      if (widget.expense == null) {
        await ref.read(expenseProvider.notifier).addExpense(expenseData);
      } else {
        await ref
            .read(expenseProvider.notifier)
            .updateExpense(widget.expense!.id, expenseData);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep isEditing unused if not needed, or use it
    final isEditing = widget.expense != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch AsyncValue
    final groupsAsync = ref.watch(groupsProvider);
    final groups = groupsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
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
              // Toggle Type
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate[800] : AppColors.slate[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTypeToggle('Personal', false, isDark),
                    _buildTypeToggle('Group', true, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info
              InputField(
                label: 'Description',
                controller: _descriptionController,
                hint: 'Dinner, Movies, etc.',
                prefixIcon: LucideIcons.fileText,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Amount',
                controller: _amountController,
                hint: '0.00',
                prefixIcon: LucideIcons.indianRupee,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Category',
                controller: _categoryController,
                hint: 'Food',
                prefixIcon: LucideIcons.tag,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: InputField(
                    label: 'Date',
                    controller: TextEditingController(
                      text: DateFormat('MMM dd, yyyy').format(_selectedDate),
                    ),
                    hint: 'Select Date',
                    prefixIcon: LucideIcons.calendar,
                  ),
                ),
              ),

              // Group Section
              if (_isGroupExpense) ...[
                const SizedBox(height: 32),
                Text(
                  "Group Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // Group Selector
                DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  decoration: InputDecoration(
                    labelText: 'Select Group',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(LucideIcons.users),
                    filled: true,
                    fillColor: isDark ? AppColors.slate[800] : Colors.white,
                  ),
                  items: groups
                      .map(
                        (g) =>
                            DropdownMenuItem(value: g.id, child: Text(g.name)),
                      )
                      .toList(),
                  onChanged: _onGroupSelected,
                ),

                if (_selectedGroup != null) ...[
                  const SizedBox(height: 16),
                  // Split Type Selector
                  DropdownButtonFormField<String>(
                    value: _splitType,
                    decoration: InputDecoration(
                      labelText: 'Split Method',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.slate[800] : Colors.white,
                    ),
                    items: ['EQUAL', 'EXACT', 'PERCENT']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: _onSplitTypeChanged,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Participants",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.slate[300]
                          : AppColors.slate[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Participants List
                  ..._selectedGroup!.members.map((member) {
                    final isSelected = _selectedParticipants.contains(
                      member.id,
                    );
                    return CheckboxListTile(
                      title: Text(member.username),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedParticipants.add(member.id);
                          } else {
                            _selectedParticipants.remove(member.id);
                          }
                        });
                      },
                      secondary:
                          _splitType == 'EXACT' || _splitType == 'PERCENT'
                          ? SizedBox(
                              width: 100,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  suffixText: _splitType == 'PERCENT'
                                      ? '%'
                                      : null,
                                  hintText: '0',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  final numVal = double.tryParse(val) ?? 0;
                                  _splits[member.id] = numVal;
                                },
                              ),
                            )
                          : null,
                    );
                  }).toList(),
                ],
              ],

              const SizedBox(height: 32),
              PrimaryButton(
                text: isEditing ? 'Update Expense' : 'Add Expense',
                onPressed: _saveExpense,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String label, bool isGroup, bool isDark) {
    final isSelected = _isGroupExpense == isGroup;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isGroupExpense = isGroup),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary[600] : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : AppColors.slate[500],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
