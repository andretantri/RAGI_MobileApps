import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/mobile_feature_config.dart';
import '../models/mobile_feature_model.dart';
import '../models/mobile_feature_submission.dart';
import 'api_exception.dart';
import 'attendance_service.dart';

/// Service generik untuk fitur mobile hasil kurasi modul RAG.
///
/// Endpoint disimpan di [MobileFeature] agar mudah diganti tanpa menyentuh UI.
class MobileFeatureService {
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

  static const _listKeys = [
    'data',
    'items',
    'rows',
    'payrolls',
    'pengajuan',
    'proposals',
    'dokumen',
    'documents',
    'materi',
    'pengumuman',
    'referral',
    'tiket',
    'results',
  ];

  static Future<List<MobileFeatureItem>> fetchItems(
    MobileFeature feature,
  ) async {
    if (!feature.hasEndpoint) return const <MobileFeatureItem>[];

    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.get(
        '$baseUrl${feature.endpoint}',
        queryParameters: const {'per_page': 15},
        options: Options(
          headers: token != null && token.isNotEmpty
              ? {'Authorization': 'Bearer $token'}
              : null,
        ),
      );

      if (response.statusCode != 200) {
        return const <MobileFeatureItem>[];
      }

      final payload = response.data;
      final list = _extractList(payload);
      if (list == null) return const <MobileFeatureItem>[];

      return list
          .whereType<Map>()
          .map((e) => MobileFeatureItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw _featureException(e, feature, 'Gagal memuat');
    }
  }

  /// Kirim aksi tulis (proposal, pengajuan, tiket, referral) ke backend.
  ///
  /// Bila [file] diberikan, body dikirim sebagai `multipart/form-data`.
  static Future<MobileFeatureItem?> submit(
    MobileFeature feature,
    MobileFeatureSubmission submission, {
    XFile? file,
  }) async {
    if (!feature.isSubmittable) return null;

    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final payload = submission.toJson();
    dynamic body = payload;
    Options options = Options(headers: headers);

    if (file != null && submission.supportsFile) {
      final formData = FormData.fromMap(payload);
      formData.files.add(
        MapEntry(
          submission.fileKey,
          await MultipartFile.fromFile(
            file.path,
            filename: file.name,
          ),
        ),
      );
      body = formData;
      options = Options(
        headers: headers,
        contentType: 'multipart/form-data',
      );
    }

    try {
      final response = await _dio.post(
        '$baseUrl${feature.submitEndpoint}',
        data: body,
        options: options,
      );

      final data = _extractData(response.data);
      return data == null ? null : MobileFeatureItem.fromJson(data);
    } catch (e) {
      throw _featureException(e, feature, 'Gagal mengirim');
    }
  }

  /// Ubah 404 route Laravel menjadi pesan yang bisa dipahami pengguna.
  static ApiException _featureException(
    Object error,
    MobileFeature feature,
    String action,
  ) {
    if (error is DioException && error.response?.statusCode == 404) {
      return ApiException(
        'Fitur "${feature.title}" belum tersedia di server. '
        'Endpoint mobile untuk fitur ini belum diaktifkan.',
        cause: error,
      );
    }
    return ApiException.from(error, '$action ${feature.title}.');
  }

  static Map<String, dynamic>? _extractData(dynamic payload) {
    if (payload is! Map) return null;
    final data = payload['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return null;
  }

  static List<dynamic>? _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is! Map) return null;

    for (final key in _listKeys) {
      final value = payload[key];
      if (value is List) return value;
      if (value is Map && value['data'] is List) return value['data'] as List;
    }
    return null;
  }
}
