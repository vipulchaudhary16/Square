class FeatureFlag {
  final String id;
  final String key;
  final String description;
  final String category;
  final bool userToggleable;
  final bool value;

  const FeatureFlag({
    required this.id,
    required this.key,
    required this.description,
    required this.category,
    required this.userToggleable,
    required this.value,
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) => FeatureFlag(
        id: json['id'] as String,
        key: json['key'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        userToggleable: json['user_toggleable'] as bool,
        value: json['value'] as bool,
      );

  FeatureFlag copyWith({bool? value}) => FeatureFlag(
        id: id,
        key: key,
        description: description,
        category: category,
        userToggleable: userToggleable,
        value: value ?? this.value,
      );
}
