import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/camera/camera_adapter.dart';
import '../../core/services/app_permission_service.dart';
import '../../core/services/face_capture_preferences.dart';
import '../../core/services/face_detection_service.dart';
import '../../core/theme/app_colors.dart';
import '../common/face_oval_guide.dart';

/// Ambil satu foto wajah live untuk presensi.
///
/// Kamera depan dinyalakan saat halaman dibuka dan hasilnya langsung tampil di
/// layar. Hasil dikembalikan sebagai base64 JPEG lewat `Navigator.pop`.
class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  late final CameraAdapter _cameraAdapter = createCameraAdapter();

  bool _isCameraReady = false;
  bool _isInitializing = true;
  bool _hasCameraError = false;
  String _cameraErrorMessage = '';
  String _statusText = 'Menyalakan kamera depan...';
  bool _isCapturing = false;
  bool _isAutoRunning = false;
  bool _autoStartAttempted = false;
  FaceCaptureMode _captureMode = FaceCaptureMode.auto;

  @override
  void initState() {
    super.initState();
    _loadCaptureMode();
    _initCamera();
  }

  @override
  void dispose() {
    _isAutoRunning = false;
    _cameraAdapter.dispose();
    super.dispose();
  }

  Future<void> _loadCaptureMode() async {
    final mode = await FaceCapturePreferences.load();
    if (!mounted) return;
    setState(() {
      _captureMode = mode;
      _statusText = mode == FaceCaptureMode.auto
          ? 'Hadapkan wajah ke dalam oval untuk diambil otomatis.'
          : 'Tekan tombol untuk mengambil foto wajah.';
    });
    _maybeStartAutoCapture();
  }

  /// Jalankan deteksi otomatis begitu kamera dan preferensi mode siap.
  void _maybeStartAutoCapture() {
    if (_captureMode != FaceCaptureMode.auto ||
        !_isCameraReady ||
        _hasCameraError ||
        _autoStartAttempted) {
      return;
    }
    _autoStartAttempted = true;
    _startAutoCapture();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _hasCameraError = false;
      _isCameraReady = false;
      _autoStartAttempted = false;
      _statusText = 'Menyalakan kamera depan...';
    });

    final granted = await AppPermissionService.requestCamera();
    final success = granted && await _cameraAdapter.initialize();
    if (!mounted) return;

    setState(() {
      _isInitializing = false;
      _isCameraReady = success;
      _hasCameraError = !success;
      if (success) {
        _statusText = _captureMode == FaceCaptureMode.auto
            ? 'Hadapkan wajah ke dalam oval untuk diambil otomatis.'
            : 'Tekan tombol untuk mengambil foto wajah.';
      } else {
        _cameraErrorMessage = !granted
            ? 'Izin kamera belum diberikan. Aktifkan izin kamera untuk aplikasi ini.'
            : (_cameraAdapter.errorMessage ??
                'Kamera sedang digunakan aplikasi lain atau tidak tersedia.');
        _statusText = _cameraErrorMessage;
      }
    });
    _maybeStartAutoCapture();
  }

  Future<void> _finish(String? base64) async {
    if (base64 == null || base64.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto wajah belum tersedia dari kamera.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    if (mounted) Navigator.of(context).pop(base64);
  }

  Future<void> _captureManually() async {
    if (_isCapturing || !_isCameraReady) return;
    _isAutoRunning = false;
    setState(() {
      _isCapturing = true;
      _statusText = 'Mengambil dan menyimpan foto wajah...';
    });
    String? frame;
    try {
      frame = await _cameraAdapter.takePictureBase64();
    } catch (e) {
      debugPrint('[FaceCapture] gagal memotret: $e');
    }
    if (!mounted) return;
    setState(() => _isCapturing = false);
    await _finish(frame);
  }

  /// Auto capture berbasis deteksi wajah on-device.
  Future<void> _startAutoCapture() async {
    if (_isCapturing || _isAutoRunning || !_isCameraReady) return;
    if (!FaceDetectionService.isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Deteksi wajah otomatis tidak didukung di perangkat ini. Gunakan tombol manual.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    setState(() {
      _isAutoRunning = true;
      _statusText = 'Mencari wajah di dalam oval...';
    });

    int misses = 0;
    while (mounted && _isAutoRunning && misses < 120) {
      final frame = await _cameraAdapter.takePictureBase64();
      if (!_isAutoRunning || !mounted) return;
      if (frame == null || frame.isEmpty) {
        misses++;
        await Future.delayed(const Duration(milliseconds: 350));
        continue;
      }

      bool hasFace = false;
      try {
        hasFace = await FaceDetectionService.containsFace(base64Decode(frame));
      } catch (e) {
        debugPrint('[FaceCapture] gagal decode frame deteksi: $e');
      }
      if (!_isAutoRunning || !mounted) return;

      if (hasFace) {
        setState(() {
          _isAutoRunning = false;
          _isCapturing = true;
          _statusText = 'Wajah terdeteksi! Menyimpan foto...';
        });
        await _finish(frame);
        return;
      }

      misses++;
      setState(() {
        if (misses >= 3) {
          _statusText = 'Wajah belum terkunci otomatis. Bisa langsung ketuk tombol di bawah.';
        } else {
          _statusText = 'Mencari wajah... pastikan berada di dalam oval.';
        }
      });
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (mounted && _isAutoRunning) {
      setState(() {
        _isAutoRunning = false;
        if (!_hasCameraError) {
          _statusText = 'Silakan ketuk tombol "Ambil Foto Sekarang" di bawah.';
        }
      });
    }
  }

  void _stopAutoCapture() {
    setState(() {
      _isAutoRunning = false;
      _statusText = 'Deteksi otomatis dijeda. Ketuk tombol untuk foto.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _isCameraReady
                ? _cameraAdapter.buildPreview()
                : _buildCameraStatusView(),
          ),

          IgnorePointer(
            child: AnimatedBuilder(
              animation: const AlwaysStoppedAnimation<double>(3.0),
              builder: (context, child) => CustomPaint(
                size: Size.infinite,
                painter: FaceOvalGuidePainter(
                  borderColor: const Color(0xFF38BDF8),
                  borderWidth: 3,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AMBIL FOTO WAJAH',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Verifikasi biometrik presensi RAG',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
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
                              _statusText,
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

          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Utama: Selalu mencolok, aktif, dan langsung mengambil foto presensi
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1), // Indonusa Blue
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (!_isCameraReady || _isCapturing)
                          ? null
                          : _captureManually,
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 22),
                      label: Text(
                        _isCapturing
                            ? 'Menyimpan Foto...'
                            : 'Ambil Foto Sekarang',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tombol Sakelar / Bantuan Mode
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    onPressed: _isCapturing
                        ? null
                        : () {
                            if (_isAutoRunning) {
                              _stopAutoCapture();
                              setState(() => _captureMode = FaceCaptureMode.manual);
                            } else {
                              setState(() => _captureMode = FaceCaptureMode.auto);
                              _startAutoCapture();
                            }
                          },
                    icon: Icon(
                      _isAutoRunning
                          ? Icons.pause_circle_outline_rounded
                          : Icons.auto_mode_rounded,
                      size: 17,
                      color: const Color(0xFF38BDF8),
                    ),
                    label: Text(
                      _isAutoRunning
                          ? 'Jeda Deteksi Otomatis'
                          : 'Aktifkan Deteksi Wajah Otomatis',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              ] else ...[
                const Icon(Icons.camera_alt_outlined,
                    size: 44, color: Color(0xFF38BDF8)),
                const SizedBox(height: 16),
                const Text(
                  'Kamera Belum Aktif',
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
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _initCamera,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                ),
                const SizedBox(height: 8),
                if (!FaceDetectionService.isSupported)
                  const Text(
                    'Pada browser, izinkan akses kamera dari alamat situs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => openAppSettings(),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Buka Pengaturan Izin'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
