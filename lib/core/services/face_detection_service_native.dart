import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

const bool faceDetectionSupported = true;

final FaceDetector _faceDetector = FaceDetector(
  options: FaceDetectorOptions(
    // Mode fast jauh lebih responsif, hemat resource, dan deteksi wajah sangat handal
    performanceMode: FaceDetectorMode.fast,
    minFaceSize: 0.1,
  ),
);

/// ML Kit menerima path file untuk JPEG. Foto sementara dibuat dari frame
/// kamera yang sudah diambil adapter, lalu dihapus lagi setelah diproses.
Future<bool> detectFaceFromJpeg(Uint8List jpegBytes) async {
  if (jpegBytes.isEmpty) return false;

  final path =
      '${Directory.systemTemp.path}/myinu_face_detect_${DateTime.now().microsecondsSinceEpoch}.jpg';
  final file = File(path);

  try {
    await file.writeAsBytes(jpegBytes, flush: true);

    // 1. Coba deteksi langsung dari file JPEG
    try {
      final fromFile = await _faceDetector.processImage(
        InputImage.fromFilePath(path),
      );
      if (fromFile.isNotEmpty) return true;
    } catch (e) {
      developer.log('[FaceDetection] fromFilePath: $e');
    }

    // 2. Jika orientasi sensor kamera depan (misal di beberapa seri Xiaomi/Oppo)
    // tidak terbaca dari EXIF, decode ke bitmap dan uji beberapa rotasi umum (0, 270, 90)
    try {
      final codec = await ui.instantiateImageCodec(jpegBytes);
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final width = frame.image.width;
        final height = frame.image.height;

        for (final rot in [0, 270, 90]) {
          try {
            final fromBitmap = await _faceDetector.processImage(
              InputImage.fromBitmap(
                bitmap: bytes,
                width: width,
                height: height,
                rotation: rot,
              ),
            );
            if (fromBitmap.isNotEmpty) return true;
          } catch (_) {}
        }
      }
    } catch (e) {
      developer.log('[FaceDetection] fromBitmap: $e');
    }

    return false;
  } catch (e) {
    developer.log('[FaceDetection] gagal mendeteksi wajah: $e');
    return false;
  } finally {
    try {
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
