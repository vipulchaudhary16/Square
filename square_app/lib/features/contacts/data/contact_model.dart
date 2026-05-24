class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? linkedUserId;
  final bool onPlatform;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.linkedUserId,
    required this.onPlatform,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'],
        email: json['email'],
        linkedUserId: json['linked_user_id'],
        onPlatform: json['on_platform'] ?? false,
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class PlatformUserResult {
  final String id;
  final String username;
  final String name;
  final String email;
  final String? mobileNumber;

  PlatformUserResult({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.mobileNumber,
  });

  factory PlatformUserResult.fromJson(Map<String, dynamic> json) =>
      PlatformUserResult(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        mobileNumber: json['mobile_number'],
      );
}

class ContactSearchResult {
  final List<Contact> contacts;
  final List<PlatformUserResult> platformUsers;

  ContactSearchResult({required this.contacts, required this.platformUsers});
}
