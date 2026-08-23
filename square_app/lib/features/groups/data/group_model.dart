import '../../expense/data/expense_model.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final List<GroupMember> members;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['created_by'] ?? '',
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

  String get shortName => firstName ?? username;
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

class Settlement {
  final String id;
  final double amount;
  final DateTime date;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String? groupId;

  Settlement({
    required this.id,
    required this.amount,
    required this.date,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    this.groupId,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      fromUserId: json['from_user_id'] ?? '',
      fromUserName: json['from_user_name'] ?? '',
      toUserId: json['to_user_id'] ?? '',
      toUserName: json['to_user_name'] ?? '',
      groupId: json['group_id'],
    );
  }
}

/// A single entry in a group's chronological feed — either a shared [Expense]
/// or a direct [Settlement] payment between two members.
sealed class GroupFeedItem {
  DateTime get date;
}

class ExpenseFeedItem extends GroupFeedItem {
  final Expense expense;
  ExpenseFeedItem(this.expense);

  @override
  DateTime get date => expense.date;
}

class SettlementFeedItem extends GroupFeedItem {
  final Settlement settlement;
  SettlementFeedItem(this.settlement);

  @override
  DateTime get date => settlement.date;
}

GroupFeedItem groupFeedItemFromJson(Map<String, dynamic> json) {
  if (json['type'] == 'settlement')
    return SettlementFeedItem(Settlement.fromJson(json));
  return ExpenseFeedItem(Expense.fromJson(json));
}

/// An expiring, email-targeted link a group admin can share so someone joins
/// on their own — never a direct add. `status` is one of pending / accepted
/// / revoked / expired (the last one is computed server-side, not stored).
class GroupInvite {
  final String id;
  final String email;
  final String status;
  final String link;
  final DateTime createdAt;
  final DateTime expiresAt;

  GroupInvite({
    required this.id,
    required this.email,
    required this.status,
    required this.link,
    required this.createdAt,
    required this.expiresAt,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'pending',
      link: json['link'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        json['expires_at'] ?? DateTime.now().toIso8601String(),
      ),
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
