import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import 'contact_model.dart';
import '../../transactions/data/loan_model.dart';

class ContactsRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<Contact>> getContacts(String token) async {
    try {
      final res = await _dio.get(
        '/contacts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (res.data as List? ?? [])
          .map((j) => Contact.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch contacts: $e');
    }
  }

  Future<ContactSearchResult> search(String token, String query) async {
    try {
      final res = await _dio.get(
        '/contacts/search',
        queryParameters: {'q': query},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data as Map<String, dynamic>;
      return ContactSearchResult(
        contacts: (data['contacts'] as List? ?? [])
            .map((j) => Contact.fromJson(j))
            .toList(),
        platformUsers: (data['platform_users'] as List? ?? [])
            .map((j) => PlatformUserResult.fromJson(j))
            .toList(),
      );
    } catch (e) {
      throw Exception('Failed to search contacts: $e');
    }
  }

  Future<Contact> updateContact(
    String token,
    String contactId, {
    required String name,
    String? phone,
    String? email,
  }) async {
    try {
      final res = await _dio.patch(
        '/contacts/$contactId',
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Contact.fromJson(res.data);
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  Future<Contact> createContact(
    String token, {
    required String name,
    String? phone,
    String? email,
    String? linkedUserId,
  }) async {
    try {
      final res = await _dio.post(
        '/contacts',
        data: {
          'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (linkedUserId != null) 'linked_user_id': linkedUserId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Contact.fromJson(res.data);
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  Future<ContactLoansResult> getContactLoans(
      String token, String contactId) async {
    try {
      final res = await _dio.get(
        '/contacts/$contactId/loans',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data as Map<String, dynamic>;
      return ContactLoansResult(
        contact: Contact.fromJson(data['contact']),
        loans: (data['loans'] as List? ?? [])
            .map((j) => Loan.fromJson(j as Map<String, dynamic>))
            .toList(),
        netBalance: (data['net_balance'] as Map<String, dynamic>?) ?? {},
      );
    } catch (e) {
      throw Exception('Failed to fetch contact loans: $e');
    }
  }
}
