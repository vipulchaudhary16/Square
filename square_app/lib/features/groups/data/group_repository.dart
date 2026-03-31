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
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/groups',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data == null) return [];

      final dynamic rawData = response.data;
      List<dynamic> dataList = [];
      if (rawData is List) {
        dataList = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        dataList = rawData['data'] ?? [];
      } else if (rawData is Map) {
        // Handle Fiber error response { "error": "msg" }
        if (rawData.containsKey('error')) throw rawData['error'];
        dataList = [];
      }

      return dataList.map((json) => Group.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch groups';
    } catch (e) {
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
      await _dio.post(
        '/groups/$groupId/invite',
        data: {'email': email},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to invite user: $e');
    }
  }

  Future<void> addMember(String groupId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      await _dio.post(
        '/groups/$groupId/members',
        data: {'user_id': userId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to add member';
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  Future<List<Expense>> getGroupExpenses(
    String groupId, {
    String? searchQuery,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final queryParams = <String, dynamic>{};
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _dio.get(
        '/groups/$groupId/expenses',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data == null) {
        return [];
      }

      final dynamic rawData = response.data;
      List<dynamic> dataList = [];

      if (rawData is List) {
        dataList = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        dataList = rawData['data'] ?? [];
      } else if (rawData is Map) {
        if (rawData.containsKey('error')) throw rawData['error'];
        dataList = [];
      }

      return dataList.map((json) => Expense.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch group expenses';
    } catch (e) {
      throw Exception('Failed to fetch group expenses: $e');
    }
  }
}
