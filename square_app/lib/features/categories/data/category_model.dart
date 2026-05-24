class Category {
  final String id;
  final String name;
  final List<String> appliesTo;
  final bool isStandard;

  const Category({
    required this.id,
    required this.name,
    required this.appliesTo,
    required this.isStandard,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        appliesTo: List<String>.from(json['applies_to'] as List),
        isStandard: json['is_standard'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'applies_to': appliesTo,
      };

  Category copyWith({String? name, List<String>? appliesTo}) => Category(
        id: id,
        name: name ?? this.name,
        appliesTo: appliesTo ?? this.appliesTo,
        isStandard: isStandard,
      );
}
