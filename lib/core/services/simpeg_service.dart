import 'package:dio/dio.dart';
import '../models/simpeg_model.dart';
import 'attendance_service.dart';
import 'api_exception.dart';

class SimpegService {
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

  /// Helper untuk mengambil base URL API SIMPEG (mengupas /v1 jika ada)
  static Future<String> _getSimpegBaseUrl() async {
    final v1Url = await AttendanceService.getBaseUrl();
    if (v1Url.endsWith('/v1')) {
      return v1Url.substring(0, v1Url.length - 3);
    }
    return v1Url;
  }

  /// Helper untuk mengambil base URL v1 (untuk presensi/attendance)
  static Future<String> _getV1BaseUrl() async {
    return await AttendanceService.getBaseUrl();
  }

  // ==========================================
  // 1. MASTER JENIS CUTI & IZIN
  // ==========================================

  /// Ambil daftar master jenis cuti dari server RAG
  static Future<List<MasterJenisCutiModel>> fetchMasterJenisCuti() async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _getSimpegBaseUrl();

    try {
      final response = await _dio.get(
        '$baseUrl/simpeg/master-jenis-cuti',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final list = response.data['data'] as List?;
        if (list != null && list.isNotEmpty) {
          return list
              .map((e) => MasterJenisCutiModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      throw ApiException.from(e, 'Gagal memuat master jenis cuti dari server.');
    }

    throw const ApiException('Server tidak mengirimkan master jenis cuti.');
  }

  // ==========================================
  // 2. PENGAJUAN & RIWAYAT CUTI
  // ==========================================

  /// Ambil riwayat pengajuan cuti pegawai yang login
  static Future<List<PengajuanCutiModel>> fetchCutiList({
    String? status,
    int page = 1,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _getSimpegBaseUrl();

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': 25,
      };
      if (status != null && status.isNotEmpty && status != 'semua') {
        // UI memakai label Indonesia; database/API SIMPEG memakai nilai canonical.
        const statusMap = <String, String>{
          'menunggu': 'pending',
          'disetujui': 'approved',
          'ditolak': 'rejected',
        };
        queryParams['status_approval'] = statusMap[status] ?? status;
      }

      final response = await _dio.get(
        '$baseUrl/simpeg/cuti',
        queryParameters: queryParams,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final list = response.data['data'] as List?;
        if (list != null) {
          return list
              .map((e) => PengajuanCutiModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      throw ApiException.from(e, 'Gagal memuat riwayat cuti dari server.');
    }

    throw const ApiException('Server tidak mengirimkan riwayat cuti.');
  }

  /// Kirim pengajuan cuti baru ke server RAG
  static Future<Map<String, dynamic>> submitCuti({
    required int masterJenisCutiId,
    required String tanggalMulai,
    required String tanggalSelesai,
    required int jumlahHari,
    required String alasan,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _getSimpegBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/simpeg/cuti',
        data: {
          'master_jenis_cuti_id': masterJenisCutiId,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': tanggalSelesai,
          'jumlah_hari': jumlahHari,
          'alasan': alasan,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Pengajuan cuti berhasil dibuat',
          'data': response.data['data'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal membuat pengajuan cuti',
      };
    } on DioException catch (e) {
      String msg = 'Gagal mengirim pengajuan cuti';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  // ==========================================
  // 3. REKAP & LAPORAN KEHADIRAN (ATTENDANCE)
  // ==========================================

  /// Ambil data rekapitulasi kehadiran bulanan pegawai.
  /// Mengembalikan null bila server tidak mengirim data presensi riil.
  static Future<AttendanceRecapModel?> fetchAttendanceRecap({
    int? month,
    int? year,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _getV1BaseUrl();

    try {
      final now = DateTime.now();
      final targetMonth = month ?? now.month;
      final targetYear = year ?? now.year;

      final response = await _dio.get(
        '$baseUrl/attendance/recap',
        queryParameters: {
          'month': targetMonth,
          'year': targetYear,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final payload = response.data;
        final envelope = payload is Map
            ? (payload['data'] is Map
                ? Map<String, dynamic>.from(payload['data'] as Map)
                : Map<String, dynamic>.from(payload))
            : null;
        if (envelope == null || envelope.isEmpty) return null;

        // Jangan pernah menampilkan data contoh/demo sebagai presensi pegawai.
        if (envelope['is_demo'] == true ||
            envelope['dummy'] == true ||
            envelope['is_sample'] == true) {
          return null;
        }

        final hasSummary = envelope['summary'] is Map;
        final rawRows = envelope['rows'] as List?;
        if (!hasSummary && (rawRows == null || rawRows.isEmpty)) return null;

        final recap = AttendanceRecapModel.fromJson(envelope);
        return recap.hasAttendanceData ? recap : null;
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.from(e, 'Gagal memuat rekap kehadiran dari server.');
    }

    return null;
  }

  // ==========================================
  // 4. PENGUMUMAN KAMPUS (ANNOUNCEMENTS)
  // ==========================================

  /// Ambil feed pengumuman kampus.
  ///
  /// Daftar kosong adalah kondisi valid (belum ada pengumuman), bukan error.
  /// Respons API juga bisa berbentuk `data`, `announcements`, `items`, atau
  /// langsung berupa List tergantung versi backend yang dipakai.
  static Future<List<CampusAnnouncementItem>> fetchAnnouncements({
    String? category,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _getSimpegBaseUrl();

    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category != 'semua') {
        queryParams['category'] = category;
      }

      final response = await _dio.get(
        '$baseUrl/simpeg/announcements',
        queryParameters: queryParams,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final rawList = _extractList(response.data);
        if (rawList == null || rawList.isEmpty) {
          return const <CampusAnnouncementItem>[];
        }
        return rawList
            .whereType<Map>()
            .map((e) => CampusAnnouncementItem.fromJson(Map<String, dynamic>.from(e)))
            .where((item) => item.title.trim().isNotEmpty)
            .toList();
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.from(e, 'Gagal memuat pengumuman dari server.');
    }

    return const <CampusAnnouncementItem>[];
  }

  /// Cari daftar pengumuman dari berbagai bentuk envelope respons API.
  static List<dynamic>? _extractList(dynamic payload, [int depth = 0]) {
    if (depth > 4) return null;
    if (payload is List) return payload;
    if (payload is Map) {
      for (final key in const [
        'data',
        'announcements',
        'pengumuman',
        'items',
        'results',
        'list',
      ]) {
        if (!payload.containsKey(key)) continue;
        final found = _extractList(payload[key], depth + 1);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Broadcast pengumuman baru dari Admin SIMPEG
  static Future<Map<String, dynamic>> broadcastAnnouncement({
    required String title,
    required String category,
    required String targetRole,
    required String content,
    bool isAgenda = false,
    String? eventDate,
    String? eventTime,
    String? eventLocation,
    String priority = 'normal',
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await _getSimpegBaseUrl();

    try {
      final payload = <String, dynamic>{
        'title': title,
        'category': category,
        'target_role': targetRole,
        'content': content,
        'is_agenda': isAgenda,
        'priority': priority,
      };
      if (eventDate != null && eventDate.isNotEmpty) payload['event_date'] = eventDate;
      if (eventTime != null && eventTime.isNotEmpty) payload['event_time'] = eventTime;
      if (eventLocation != null && eventLocation.isNotEmpty) payload['event_location'] = eventLocation;

      final response = await _dio.post(
        '$baseUrl/simpeg/announcements/broadcast',
        data: payload,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Broadcast pengumuman berhasil dikirimkan.',
          'data': response.data['data'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal mengirimkan broadcast.',
      };
    } on DioException catch (e) {
      String msg = 'Gagal mengirim broadcast pengumuman';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }
}
