import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/camera/camera_adapter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/app_permission_service.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/face_capture_preferences.dart';
import '../../core/services/face_detection_service.dart';
import '../common/face_oval_guide.dart';

class FaceEnrollmentScreen extends ConsumerStatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  ConsumerState<FaceEnrollmentScreen> createState() =>
      _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends ConsumerState<FaceEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  late final CameraAdapter _cameraAdapter = createCameraAdapter();
  bool _isCameraReady = false;
  bool _isInitializing = true;
  bool _hasCameraError = false;
  String _cameraErrorMessage = '';
  String _faceStatusText = 'Menyiapkan kamera depan...';

  // 3 Pose pendaftaran wajah sesuai aturan PROJECT_RULES.md
  // 1: Tegap Hadap Depan, 2: Nunduk Sedikit (Dagu Turun), 3: Mendongak ke Atas (Dagu Naik)
  int _currentStep = 1; // 1, 2, atau 3
  final List<String> _capturedPhotos = []; // base64 JPEG strings
  bool _isProcessing = false;
  String _processingMessage = '';
  bool _isAutoCapturing = false;
  bool _autoStartAttempted = false;
  bool _consentAccepted = false;
  FaceCaptureMode _captureMode = FaceCaptureMode.auto;

  // Senter layar depan (Screen Torch / Ring Light)
  bool _isScreenFlashActive = false;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadCaptureMode();
    _initCamera();
  }

  @override
  void dispose() {
    _isAutoCapturing = false;
    _pulseCtrl.dispose();
    _cameraAdapter.dispose();
    super.dispose();
  }

  Future<void> _loadCaptureMode() async {
    final mode = await FaceCapturePreferences.load();
    if (!mounted) return;
    setState(() {
      _captureMode = mode;
      _faceStatusText = mode == FaceCaptureMode.auto
          ? 'Kamera aktif. Hadapkan wajah ke dalam oval.'
          : 'Kamera aktif. Ambil foto untuk setiap pose.';
    });
    _maybeStartAutoEnrollment();
  }

  /// Mulai take otomatis segera setelah kamera, mode, dan persetujuan siap.
  void _maybeStartAutoEnrollment() {
    if (_captureMode != FaceCaptureMode.auto ||
        !_isCameraReady ||
        !_consentAccepted ||
        _autoStartAttempted) {
      return;
    }
    _autoStartAttempted = true;
    _startAutoCapture();
  }

  Future<void> _initCamera() async {
    setState(() {
      _hasCameraError = false;
      _isInitializing = true;
      _isCameraReady = false;
      _autoStartAttempted = false;
      _faceStatusText = 'Menyalakan kamera depan...';
    });
    // Pastikan izin kamera aktif tepat sebelum adapter menyalakan kamera.
    final granted = await AppPermissionService.requestCamera();
    final success = granted && await _cameraAdapter.initialize();
    if (!mounted) return;
    setState(() {
      _isInitializing = false;
      _isCameraReady = success;
      _hasCameraError = !success;
      if (success) {
        _faceStatusText = _captureMode == FaceCaptureMode.auto
            ? 'Kamera aktif. Hadapkan wajah ke dalam oval.'
            : 'Kamera aktif. Ambil foto untuk setiap pose.';
      } else {
        _cameraErrorMessage = !granted
            ? 'Izin kamera belum diberikan. Aktifkan izin kamera untuk aplikasi ini.'
            : (_cameraAdapter.errorMessage ??
                'Kamera sedang digunakan aplikasi lain atau tidak tersedia.');
        _faceStatusText = _cameraErrorMessage;
      }
    });
    _maybeStartAutoEnrollment();
  }

  String _getPoseName(int step) {
    switch (step) {
      case 2:
        return 'Nunduk Sedikit (Dagu Turun)';
      case 3:
        return 'Mendongak ke Atas (Dagu Naik)';
      default:
        return 'Tegap Hadap Depan';
    }
  }

  String _getPoseInstruction(int step) {
    switch (step) {
      case 2:
        return 'Tundukkan kepala dan dagu sedikit ke bawah, pastikan wajah tetap di dalam oval.';
      case 3:
        return 'Arahkan dagu dan kepala sedikit ke atas, tatap kamera dengan jelas.';
      default:
        return 'Posisikan wajah Anda tegak lurus menghadap kamera di tengah oval panduan.';
    }
  }

  Future<void> _captureCurrentPose() async {
    if (_isProcessing || !_consentAccepted) return;
    HapticFeedback.mediumImpact();

    String? photoBase64;

    if (_isCameraReady) {
      try {
        final captured = await _cameraAdapter.takePictureBase64();
        if (captured != null && captured.isNotEmpty) {
          photoBase64 = captured;
        }
      } catch (e) {
        debugPrint('[FaceEnrollment] Gagal memotret via camera adapter: $e');
      }
    }

    if (photoBase64 == null || photoBase64.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Gambar wajah tidak tersedia dari kamera. Tidak ada data simulasi yang dikirim ke server.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await _storeCapture(photoBase64);
  }

  /// Simpan hasil kamera ke pose berjalan, lalu lanjut ke pose berikutnya.
  Future<void> _storeCapture(String photoBase64) async {
    _capturedPhotos.add(photoBase64);

    if (_currentStep < 3) {
      if (mounted) {
        setState(() {
          _currentStep++;
          _faceStatusText = 'Pose $_currentStep siap. ${_getPoseInstruction(_currentStep)}';
        });
      }
      return;
    }

    // 3 pose lengkap terkumpul.
    await _submitEnrollment();
  }

  /// Take otomatis: foto diambil hanya ketika ML Kit mendeteksi wajah.
  /// Foto yang sama dipakai sebagai sampel, jadi tidak ada pengambilan ganda.
  Future<void> _startAutoCapture() async {
    if (_isProcessing || _isAutoCapturing || !_consentAccepted || !_isCameraReady) {
      return;
    }
    if (!FaceDetectionService.isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Deteksi wajah otomatis tidak tersedia di web. Gunakan mode manual.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    setState(() {
      _isAutoCapturing = true;
      _currentStep = 1;
      _capturedPhotos.clear();
      _faceStatusText = 'Mencari wajah di kamera...';
    });

    int misses = 0;
    while (mounted &&
        _isAutoCapturing &&
        _capturedPhotos.length < 3 &&
        misses < 30) {
      final String? frame = await _cameraAdapter.takePictureBase64();
      if (frame == null || frame.isEmpty) {
        misses++;
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      bool hasFace = false;
      try {
        hasFace = await FaceDetectionService.containsFace(base64Decode(frame));
      } catch (e) {
        debugPrint('[FaceEnrollment] gagal decode frame deteksi: $e');
      }

      if (!mounted) return;

      if (hasFace) {
        setState(() {
          _faceStatusText =
              'Wajah terdeteksi. Menyimpan pose $_currentStep/3...';
        });
        HapticFeedback.mediumImpact();
        await _storeCapture(frame);
        misses = 0;
        if (_capturedPhotos.length < 3) {
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      } else {
        misses++;
        setState(() {
          _faceStatusText =
              'Wajah belum terdeteksi. Hadapkan wajah ke kamera.';
        });
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }

    if (mounted) {
      setState(() {
        _isAutoCapturing = false;
        if (_capturedPhotos.length >= 3) {
          _faceStatusText = '3 pose terkirim ke server.';
        } else if (!_isProcessing) {
          _faceStatusText = 'Auto capture dihentikan.';
        }
      });
    }
  }

  void _stopAutoCapture() {
    setState(() {
      _isAutoCapturing = false;
      _faceStatusText = 'Auto capture dihentikan.';
    });
  }

  Future<void> _submitEnrollment() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Mengirim 3 sampel pose wajah ke AI Backend...';
    });

    try {
      // Backend mewajibkan consent PDP tercatat sebelum embedding disimpan.
      final consent = await AttendanceService.recordConsent();
      if (!consent.success) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(consent.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final res = await AttendanceService.enrollFace(
        photosBase64: _capturedPhotos,
      );

      final now = DateTime.now();
      final nowFormatted =
          '${now.day} ${_months[now.month - 1]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

      if (!mounted) return;

      if (!res.success) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      ref.read(authProvider.notifier).updateFaceEnrollment(
            isEnrolled: true,
            enrolledAt: nowFormatted,
          );

      setState(() {
        _isProcessing = false;
      });

      _showSuccessDialog(res.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Wajah Berhasil Didaftarkan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isNotEmpty
                  ? message
                  : 'Data biometrik wajah berhasil disimpan di server.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile/biometric');
              }
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. LIVE CAMERA PREVIEW (Front Camera) — langsung menyala saat halaman dibuka
          Positioned.fill(
            child: _isCameraReady
                ? _cameraAdapter.buildPreview()
                : _buildCameraStatusView(),
          ),

          // 2. SENTER LAYAR DEPAN (Screen Torch Ring Light untuk Ruangan Redup)
          if (_isScreenFlashActive)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _ScreenTorchPainter(),
              ),
            ),

          // 3. OVERLAY BINGKAI OVAL PANDUAN WAJAH (Transparan 100% di dalam oval)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final double glowWidth = 3.0 + _pulseCtrl.value * 1.5;
                final Color borderColor = _currentStep == 3
                    ? AppColors.success
                    : (_currentStep == 2
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFFFBBF24));

                return CustomPaint(
                  size: Size.infinite,
                  painter: FaceOvalGuidePainter(
                    borderColor: borderColor,
                    borderWidth: glowWidth,
                  ),
                );
              },
            ),
          ),

          // 4. HEADER NAVIGASI, STEP CHIPS, & PETUNJUK POSE
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bar Navigasi Atas
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/profile/biometric');
                          }
                        },
                      ),
                      const Text(
                        'PEREKAMAN 3 POSE WAJAH',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        tooltip: _isScreenFlashActive
                            ? 'Matikan Senter Layar'
                            : 'Nyalakan Senter Layar',
                        icon: Icon(
                          _isScreenFlashActive
                              ? Icons.flashlight_on_rounded
                              : Icons.flashlight_off_rounded,
                          color: _isScreenFlashActive
                              ? const Color(0xFFFBBF24)
                              : Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _isScreenFlashActive = !_isScreenFlashActive;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Step Chips Indikator 3 Pose
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepChip(1, 'Tegap', _currentStep >= 1),
                          const SizedBox(width: 8),
                          _buildStepChip(2, 'Nunduk', _currentStep >= 2),
                          const SizedBox(width: 8),
                          _buildStepChip(3, 'Mendongak', _currentStep >= 3),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Teks Petunjuk Dinamis Pose
                      Text(
                        '📸 Pose $_currentStep/3: ${_getPoseName(_currentStep)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getPoseInstruction(_currentStep),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Status kamera + mode ambil wajah (dari pengaturan biometrik).
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _captureMode == FaceCaptureMode.auto
                            ? Icons.auto_mode_rounded
                            : Icons.touch_app_rounded,
                        color: const Color(0xFF38BDF8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _captureMode == FaceCaptureMode.auto
                                  ? 'Mode: Otomatis (deteksi wajah)'
                                  : 'Mode: Manual',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _faceStatusText,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. INDIKATOR PROSES SERVER
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.70),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: AppColors.primary),
                      const SizedBox(height: 18),
                      Text(
                        _processingMessage,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. TOMBOL AKSI CAPTURE BAWAH (Shutter Manual & Otomatis)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Persetujuan eksplisit UU PDP wajib sebelum data biometrik
                // dikirim dan disimpan di server RAG.
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      value: _consentAccepted,
                      onChanged: _isProcessing
                          ? null
                          : (value) {
                              setState(() => _consentAccepted = value ?? false);
                              _maybeStartAutoEnrollment();
                            },
                      title: const Text(
                        'Saya menyetujui pemrosesan data biometrik wajah saya',
                        style: TextStyle(color: Colors.white, fontSize: 11.5),
                      ),
                      subtitle: const Text(
                        'Data digunakan hanya untuk verifikasi presensi sesuai UU PDP.',
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                // Tombol utama mengikuti mode dari Pengaturan Biometrik.
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (_isProcessing || !_consentAccepted)
                        ? null
                        : (_captureMode == FaceCaptureMode.auto
                            ? (_isAutoCapturing
                                ? _stopAutoCapture
                                : _startAutoCapture)
                            : _captureCurrentPose),
                    icon: Icon(
                      _captureMode == FaceCaptureMode.auto
                          ? Icons.auto_mode_rounded
                          : Icons.camera_alt_rounded,
                      size: 22,
                    ),
                    label: Text(
                      _captureMode == FaceCaptureMode.auto
                          ? (_isAutoCapturing
                              ? 'Hentikan Deteksi Wajah'
                              : 'Mulai Take Otomatis (Deteksi Wajah)')
                          : 'Ambil Foto Pose $_currentStep/3 (${_currentStep == 1 ? "Tegap" : (_currentStep == 2 ? "Nunduk" : "Mendongak")})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tombol alternatif tetap tersedia tanpa harus keluar halaman.
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.55),
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (_isProcessing || !_consentAccepted)
                        ? null
                        : (_captureMode == FaceCaptureMode.auto
                            ? _captureCurrentPose
                            : _startAutoCapture),
                    icon: Icon(
                      _captureMode == FaceCaptureMode.auto
                          ? Icons.camera_alt_rounded
                          : Icons.auto_mode_rounded,
                      size: 18,
                      color: const Color(0xFF38BDF8),
                    ),
                    label: Text(
                      _captureMode == FaceCaptureMode.auto
                          ? 'Ambil Manual Pose $_currentStep/3'
                          : 'Mulai Take Otomatis (Deteksi Wajah)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status kamera. Saat kamera masih disiapkan hanya ditampilkan progress
  /// netral; placeholder bertanda seru sengaja dihapus karena layar harus
  /// menampilkan hasil kamera begitu adapter siap.
  Widget _buildCameraStatusView() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isInitializing && !_hasCameraError) ...[
                const CircularProgressIndicator(color: Color(0xFF38BDF8)),
                const SizedBox(height: 20),
                const Text(
                  'Menyalakan kamera depan...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tampilan kamera langsung muncul setelah siap.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ] else ...[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 34,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kamera Belum Aktif',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _cameraErrorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _initCamera,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Coba Lagi',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                if (!FaceDetectionService.isSupported) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Pada browser, izinkan akses kamera dari alamat situs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => openAppSettings(),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Buka Pengaturan Izin',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepChip(int stepNumber, String title, bool isActive) {
    final isDone = _capturedPhotos.length >= stepNumber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success
            : (isActive
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.white : Colors.white24,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDone)
            const Icon(Icons.check_rounded, size: 12, color: Colors.white)
          else
            Text(
              '$stepNumber. ',
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (isDone) const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? Colors.white : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk Senter Layar (Screen Torch Ring Light)
class _ScreenTorchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const ovalWidth = 235.0;
    const ovalHeight = 300.0;
    final center = Offset(size.width / 2, size.height / 2 - 24);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );
    final ovalRRect =
        RRect.fromRectAndRadius(ovalRect, const Radius.circular(120));

    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(screenRect)
      ..addRRect(ovalRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
