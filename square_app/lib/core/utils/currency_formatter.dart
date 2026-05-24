/// Formats a [double] as an Indian-locale currency string.
///
/// Examples:
///   formatInr(22000000)  → "₹2,20,00,000"
///   formatInr(150000)    → "₹1,50,000"
///   formatInr(1500.5)    → "₹1,500.50"  (decimals shown only when non-zero)
///   formatInr(-5000)     → "-₹5,000"
String formatInr(double amount, {bool showPaise = false}) {
  final isNegative = amount < 0;
  final absAmount = amount.abs();

  // Split into integer and decimal parts
  final integerPart = absAmount.floor();
  final decimalPart = absAmount - integerPart;

  // Format integer with Indian grouping:  last 3 digits, then groups of 2
  final intStr = integerPart.toString();
  final formatted = _applyIndianGrouping(intStr);

  // Build paise string
  String paiseStr = '';
  if (showPaise || (decimalPart > 0.001 && !showPaise)) {
    // Round to 2 decimal places
    final paise = (decimalPart * 100).round();
    if (paise > 0 || showPaise) {
      paiseStr = '.${paise.toString().padLeft(2, '0')}';
    }
  }

  final sign = isNegative ? '-' : '';
  return '$sign₹$formatted$paiseStr';
}

/// Applies the Indian number grouping system:
///   - Last 3 digits are grouped as thousands
///   - Every 2 digits before that are grouped (lakhs, crores, etc.)
///
/// e.g. "22000000" → "2,20,00,000"
///      "150000"   → "1,50,000"
///      "1500"     → "1,500"
String _applyIndianGrouping(String digits) {
  if (digits.length <= 3) return digits;

  // First group: last 3 digits
  final last3 = digits.substring(digits.length - 3);
  var remaining = digits.substring(0, digits.length - 3);

  // Subsequent groups: 2 digits each
  final parts = <String>[];
  while (remaining.length > 2) {
    parts.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }
  if (remaining.isNotEmpty) parts.insert(0, remaining);

  return '${parts.join(',')},${last3}';
}

// ─── Indian number → words ────────────────────────────────────────────────────

const _ones = [
  '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
  'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
  'seventeen', 'eighteen', 'nineteen',
];

const _tens = [
  '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety',
];

String _twoDigitWords(int n) {
  assert(n >= 0 && n < 100);
  if (n < 20) return _ones[n];
  final t = _tens[n ~/ 10];
  final o = n % 10 == 0 ? '' : ' ${_ones[n % 10]}';
  return '$t$o';
}

/// Converts [amount] to Indian-system words.
///
/// Examples:
///   amountToIndianWords(22000000)  → "2 crore 20 lakh"
///   amountToIndianWords(150750)    → "1 lakh 50 thousand 7 hundred 50"
///   amountToIndianWords(1500)      → "1 thousand 5 hundred"
///   amountToIndianWords(42)        → "forty two"
String amountToIndianWords(double amount) {
  if (amount < 0) return 'minus ${amountToIndianWords(-amount)}';

  final n = amount.round();
  if (n == 0) return 'zero';

  final crores    = n ~/ 10000000;
  final lakhs     = (n % 10000000) ~/ 100000;
  final thousands = (n % 100000) ~/ 1000;
  final hundreds  = (n % 1000) ~/ 100;
  final remainder = n % 100;

  final parts = <String>[];
  if (crores    > 0) parts.add('${_twoDigitWords(crores)} crore');
  if (lakhs     > 0) parts.add('${_twoDigitWords(lakhs)} lakh');
  if (thousands > 0) parts.add('${_twoDigitWords(thousands)} thousand');
  if (hundreds  > 0) parts.add('${_ones[hundreds]} hundred');
  if (remainder > 0) parts.add(_twoDigitWords(remainder));

  // Capitalise first letter
  final result = parts.join(' ');
  return result[0].toUpperCase() + result.substring(1);
}
