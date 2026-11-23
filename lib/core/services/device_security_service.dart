import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'location_service.dart';

/// Hasil pemeriksaan integritas keamanan perangkat
class DeviceSecurityResult {
  final bool isSafe;
  final bool isRootedOrJailbroken;
  final bool isMockLocation;
  final String? reason;

  const DeviceSecurityResult({
    required this.isSafe,
    this.isRootedOrJailbroken = false,
    this.isMockLocation = false,
    this.reason,
  });

  static const safe = DeviceSecurityResult(isSafe: true);
}

/// Service untuk mendeteksi Root, Jailbreak, dan Mock Location (Fake GPS)
class DeviceSecurityService {
  /// Cek apakah perangkat telah di-root (Android) atau di-jailbreak (iOS)
  static Future<bool> isRootedOrJailbroken() async {
    if (kIsWeb) return false;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return false;
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceSecurityService] Root check exception: $e');
      }
      return false;
    }
  }

  /// Cek integritas perangkat dan lokasi sebelum presensi (Anti-Fake GPS & Anti-Root)
  static Future<DeviceSecurityResult> validateAttendanceIntegrity(
      LocationResult loc) async {
    // 1. Cek Mock Location (Fake GPS)
    if (loc.isMockLocation) {
      if (!kDebugMode) {
        return const DeviceSecurityResult(
          isSafe: false,
          isMockLocation: true,
          reason:
              'Presensi Ditolak: Terdeteksi penggunaan Fake GPS / Lokasi Palsu (Mock Location). Harap matikan aplikasi pemalsu lokasi.',
        );
      }
    }

    // 2. Cek Root / Jailbreak
    final rooted = await isRootedOrJailbroken();
    if (rooted) {
      if (!kDebugMode) {
        return const DeviceSecurityResult(
          isSafe: false,
          isRootedOrJailbroken: true,
          reason:
              'Presensi Ditolak: Perangkat terdeteksi Root / Jailbreak demi menjaga integritas data presensi kampus.',
        );
      }
    }

    return DeviceSecurityResult.safe;
  }
}
