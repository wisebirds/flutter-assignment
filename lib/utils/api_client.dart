// ignore_for_file: avoid_print

import 'dart:isolate';

import 'package:bcrypt/bcrypt.dart';
import 'package:dio/dio.dart';

const _passwordSaltRounds = 10;

// Configuration
const _apiBaseUrl = 'https://zimobhtejidbcsrujhxd.supabase.co/rest/v1';
const _apiKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InppbW9iaHRlamlkYmNzcnVqaHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwOTgxNzYsImV4cCI6MjA3MzY3NDE3Nn0.oi_IEKXYWgSUwrCNGVWtZhRf2ys92N028Kp1Km9vOXE';

// Types

/// 캠페인 목적 코드 값. 서버가 새 값을 내려줄 수 있어 모델에서는 String 으로 받습니다.
abstract final class CampaignObjective {
  static const websiteConversions = 'WEBSITE_CONVERSIONS';
  static const websiteTraffic = 'WEBSITE_TRAFFIC';
  static const sales = 'SALES';
  static const appInstallation = 'APP_INSTALLATION';
  static const lead = 'LEAD';
  static const brand = 'BRAND';
  static const videoViews = 'VIDEO_VIEWS';

  static const values = [
    websiteConversions,
    websiteTraffic,
    sales,
    appInstallation,
    lead,
    brand,
    videoViews,
  ];
}

/// 캠페인 주기 코드 값. 서버가 새 값을 내려줄 수 있어 모델에서는 String 으로 받습니다.
abstract final class CampaignPeriod {
  static const daily = 'DAILY';
  static const weekly = 'WEEKLY';
  static const monthly = 'MONTHLY';

  static const values = [daily, weekly, monthly];
}

class Company {
  const Company({required this.id, required this.name, required this.createdAt});

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as int,
        name: json['name'] as String,
        createdAt: json['created_at'] as String,
      );

  final int id;
  final String name;
  final String createdAt;
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        password: json['password'] as String,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  final int id;
  final String email;
  final String name;
  final String password;
  final String createdAt;
  final String updatedAt;
}

class Campaign {
  const Campaign({
    required this.id,
    required this.name,
    required this.enabled,
    required this.campaignObjective,
    required this.period,
    required this.impressions,
    required this.clicks,
    required this.ctr,
    required this.videoViews,
    required this.vtr,
    required this.createdAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'] as int,
        name: json['name'] as String,
        enabled: json['enabled'] as bool,
        campaignObjective: json['campaign_objective'] as String,
        period: json['period'] as String,
        impressions: json['impressions'] as int,
        clicks: json['clicks'] as int,
        ctr: (json['ctr'] as num).toDouble(),
        videoViews: json['video_views'] as int,
        vtr: (json['vtr'] as num).toDouble(),
        createdAt: json['created_at'] as String,
      );

  final int id;
  final String name;
  final bool enabled;

  /// [CampaignObjective] 의 값
  final String campaignObjective;

  /// [CampaignPeriod] 의 값
  final String period;
  final int impressions;
  final int clicks;
  final double ctr;
  final int videoViews;
  final double vtr;
  final String createdAt;
}

/// create / update 요청 body. null 인 필드는 전송하지 않습니다. (web 의 `Partial<Company>`)
class CompanyInput {
  const CompanyInput({this.name});

  final String? name;

  Map<String, dynamic> toJson() => {if (name != null) 'name': name};
}

/// create / update 요청 body. null 인 필드는 전송하지 않습니다. (web 의 `Partial<User>`)
class UserInput {
  const UserInput({this.email, this.name, this.password});

  final String? email;
  final String? name;
  final String? password;

  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (password != null) 'password': password,
      };
}

/// create / update 요청 body. null 인 필드는 전송하지 않습니다. (web 의 `Partial<Campaign>`)
class CampaignInput {
  const CampaignInput({
    this.name,
    this.enabled,
    this.campaignObjective,
    this.period,
    this.impressions,
    this.clicks,
    this.ctr,
    this.videoViews,
    this.vtr,
  });

  final String? name;
  final bool? enabled;
  final String? campaignObjective;
  final String? period;
  final int? impressions;
  final int? clicks;
  final double? ctr;
  final int? videoViews;
  final double? vtr;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (enabled != null) 'enabled': enabled,
        if (campaignObjective != null) 'campaign_objective': campaignObjective,
        if (period != null) 'period': period,
        if (impressions != null) 'impressions': impressions,
        if (clicks != null) 'clicks': clicks,
        if (ctr != null) 'ctr': ctr,
        if (videoViews != null) 'video_views': videoViews,
        if (vtr != null) 'vtr': vtr,
      };
}

class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    required this.hasNext,
    required this.hasPrev,
  });

  final List<T> data;
  final int total;
  final int totalPages;
  final int currentPage;
  final bool hasNext;
  final bool hasPrev;
}

enum OrderDirection { asc, desc }

class QueryOptions {
  const QueryOptions({
    this.page = 0,
    this.limit = 20,
    this.orderBy = 'id',
    this.orderDir = OrderDirection.desc,
    this.select = '*',
    this.filters = const {},
  });

  final int page;
  final int limit;
  final String orderBy;
  final OrderDirection orderDir;
  final String select;

  /// PostgREST 필터. 예: {'enabled': 'eq.true'}
  final Map<String, Object?> filters;

  QueryOptions copyWith({
    int? page,
    int? limit,
    String? orderBy,
    OrderDirection? orderDir,
    String? select,
    Map<String, Object?>? filters,
  }) =>
      QueryOptions(
        page: page ?? this.page,
        limit: limit ?? this.limit,
        orderBy: orderBy ?? this.orderBy,
        orderDir: orderDir ?? this.orderDir,
        select: select ?? this.select,
        filters: filters ?? this.filters,
      );
}

class SupabaseError {
  const SupabaseError({required this.code, this.details, this.hint, required this.message});

  factory SupabaseError.fromJson(Map<String, dynamic> json) => SupabaseError(
        code: json['code'] as String,
        details: json['details'] as String?,
        hint: json['hint'] as String?,
        message: json['message'] as String,
      );

  final String code;
  final String? details;
  final String? hint;
  final String message;
}

/// API 에러. message 는 "code: message" 형식입니다.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, String> _toQueryParameters(Map<String, Object?> filters) => {
      for (final entry in filters.entries)
        if (entry.value != null && entry.value.toString().isNotEmpty) entry.key: entry.value.toString(),
    };

// Base Dio Client
class SupabaseDioClient {
  SupabaseDioClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _apiBaseUrl,
            headers: {
              'apikey': _apiKey,
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🚀 ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Response Error: ${error.response?.data ?? error.message}');
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  // Generic GET method with pagination
  Future<PaginatedResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic> json) fromJson, {
    QueryOptions options = const QueryOptions(),
  }) async {
    final filterParameters = _toQueryParameters(options.filters);
    final start = options.page * options.limit;

    try {
      final response = await _dio.get<List<dynamic>>(
        endpoint,
        queryParameters: {
          // Pagination
          'offset': '$start',
          'limit': '${options.limit}',
          // Ordering
          'order': '${options.orderBy}.${options.orderDir.name}',
          // Column selection
          'select': options.select,
          // Filters
          ...filterParameters,
        },
        options: Options(headers: {'Range': '$start-${start + options.limit - 1}'}),
      );
      final data = response.data!.map((item) => fromJson(item as Map<String, dynamic>)).toList();

      // Always fetch total count from API using Prefer: count=exact header,
      // with the same filters as the data request
      int total;
      try {
        final countResponse = await _dio.get<List<dynamic>>(
          endpoint,
          queryParameters: filterParameters,
          options: Options(headers: {'Prefer': 'count=exact', 'Range': '0-0'}),
        );
        final contentRange = countResponse.headers.value('content-range');
        final match = contentRange == null ? null : RegExp(r'/(\d+)$').firstMatch(contentRange);
        total = match == null ? data.length : int.parse(match.group(1)!);
      } catch (_) {
        total = data.length;
      }
      final totalPages = (total / options.limit).ceil();

      return PaginatedResponse(
        data: data,
        total: total,
        totalPages: totalPages,
        currentPage: options.page,
        hasNext: options.page < totalPages - 1,
        hasPrev: options.page > 0,
      );
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  // Generic POST method
  Future<List<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        endpoint,
        data: data,
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      return response.data!.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  // Generic PUT method (sent as PATCH)
  Future<List<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, Object> filters = const {},
  }) async {
    try {
      final response = await _dio.patch<List<dynamic>>(
        endpoint,
        data: data,
        queryParameters: {for (final entry in filters.entries) entry.key: 'eq.${entry.value}'},
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      return response.data!.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  // Generic DELETE method (blocked by RLS but included for completeness)
  Future<void> delete(String endpoint, Map<String, Object> filters) async {
    try {
      await _dio.delete<void>(
        endpoint,
        queryParameters: {for (final entry in filters.entries) entry.key: 'eq.${entry.value}'},
      );
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  // Get single record by ID
  Future<T?> getById<T>(
    String endpoint,
    int id,
    T Function(Map<String, dynamic> json) fromJson, {
    String select = '*',
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        endpoint,
        queryParameters: {'id': 'eq.$id', 'select': select},
      );
      final rows = response.data!;
      return rows.isEmpty ? null : fromJson(rows.first as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  // Get count only
  Future<int> count(String endpoint, {Map<String, Object?> filters = const {}}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        endpoint,
        queryParameters: {'select': 'count', ..._toQueryParameters(filters)},
      );
      final rows = response.data!;
      return rows.isEmpty ? 0 : (rows.first as Map<String, dynamic>)['count'] as int;
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  // Get distinct values for a column via RPC
  Future<List<String>> getDistinct(String tableName, String column) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        '/rpc/get_distinct_column_values',
        data: {'table_name': tableName, 'column_name': column},
      );
      return response.data!.cast<String>();
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  // Error handling (Supabase 형식이 아닌 에러 body 는 DioException 그대로 전달)
  Exception _handleError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['code'] is String && data['message'] is String) {
      final supabaseError = SupabaseError.fromJson(data);
      return ApiException('${supabaseError.code}: ${supabaseError.message}');
    }
    return error;
  }
}

// Companies API
class CompaniesApi {
  CompaniesApi(this._client);

  static const _endpoint = '/web_assignment_company';
  final SupabaseDioClient _client;

  Future<PaginatedResponse<Company>> getAll({QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, Company.fromJson, options: options);

  Future<Company?> getById(int id) => _client.getById(_endpoint, id, Company.fromJson);

  Future<List<Company>> create(CompanyInput company) =>
      _client.post(_endpoint, company.toJson(), Company.fromJson);

  Future<List<Company>> update(int id, CompanyInput company) =>
      _client.put(_endpoint, company.toJson(), Company.fromJson, filters: {'id': id});

  Future<PaginatedResponse<Company>> search(String name, {QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, Company.fromJson, options: options.copyWith(filters: {'name': 'ilike.*$name*'}));

  Future<int> count() => _client.count(_endpoint);
}

// Users API
class UsersApi {
  UsersApi(this._client);

  static const _endpoint = '/web_assignment_users';
  final SupabaseDioClient _client;

  Future<PaginatedResponse<User>> getAll({QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, User.fromJson, options: options);

  Future<User?> getById(int id) => _client.getById(_endpoint, id, User.fromJson);

  /// password 는 bcrypt 로 해시해서 저장합니다.
  /// bcrypt 는 UTF-8 72바이트까지만 받으며, 넘으면 ArgumentError 가 발생합니다.
  Future<List<User>> create(UserInput user) async =>
      _client.post(_endpoint, await _withHashedPassword(user), User.fromJson);

  /// password 가 있으면 [create] 와 같이 bcrypt 로 해시해서 저장합니다.
  Future<List<User>> update(int id, UserInput user) async =>
      _client.put(_endpoint, await _withHashedPassword(user), User.fromJson, filters: {'id': id});

  Future<PaginatedResponse<User>> searchByEmail(String email, {QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, User.fromJson, options: options.copyWith(filters: {'email': 'ilike.*$email*'}));

  Future<PaginatedResponse<User>> searchByName(String name, {QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, User.fromJson, options: options.copyWith(filters: {'name': 'ilike.*$name*'}));

  Future<int> count() => _client.count(_endpoint);

  static Future<Map<String, dynamic>> _withHashedPassword(UserInput user) async {
    final json = user.toJson();
    final password = user.password;
    if (password != null && password.isNotEmpty) {
      json['password'] = await _hashPassword(password);
    }
    return json;
  }

  // bcrypt 는 CPU 를 오래 쓰므로 UI isolate 를 막지 않도록 별도 isolate 에서 실행
  static Future<String> _hashPassword(String password) => Isolate.run(
        () => BCrypt.hashpw(password, BCrypt.gensalt(logRounds: _passwordSaltRounds)),
      );
}

/// 캠페인 목록 필터.
/// - null 이면 해당 조건 없음
/// - 빈 리스트면 결과 없음 (web 과 동일하게 `in.()` 로 전송)
class CampaignFilterParams {
  const CampaignFilterParams({this.period, this.campaignObjective, this.enabled, this.name});

  final List<String>? period;
  final List<String>? campaignObjective;
  final bool? enabled;
  final String? name;
}

class CampaignFilter {
  const CampaignFilter({required this.key, required this.values});

  final String key;
  final List<String> values;
}

// Campaigns API
class CampaignsApi {
  CampaignsApi(this._client);

  static const _table = 'web_assignment_campaigns';
  static const _endpoint = '/$_table';
  final SupabaseDioClient _client;

  Future<PaginatedResponse<Campaign>> getAll({
    QueryOptions options = const QueryOptions(),
    CampaignFilterParams? campaignFilters,
  }) {
    final filters = <String, Object?>{...options.filters};
    final period = campaignFilters?.period;
    if (period != null) {
      filters['period'] = 'in.(${period.join(',')})';
    }
    final campaignObjective = campaignFilters?.campaignObjective;
    if (campaignObjective != null) {
      filters['campaign_objective'] = 'in.(${campaignObjective.join(',')})';
    }
    final enabled = campaignFilters?.enabled;
    if (enabled != null) {
      filters['enabled'] = 'eq.$enabled';
    }
    final name = campaignFilters?.name;
    if (name != null && name.isNotEmpty) {
      filters['name'] = 'ilike.*$name*';
    }
    return _client.get(_endpoint, Campaign.fromJson, options: options.copyWith(filters: filters));
  }

  Future<List<CampaignFilter>> getFilters() async {
    final [periods, objectives] = await Future.wait([
      _client.getDistinct(_table, 'period'),
      _client.getDistinct(_table, 'campaign_objective'),
    ]);
    return [
      CampaignFilter(key: 'period', values: periods),
      CampaignFilter(key: 'campaign_objective', values: objectives),
    ];
  }

  Future<Campaign?> getById(int id) => _client.getById(_endpoint, id, Campaign.fromJson);

  Future<List<Campaign>> create(CampaignInput campaign) =>
      _client.post(_endpoint, campaign.toJson(), Campaign.fromJson);

  Future<List<Campaign>> update(int id, CampaignInput campaign) =>
      _client.put(_endpoint, campaign.toJson(), Campaign.fromJson, filters: {'id': id});

  Future<PaginatedResponse<Campaign>> getByObjective(String objective, {QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, Campaign.fromJson,
          options: options.copyWith(filters: {'campaign_objective': 'eq.$objective'}));

  Future<PaginatedResponse<Campaign>> getByPeriod(String period, {QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, Campaign.fromJson, options: options.copyWith(filters: {'period': 'eq.$period'}));

  Future<PaginatedResponse<Campaign>> getEnabled({QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, Campaign.fromJson, options: options.copyWith(filters: {'enabled': 'eq.true'}));

  Future<PaginatedResponse<Campaign>> getDisabled({QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, Campaign.fromJson, options: options.copyWith(filters: {'enabled': 'eq.false'}));

  Future<PaginatedResponse<Campaign>> search(String name, {QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, Campaign.fromJson, options: options.copyWith(filters: {'name': 'ilike.*$name*'}));

  Future<PaginatedResponse<Campaign>> getTopPerforming({int limit = 10}) => _client.get(
        _endpoint,
        Campaign.fromJson,
        options: QueryOptions(
          limit: limit,
          orderBy: 'clicks',
          orderDir: OrderDirection.desc,
          filters: const {'enabled': 'eq.true'},
        ),
      );

  Future<PaginatedResponse<Campaign>> getHighCtr({double minCtr = 1.0, QueryOptions options = const QueryOptions()}) =>
      _client.get(_endpoint, Campaign.fromJson, options: options.copyWith(filters: {'ctr': 'gte.$minCtr'}));

  Future<int> count() => _client.count(_endpoint);

  Future<Map<String, int>> countByObjective() async {
    final counts = await Future.wait(
      CampaignObjective.values.map(
        (objective) => _client.count(_endpoint, filters: {'campaign_objective': 'eq.$objective'}),
      ),
    );
    return {
      for (var index = 0; index < CampaignObjective.values.length; index++)
        CampaignObjective.values[index]: counts[index],
    };
  }
}

// Main API Client
class SupabaseApi {
  factory SupabaseApi() => SupabaseApi._(SupabaseDioClient());

  SupabaseApi._(SupabaseDioClient client)
      : companies = CompaniesApi(client),
        users = UsersApi(client),
        campaigns = CampaignsApi(client);

  final CompaniesApi companies;
  final UsersApi users;
  final CampaignsApi campaigns;

  // Health check
  Future<bool> healthCheck() async {
    try {
      await companies.count();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Export singleton instance
final supabaseApi = SupabaseApi();

// Usage Examples:
/*

import 'package:flutter_assignment/utils/api_client.dart';

// Get campaigns with pagination
final campaigns = await supabaseApi.campaigns.getAll(
  options: const QueryOptions(page: 0, limit: 25, orderBy: 'impressions'),
);

// Filter campaigns (multi select)
final filtered = await supabaseApi.campaigns.getAll(
  campaignFilters: const CampaignFilterParams(period: [CampaignPeriod.daily, CampaignPeriod.weekly]),
);

// Filter keys & values
final filters = await supabaseApi.campaigns.getFilters();

// Create user (password is hashed with bcrypt before sending)
final created = await supabaseApi.users.create(
  const UserInput(email: 'user@wisebirds.ai', name: '홍길동', password: 'Abcd1234!'),
);

// Update campaign
final updated = await supabaseApi.campaigns.update(1, const CampaignInput(enabled: false));

*/
