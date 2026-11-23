import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/services/app_permission_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;
  bool _torchOn = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Mode presensi: true = Masuk (Clock In), false = Pulang (Clock Out)
  bool _isClockIn = true;
  String? _attendanceResult;
  bool _isSuccess = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(_pulseCtrl);

    // Pastikan izin kamera aktif untuk scanner QR maupun foto wajah.
    unawaited(AppPermissionService.requestCamera());

    // Auto-select mode: jika belum clock in -> Masuk, jika sudah clock in -> Pulang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(attendanceProvider);
      setState(() {
        _isClockIn = !state.hasClockedIn;
      });
      // Segarkan koordinat GPS
      ref.read(attendanceProvider.notifier).checkLocationAndDistance();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // Dipanggil saat QR code terdeteksi kamera
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || _loading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _processAttendance(qrCode: barcode.rawValue);
  }

  // Proses presensi baik lewat scan QR maupun tombol capture kamera
  Future<void> _processAttendance({String? qrCode}) async {
    if (_hasScanned || _loading) return;

    setState(() {
      _hasScanned = true;
      _loading = true;
    });

    try {
      _scannerController.stop();
    } catch (_) {}

    // Amankan foto wajah live dari kamera depan. Tanpa foto ini backend
    // tidak akan melakukan verifikasi biometrik dan presensi ditolak.
    final faceImage = await _captureFaceImage();
    if (faceImage == null) {
      if (mounted) {
        setState(() {
          _hasScanned = false;
          _loading = false;
        });
        try {
          _scannerController.start();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto wajah wajib diambil sebelum presensi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final notifier = ref.read(attendanceProvider.notifier);
    final response = _isClockIn
        ? await notifier.clockIn(qrCode: qrCode, faceImage: faceImage)
        : await notifier.clockOut(faceImage: faceImage);

    if (mounted) {
      setState(() {
        _loading = false;
        _isSuccess = response.success;
        _attendanceResult = response.message;
      });
    }
  }

  /// Ambil foto wajah dari halaman kamera live. Halaman tersebut langsung
  /// menyalakan kamera depan dan mendukung mode auto/manual sesuai pengaturan.
  /// Jika pengguna membatalkan, presensi dibatalkan (tidak ada foto rekaan).
  Future<String?> _captureFaceImage() async {
    try {
      await AppPermissionService.requestCamera();
      if (!mounted) return null;
      final captured = await context.push<String>('/face-capture');
      if (captured == null || captured.trim().isEmpty) return null;
      return captured;
    } catch (e) {
      if (kDebugMode) debugPrint('[Scanner] gagal mengambil foto wajah: $e');
      return null;
    }
  }

  void _reset() {
    setState(() {
      _hasScanned = false;
      _loading = false;
      _attendanceResult = null;
    });
    try {
      _scannerController.start();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final attState = ref.watch(attendanceProvider);
    final officeName = attState.nearestOffice?.name ?? '-';
    final distanceText = attState.currentDistanceMeters != null
        ? '${attState.currentDistanceMeters!.round()}m'
        : '-';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          // Deteksi swipe ke kanan untuk menutup scanner dengan animasi morphing kembali ke tombol center
          if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
            Navigator.of(context).maybePop();
          }
        },
        child: Stack(
          children: [
          // 1. Live Camera Feed
          if (!_hasScanned)
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

          // Dark overlay ketika scan selesai
          if (_hasScanned)
            Container(color: const Color(0xFF0F172A)),

          // 2. Top Header & Navigasi
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isClockIn
                                    ? 'Presensi Masuk (Clock In)'
                                    : 'Presensi Pulang (Clock Out)',
                                style: AppTextStyles.titleLarge
                                    .copyWith(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                'Foto wajah live + GPS akan diverifikasi server RAG',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (!_hasScanned)
                          IconButton(
                            icon: Icon(
                              _torchOn ? Icons.flash_on : Icons.flash_off,
                              color: _torchOn ? Colors.amber : Colors.white,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() => _torchOn = !_torchOn);
                              _scannerController.toggleTorch();
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Toggle Mode Presensi (Masuk vs Pulang)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_hasScanned) {
                                  setState(() => _isClockIn = true);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isClockIn
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Clock In (Masuk)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_hasScanned) {
                                  setState(() => _isClockIn = false);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !_isClockIn
                                      ? const Color(0xFFE65100)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Clock Out (Pulang)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Badge Status GPS & Radius Kampus (Fungsi dari indonusa/absen)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: attState.isWithinRadius
                              ? AppColors.success.withValues(alpha: 0.4)
                              : AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: attState.isWithinRadius
                                ? AppColors.success
                                : AppColors.error,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$officeName ($distanceText)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: attState.isWithinRadius
                                  ? AppColors.success.withValues(alpha: 0.25)
                                  : AppColors.error.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              attState.isWithinRadius
                                  ? 'Radius Valid'
                                  : 'Luar Radius',
                              style: TextStyle(
                                color: attState.isWithinRadius
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Scan Frame atau Panel Hasil
          if (!_hasScanned)
            _buildScanFrame()
          else
            _buildResultPanel(),

          // 4. Bottom Controls (Scan QR / Tombol Capture Kamera Langsung)
          if (!_hasScanned)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Tombol Presensi Langsung Kamera & GPS (Fitur indonusa/absen)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _processAttendance(),
                        icon: const Icon(Icons.camera_alt_rounded, size: 20),
                        label: Text(
                          _isClockIn
                              ? 'Konfirmasi Absen Masuk Sekarang'
                              : 'Konfirmasi Absen Pulang Sekarang',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isClockIn
                              ? AppColors.primary
                              : const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Atau arahkan kamera tepat ke QR Code di dinding area kantor',
                      style: AppTextStyles.caption.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
  }

  Widget _buildScanFrame() {
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.65;

    return Center(
      child: SizedBox(
        width: frameSize,
        height: frameSize,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (ctx, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: child,
          ),
          child: Stack(
            children: [
              ..._buildCorners(frameSize),
              _ScanLine(frameSize: frameSize),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCorners(double size) {
    final c = _isClockIn ? AppColors.primaryLight : const Color(0xFFFFB74D);
    const thick = 3.5;
    const len = 28.0;
    const r = 8.0;

    Widget corner({
      required Alignment align,
      required bool flipH,
      required bool flipV,
    }) {
      return Align(
        alignment: align,
        child: Transform.scale(
          scaleX: flipH ? -1 : 1,
          scaleY: flipV ? -1 : 1,
          child: SizedBox(
            width: len,
            height: len,
            child: CustomPaint(painter: _CornerPainter(c, thick, r)),
          ),
        ),
      );
    }

    return [
      corner(align: Alignment.topLeft, flipH: false, flipV: false),
      corner(align: Alignment.topRight, flipH: true, flipV: false),
      corner(align: Alignment.bottomLeft, flipH: false, flipV: true),
      corner(align: Alignment.bottomRight, flipH: true, flipV: true),
    ];
  }

  Widget _buildResultPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _loading
                  ? Colors.white12
                  : _isSuccess
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.error.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loading) ...[
                const SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Memverifikasi Lokasi & Presensi...',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mengirim data GPS & biometric ke server RAG',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
                ),
              ] else ...[
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: _isSuccess ? AppColors.success : AppColors.error,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isSuccess ? 'Presensi Berhasil!' : 'Presensi Gagal',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _attendanceResult ?? 'Data presensi berhasil dicatat.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatDate(DateTime.now()),
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Scan Lagi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isSuccess ? AppColors.success : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Selesai'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _ScanLine extends StatefulWidget {
  final double frameSize;
  const _ScanLine({required this.frameSize});

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.05, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Positioned(
        top: widget.frameSize * _anim.value,
        left: 8,
        right: 8,
        child: Container(
          height: 2.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              AppColors.primaryLight.withValues(alpha: 0.9),
              Colors.transparent,
            ]),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _CornerPainter(this.color, this.strokeWidth, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
