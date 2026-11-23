import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

const bool faceDetectionSupported = true;

final FaceDetector _faceDetector = FaceDetector(
  options: FaceDetectorOptions(
    performanceMode: FaceDetectorMode.fast,
    minFaceSize: 0.12,
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
    final faces = await _faceDetector.processImage(
      InputImage.fromFilePath(path),
    );
    return faces.isNotEmpty;
  } catch (e) {
    developer.log('[FaceDetection] gagal mendeteksi wajah: $e');
    return false;
  } finally {
    try {
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
