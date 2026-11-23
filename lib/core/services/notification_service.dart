import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/notification_provider.dart';
import 'api_exception.dart';
import 'attendance_service.dart';

class NotificationService {
  static const String _prefKey = 'cached_notifications_list';

  /// Endpoint notifikasi terdaftar di grup `/api` (bukan `/api/v1`).
  /// Base URL aplikasi adalah `/api/v1`, jadi segmen `/v1` dilepas di sini.
  static Future<String> _apiBaseUrl() async {
    final base = await AttendanceService.getBaseUrl();
    return base.endsWith('/v1') ? base.substring(0, base.length - 3) : base;
  }
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

  /// Hasil fetch notifikasi: data dari API/cache + status error bila API gagal.
  static Future<({List<NotificationItem> items, String? error})> fetchNotifications() async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _apiBaseUrl();

    final headers = <String, dynamic>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _dio.get(
        '$baseUrl/notifications',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        final List rawList;
        if (resData is Map && resData['data'] is List) {
          rawList = resData['data'] as List;
        } else if (resData is List) {
          rawList = resData;
        } else {
          rawList = [];
        }

        final items = rawList
            .map((json) => NotificationItem.fromApi(json as Map<String, dynamic>))
            .toList();

        await _saveToCache(items);
        return (items: items, error: null);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] Gagal fetch notifikasi: $e');
      final cached = await getCachedNotifications();
      return (
        items: cached,
        error: ApiException.from(e, 'Gagal memuat notifikasi dari server.').message,
      );
    }

    final cached = await getCachedNotifications();
    return (
      items: cached,
      error: 'Server tidak mengirimkan daftar notifikasi.',
    );
  }

  /// Tandai notifikasi telah dibaca di server
  static Future<bool> markAsRead(String id) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _apiBaseUrl();

    final headers = <String, dynamic>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _dio.post(
        '$baseUrl/notifications/$id/read',
        options: Options(headers: headers),
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] markAsRead error: $e');
      return false;
    }
  }

  /// Tandai semua notifikasi telah dibaca di server
  static Future<bool> markAllAsRead() async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _apiBaseUrl();

    final headers = <String, dynamic>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _dio.post(
        '$baseUrl/notifications/read-all',
        options: Options(headers: headers),
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] markAllAsRead error: $e');
      return false;
    }
  }

  /// Simpan daftar notifikasi ke cache SharedPreferences
  static Future<void> _saveToCache(List<NotificationItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
      await prefs.setString(_prefKey, encoded);
    } catch (_) {}
  }

  /// Ambil riwayat notifikasi dari cache lokal
  static Future<List<NotificationItem>> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefKey);
      if (str != null && str.isNotEmpty) {
        final List decoded = jsonDecode(str) as List;
        return decoded
            .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Tambah notifikasi lokal (misal setelah presensi masuk/pulang sukses)
  static Future<void> addLocalNotification(NotificationItem item) async {
    final list = await getCachedNotifications();
    list.insert(0, item);
    await _saveToCache(list);
  }
}
