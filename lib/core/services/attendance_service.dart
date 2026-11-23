import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/face_verification_info.dart';
import 'api_exception.dart';

class AttendanceResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final double? faceScore;
  final FaceVerificationInfo faceVerification;

  AttendanceResponse({
    required this.success,
    required this.message,
    this.data,
    this.faceScore,
    this.faceVerification = const FaceVerificationInfo(),
  });
}

class AttendanceRecord {
  final int id;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String status;
  final double? distanceMeters;
  final String? officeName;
  final String? rejectionReason;

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.status,
    this.distanceMeters,
    this.officeName,
    this.rejectionReason,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      date: json['attendance_date']?.toString() ?? json['date']?.toString() ?? '',
      clockIn: json['clock_in']?.toString(),
      clockOut: json['clock_out']?.toString(),
      status: json['status']?.toString() ?? 'hadir',
      distanceMeters: (json['clock_in_distance_meters'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble(),
      officeName: json['office'] is Map
          ? json['office']['name']?.toString()
          : json['office_name']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'attendance_date': date,
        'clock_in': clockIn,
        'clock_out': clockOut,
        'status': status,
        'clock_in_distance_meters': distanceMeters,
        'office_name': officeName,
        'rejection_reason': rejectionReason,
      };
}

class AttendanceService {
  static const String defaultProdBaseUrl = AppConfig.productionApiBaseUrl;
  static const String defaultLocalBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String _prefCustomUrlKey = 'custom_api_url';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: defaultProdBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  static const String _prefTodayKey = 'today_attendance_data';
  static const String _prefFaceSettingsKey = 'face_similarity_settings';
  static const String _prefTokenKey = 'auth_token';
  static const String _prefUserKey = 'user_data';
  static const String _prefEmployeeKey = 'employee_data';

  /// Server dapat membalas HTTP 200 dengan `success: false` atau
  /// `status: error`/`ditolak`. Jangan anggap itu presensi berhasil.
  static bool _isServerSuccess(Map<String, dynamic> json) {
    if (json['success'] == false) return false;
    final status = json['status']?.toString().trim().toLowerCase();
    return status != 'error' &&
        status != 'failed' &&
        status != 'fail' &&
        status != 'ditolak';
  }

  static String? _firstMessage(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static FaceVerificationInfo _faceInfoFromError(Object error) {
    if (error is DioException && error.response?.data is Map) {
      final raw = Map<String, dynamic>.from(error.response!.data as Map);
      final nested = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      final info = FaceVerificationInfo.fromJson({...raw, ...nested});
      if (info.hasData) return info;
    }
    return FaceVerificationInfo.fromMessage(
      ApiException.from(error, '').message,
    );
  }

  /// Simpan batas kemiripan wajah yang diterima dari server supaya tetap
  /// tersedia saat aplikasi dibuka tanpa koneksi.
  static Future<void> _cacheFaceSimilaritySettings(
    FaceSimilaritySettings? settings,
  ) async {
    if (settings == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefFaceSettingsKey, jsonEncode(settings.toJson()));
  }

  /// Ambil pengaturan presensi aktif dari endpoint khusus mobile.
  ///
  /// Endpoint baru belum tersedia di semua deploy; bila gagal, pemanggil
  /// tetap memakai nilai dari payload `/attendance/today` atau cache lokal.
  static Future<FaceSimilaritySettings?> getFaceSimilaritySettings() async {
    try {
      final token = await getToken();
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;
      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final response = await _dio.get('/attendance/settings', options: options);
      if (response.statusCode == 200 && response.data is Map) {
        final resData = response.data as Map<String, dynamic>;
        if (!_isServerSuccess(resData)) return null;

        final data = resData['data'] is Map
            ? Map<String, dynamic>.from(resData['data'] as Map)
            : resData;
        final settings = FaceSimilaritySettings.fromJson(data);
        await _cacheFaceSimilaritySettings(settings);
        return settings;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AttendanceService] getFaceSimilaritySettings error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefFaceSettingsKey);
    if (cached != null) {
      try {
        return FaceSimilaritySettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
      } catch (_) {}
    }
    return null;
  }

  // Secure storage for sensitive data (token, user/employee data)
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Dapatkan URL aktif.
  ///
  /// Build release selalu memakai API produksi RAG. Custom URL hanya dipakai
  /// saat debug; nilai lokal/HTTP lama dibersihkan otomatis.
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_prefCustomUrlKey);

    final isLocalOrLegacy = custom != null &&
        (custom.contains('127.0.0.1') ||
            custom.contains('localhost') ||
            custom.contains('10.0.2.2') ||
            custom.startsWith('http://'));

    if (!kDebugMode || custom == null || custom.isEmpty || isLocalOrLegacy) {
      if (custom != null) await prefs.remove(_prefCustomUrlKey);
      _dio.options.baseUrl = defaultProdBaseUrl;
      return defaultProdBaseUrl;
    }

    _dio.options.baseUrl = custom;
    return custom;
  }

  /// Ubah URL API Server
  static Future<String> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    var clean = url.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (!clean.endsWith('/api/v1')) {
      if (clean.endsWith('/api')) {
        clean = '$clean/v1';
      } else {
        clean = '$clean/api/v1';
      }
    }
    await prefs.setString(_prefCustomUrlKey, clean);
    _dio.options.baseUrl = clean;
    return clean;
  }

  /// Reset URL API ke default
  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefCustomUrlKey);
    _dio.options.baseUrl = defaultProdBaseUrl;
  }

  /// Ambil Token SSO (dari Encrypted Storage)
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _prefTokenKey);
  }

  /// Simpan Token (ke Encrypted Storage)
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _prefTokenKey, value: token);
  }

  /// Login Karyawan / Dosen (API Project Absen)
  /// Hanya pengguna yang terdaftar di backend yang dapat mengakses aplikasi
  static Future<AttendanceResponse<Map<String, dynamic>>> login({
    required String login,
    required String password,
  }) async {
    final baseUrl = await getBaseUrl();
    _dio.options.baseUrl = baseUrl;

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'login': login,
          'password': password,
          'device_name': 'myinu-staff-mobile',
        },
      );

      final resData = response.data;
      if (response.statusCode == 200 && resData is Map) {
        final data = resData['data'] is Map ? Map<String, dynamic>.from(resData['data'] as Map) : <String, dynamic>{};
        final token = data['token']?.toString() ??
            data['access_token']?.toString() ??
            resData['token']?.toString() ??
            resData['access_token']?.toString() ??
            '';
        final user = (data['user'] ?? resData['user']) as Map<String, dynamic>?;
        final employee = (data['employee'] ?? resData['employee']) as Map<String, dynamic>?;

        if (token.isNotEmpty && user != null && employee != null) {
          await saveToken(token);
          await _secureStorage.write(key: _prefUserKey, value: jsonEncode(user));
          await _secureStorage.write(key: _prefEmployeeKey, value: jsonEncode(employee));

          final completeData = {
            'token': token,
            'user': user,
            'employee': employee,
          };
          return AttendanceResponse(
            success: true,
            message: resData['message']?.toString() ?? 'Login berhasil',
            data: completeData,
          );
        }
      }

      return AttendanceResponse(
        success: false,
        message: resData is Map && resData['message'] != null
            ? resData['message'].toString()
            : 'Login gagal. Kredensial tidak valid.',
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] login DioException: ${e.response?.statusCode}');
      if (e.response != null && e.response?.data != null) {
        final body = e.response!.data;
        String msg = 'Kredensial login tidak cocok dengan data kami.';
        if (body is Map) {
          if (body['message'] != null && body['message'].toString().trim().isNotEmpty) {
            msg = body['message'].toString();
          } else if (body['errors'] is Map) {
            final errs = body['errors'] as Map;
            final firstVal = errs.values.firstOrNull;
            if (firstVal is List && firstVal.isNotEmpty) {
              msg = firstVal.first.toString();
            } else if (firstVal != null) {
              msg = firstVal.toString();
            }
          }
        }
        return AttendanceResponse(
          success: false,
          message: msg,
        );
      }
      return AttendanceResponse(
        success: false,
        message: 'Koneksi ke server gagal ($baseUrl). Pastikan backend aktif atau cek pengaturan URL.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] login error: $e');
      return AttendanceResponse(
        success: false,
        message: 'Terjadi kesalahan sistem: $e',
      );
    }
  }

  /// Ambil Profil Karyawan (GET /auth/profile)
  static Future<AttendanceResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;
      final token = await getToken();
      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );
      final response = await _dio.get('/auth/profile', options: options);
      if (response.statusCode == 200 && response.data is Map) {
        final resData = response.data as Map<String, dynamic>;
        final data = resData['data'] is Map ? Map<String, dynamic>.from(resData['data'] as Map) : null;
        return AttendanceResponse(
          success: true,
          message: 'Berhasil memuat profil',
          data: data,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return AttendanceResponse(
          success: false,
          message: 'UNAUTHORIZED_401',
        );
      }
      if (kDebugMode) debugPrint('[AttendanceService] getProfile DioException: ${e.response?.statusCode}');
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] getProfile error: $e');
    }
    return AttendanceResponse(
      success: false,
      message: 'Gagal memuat profil karyawan',
    );
  }

  /// Update & sinkronisasi foto profil ke endpoint RAG.
  /// Hanya `avatar_base64` (atau `remove_avatar`) yang didukung server.
  static Future<AttendanceResponse<Map<String, dynamic>>> updateProfileAvatar({
    String? avatarBase64,
    bool removeAvatar = false,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;
      final token = await getToken();
      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final payload = <String, dynamic>{};
      if (removeAvatar) {
        payload['remove_avatar'] = true;
      } else if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        payload['avatar_base64'] = avatarBase64;
      } else {
        return AttendanceResponse(
          success: false,
          message: 'Foto profil belum dipilih.',
        );
      }

      final res = await _dio.post(
        '$baseUrl/mobile/staff/avatar',
        data: payload,
        options: options,
      );

      final resData = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      final apiSuccess = (res.statusCode == 200 || res.statusCode == 201) &&
          (resData['success'] == true || resData['status'] == 'success');

      return AttendanceResponse(
        success: apiSuccess,
        message: apiSuccess
            ? (resData['message']?.toString() ?? 'Foto profil berhasil disimpan di server RAG.')
            : (resData['message']?.toString() ?? 'Server gagal menyimpan foto profil.'),
        data: resData,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] updateProfileAvatar error: $e');
      return AttendanceResponse(
        success: false,
        message: ApiException.from(e, 'Gagal menyinkronkan foto profil ke server.').message,
      );
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;
      final token = await getToken();
      if (token != null) {
        await _dio.post('/auth/logout',
            options: Options(headers: {'Authorization': 'Bearer $token'}));
      }
    } catch (_) {}
    // Hapus data sensitif dari secure storage
    await _secureStorage.delete(key: _prefTokenKey);
    await _secureStorage.delete(key: _prefUserKey);
    await _secureStorage.delete(key: _prefEmployeeKey);
    // Hapus juga dari SharedPreferences untuk membersihkan sisa sesi lama (migrasi)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
    await prefs.remove(_prefUserKey);
    await prefs.remove(_prefEmployeeKey);
    await prefs.remove(_prefTodayKey);
    await prefs.remove('cached_teaching_schedule');
  }

  /// Catat persetujuan eksplisit UU PDP sebelum biometrik wajah didaftarkan.
  static Future<AttendanceResponse<Map<String, dynamic>>> recordConsent() async {
    try {
      final token = await getToken();
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;

      final response = await _dio.post(
        '/auth/consent',
        data: {'consent': true},
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final resData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final ok = response.statusCode == 200 &&
          (resData['success'] == true || resData['status'] == 'success');

      return AttendanceResponse(
        success: ok,
        message: resData['message']?.toString() ??
            (ok ? 'Persetujuan biometrik tercatat.' : 'Server gagal mencatat persetujuan.'),
        data: resData,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] recordConsent error: $e');
      return AttendanceResponse(
        success: false,
        message: ApiException.from(e, 'Gagal mencatat persetujuan biometrik ke server.').message,
      );
    }
  }

  /// Pendaftaran / Retake Biometrik Wajah (Mendukung 3 Sampel Pose Multi-Shot)
  static Future<AttendanceResponse<Map<String, dynamic>>> enrollFace({
    String? photoBase64,
    List<String>? photosBase64,
  }) async {
    final photos = photosBase64 ??
        (photoBase64 != null ? [photoBase64] : <String>[]);
    if (photos.isEmpty || photos.any((p) => p.trim().isEmpty)) {
      return AttendanceResponse<Map<String, dynamic>>(
        success: false,
        message: 'Foto wajah belum tersedia. Ambil foto terlebih dahulu.',
      );
    }
    try {
      final token = await getToken();
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;

      final response = await _dio.post(
        '/auth/enroll-face',
        data: {
          'photos': photos,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final resData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      return AttendanceResponse(
        success: response.statusCode == 200 &&
            (resData['success'] == true || resData['status'] == 'success'),
        message: resData['message']?.toString() ??
            'Pendaftaran wajah berhasil disimpan.',
        data: resData,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] enrollFace error: $e');
      return AttendanceResponse(
        success: false,
        message: ApiException.from(e, 'Gagal mendaftarkan wajah ke server.').message,
      );
    }
  }

  /// Reset Data Biometrik Wajah
  static Future<AttendanceResponse<void>> resetFace() async {
    try {
      final token = await getToken();
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;

      await _dio.post(
        '/auth/reset-face',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      return AttendanceResponse(
        success: true,
        message: 'Data biometrik wajah berhasil direset.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] resetFace error: $e');
      return AttendanceResponse(
        success: false,
        message: ApiException.from(e, 'Gagal mereset data biometrik wajah di server.').message,
      );
    }
  }

  /// Ambil status presensi hari ini dari API.
  /// Cache lokal hanya dipakai jika sebelumnya berasal dari API.
  static Future<AttendanceResponse<Map<String, dynamic>>> getTodayStatus() async {
    Object? apiError;

    try {
      final token = await getToken();
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;
      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final response = await _dio.get('/attendance/today', options: options);
      if (response.statusCode == 200 && response.data is Map) {
        final resData = response.data as Map<String, dynamic>;
        final data = resData['data'] is Map ? resData['data'] as Map<String, dynamic> : resData;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefTodayKey, jsonEncode(data));

        // Endpoint /attendance/settings lebih baru; bila belum tersedia,
        // batas minimal tetap diambil dari payload today / rejection_reason.
        FaceSimilaritySettings? settings;
        try {
          settings = FaceSimilaritySettings.fromJson(data);
          await _cacheFaceSimilaritySettings(settings);
        } catch (_) {}

        final faceInfo = FaceVerificationInfo.fromJson(
          data['attendance'] is Map
              ? Map<String, dynamic>.from(data['attendance'] as Map)
              : data,
        );
        final mergedInfo = FaceVerificationInfo(
          score: faceInfo.score,
          minimum: faceInfo.minimum ?? settings?.minimum,
          message: faceInfo.message,
          source: settings?.source,
          updatedAt: settings?.updatedAt,
        );

        return AttendanceResponse(
          success: true,
          message: resData['message']?.toString() ?? 'Status presensi dimuat',
          data: data,
          faceVerification: mergedInfo,
          faceScore: mergedInfo.score,
        );
      }
      apiError = ApiException('Server mengembalikan respons yang tidak valid');
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] getTodayStatus error: $e');
      apiError = e;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefTodayKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        return AttendanceResponse(
          success: true,
          message: 'Dimuat dari data server yang tersimpan (offline)',
          data: decoded,
        );
      } catch (_) {}
    }

    return AttendanceResponse(
      success: false,
      message: ApiException.from(apiError, 'Gagal memuat status presensi dari server.').message,
    );
  }

  /// Clock In (Presensi Masuk)
  static Future<AttendanceResponse<Map<String, dynamic>>> clockIn({
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool isMockLocation,
    String? faceImage,
    String? qrCode,
  }) async {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    if (faceImage == null || faceImage.trim().isEmpty) {
      return AttendanceResponse(
        success: false,
        message: 'Foto wajah wajib diambil untuk verifikasi biometrik presensi masuk.',
      );
    }

    try {
      final token = await getToken();
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;
      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      // Skor kemiripan TIDAK dikirim oleh klien. Backend yang menentukan
      // hasil verifikasi melalui microservice Python.
      final payload = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'is_mock_location': isMockLocation,
        'timestamp': now.toIso8601String(),
        'face_image': faceImage,
        'qr_code': ?qrCode,
      };

      final response = await _dio.post('/attendance/clock-in',
          data: payload, options: options);

      if (response.statusCode == 200 && response.data is Map) {
        final resData = Map<String, dynamic>.from(response.data as Map);
        final attData = resData['data'] is Map
            ? Map<String, dynamic>.from(resData['data'] as Map)
            : resData;
        final faceInfo = FaceVerificationInfo.fromJson({...resData, ...attData});

        final serverSuccess = _isServerSuccess(resData) &&
            _isServerSuccess(attData);
        final rejection = _firstMessage([
          serverSuccess ? null : resData['message'],
          attData['rejection_reason'],
          attData['notes'],
          faceInfo.message,
        ]);
        final hasClockIn = attData['clock_in']?.toString().trim().isNotEmpty == true;

        if (!serverSuccess || (!hasClockIn && rejection != null)) {
          return AttendanceResponse(
            success: false,
            message: rejection ?? 'Server menolak presensi masuk. Silakan coba lagi.',
            data: attData,
            faceVerification: faceInfo,
            faceScore: faceInfo.score,
          );
        }

        // Update cache lokal hanya setelah server mengonfirmasi kehadiran.
        await _updateLocalAttendance(clockIn: timeStr, status: 'hadir');

        return AttendanceResponse(
          success: true,
          message: _firstMessage([
                resData['message'],
                'Presensi masuk berhasil dicatat!',
              ])!,
          data: attData,
          faceVerification: faceInfo,
          faceScore: faceInfo.score,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] clockIn error: $e');
      return AttendanceResponse(
        success: false,
        message: ApiException.from(e, 'Gagal mencatat presensi masuk ke server.').message,
        faceVerification: _faceInfoFromError(e),
      );
    }

    return AttendanceResponse(
      success: false,
      message: 'Server tidak mengonfirmasi presensi masuk. Silakan coba lagi.',
    );
  }

  /// Clock Out (Presensi Pulang)
  static Future<AttendanceResponse<Map<String, dynamic>>> clockOut({
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool isMockLocation,
    String? faceImage,
  }) async {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    if (faceImage == null || faceImage.trim().isEmpty) {
      return AttendanceResponse(
        success: false,
        message: 'Foto wajah wajib diambil untuk verifikasi biometrik presensi pulang.',
      );
    }

    try {
      final token = await getToken();
      final baseUrl = await getBaseUrl();
      _dio.options.baseUrl = baseUrl;
      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      final payload = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'is_mock_location': isMockLocation,
        'timestamp': now.toIso8601String(),
        'face_image': faceImage,
      };

      final response = await _dio.post('/attendance/clock-out',
          data: payload, options: options);

      if (response.statusCode == 200 && response.data is Map) {
        final resData = Map<String, dynamic>.from(response.data as Map);
        final attData = resData['data'] is Map
            ? Map<String, dynamic>.from(resData['data'] as Map)
            : resData;
        final faceInfo = FaceVerificationInfo.fromJson({...resData, ...attData});

        final serverSuccess = _isServerSuccess(resData) &&
            _isServerSuccess(attData);
        final rejection = _firstMessage([
          serverSuccess ? null : resData['message'],
          attData['rejection_reason'],
          attData['notes'],
          faceInfo.message,
        ]);
        final hasClockOut =
            attData['clock_out']?.toString().trim().isNotEmpty == true;

        if (!serverSuccess || (!hasClockOut && rejection != null)) {
          return AttendanceResponse(
            success: false,
            message: rejection ?? 'Server menolak presensi pulang. Silakan coba lagi.',
            data: attData,
            faceVerification: faceInfo,
            faceScore: faceInfo.score,
          );
        }

        await _updateLocalAttendance(clockOut: timeStr);

        return AttendanceResponse(
          success: true,
          message: _firstMessage([
                resData['message'],
                'Presensi pulang berhasil dicatat.',
              ])!,
          data: attData,
          faceVerification: faceInfo,
          faceScore: faceInfo.score,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AttendanceService] clockOut error: $e');
      return AttendanceResponse(
        success: false,
        message: ApiException.from(e, 'Gagal mencatat presensi pulang ke server.').message,
        faceVerification: _faceInfoFromError(e),
      );
    }

    return AttendanceResponse(
      success: false,
      message: 'Server tidak mengonfirmasi presensi pulang. Silakan coba lagi.',
    );
  }

  /// Helper untuk menyimpan state presensi hari ini secara persisten
  static Future<void> _updateLocalAttendance({
    String? clockIn,
    String? clockOut,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefTodayKey);
    Map<String, dynamic> data = {};
    if (cached != null) {
      try {
        data = jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }

    final att = (data['attendance'] is Map)
        ? Map<String, dynamic>.from(data['attendance'] as Map)
        : <String, dynamic>{};

    if (clockIn != null) att['clock_in'] = clockIn;
    if (clockOut != null) att['clock_out'] = clockOut;
    if (status != null) att['status'] = status;

    data['attendance'] = att;
    if (clockIn != null) data['is_clocked_in'] = true;
    if (clockOut != null) data['is_clocked_out'] = true;

    await prefs.setString(_prefTodayKey, jsonEncode(data));
  }
}
