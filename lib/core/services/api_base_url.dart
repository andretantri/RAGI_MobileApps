import 'attendance_service.dart';

/// Base URL `/api` untuk endpoint di luar gateway `/api/v1`.
///
/// Endpoint RAG seperti `/api/modules/my-modules` dan `/api/sippm/skema`
/// tidak berada di bawah prefix `v1`, sehingga `/v1` perlu dibuang dari
/// base URL aplikasi.
Future<String> getApiBaseUrl() async {
  final v1Url = await AttendanceService.getBaseUrl();
  if (v1Url.endsWith('/v1')) {
    return v1Url.substring(0, v1Url.length - 3);
  }
  return v1Url;
}
