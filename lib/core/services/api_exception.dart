import 'package:dio/dio.dart';

/// Error standar untuk kegagalan request API.
///
/// Dipakai agar UI tidak pernah menampilkan data rekaan saat server gagal,
/// melainkan pesan error yang jelas dan bisa di-repeat.
class ApiException implements Exception {
  final String message;
  final Object? cause;

  const ApiException(this.message, {this.cause});

  factory ApiException.from(Object error, String fallbackMessage) {
    if (error is ApiException) return error;

    String? serverMessage;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        serverMessage = data['message']?.toString() ?? data['error']?.toString();
      }
      serverMessage ??= error.message;
    }

    final detail = serverMessage?.trim();
    if (detail != null && detail.isNotEmpty) {
      // Laravel mengembalikan teks teknis "The route ... could not be
      // found" ketika endpoint belum terdaftar di server. Jangan tampilkan
      // teks tersebut ke pengguna.
      final lower = detail.toLowerCase();
      if (lower.contains('could not be found') ||
          lower.contains('no route found') ||
          (lower.contains('route') && lower.contains('not found'))) {
        return ApiException(
          'Layanan ini belum tersedia di server (endpoint tidak ditemukan).',
          cause: error,
        );
      }
      return ApiException(detail, cause: error);
    }
    return ApiException(fallbackMessage, cause: error);
  }

  @override
  String toString() => message;
}
