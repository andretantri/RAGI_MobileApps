import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_notification_service.dart';

/// Permintaan izin OS yang dibutuhkan aplikasi setelah pengguna login.
///
/// Kamera dipakai pendaftaran wajah & scanner QR, lokasi dipakai validasi
/// presensi, sedangkan notifikasi memakai layanan notifikasi lokal yang sudah
/// ada. Semua panggilan dibungkus try/catch supaya kegagalan plugin tidak
/// menggagalkan render antarmuka.
class AppPermissionService {
  AppPermissionService._();

  static bool _requestedOnStart = false;

  /// Dipanggil sekali saat shell terautentikasi pertama kali dibuat.
  /// Hanya meminta izin dasar notifikasi. Izin lokasi dan kamera hanya
  /// diminta saat pengguna benar-benar mengakses fitur presensi/kamera.
  static Future<void> requestOnAuthenticatedStart() async {
    if (kIsWeb || _requestedOnStart) return;
    _requestedOnStart = true;

    try {
      await LocalNotificationService.instance.requestPermissions();
    } catch (e) {
      debugPrint('[AppPermissionService] notifikasi error: $e');
    }
  }

  /// Meminta izin kamera. Dipanggil ulang secara eksplisit oleh layar wajah.
  static Future<bool> requestCamera() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        debugPrint('[AppPermissionService] kamera: ${status.name}');
      }
      return status.isGranted;
    } catch (e) {
      debugPrint('[AppPermissionService] kamera error: $e');
      return false;
    }
  }

  /// Meminta izin lokasi saat aplikasi sedang dipakai (needed by presensi).
  static Future<bool> requestLocation() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        debugPrint('[AppPermissionService] lokasi: ${status.name}');
      }
      return status.isGranted;
    } catch (e) {
      debugPrint('[AppPermissionService] lokasi error: $e');
      return false;
    }
  }
}
