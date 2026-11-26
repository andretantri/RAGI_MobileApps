import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/mobile_feature_model.dart';
import '../models/mobile_staff_models.dart';
import 'api_base_url.dart';
import 'api_exception.dart';
import 'attendance_service.dart';

/// Hasil unduh biner (slip PDF). Nama file sudah sesuai `Content-Disposition`.
class MobileStaffDownloadResult {
  final Uint8List bytes;
  final String fileName;

  const MobileStaffDownloadResult({
    required this.bytes,
    required this.fileName,
  });
}

/// Service dedicated untuk endpoint baru `/api/v1/mobile/staff/...`.
///
/// Endpoint master SIMPEG tetap memakai prefix `/api` (tanpa `/v1`) sesuai
/// jalur lama yang sudah dipakai aplikasi. Semua ID master diambil dari sana.
class MobileStaffService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  static const _masterEndpoints = <String, String>{
    'jenis_cuti': '/simpeg/master-jenis-cuti',
    'jenis_izin': '/simpeg/master/jenis-izin-jam-kerja',
    'kategori_kegiatan': '/simpeg/master/kategori-kegiatan-tugas',
    'jenis_transportasi': '/simpeg/master/jenis-transportasi',
    'kategori_sk': '/simpeg/master/kategori-sk',
  };

  static Future<Options> _options({String? accept, bool bytes = false}) async {
    final token = await AttendanceService.getToken();
    return Options(
      headers: <String, dynamic>{
        'Accept': accept ?? 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      responseType: bytes ? ResponseType.bytes : null,
    );
  }

  /// GET daftar dengan envelope `{data, meta}`.
  static Future<MobileStaffPage> fetchList(
    String endpoint, {
    Map<String, dynamic>? query,
  }) async {
    final baseUrl = await AttendanceService.getBaseUrl();
    try {
      final response = await _dio.get(
        '$baseUrl$endpoint',
        queryParameters: query,
        options: await _options(),
      );
      return MobileStaffPage.fromJson(response.data);
    } catch (e) {
      throw _exception(e, 'Gagal memuat data.');
    }
  }

  /// GET satu item detail (e-file). Endpoint sudah termasuk ID.
  static Future<MobileFeatureItem> fetchDetail(String endpoint) async {
    final baseUrl = await AttendanceService.getBaseUrl();
    try {
      final response = await _dio.get(
        '$baseUrl$endpoint',
        options: await _options(),
      );
      final data = _extractMap(response.data);
      if (data == null) {
        throw const ApiException('Server tidak mengirimkan data detail.');
      }
      return MobileFeatureItem.fromJson(data);
    } catch (e) {
      throw _exception(e, 'Gagal memuat detail.');
    }
  }

  /// GET detail payroll beserta komponen pendapatan/potongan.
  static Future<MobileStaffPayrollDetail> fetchPayrollDetail(String id) async {
    final baseUrl = await AttendanceService.getBaseUrl();
    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/sikeu/payroll/$id',
        options: await _options(),
      );
      final data = _extractMap(response.data);
      if (data == null) {
        throw const ApiException('Server tidak mengirimkan detail slip gaji.');
      }
      return MobileStaffPayrollDetail.fromJson(data);
    } catch (e) {
      throw _exception(e, 'Gagal memuat detail slip gaji.');
    }
  }

  /// GET slip gaji PDF on demand (response biner, bukan JSON).
  static Future<MobileStaffDownloadResult> downloadPayrollSlip(
    String id,
  ) async {
    final baseUrl = await AttendanceService.getBaseUrl();
    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/sikeu/payroll/$id/slip',
        options: await _options(accept: 'application/pdf', bytes: true),
      );

      final raw = response.data;
      final bytes = raw is Uint8List
          ? raw
          : (raw is List<int> ? Uint8List.fromList(raw) : null);
      if (bytes == null ||
          bytes.length < 4 ||
          bytes[0] != 0x25 ||
          bytes[1] != 0x50) {
        throw const ApiException('Server mengembalikan berkas yang bukan PDF.');
      }

      final disposition = response.headers.value('content-disposition') ?? '';
      final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
      final suggestedName = match?.group(1)?.trim();
      final fileName = (suggestedName != null && suggestedName.isNotEmpty)
          ? suggestedName
          : 'slip-gaji-$id.pdf';

      return MobileStaffDownloadResult(bytes: bytes, fileName: fileName);
    } catch (e) {
      throw _exception(e, 'Gagal mengunduh slip gaji.');
    }
  }

  /// GET signed URL e-file yang berlaku 15 menit (response JSON).
  static Future<MobileStaffDownloadLink> fetchEfileDownload(String id) async {
    final baseUrl = await AttendanceService.getBaseUrl();
    try {
      final response = await _dio.get(
        '$baseUrl/mobile/staff/arsip/e-file/$id/download',
        options: await _options(),
      );
      final data = _extractMap(response.data);
      if (data == null) {
        throw const ApiException('Server tidak mengirimkan tautan unduh.');
      }
      final link = MobileStaffDownloadLink.fromJson(data);
      if (link.fileUrl.isEmpty) {
        throw const ApiException('Tautan unduh dokumen belum tersedia.');
      }
      return link;
    } catch (e) {
      throw _exception(e, 'Gagal membuat tautan unduh.');
    }
  }

  /// Master SIMPEG untuk dropdown form (prefix `/api`, bukan `/api/v1`).
  static Future<MobileStaffLookups> fetchMasterLookups() async {
    final baseUrl = await getApiBaseUrl();
    final options = await _options();
    final errors = <String, String>{};

    final results = await Future.wait(
      _masterEndpoints.entries.map(
        (entry) =>
            _fetchMaster('$baseUrl${entry.value}', entry.key, options, errors),
      ),
    );

    return MobileStaffLookups(
      jenisCuti: _optionsFrom(results[0]),
      jenisIzin: _optionsFrom(results[1]),
      kategoriKegiatan: _optionsFrom(results[2]),
      jenisTransportasi: _optionsFrom(results[3]),
      kategoriSk: _optionsFrom(results[4]),
      errors: Map<String, String>.unmodifiable(errors),
    );
  }

  static Future<List<dynamic>> _fetchMaster(
    String url,
    String key,
    Options options,
    Map<String, String> errors,
  ) async {
    try {
      final response = await _dio.get(url, options: options);
      return _extractList(response.data);
    } catch (e) {
      errors[key] = _exception(e, 'Master $key gagal dimuat.').message;
      return const <dynamic>[];
    }
  }

  /// POST LPJ ke surat tugas milik penanggung jawab (endpoint §43).
  static Future<MobileFeatureItem> uploadLpj({
    required String suratTugasId,
    required XFile file,
    String? laporanKegiatan,
    String? biayaRealisasi,
  }) async {
    final baseUrl = await AttendanceService.getBaseUrl();
    final options = await _options();

    final payload = <String, dynamic>{};
    final laporan = laporanKegiatan?.trim() ?? '';
    if (laporan.isNotEmpty) payload['laporan_kegiatan'] = laporan;
    final biaya = int.tryParse(
      (biayaRealisasi ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (biaya != null) payload['biaya_realisasi'] = biaya;

    final form = FormData.fromMap(payload);
    form.files.add(
      MapEntry(
        'file_lpj',
        await MultipartFile.fromFile(file.path, filename: file.name),
      ),
    );

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/simpeg/surat-tugas/$suratTugasId/lpj',
        data: form,
        options: options.copyWith(contentType: 'multipart/form-data'),
      );
      final data = _extractMap(response.data);
      if (data == null) {
        throw const ApiException('Server tidak mengirimkan hasil unggah LPJ.');
      }
      return MobileFeatureItem.fromJson(data);
    } catch (e) {
      throw _exception(e, 'Gagal mengunggah LPJ.');
    }
  }

  /// Perbarui metadata atau berkas dokumen e-file pribadi.
  static Future<MobileFeatureItem> updateEfile({
    required String id,
    required String namaDokumen,
    required String jenisDokumen,
    XFile? file,
  }) async {
    final baseUrl = await AttendanceService.getBaseUrl();
    final options = await _options();
    final form = FormData.fromMap({
      'nama_dokumen': namaDokumen.trim(),
      'jenis_dokumen': jenisDokumen.trim(),
    });
    if (file != null) {
      form.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ),
      );
    }

    try {
      final response = await _dio.post(
        '$baseUrl/mobile/staff/arsip/e-file/$id',
        data: form,
        options: options.copyWith(contentType: 'multipart/form-data'),
      );
      final data = _extractMap(response.data);
      if (data == null) {
        throw const ApiException('Server tidak mengirimkan data dokumen.');
      }
      return MobileFeatureItem.fromJson(data);
    } catch (e) {
      throw _exception(e, 'Gagal memperbarui dokumen e-file.');
    }
  }

  /// Hapus dokumen e-file pribadi dari server RAG.
  static Future<void> deleteEfile(String id) async {
    final baseUrl = await AttendanceService.getBaseUrl();
    try {
      await _dio.delete(
        '$baseUrl/mobile/staff/arsip/e-file/$id',
        options: await _options(),
      );
    } catch (e) {
      throw _exception(e, 'Gagal menghapus dokumen e-file.');
    }
  }

  static Map<String, dynamic>? _extractMap(dynamic payload) {
    if (payload is Map) {
      final data = payload['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is! Map) return const <dynamic>[];
    final data = payload['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }

  static List<MobileStaffMasterOption> _optionsFrom(List<dynamic> payload) =>
      payload
          .whereType<Map>()
          .map(
            (e) =>
                MobileStaffMasterOption.fromJson(Map<String, dynamic>.from(e)),
          )
          .where((option) => option.id > 0 && option.name.isNotEmpty)
          .toList();

  /// Tangani error biner (slip PDF) yang tidak dibaca `ApiException.from`.
  static ApiException _exception(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is List<int>) {
        try {
          final decoded = jsonDecode(utf8.decode(data));
          if (decoded is Map && decoded['message'] != null) {
            return ApiException(decoded['message'].toString(), cause: error);
          }
        } catch (_) {
          // Response biner bukan JSON: pakai pesan fallback.
        }
      }
    }
    if (error is ApiException) return error;
    return ApiException.from(error, fallback);
  }
}
