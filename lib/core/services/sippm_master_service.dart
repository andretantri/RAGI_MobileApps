import 'package:dio/dio.dart';
import '../models/sippm_lookup_model.dart';
import 'api_base_url.dart';
import 'api_exception.dart';
import 'attendance_service.dart';

/// Master skema & periode SIPPM untuk form proposal mobile.
///
/// Endpoint ini berada di prefix `/api` (tanpa `/v1`) sesuai
/// `MasterSippmController.md`, berbeda dengan gateway `/api/v1/mobile/staff`.
class SippmMasterService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  static Future<SippmLookups> fetchLookups() async {
    final baseUrl = await getApiBaseUrl();
    final token = await AttendanceService.getToken();
    final options = Options(
      headers: token != null && token.isNotEmpty
          ? {'Authorization': 'Bearer $token'}
          : null,
    );

    try {
      final responses = await Future.wait([
        _dio.get('$baseUrl/sippm/skema', options: options),
        _dio.get('$baseUrl/sippm/periode', options: options),
      ]);

      return SippmLookups(
        skema: _parse(responses[0].data),
        periode: _parse(responses[1].data),
      );
    } catch (e) {
      throw ApiException.from(
        e,
        'Gagal memuat skema dan periode hibah SIPPM.',
      );
    }
  }

  static List<SippmLookup> _parse(dynamic payload) {
    final list = payload is Map ? payload['data'] : payload;
    if (list is! List) return const <SippmLookup>[];
    return list
        .whereType<Map>()
        .map((e) => SippmLookup.fromJson(Map<String, dynamic>.from(e)))
        .where((item) => item.id > 0 && item.name.isNotEmpty)
        .toList();
  }
}
