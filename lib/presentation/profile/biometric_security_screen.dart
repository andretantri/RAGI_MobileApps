import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/face_capture_preferences.dart';
import '../common/app_header.dart';

class BiometricSecurityScreen extends ConsumerStatefulWidget {
  const BiometricSecurityScreen({super.key});

  @override
  ConsumerState<BiometricSecurityScreen> createState() =>
      _BiometricSecurityScreenState();
}

class _BiometricSecurityScreenState
    extends ConsumerState<BiometricSecurityScreen>
    with SingleTickerProviderStateMixin {
  bool _fingerprintEnabled = true;
  FaceCaptureMode _faceCaptureMode = FaceCaptureMode.auto;
  bool _isLoading = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadPreferences();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = await FaceCapturePreferences.load();
    if (mounted) {
      setState(() {
        _fingerprintEnabled = prefs.getBool('biometric_fingerprint_enabled') ?? true;
        _faceCaptureMode = mode;
      });
    }
  }

  Future<void> _setFaceCaptureMode(FaceCaptureMode mode) async {
    setState(() => _faceCaptureMode = mode);
    await FaceCapturePreferences.save(mode);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == FaceCaptureMode.auto
              ? 'Take otomatis berbasis deteksi wajah diaktifkan'
              : 'Take manual per pose diaktifkan',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleFingerprint(bool val) async {
    setState(() => _fingerprintEnabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_fingerprint_enabled', val);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          val
              ? 'Autentikasi sidik jari perangkat diaktifkan'
              : 'Autentikasi sidik jari perangkat dinonaktifkan',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openFaceEnrollmentScreen() {
    context.push('/profile/face-enrollment');
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 28),
            const SizedBox(width: 10),
            Text('Hapus Data Wajah?', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: const Text(
          'Embedding biometrik wajah akan dihapus dari sistem. Anda wajib melakukan pendaftaran ulang sebelum dapat presensi dengan verifikasi wajah.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              setState(() => _isLoading = true);
              final res = await AttendanceService.resetFace();
              if (mounted) {
                if (res.success) {
                  ref.read(authProvider.notifier).updateFaceEnrollment(
                        isEnrolled: false,
                        enrolledAt: null,
                      );
                }
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor:
                        res.success ? AppColors.primaryDark : AppColors.error,
                    content: Text(res.message),
                  ),
                );
              }
            },
            child: const Text('Hapus Wajah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isEnrolled = user?.isFaceEnrolled ?? false;
    final enrolledDate = user?.faceEnrolledAt;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header dengan Background Image background.jpeg
            AppHeader(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/profile');
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keamanan Biometrik',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proteksi Biometrik Pegawai',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Verifikasi kehadiran cepat berbasis AI Facial Mesh & Sidik Jari hardware.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Section: Pengenalan Wajah (Face Recognition)
            Text(
              'BIOMETRIK WAJAH (FACE RECOGNITION)',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.face_rounded,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Wajah Terdaftar (Maksimal 1)',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isEnrolled
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEnrolled
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              size: 12,
                              color: isEnrolled
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isEnrolled ? 'Terdaftar' : 'Belum Ada',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isEnrolled
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (isEnrolled) ...[
                    // Item Card Wajah Terdaftar
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: AppColors.primary, size: 28),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Sampel Wajah Utama',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '1/1',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  enrolledDate != null
                                      ? 'Direkam pada: $enrolledDate'
                                      : 'Tanggal perekaman tidak tersedia dari server.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Format: Centroid Embedding AI (512 Dimensi)',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryMid,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tombol Aksi: Retake & Hapus
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _openFaceEnrollmentScreen,
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Re-take'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed:
                                _isLoading ? null : _showResetConfirmationDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(
                                  color: AppColors.error, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 20),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Belum ada wajah
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.no_accounts_rounded,
                              color: AppColors.warning, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Anda belum mendaftarkan sampel wajah. Daftarkan sekarang untuk mengaktifkan fitur presensi wajah otomatis.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.warning,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _openFaceEnrollmentScreen,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Daftarkan Wajah Sekarang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2b. Pengaturan mode ambil wajah (auto deteksi objek / manual).
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_mode_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MODE AMBIL FOTO WAJAH',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<FaceCaptureMode>(
                      segments: const [
                        ButtonSegment(
                          value: FaceCaptureMode.auto,
                          label: Text('Otomatis'),
                          icon: Icon(Icons.auto_mode_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: FaceCaptureMode.manual,
                          label: Text('Manual'),
                          icon: Icon(Icons.touch_app_rounded, size: 16),
                        ),
                      ],
                      selected: <FaceCaptureMode>{_faceCaptureMode},
                      onSelectionChanged: (selection) {
                        if (selection.isNotEmpty) {
                          _setFaceCaptureMode(selection.first);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _faceCaptureMode == FaceCaptureMode.auto
                        ? 'Kamera langsung menyala dan foto diambil otomatis saat wajah terdeteksi di dalam oval.'
                        : 'Kamera langsung menyala, tetapi foto diambil sendiri untuk setiap pose.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Section: Biometrik Sidik Jari (Fingerprint Hardware)
            Text(
              'BIOMETRIK SIDIK JARI (FINGERPRINT)',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _fingerprintEnabled
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          color: _fingerprintEnabled
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 26,
                        ),
                      ),
                      title: Text(
                        'Presensi & Login Sidik Jari',
                        style: AppTextStyles.titleMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Buka kunci sesi dan konfirmasi presensi menggunakan sensor fingerprint HP.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      value: _fingerprintEnabled,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      onChanged: _toggleFingerprint,
                    ),
                  ),

                  const Divider(height: 24),

                  // Edukasi / Penjelasan: Apakah dari Google atau Perangkat?
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.info, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Sumber Data Sidik Jari',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sidik jari BUKAN berasal dari Google ataupun server luar, melainkan langsung dari data sidik jari yang telah Anda daftarkan di menu Pengaturan Keamanan HP/perangkat Anda sendiri.\n\nSistem Android (BiometricPrompt) & iOS memverifikasi sidik jari di dalam chip hardware terenkripsi (Secure Enclave / Keystore). Aplikasi tidak pernah menerima salinan sidik jari, melainkan hanya status konfirmasi berhasil/gagal.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.45,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Kepatuhan Regulasi PDP
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppColors.success, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sesuai UU No. 27 Tahun 2022 (Perlindungan Data Pribadi), data biometrik disimpan secara terenkripsi dan hanya digunakan untuk validasi absensi pegawai Politeknik Indonusa Surakarta.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48), // Padding bawah yang rapi
          ],
        ),
      ),
    ],
  ),
),
);
}
}
