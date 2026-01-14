import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import 'group_model.dart';
import '../../expense/data/expense_model.dart';

final groupRepositoryProvider = Provider((ref) => GroupRepository());

class GroupRepository {
  final Dio _dio;

  GroupRepository({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<Group>> getUserGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print('AUTH TOKEN: ${token != null ? "FOUND" : "MISSING"}');
      if (token == null) throw Exception('Not authenticated');

      print('FETCHING GROUPS FROM: ${_dio.options.baseUrl}/groups');
      final response = await _dio.get(
        '/groups',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('RESPONSE STATUS: ${response.statusCode}');
      print('RESPONSE DATA: ${response.data}');

      if (response.data == null) {
        return [];
      }

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['data'] ?? [];

      return data.map((json) => Group.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DIO ERROR: ${e.message}');
      print('DIO RESPONSE: ${e.response?.data}');
      throw e.response?.data['error'] ?? 'Failed to fetch groups';
    } catch (e) {
      print('GENERAL ERROR: $e');
      throw Exception('Failed to fetch groups: $e');
    }
  }

  Future<Group> createGroup(Map<String, dynamic> groupData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.post(
        '/groups',
        data: groupData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Group.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to create group';
    }
  }

  Future<GroupDetails> getGroupDetails(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/groups/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return GroupDetails.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch group details';
    }
  }

  // Helper method for generic calls if needed
  Future<void> inviteUser(String groupId, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await _dio.post(
        '/groups/$groupId/invite',
        data: {'email': email},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to invite user: $e');
    }
  }
}
