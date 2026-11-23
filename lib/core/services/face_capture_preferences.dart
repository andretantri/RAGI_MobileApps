import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode pengambilan sampel wajah.
///
/// [auto] memakai deteksi objek wajah on-device: kamera mengambil foto saat
/// wajah benar-benar terlihat. [manual] menunggu pegawai menekan tombol.
enum FaceCaptureMode { auto, manual }

/// Preferensi mode ambil wajah yang dipakai pendaftaran maupun presensi.
class FaceCapturePreferences {
  FaceCapturePreferences._();

  static const String key = 'face_capture_mode';

  static Future<FaceCaptureMode> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == 'manual') return FaceCaptureMode.manual;
      if (raw == 'auto') return FaceCaptureMode.auto;
    } catch (e) {
      debugPrint('[FaceCapturePreferences] gagal membaca: $e');
    }
    // Default: otomatis memakai deteksi wajah.
    return FaceCaptureMode.auto;
  }

  static Future<void> save(FaceCaptureMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, mode.name);
    } catch (e) {
      debugPrint('[FaceCapturePreferences] gagal menyimpan: $e');
    }
  }
}
