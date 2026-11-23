import 'dart:typed_data';

import 'face_detection_service_stub.dart'
    if (dart.library.io) 'face_detection_service_native.dart';

/// Deteksi wajah on-device untuk mode take otomatis.
///
/// Web tidak memiliki ML Kit, jadi pemanggil harus mengecek [isSupported]
/// sebelum mengaktifkan auto capture. Di web mode manual tetap tersedia.
abstract class FaceDetectionService {
  static bool get isSupported => faceDetectionSupported;

  /// [jpegBytes] adalah hasil kamera depan dalam format JPEG.
  static Future<bool> containsFace(Uint8List jpegBytes) =>
      detectFaceFromJpeg(jpegBytes);
}
