import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../transactions/data/loan_model.dart';
import '../../data/loans_repository.dart';

class ReminderSheet extends StatefulWidget {
  final Loan loan;
  final String token;
  final LoansRepository repository;

  const ReminderSheet({
    super.key,
    required this.loan,
    required this.token,
    required this.repository,
  });

  static void show(
    BuildContext context, {
    required Loan loan,
    required String token,
    required LoansRepository repository,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReminderSheet(loan: loan, token: token, repository: repository),
    );
  }

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  DateTime? _selectedDate;
  bool _nudgeBorrower = false;
  bool _loading = false;
  String? _error;

  void _selectQuickDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      setState(() => _error = 'Select a date');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.setReminder(
        widget.token,
        widget.loan.id,
        remindAt: _selectedDate!,
        nudgeBorrower: _nudgeBorrower,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder set')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDueDate = widget.loan.dueDate != null;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final inThreeDays = DateTime.now().add(const Duration(days: 3));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Set Reminder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickChip(
                label: 'Tomorrow',
                selected: _selectedDate != null &&
                    _isSameDay(_selectedDate!, tomorrow),
                onTap: () => _selectQuickDate(tomorrow),
                isDark: isDark,
              ),
              _QuickChip(
                label: 'In 3 days',
                selected: _selectedDate != null &&
                    _isSameDay(_selectedDate!, inThreeDays),
                onTap: () => _selectQuickDate(inThreeDays),
                isDark: isDark,
              ),
              _QuickChip(
                label: 'On due date',
                selected: hasDueDate &&
                    _selectedDate != null &&
                    _isSameDay(_selectedDate!, widget.loan.dueDate!),
                onTap: hasDueDate
                    ? () => _selectQuickDate(widget.loan.dueDate!)
                    : null,
                isDark: isDark,
                disabled: !hasDueDate,
              ),
              _QuickChip(
                label: 'Custom',
                selected: _selectedDate != null &&
                    !_isSameDay(_selectedDate!, tomorrow) &&
                    !_isSameDay(_selectedDate!, inThreeDays) &&
                    !(hasDueDate &&
                        _isSameDay(_selectedDate!, widget.loan.dueDate!)),
                onTap: _pickCustomDate,
                isDark: isDark,
                icon: LucideIcons.calendar,
              ),
            ],
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reminder: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (widget.loan.direction == 'lent' && widget.loan.borrowerUserId != null) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Also nudge ${widget.loan.contactName}',
                style: const TextStyle(fontSize: 13),
              ),
              value: _nudgeBorrower,
              onChanged: (v) => setState(() => _nudgeBorrower = v),
              dense: true,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Set Reminder',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool isDark;
  final bool disabled;
  final IconData? icon;

  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.disabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.orange[600]
              : disabled
                  ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0))
                  : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(
                  color: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFDDDDDD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: disabled
                      ? Colors.grey
                      : (selected ? Colors.white : null)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: disabled
                    ? Colors.grey
                    : (selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
