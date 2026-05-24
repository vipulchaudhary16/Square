import 'package:flutter_test/flutter_test.dart';
import 'package:square_app/features/feature_flags/data/feature_flag_model.dart';

void main() {
  group('FeatureFlag.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'abc123',
        'key': 'show_expense_trends_chart',
        'description': 'Show expense trends chart on dashboard',
        'category': 'dashboard',
        'user_toggleable': true,
        'value': false,
      };

      final flag = FeatureFlag.fromJson(json);

      expect(flag.id, 'abc123');
      expect(flag.key, 'show_expense_trends_chart');
      expect(flag.description, 'Show expense trends chart on dashboard');
      expect(flag.category, 'dashboard');
      expect(flag.userToggleable, isTrue);
      expect(flag.value, isFalse);
    });

    test('copyWith updates only value field', () {
      const flag = FeatureFlag(
        id: 'abc123',
        key: 'flag_a',
        description: 'desc',
        category: 'cat',
        userToggleable: true,
        value: false,
      );

      final updated = flag.copyWith(value: true);

      expect(updated.value, isTrue);
      expect(updated.id, 'abc123');
      expect(updated.key, 'flag_a');
      expect(updated.userToggleable, isTrue);
    });
  });
}
