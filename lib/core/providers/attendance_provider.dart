import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/face_verification_info.dart';
import '../services/attendance_service.dart';
import '../services/device_security_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'notification_provider.dart';

class AttendanceState {
  final bool isLoading;
  final bool isCheckingLocation;
  final bool isSubmitting;
  final String? clockInTime;
  final String? clockOutTime;
  final String status;
  final LocationResult? currentLocation;
  final OfficeLocationModel? nearestOffice;
  final double? currentDistanceMeters;
  final bool isWithinRadius;
  final String? locationError;
  final String? lastMessage;
  final double? faceSimilarityScore;
  final double? minimumFaceSimilarity;
  final String? faceVerificationMessage;
  final String? faceThresholdSource;
  final String? faceThresholdUpdatedAt;

  const AttendanceState({
    this.isLoading = false,
    this.isCheckingLocation = false,
    this.isSubmitting = false,
    this.clockInTime,
    this.clockOutTime,
    this.status = 'Belum Absen',
    this.currentLocation,
    this.nearestOffice,
    this.currentDistanceMeters,
    this.isWithinRadius = false,
    this.locationError,
    this.lastMessage,
    this.faceSimilarityScore,
    this.minimumFaceSimilarity,
    this.faceVerificationMessage,
    this.faceThresholdSource,
    this.faceThresholdUpdatedAt,
  });

  static const Object _unset = Object();

  bool get hasClockedIn => clockInTime != null && clockInTime!.isNotEmpty;
  bool get hasClockedOut => clockOutTime != null && clockOutTime!.isNotEmpty;
  bool get isCompleted => hasClockedIn && hasClockedOut;

  AttendanceState copyWith({
    bool? isLoading,
    bool? isCheckingLocation,
    bool? isSubmitting,
    String? clockInTime,
    String? clockOutTime,
    String? status,
    LocationResult? currentLocation,
    OfficeLocationModel? nearestOffice,
    double? currentDistanceMeters,
    bool? isWithinRadius,
    String? locationError,
    String? lastMessage,
    Object? faceSimilarityScore = _unset,
    Object? minimumFaceSimilarity = _unset,
    Object? faceVerificationMessage = _unset,
    Object? faceThresholdSource = _unset,
    Object? faceThresholdUpdatedAt = _unset,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingLocation: isCheckingLocation ?? this.isCheckingLocation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      nearestOffice: nearestOffice ?? this.nearestOffice,
      currentDistanceMeters:
          currentDistanceMeters ?? this.currentDistanceMeters,
      isWithinRadius: isWithinRadius ?? this.isWithinRadius,
      locationError: locationError ?? this.locationError,
      lastMessage: lastMessage ?? this.lastMessage,
      faceSimilarityScore: identical(faceSimilarityScore, _unset)
          ? this.faceSimilarityScore
          : faceSimilarityScore as double?,
      minimumFaceSimilarity: identical(minimumFaceSimilarity, _unset)
          ? this.minimumFaceSimilarity
          : minimumFaceSimilarity as double?,
      faceVerificationMessage: identical(faceVerificationMessage, _unset)
          ? this.faceVerificationMessage
          : faceVerificationMessage as String?,
      faceThresholdSource: identical(faceThresholdSource, _unset)
          ? this.faceThresholdSource
          : faceThresholdSource as String?,
      faceThresholdUpdatedAt: identical(faceThresholdUpdatedAt, _unset)
          ? this.faceThresholdUpdatedAt
          : faceThresholdUpdatedAt as String?,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(const AttendanceState()) {
    init();
  }

  List<OfficeLocationModel> _allOffices = [];

  Future<void> init() async {
    await Future.wait([
      fetchTodayStatus(),
      fetchFaceSimilaritySettings(),
    ]);
    await checkLocationAndDistance();
  }

  /// Ambil batas kemiripan wajah aktif dari endpoint pengaturan RAG.
  /// Endpoint lama belum memilikinya, sehingga kegagalan ditoleransi dan
  /// nilai dari `/attendance/today` tetap dipakai.
  Future<void> fetchFaceSimilaritySettings() async {
    try {
      final settings = await AttendanceService.getFaceSimilaritySettings();
      if (settings == null) return;
      state = state.copyWith(
        minimumFaceSimilarity: settings.minimum,
        faceThresholdSource: settings.source,
        faceThresholdUpdatedAt: settings.updatedAt,
      );
    } catch (e) {
      debugPrint('[AttendanceNotifier] fetchFaceSimilaritySettings error: $e');
    }
  }

  /// Ambil status hari ini dari API (cache lokal hanya jika berasal dari API)
  Future<void> fetchTodayStatus() async {
    state = state.copyWith(isLoading: true, lastMessage: null);
    _allOffices = [];

    try {
      final res = await AttendanceService.getTodayStatus();
      if (!res.success || res.data == null) {
        final info = FaceVerificationInfo.fromMessage(res.message);
        state = state.copyWith(
          isLoading: false,
          lastMessage: res.message,
          faceSimilarityScore: info.score,
          minimumFaceSimilarity: info.minimum,
          faceVerificationMessage: info.message,
        );
        return;
      }

      final data = res.data!;

      // Daftar kantor diambil dari `allowed_offices` yang dikirim endpoint
      // /attendance/today. Endpoint /offices tidak tersedia di API produksi.
      final rawOffices = data['allowed_offices'] as List? ?? const [];
      for (final raw in rawOffices) {
        if (raw is! Map<String, dynamic>) continue;
        try {
          _allOffices.add(OfficeLocationModel.fromJson(raw));
        } catch (_) {
          // Lewati entri kantor tanpa koordinat yang valid dari server.
        }
      }
      if (_allOffices.isEmpty && data['office'] is Map<String, dynamic>) {
        try {
          _allOffices.add(OfficeLocationModel.fromJson(data['office'] as Map<String, dynamic>));
        } catch (_) {}
      }

      final att = data['attendance'] as Map<String, dynamic>?;
      final clockIn = att?['clock_in']?.toString();
      final clockOut = att?['clock_out']?.toString();
      final attStatus = att?['status']?.toString();
      final faceInfo = res.faceVerification.hasData
          ? res.faceVerification
          : FaceVerificationInfo.fromJson(att ?? data);

      state = state.copyWith(
        isLoading: false,
        clockInTime: clockIn,
        clockOutTime: clockOut,
        status: attStatus == 'ditolak'
            ? 'Ditolak'
            : clockIn != null
                ? (attStatus == 'terlambat' ? 'Terlambat' : 'Sudah Masuk')
                : 'Belum Absen',
        nearestOffice: _allOffices.isEmpty ? null : _allOffices.first,
        lastMessage: res.message,
        faceSimilarityScore: faceInfo.score,
        minimumFaceSimilarity: faceInfo.minimum,
        faceVerificationMessage: faceInfo.message,
        faceThresholdSource: faceInfo.source,
        faceThresholdUpdatedAt: faceInfo.updatedAt,
      );
    } catch (e) {
      debugPrint('[AttendanceNotifier] fetchTodayStatus error: $e');
      state = state.copyWith(isLoading: false, lastMessage: 'Gagal memuat status presensi dari server.');
    }
  }

  /// Mengambil lokasi GPS riil on-demand dan menghitung jarak ke kampus terdekat
  Future<void> checkLocationAndDistance() async {
    state = state.copyWith(isCheckingLocation: true, locationError: null);

    try {
      final loc = await LocationService.getCurrentLocationOnDemand();

      // Cari kantor/kampus terdekat dari koordinat GPS pengguna
      OfficeLocationModel? closest;
      double minDistance = double.infinity;

      for (final office in _allOffices) {
        final dist = LocationService.calculateDistanceMeters(
          startLat: loc.latitude,
          startLng: loc.longitude,
          endLat: office.latitude,
          endLng: office.longitude,
        );
        if (dist < minDistance) {
          minDistance = dist;
          closest = office;
        }
      }

      if (closest == null) {
        state = state.copyWith(
          isCheckingLocation: false,
          locationError: 'Data lokasi kantor belum tersedia dari server.',
          isWithinRadius: false,
        );
        return;
      }

      final withinRadius = minDistance <= closest.radiusMeters;

      state = state.copyWith(
        isCheckingLocation: false,
        currentLocation: loc,
        nearestOffice: closest,
        currentDistanceMeters: minDistance,
        isWithinRadius: withinRadius,
      );
    } catch (e) {
      debugPrint('[AttendanceNotifier] GPS error: $e');
      state = state.copyWith(
        isCheckingLocation: false,
        locationError: e.toString().replaceAll('Exception: ', ''),
        isWithinRadius: false,
      );
    }
  }

  /// Presensi Masuk (Clock In)
  Future<AttendanceResponse<Map<String, dynamic>>> clockIn({
    String? qrCode,
    String? faceImage,
  }) async {
    state = state.copyWith(isSubmitting: true);

    LocationResult loc = state.currentLocation ??
        await LocationService.getCurrentLocationOnDemand();

    // Validasi integritas keamanan perangkat (Anti-Fake GPS & Anti-Root)
    final securityCheck =
        await DeviceSecurityService.validateAttendanceIntegrity(loc);
    if (!securityCheck.isSafe) {
      final msg = securityCheck.reason ??
          'Presensi ditolak demi menjaga integritas data presensi.';
      state = state.copyWith(
        isSubmitting: false,
        lastMessage: msg,
      );
      return AttendanceResponse(
        success: false,
        message: msg,
      );
    }

    final response = await AttendanceService.clockIn(
      latitude: loc.latitude,
      longitude: loc.longitude,
      accuracy: loc.accuracy,
      isMockLocation: loc.isMockLocation,
      faceImage: faceImage,
      qrCode: qrCode,
    );

    final faceInfo = response.faceVerification.hasData
        ? response.faceVerification
        : FaceVerificationInfo.fromMessage(response.message);

    if (response.success) {
      final timeStr = response.data?['clock_in']?.toString() ??
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB';
      state = state.copyWith(
        isSubmitting: false,
        clockInTime: timeStr,
        status: 'Sudah Masuk',
        lastMessage: response.message,
        faceSimilarityScore: faceInfo.score ?? response.faceScore,
        minimumFaceSimilarity: faceInfo.minimum,
        faceVerificationMessage: faceInfo.message,
      );
      NotificationService.addLocalNotification(
        NotificationItem(
          id: UniqueKey().toString(),
          title: 'Presensi Masuk Berhasil',
          body:
              'Presensi masuk terekam pukul $timeStr di Kampus Politeknik Indonusa Surakarta.',
          icon: Icons.fingerprint_rounded,
          color: AppColors.success,
          time: 'Baru saja',
          isRead: false,
          module: 'PRESENSI',
          period: 'Hari Ini',
        ),
      );
    } else {
      state = state.copyWith(
        isSubmitting: false,
        lastMessage: response.message,
        status: faceInfo.isBelowMinimum ? 'Wajah Tidak Cocok' : state.status,
        faceSimilarityScore: faceInfo.score ?? response.faceScore,
        minimumFaceSimilarity: faceInfo.minimum,
        faceVerificationMessage: faceInfo.message,
      );
    }

    return response;
  }

  /// Presensi Pulang (Clock Out)
  Future<AttendanceResponse<Map<String, dynamic>>> clockOut({
    String? faceImage,
  }) async {
    state = state.copyWith(isSubmitting: true);

    LocationResult loc = state.currentLocation ??
        await LocationService.getCurrentLocationOnDemand();

    // Validasi integritas keamanan perangkat (Anti-Fake GPS & Anti-Root)
    final securityCheck =
        await DeviceSecurityService.validateAttendanceIntegrity(loc);
    if (!securityCheck.isSafe) {
      final msg = securityCheck.reason ??
          'Presensi ditolak demi menjaga integritas data presensi.';
      state = state.copyWith(
        isSubmitting: false,
        lastMessage: msg,
      );
      return AttendanceResponse(
        success: false,
        message: msg,
      );
    }

    final response = await AttendanceService.clockOut(
      latitude: loc.latitude,
      longitude: loc.longitude,
      accuracy: loc.accuracy,
      isMockLocation: loc.isMockLocation,
      faceImage: faceImage,
    );

    final faceInfo = response.faceVerification.hasData
        ? response.faceVerification
        : FaceVerificationInfo.fromMessage(response.message);

    if (response.success) {
      final timeStr = response.data?['clock_out']?.toString() ??
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB';
      state = state.copyWith(
        isSubmitting: false,
        clockOutTime: timeStr,
        lastMessage: response.message,
        faceSimilarityScore: faceInfo.score ?? response.faceScore,
        minimumFaceSimilarity: faceInfo.minimum,
        faceVerificationMessage: faceInfo.message,
      );
      NotificationService.addLocalNotification(
        NotificationItem(
          id: UniqueKey().toString(),
          title: 'Presensi Pulang Tervalidasi',
          body:
              'Presensi pulang terekam pukul $timeStr. Terima kasih atas dedikasi Anda hari ini.',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          time: 'Baru saja',
          isRead: false,
          module: 'PRESENSI',
          period: 'Hari Ini',
        ),
      );
    } else {
      state = state.copyWith(
        isSubmitting: false,
        lastMessage: response.message,
        status: faceInfo.isBelowMinimum ? 'Wajah Tidak Cocok' : state.status,
        faceSimilarityScore: faceInfo.score ?? response.faceScore,
        minimumFaceSimilarity: faceInfo.minimum,
        faceVerificationMessage: faceInfo.message,
      );
    }

    return response;
  }

  void reset() {
    state = const AttendanceState();
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier();
});
