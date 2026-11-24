import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/grading_model.dart';
import '../models/advisee_model.dart';
import '../models/pertemuan_model.dart';
import 'attendance_service.dart';
import 'api_exception.dart';

class AcademicService {
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

  // ==========================================
  // FITUR 3: INPUT NILAI MAHASISWA (OBE / KHS)
  // ==========================================

  /// Ambil daftar kelas yang diampu dosen untuk input nilai
  static Future<List<GradingClassItem>> fetchGradingClasses() async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/nilai/kelas',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final list = response.data['data'] as List?;
        if (list != null) {
          return list
              .map((e) => GradingClassItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] fetchGradingClasses error: $e');
    }

    return const [];
  }

  /// Ambil detail kelas dan daftar nilai mahasiswa
  static Future<GradingClassDetail?> fetchClassGradeDetail(int kelasId) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/nilai/kelas/$kelasId',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return GradingClassDetail.fromJson(data);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] fetchClassGradeDetail error: $e');
    }

    return null;
  }

  /// Simpan nilai mahasiswa (draft atau final)
  static Future<bool> saveClassGrades({
    required int kelasId,
    required List<StudentGradeItem> grades,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final payload = {
        'grades': grades.map((g) => g.toJson()).toList(),
      };

      final response = await _dio.post(
        '$baseUrl/mobile/staff/nilai/kelas/$kelasId',
        data: payload,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] saveClassGrades error: $e');
      return false;
    }
  }

  // ==========================================
  // FITUR 4: BIMBINGAN AKADEMIK (DPA) & KRS
  // ==========================================

  /// Ambil daftar mahasiswa bimbingan PA
  static Future<List<AdviseeStudent>> fetchAdvisees() async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/bimbingan-pa/mahasiswa',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final list = response.data['data'] as List?;
        if (list != null) {
          return list
              .map((e) => AdviseeStudent.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] fetchAdvisees error: $e');
    }

    return const [];
  }

  /// Ambil rincian KRS mahasiswa bimbingan
  static Future<KrsApprovalDetail?> fetchKrsDetail(int krsId) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/bimbingan-pa/krs/$krsId',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return KrsApprovalDetail.fromJson(data);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] fetchKrsDetail error: $e');
    }

    return null;
  }

  /// Setujui KRS Mahasiswa
  static Future<bool> approveKrs(int krsId) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/bimbingan-pa/krs/$krsId/approve',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] approveKrs error: $e');
      return false;
    }
  }

  /// Tolak / Minta revisi KRS Mahasiswa dengan catatan
  static Future<bool> rejectKrs(int krsId, String alasan) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/bimbingan-pa/krs/$krsId/reject',
        data: {'alasan': alasan},
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] rejectKrs error: $e');
      return false;
    }
  }

  /// Ambil catatan konsultasi bimbingan akademik mahasiswa
  static Future<List<PaConsultationNote>> fetchConsultationNotes(int mahasiswaId) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/bimbingan-pa/catatan/$mahasiswaId',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final list = response.data['data'] as List?;
        if (list != null) {
          return list
              .map((e) => PaConsultationNote.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] fetchConsultationNotes error: $e');
    }

    return const [];
  }

  /// Tambah catatan konsultasi bimbingan akademik baru
  static Future<PaConsultationNote?> addConsultationNote({
    required int mahasiswaId,
    required String isi,
    String kategori = 'Akademik',
    String? kesimpulan,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/bimbingan-pa/catatan/$mahasiswaId',
        data: {
          'isi': isi,
          'kategori': kategori,
          'kesimpulan': kesimpulan,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return PaConsultationNote.fromJson(data);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] addConsultationNote error: $e');
    }

    return null;
  }

  // ================================================================
  // FITUR 5: JURNAL PERTEMUAN (BAP) & PRESENSI KELAS PERKULIAHAN
  // ================================================================

  /// Ambil daftar kelas perkuliahan beserta progres pertemuan (16 pertemuan)
  static Future<List<KelasPertemuanItem>> fetchKelasPertemuan() async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sesi login berakhir. Silakan login kembali.');
    }

    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/perkuliahan/kelas',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final list = response.data['data'] as List?;
        if (list != null) {
          return list
              .map((e) => KelasPertemuanItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      throw ApiException.from(e, 'Gagal memuat daftar kelas perkuliahan dari server.');
    }

    throw const ApiException('Server tidak mengirimkan daftar kelas perkuliahan.');
  }

  /// Ambil rincian kelas & seluruh daftar pertemuan 1 s/d 16
  static Future<Map<String, dynamic>> fetchPertemuanList(int kelasId) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sesi login berakhir. Silakan login kembali.');
    }

    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/perkuliahan/kelas/$kelasId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          final kelasData = data['kelas'] as Map<String, dynamic>?;
          final pertemuanListRaw = data['pertemuan'] as List?;

          final pertemuanList = (pertemuanListRaw ?? [])
              .map((e) => PertemuanItem.fromJson(e as Map<String, dynamic>))
              .toList();

          return {
            'kelas': kelasData != null ? KelasPertemuanItem.fromJson(kelasData) : null,
            'pertemuan': pertemuanList,
          };
        }
      }
    } catch (e) {
      throw ApiException.from(e, 'Gagal memuat jurnal pertemuan dari server.');
    }

    throw const ApiException('Server tidak mengirimkan data pertemuan kelas.');
  }

  /// Mulai sesi perkuliahan & buka presensi kelas mahasiswa
  static Future<Map<String, dynamic>> mulaiSesiPertemuan({
    required int kelasId,
    required int pertemuanKe,
    required String materi,
    String? catatan,
    String? tanggal,
    String? jamMulai,
    String? modePresensi,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/perkuliahan/kelas/$kelasId/mulai',
        data: {
          'pertemuan_ke': pertemuanKe,
          'materi': materi,
          'catatan': catatan,
          'tanggal': tanggal,
          'jam_mulai': jamMulai,
          // Default online agar kelas Zoom/daring tidak dipaksa geofence.
          'mode_presensi': modePresensi ?? 'online',
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) return data;
      }
    } catch (e) {
      throw ApiException.from(e, 'Gagal memulai sesi perkuliahan di server.');
    }

    throw const ApiException('Server tidak mengirimkan detail sesi perkuliahan.');
  }

  /// Putar ulang token absensi dinamis (token selalu berasal dari server RAG)
  static Future<Map<String, dynamic>> rotateTokenPertemuan(int pertemuanId) async {
    final token = await AttendanceService.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sesi login berakhir. Silakan login kembali.');
    }
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/perkuliahan/pertemuan/$pertemuanId/rotate-token',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) return data;
      }
    } catch (e) {
      throw ApiException.from(e, 'Gagal memperbarui token absensi dari server.');
    }

    throw const ApiException('Server tidak mengirimkan token absensi baru.');
  }

  /// Tutup sesi perkuliahan dan kunci presensi kelas
  static Future<Map<String, dynamic>> selesaiSesiPertemuan(int pertemuanId) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/perkuliahan/pertemuan/$pertemuanId/selesai',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) return data;
      }
    } catch (e) {
      throw ApiException.from(e, 'Gagal menutup sesi perkuliahan di server.');
    }

    throw const ApiException('Server tidak mengonfirmasi penutupan sesi perkuliahan.');
  }

  /// Ambil presensi mahasiswa pada suatu sesi perkuliahan
  static Future<Map<String, dynamic>> fetchPresensiPertemuan(int pertemuanId) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sesi login berakhir. Silakan login kembali.');
    }

    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/perkuliahan/pertemuan/$pertemuanId/presensi',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          final pertemuanData = data['pertemuan'] as Map<String, dynamic>?;
          final rekapData = data['rekap'] as Map<String, dynamic>?;
          final mhsListRaw = data['mahasiswa'] as List?;

          final mhsList = (mhsListRaw ?? [])
              .map((e) => PresensiMahasiswaItem.fromJson(e as Map<String, dynamic>))
              .toList();

          return {
            'pertemuan': pertemuanData != null ? PertemuanItem.fromJson(pertemuanData) : null,
            'rekap': rekapData ?? {},
            'mahasiswa': mhsList,
          };
        }
      }
    } catch (e) {
      throw ApiException.from(e, 'Gagal memuat presensi perkuliahan dari server.');
    }

    throw const ApiException('Server tidak mengirimkan data presensi perkuliahan.');
  }

  /// Update / override status presensi mahasiswa oleh dosen
  static Future<bool> updatePresensiMahasiswa({
    required int pertemuanId,
    required List<PresensiMahasiswaItem> items,
  }) async {
    final token = await AttendanceService.getToken();
    final baseUrl = await AttendanceService.getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/perkuliahan/pertemuan/$pertemuanId/presensi',
        data: {
          'items': items.map((e) => e.toJson()).toList(),
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicService] updatePresensiMahasiswa error: $e');
      return false;
    }
  }

  /// Tandai semua mahasiswa dalam kelas dengan status tertentu (misal: 'hadir')
  static Future<bool> setAllStudentsStatus({
    required int pertemuanId,
    required List<PresensiMahasiswaItem> students,
    required String status,
  }) async {
    final updatedList = students.map((s) {
      return PresensiMahasiswaItem(
        mahasiswaId: s.mahasiswaId,
        nama: s.nama,
        nim: s.nim,
        status: status,
      );
    }).toList();

    return await updatePresensiMahasiswa(
      pertemuanId: pertemuanId,
      items: updatedList,
    );
  }
}
