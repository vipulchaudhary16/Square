import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/expense_model.dart';
import '../expense_provider.dart';
import '../../../groups/presentation/groups_provider.dart';
import '../../../groups/data/group_model.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;
  final String? preselectedGroupId;

  const AddEditExpenseScreen({
    super.key,
    this.expense,
    this.preselectedGroupId,
  });

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
  GroupDetails? _selectedGroupDetails;

  // Split Logic
  String _splitType = 'EQUAL'; // EQUAL, EXACT, PERCENT
  Map<String, double> _splits = {}; // userId -> amount/percent
  List<String> _selectedParticipants = []; // userIds
  bool _addToPersonal = false;

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
      Future.microtask(() => _onGroupSelected(widget.expense!.groupId));
    } else if (widget.preselectedGroupId != null) {
      _isGroupExpense = true;
      _selectedGroupId = widget.preselectedGroupId;
      Future.microtask(() => _onGroupSelected(widget.preselectedGroupId));
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

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

  Future<void> _onGroupSelected(String? groupId) async {
    if (groupId == null) return;

    setState(() => _isLoading = true);
    try {
      final details = await ref.read(groupDetailsProvider(groupId).future);
      if (mounted) {
        setState(() {
          _selectedGroupId = groupId;
          _selectedGroupDetails = details;
          if (widget.expense == null || widget.expense!.groupId != groupId) {
            _selectedParticipants = details.members.map((m) => m.id).toList();
            _splits = {};
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load group details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_isGroupExpense) {
      if (_selectedGroupId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a group')));
        return;
      }
      if (_selectedParticipants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one participant')),
        );
        return;
      }
      if (_splitType == 'EXACT') {
        final totalSplit = _selectedParticipants.fold(
          0.0,
          (sum, id) => sum + (_splits[id] ?? 0.0),
        );
        if ((totalSplit - amount).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Total split amount must equal expense amount'),
            ),
          );
          return;
        }

        for (var pId in _selectedParticipants) {
          if ((_splits[pId] ?? 0.0) <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'All selected participants must have a share amount greater than ₹0',
                ),
              ),
            );
            return;
          }
        }
      }

      if (_splitType == 'PERCENT') {
        final totalPercent = _selectedParticipants.fold(
          0.0,
          (sum, id) => sum + (_splits[id] ?? 0.0),
        );
        if ((totalPercent - 100).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Total percentage must equal 100%')),
          );
          return;
        }

        for (var pId in _selectedParticipants) {
          if ((_splits[pId] ?? 0.0) <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'All selected participants must have a share percentage greater than 0%',
                ),
              ),
            );
            return;
          }
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
        'date': DateTime.utc(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ).toIso8601String(),
        'participants': _isGroupExpense ? _selectedParticipants : [],
        if (_isGroupExpense) 'group_id': _selectedGroupId,
        if (_isGroupExpense) 'split_type': _splitType,
        if (_isGroupExpense)
          'splits': Map.fromEntries(
            _splits.entries.where(
              (element) => _selectedParticipants.contains(element.key),
            ),
          ),
        if (_isGroupExpense) 'add_to_personal': _addToPersonal,
      };

      if (widget.expense == null) {
        await ref.read(expenseProvider.notifier).addExpense(expenseData);
      } else {
        await ref
            .read(expenseProvider.notifier)
            .updateExpense(widget.expense!.id, expenseData);
      }

      if (_isGroupExpense && _selectedGroupId != null) {
        ref.invalidate(groupDetailsProvider(_selectedGroupId!));
        ref.invalidate(groupExpensesProvider("${_selectedGroupId!}|"));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupsAsync = ref.watch(groupsProvider);
    final groups = groupsAsync.value ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.expense != null ? 'Edit Expense' : 'Add Expense',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            LucideIcons.x,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 1. Context Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slate[900]
                            : AppColors.slate[50],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleOption(
                            "Personal",
                            !_isGroupExpense,
                            isDark,
                            () {
                              setState(() {
                                _isGroupExpense = false;
                                _selectedGroupId = null;
                                _selectedGroupDetails = null;
                              });
                            },
                          ),
                          _buildToggleOption(
                            _isGroupExpense
                                ? "Group: ${_selectedGroupDetails?.group.name ?? '...'}"
                                : "Group",
                            _isGroupExpense,
                            isDark,
                            () => _showGroupPicker(context, groups, isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // 2. Description
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.fileText,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black38,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _descriptionController,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Enter description",
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 3. Amount
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.indianRupee,
                                  color: isDark
                                      ? AppColors.primary[400]
                                      : AppColors.primary[600],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.primary[400]
                                        : AppColors.primary[600],
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "0.00",
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black.withOpacity(0.05),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Divider(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                          ),
                          const SizedBox(height: 12),

                          // 4. Split Row
                          if (_isGroupExpense) ...[
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(
                                  "Paid by",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                _buildBadge(
                                  "You",
                                  LucideIcons.user,
                                  isDark,
                                  () {},
                                ),
                                Text(
                                  "and split",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                _buildBadge(
                                  _splitType.toLowerCase(),
                                  _splitType == 'EQUAL'
                                      ? LucideIcons.divide
                                      : _splitType == 'PERCENT'
                                      ? LucideIcons.percent
                                      : LucideIcons.pencil,
                                  isDark,
                                  () => _showSplitTypePicker(context, isDark),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            // 5. Participants Header
                            Text(
                              "PARTICIPANTS",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05),
                            ),
                            const SizedBox(height: 12),

                            // 6. Participants List
                            if (_selectedGroupDetails != null)
                              ..._selectedGroupDetails!.members.map((member) {
                                final isSelected = _selectedParticipants
                                    .contains(member.id);
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedParticipants.remove(member.id);
                                        _splits.remove(member.id);
                                      } else {
                                        _selectedParticipants.add(member.id);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: isDark
                                              ? Colors.white10
                                              : Colors.black.withOpacity(0.05),
                                          child: Text(
                                            member.displayName[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            member.displayName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isSelected &&
                                            (_splitType == 'EXACT' ||
                                                _splitType == 'PERCENT')) ...[
                                          SizedBox(
                                            width: 70,
                                            height: 32,
                                            child: TextFormField(
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              textAlign: TextAlign.end,
                                              initialValue:
                                                  _splits[member.id]
                                                      ?.toString() ??
                                                  '',
                                              onChanged: (v) {
                                                final numVal =
                                                    double.tryParse(v) ?? 0;
                                                _splits[member.id] = numVal;
                                              },
                                              decoration: InputDecoration(
                                                hintText:
                                                    _splitType == 'PERCENT'
                                                    ? "0%"
                                                    : "₹0",
                                                hintStyle: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.white24
                                                      : Colors.black26,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                filled: true,
                                                fillColor: isDark
                                                    ? Colors.white.withOpacity(
                                                        0.05,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.02,
                                                      ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                        ],
                                        Icon(
                                          isSelected
                                              ? LucideIcons.checkCircle2
                                              : LucideIcons.circle,
                                          color: isSelected
                                              ? (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                              : (isDark
                                                    ? Colors.white10
                                                    : Colors.black12),
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],
                          const SizedBox(
                            height: 180,
                          ), // Increased Dock clearance to ensure participants aren't blocked
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 7. Floating Action Dock
          _buildFloatingDock(context, isDark),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white38 : Colors.black26),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    String label,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingDock(BuildContext context, bool isDark) {
    return Positioned(
      bottom: 5,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate[900] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _buildDockItem(
                  LucideIcons.calendar,
                  DateFormat('MMM dd').format(_selectedDate),
                  isDark,
                  () => _selectDate(context),
                ),
                _buildDockItem(
                  LucideIcons.tag,
                  _categoryController.text.isEmpty
                      ? "General"
                      : _categoryController.text,
                  isDark,
                  _showCategoryPicker,
                ),
                _buildDockItem(
                  _addToPersonal
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  "Sync",
                  isDark,
                  () => setState(() => _addToPersonal = !_addToPersonal),
                  active: _addToPersonal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem(
    IconData icon,
    String label,
    bool isDark,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? Colors.white : Colors.black)
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.slate[900]
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Food', 'Transport', 'Utilities', 'Entertainment', 'General']
            .map(
              (c) => ListTile(
                title: Text(c),
                onTap: () {
                  setState(() => _categoryController.text = c);
                  Navigator.pop(ctx);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showSplitTypePicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.slate[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['EQUAL', 'EXACT', 'PERCENT']
            .map(
              (t) => ListTile(
                title: Text(t),
                trailing: _splitType == t
                    ? const Icon(LucideIcons.check)
                    : null,
                onTap: () {
                  setState(() => _splitType = t);
                  Navigator.pop(modalCtx);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _showGroupPicker(
    BuildContext context,
    List<Group> groups,
    bool isDark,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.slate[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Select Group",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary[100],
                  child: Icon(
                    LucideIcons.user,
                    color: AppColors.primary[600],
                    size: 20,
                  ),
                ),
                title: const Text("Personal Space"),
                onTap: () {
                  setState(() {
                    _isGroupExpense = false;
                    _selectedGroupId = null;
                    _selectedGroupDetails = null;
                  });
                  Navigator.pop(modalCtx);
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final g = groups[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05),
                        child: Icon(
                          LucideIcons.users,
                          color: isDark ? Colors.white : Colors.black,
                          size: 20,
                        ),
                      ),
                      title: Text(g.name),
                      onTap: () {
                        setState(() => _isGroupExpense = true);
                        _onGroupSelected(g.id);
                        Navigator.pop(modalCtx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
