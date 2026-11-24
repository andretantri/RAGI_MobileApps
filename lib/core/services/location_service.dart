import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationCheckResult {
  final bool isReady;
  final String? errorMessage;
  final bool isGpsDisabled;
  final bool isPermissionDenied;
  final bool isPermanentlyDenied;

  const LocationCheckResult({
    required this.isReady,
    this.errorMessage,
    this.isGpsDisabled = false,
    this.isPermissionDenied = false,
    this.isPermanentlyDenied = false,
  });
}

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMockLocation;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isMockLocation,
  });

  @override
  String toString() =>
      'Lat: $latitude, Lng: $longitude, Acc: ${accuracy}m, Mock: $isMockLocation';
}

class OfficeLocationModel {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;

  const OfficeLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
  });

  factory OfficeLocationModel.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw const FormatException('Data lokasi kantor dari server tidak memiliki koordinat.');
    }

    return OfficeLocationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Lokasi kantor',
      address: json['address']?.toString() ?? '',
      latitude: latitude,
      longitude: longitude,
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 100.0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

class LocationService {
  /// Memeriksa status GPS & izin lokasi sebelum presensi dijalankan.
  /// Hanya dipanggil saat pengguna mengakses fitur presensi, bukan saat
  /// sekadar menjelajahi menu umum.
  static Future<LocationCheckResult> checkLocationPrerequisites({
    bool requestIfNotGranted = true,
  }) async {
    // 1. Periksa apakah GPS perangkat aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationCheckResult(
        isReady: false,
        isGpsDisabled: true,
        errorMessage:
            'Layanan GPS perangkat belum aktif. Presensi memerlukan GPS aktif untuk memvalidasi posisi Anda.',
      );
    }

    // 2. Periksa status izin lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestIfNotGranted) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationCheckResult(
        isReady: false,
        isPermissionDenied: true,
        errorMessage: 'Izin akses lokasi diperlukan untuk presensi pegawai.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationCheckResult(
        isReady: false,
        isPermanentlyDenied: true,
        errorMessage:
            'Izin lokasi ditolak permanen. Silakan aktifkan izin lokasi di pengaturan aplikasi.',
      );
    }

    return const LocationCheckResult(isReady: true);
  }

  /// Menampilkan dialog panduan jika lokasi / GPS belum aktif saat presensi.
  static Future<bool> showLocationRequirementDialog(
    BuildContext context,
    LocationCheckResult check,
  ) async {
    if (check.isReady) return true;

    final isGps = check.isGpsDisabled;
    final title = isGps ? 'Aktifkan GPS Perangkat' : 'Izin Lokasi Diperlukan';
    final message = isGps
        ? 'Layanan GPS pada HP Anda sedang mati. Presensi membutuhkan lokasi GPS aktif untuk memvalidasi posisi di area kampus. Silakan aktifkan GPS terlebih dahulu.'
        : 'Presensi pegawai membutuhkan izin akses lokasi agar server dapat memvalidasi kehadiran Anda. Silakan berikan izin lokasi.';
    final buttonText = isGps ? 'Buka Pengaturan GPS' : 'Buka Pengaturan Izin';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isGps ? Icons.location_off_rounded : Icons.location_searching_rounded,
              color: const Color(0xFFE65100),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              if (isGps) {
                await Geolocator.openLocationSettings();
              } else {
                await Geolocator.openAppSettings();
              }
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Mengambil lokasi GPS secara on-demand (diadopsi dari Project/indonusa/absen)
  static Future<LocationResult> getCurrentLocationOnDemand() async {
    try {
      // 1. Periksa apakah GPS perangkat aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Layanan GPS perangkat belum aktif. Silakan aktifkan GPS di pengaturan perangkat Anda.');
      }

      // 2. Periksa dan minta izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin akses lokasi ditolak oleh pengguna.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Izin lokasi ditolak permanen. Silakan buka Pengaturan Perangkat untuk mengaktifkan izin lokasi.');
      }

      // 3. Ambil posisi GPS on-demand dengan timeout 10 detik
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isMockLocation: position.isMocked,
      );
    } catch (e) {
      debugPrint('[LocationService] GPS Error: $e');
      rethrow;
    }
  }

  /// Hitung jarak antara dua koordinat (Haversine formula via Geolocator) dalam satuan meter
  static double calculateDistanceMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
