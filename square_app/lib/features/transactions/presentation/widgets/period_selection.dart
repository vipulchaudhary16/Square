import 'package:intl/intl.dart';

enum PeriodType { week, month, year, custom }

/// Client computes the concrete date range for a period — the backend just
/// filters by start/end date, no week/month/year semantics server-side.
class PeriodSelection {
  final PeriodType type;
  final DateTime anchor;
  final DateTime? customStart;
  final DateTime? customEnd;

  const PeriodSelection({
    required this.type,
    required this.anchor,
    this.customStart,
    this.customEnd,
  });

  factory PeriodSelection.initial() => PeriodSelection(type: PeriodType.month, anchor: DateTime.now());

  DateTime get startDate {
    switch (type) {
      case PeriodType.week:
        final weekday = anchor.weekday; // 1 = Monday
        return DateTime(anchor.year, anchor.month, anchor.day).subtract(Duration(days: weekday - 1));
      case PeriodType.month:
        return DateTime(anchor.year, anchor.month, 1);
      case PeriodType.year:
        return DateTime(anchor.year, 1, 1);
      case PeriodType.custom:
        return customStart ?? anchor;
    }
  }

  DateTime get endDate {
    switch (type) {
      case PeriodType.week:
        return startDate.add(const Duration(days: 6));
      case PeriodType.month:
        return DateTime(anchor.year, anchor.month + 1, 1).subtract(const Duration(days: 1));
      case PeriodType.year:
        return DateTime(anchor.year, 12, 31);
      case PeriodType.custom:
        return customEnd ?? anchor;
    }
  }

  String get apiStartDate => DateFormat('yyyy-MM-dd').format(startDate);
  String get apiEndDate => DateFormat('yyyy-MM-dd').format(endDate);

  bool get supportsNavigation => type != PeriodType.custom;

  String get label {
    switch (type) {
      case PeriodType.week:
        final s = startDate, e = endDate;
        final sameMonth = s.month == e.month;
        return sameMonth
            ? '${DateFormat('MMM d').format(s)} - ${DateFormat('d').format(e)}'
            : '${DateFormat('MMM d').format(s)} - ${DateFormat('MMM d').format(e)}';
      case PeriodType.month:
        return DateFormat('MMMM yyyy').format(anchor);
      case PeriodType.year:
        return '${anchor.year}';
      case PeriodType.custom:
        return '${DateFormat('MMM d, y').format(startDate)} - ${DateFormat('MMM d, y').format(endDate)}';
    }
  }

  PeriodSelection withType(PeriodType newType) => PeriodSelection(
        type: newType,
        anchor: anchor,
        customStart: customStart,
        customEnd: customEnd,
      );

  PeriodSelection next() {
    switch (type) {
      case PeriodType.week:
        return PeriodSelection(type: type, anchor: anchor.add(const Duration(days: 7)));
      case PeriodType.month:
        return PeriodSelection(type: type, anchor: DateTime(anchor.year, anchor.month + 1, 1));
      case PeriodType.year:
        return PeriodSelection(type: type, anchor: DateTime(anchor.year + 1, anchor.month, 1));
      case PeriodType.custom:
        return this;
    }
  }

  PeriodSelection previous() {
    switch (type) {
      case PeriodType.week:
        return PeriodSelection(type: type, anchor: anchor.subtract(const Duration(days: 7)));
      case PeriodType.month:
        return PeriodSelection(type: type, anchor: DateTime(anchor.year, anchor.month - 1, 1));
      case PeriodType.year:
        return PeriodSelection(type: type, anchor: DateTime(anchor.year - 1, anchor.month, 1));
      case PeriodType.custom:
        return this;
    }
  }

  PeriodSelection withCustomRange(DateTime start, DateTime end) => PeriodSelection(
        type: PeriodType.custom,
        anchor: anchor,
        customStart: start,
        customEnd: end,
      );
}
