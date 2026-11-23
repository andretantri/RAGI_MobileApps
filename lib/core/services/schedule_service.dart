import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teaching_schedule_model.dart';
import 'attendance_service.dart';

class ScheduleService {
  static const String _prefScheduleKey = 'cached_teaching_schedule';
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  /// Ambil jadwal mengajar dosen (hari ini & satu semester)
  static Future<TeachingScheduleResult?> fetchTeachingSchedule({
    String? nidn,
    String? nip,
    String? hari,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    // Query parameters
    final queryParams = <String, dynamic>{};
    if (nidn != null && nidn.isNotEmpty) queryParams['nidn'] = nidn;
    if (nip != null && nip.isNotEmpty) queryParams['nip'] = nip;
    if (hari != null && hari.isNotEmpty) queryParams['hari'] = hari;

    final headers = <String, dynamic>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Hubungi API server produksi
    final url = '$baseUrl/mobile/staff/jadwal-mengajar';
    try {
      if (kDebugMode) debugPrint('[ScheduleService] Fetching schedule from: $url');
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          final result = TeachingScheduleResult.fromJson(data);
          // Simpan ke offline cache
          await _saveToCache(data);
          return result;
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[ScheduleService] DioException on $url: ${e.response?.statusCode}');
    } catch (e) {
      if (kDebugMode) debugPrint('[ScheduleService] General error on $url: $e');
    }

    // 2. Jika koneksi gagal, kembalikan data dari offline cache
    final cached = await getCachedSchedule();
    if (cached != null) {
      if (kDebugMode) debugPrint('[ScheduleService] Returning cached schedule');
      return cached;
    }

    return null;
  }

  /// Simpan ke cache lokal
  static Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefScheduleKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[ScheduleService] Error caching schedule: $e');
    }
  }

  /// Ambil jadwal dari cache lokal
  static Future<TeachingScheduleResult?> getCachedSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefScheduleKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return TeachingScheduleResult.fromJson(decoded);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ScheduleService] Error reading schedule cache: $e');
    }
    return null;
  }
}
