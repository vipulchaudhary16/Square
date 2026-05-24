import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/category_picker_sheet.dart';
import '../../../transactions/presentation/transactions_provider.dart';

class AddEditInvestmentScreen extends ConsumerStatefulWidget {
  const AddEditInvestmentScreen({super.key});

  @override
  ConsumerState<AddEditInvestmentScreen> createState() =>
      _AddEditInvestmentScreenState();
}

class _AddEditInvestmentScreenState
    extends ConsumerState<AddEditInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _amountInvestedController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _selectedCategoryId;
  String _selectedCategoryName = 'Category';

  @override
  void dispose() {
    _typeController.dispose();
    _amountInvestedController.dispose();
    _currentValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final amountInvested = double.parse(_amountInvestedController.text);
      final currentValue = _currentValueController.text.isNotEmpty
          ? double.parse(_currentValueController.text)
          : amountInvested;

      final data = {
        'type': _typeController.text,
        'amount_invested': amountInvested,
        'current_value': currentValue,
        'description': _descriptionController.text,
        'date': _selectedDate.toUtc().toIso8601String(),
        'category_id': _selectedCategoryId ?? '',
      };

      await ref.read(investmentsProvider.notifier).create(data);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment added successfully')),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryPickerSheet(
        selectedId: _selectedCategoryId,
        appliesTo: 'investment',
        onSelected: (id, name) => setState(() {
          _selectedCategoryId = id;
          _selectedCategoryName = name;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text(
          'Add Investment',
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
            onPressed: _isLoading ? null : _submit,
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildFieldRow(
                            icon: LucideIcons.pieChart,
                            iconColor: isDark
                                ? Colors.white54
                                : Colors.black38,
                            isDark: isDark,
                            child: TextFormField(
                              controller: _typeController,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type (Stock, MF, Gold…)',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.slate[500]
                                      : AppColors.slate[400],
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                          ),
                          const SizedBox(height: 12),
                          _buildFieldRow(
                            icon: LucideIcons.fileText,
                            iconColor: isDark
                                ? Colors.white54
                                : Colors.black38,
                            isDark: isDark,
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: null,
                              minLines: 3,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Name / Description',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.slate[500]
                                      : AppColors.slate[400],
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                          ),
                          const SizedBox(height: 12),
                          _buildFieldRow(
                            icon: LucideIcons.indianRupee,
                            iconColor: isDark
                                ? AppColors.slate[400]!
                                : AppColors.slate[600]!,
                            isDark: isDark,
                            child: TextFormField(
                              controller: _amountInvestedController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Amount Invested',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.slate[500]
                                      : AppColors.slate[400],
                                ),
                                border: InputBorder.none,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                          ),
                          const SizedBox(height: 12),
                          _buildFieldRow(
                            icon: LucideIcons.trendingUp,
                            iconColor: isDark
                                ? Colors.white54
                                : Colors.black38,
                            isDark: isDark,
                            child: TextFormField(
                              controller: _currentValueController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Current Value (optional)',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.slate[500]
                                      : AppColors.slate[400],
                                  fontWeight: FontWeight.w400,
                                ),
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
              ],
            ),
          ),
          _buildFloatingDock(isDark),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required Color iconColor,
    required Widget child,
    required bool isDark,
  }) {
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
        child: Row(
          children: [
            _buildDockItem(
              LucideIcons.calendar,
              DateFormat('MMM dd').format(_selectedDate),
              isDark,
              _pickDate,
            ),
            _buildDockItem(
              LucideIcons.tag,
              _selectedCategoryName,
              isDark,
              _showCategoryPicker,
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
    VoidCallback onTap,
  ) {
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
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
