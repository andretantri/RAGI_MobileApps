import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

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
