import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/rag_module.dart';
import 'api_base_url.dart';
import 'api_exception.dart';
import 'attendance_service.dart';

/// Mengambil daftar modul RAG milik akun yang login.
///
/// Endpoint ini dipakai web RAG untuk App Launcher, sehingga katalog mobile
/// menampilkan modul yang sama (termasuk hasil RBAC server).
class RagModuleService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  static Future<List<RagModule>> fetchMyModules({String? tokenOverride}) async {
    final baseUrl = await getApiBaseUrl();
    final storedToken = await AttendanceService.getToken();
    final token = (tokenOverride != null && tokenOverride.isNotEmpty)
        ? tokenOverride
        : storedToken;
    final options = Options(
      headers: token != null && token.isNotEmpty
          ? {'Authorization': 'Bearer $token'}
          : null,
    );

    try {
      final response = await _dio.get(
        '$baseUrl/modules/my-modules',
        options: options,
      );

      final payload = response.data;
      final list = payload is Map ? payload['data'] : payload;
      if (list is! List) return const <RagModule>[];

      final modules = list
          .whereType<Map>()
          .map((e) => RagModule.fromJson(Map<String, dynamic>.from(e)))
          .where((module) => module.isActive && module.code.isNotEmpty)
          .toList();

      debugPrint(
        '[RagModuleService] my-modules (${response.statusCode}): '
        '${modules.map((m) => m.code).join(', ')}',
      );
      return modules;
    } catch (e) {
      throw ApiException.from(e, 'Gagal memuat daftar modul RAG.');
    }
  }
}
