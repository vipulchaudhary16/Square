class Group {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<GroupMember> members;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      members:
          (json['members'] as List<dynamic>?)?.map((e) {
            if (e is String) {
              return GroupMember(id: e, username: 'Member', email: '');
            } else if (e is Map<String, dynamic>) {
              return GroupMember.fromJson(e);
            }
            return GroupMember(id: '', username: 'Unknown', email: '');
          }).toList() ??
          [],
    );
  }
}

class GroupMember {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;

  GroupMember({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  String get displayName =>
      firstName != null ? '$firstName $lastName' : username;
}

class Debt {
  final String from;
  final String to;
  final double amount;

  Debt({required this.from, required this.to, required this.amount});

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      from: json['from'],
      to: json['to'],
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class GroupDetails {
  final Group group;
  final List<GroupMember> members;
  final List<Debt> debts;

  GroupDetails({
    required this.group,
    required this.members,
    required this.debts,
  });

  factory GroupDetails.fromJson(Map<String, dynamic> json) {
    return GroupDetails(
      group: Group.fromJson(json['group']),
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => GroupMember.fromJson(e))
              .toList() ??
          [],
      debts:
          (json['debts'] as List<dynamic>?)
              ?.map((e) => Debt.fromJson(e))
              .toList() ??
          [],
    );
  }
}
