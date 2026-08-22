import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'group_model.dart';
import 'group_analysis_model.dart';

final groupRepositoryProvider = Provider(
  (ref) => GroupRepository(ref.watch(apiClientProvider)),
);

class GroupRepository {
  final Dio _dio;

  GroupRepository(this._dio);

  Future<List<Group>> getUserGroups() async {
    try {
      final response = await _dio.get('/groups');

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
      final response = await _dio.post('/groups', data: groupData);
      return Group.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to create group';
    }
  }

  Future<GroupDetails> getGroupDetails(String id) async {
    try {
      final response = await _dio.get('/groups/$id');
      return GroupDetails.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch group details';
    }
  }

  // Helper method for generic calls if needed
  Future<void> inviteUser(String groupId, String email) async {
    try {
      await _dio.post('/groups/$groupId/invite', data: {'email': email});
    } catch (e) {
      throw Exception('Failed to invite user: $e');
    }
  }

  Future<void> addMember(String groupId, String userId) async {
    try {
      await _dio.post('/groups/$groupId/members', data: {'user_id': userId});
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to add member';
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  Future<List<GroupFeedItem>> getGroupExpenses(
    String groupId, {
    String? searchQuery,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _dio.get(
        '/groups/$groupId/expenses',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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

      return dataList.map((json) => groupFeedItemFromJson(json)).toList();
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch group expenses';
    } catch (e) {
      throw Exception('Failed to fetch group expenses: $e');
    }
  }

  Future<GroupAnalysisSummary> getGroupAnalysis(
    String groupId, {
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/groups/$groupId/analysis',
        queryParameters: {'start_date': startDate, 'end_date': endDate},
      );
      return GroupAnalysisSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch group analysis';
    }
  }

  Future<void> settle(String groupId, String toUserId, double amount) async {
    try {
      await _dio.post(
        '/groups/$groupId/settle',
        data: {'to_user_id': toUserId, 'amount': amount},
      );
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to settle';
    } catch (e) {
      throw Exception('Failed to settle: $e');
    }
  }
}
