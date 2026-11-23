import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myinu_staff/core/services/api_exception.dart';

DioException _routeNotFound(String path, String message) {
  final requestOptions = RequestOptions(path: path);
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: 404,
      data: {'status': 'error', 'message': message},
    ),
  );
}

void main() {
  group('ApiException', () {
    test('menerjemahkan route Laravel 404 ke pesan yang ramah', () {
      final error = _routeNotFound(
        '/api/v1/mobile/staff/sikeu/pengajuan',
        'The route api/v1/mobile/staff/sikeu/pengajuan could not be found.',
      );

      final exception = ApiException.from(error, 'Gagal memuat pengajuan.');

      expect(exception.message, contains('belum tersedia'));
      expect(exception.message, isNot(contains('could not be found')));
      expect(exception.cause, same(error));
    });

    test('pesan server lain tetap diteruskan', () {
      final requestOptions = RequestOptions(path: '/api/v1/mobile/staff/home');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'message': 'Token tidak valid.'},
        ),
      );

      expect(
        ApiException.from(error, 'Gagal memuat.').message,
        'Token tidak valid.',
      );
    });
  });
}
