import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import 'contact_model.dart';
import '../../transactions/data/loan_model.dart';

class ContactsRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<Contact>> getContacts(String token) async {
    final res = await _dio.get(
      '/contacts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (res.data as List).map((j) => Contact.fromJson(j)).toList();
  }

  Future<ContactSearchResult> search(String token, String query) async {
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
  }

  Future<Contact> createContact(
    String token, {
    required String name,
    String? phone,
    String? email,
    String? linkedUserId,
  }) async {
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
  }

  Future<Map<String, dynamic>> getContactLoans(
      String token, String contactId) async {
    final res = await _dio.get(
      '/contacts/$contactId/loans',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = res.data as Map<String, dynamic>;
    return {
      'contact': Contact.fromJson(data['contact']),
      'loans': (data['loans'] as List)
          .map((j) => Loan.fromJson(j))
          .toList(),
      'net_balance': data['net_balance'],
    };
  }
}
