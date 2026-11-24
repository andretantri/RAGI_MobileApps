import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/models/teaching_schedule_model.dart';
import '../../core/models/face_verification_info.dart';
import '../../core/services/location_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Quick actions dinamis terspesialisasi untuk Dosen vs Tendik / Staff
  List<Map<String, dynamic>> _getQuickActions(bool isDosen) {
    if (isDosen) {
      return [
        {
          'icon': Icons.beach_access_rounded,
          'label': 'Ajukan Cuti',
          'color': const Color(0xFFE65100),
          'route': '/simpeg/cuti',
        },
        {
          'icon': Icons.assignment_turned_in_rounded,
          'label': 'Input Nilai',
          'color': AppColors.siakad,
          'route': '/siakad/grading',
        },
        {
          'icon': Icons.supervisor_account_rounded,
          'label': 'Bimbingan PA',
          'color': const Color(0xFF059669),
          'route': '/siakad/advising',
        },
        {
          'icon': Icons.menu_book_rounded,
          'label': 'Jurnal BAP',
          'color': const Color(0xFF0F766E),
          'route': '/siakad/perkuliahan',
        },
      ];
    } else {
      return [
        {
          'icon': Icons.beach_access_rounded,
          'label': 'Ajukan Cuti',
          'color': const Color(0xFFE65100),
          'route': '/simpeg/cuti',
        },
        {
          'icon': Icons.calendar_month_rounded,
          'label': 'Rekap Absensi',
          'color': const Color(0xFF0284C7),
          'route': '/simpeg/rekap',
        },
        {
          'icon': Icons.campaign_rounded,
          'label': 'Pengumuman',
          'color': const Color(0xFF7C3AED),
          'route': '/simpeg/announcements',
        },
        {
          'icon': Icons.badge_rounded,
          'label': 'Portal SIMPEG',
          'color': AppColors.primary,
          'route': '/simpeg',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDosen = user?.isDosen ?? true;
    final attState = ref.watch(attendanceProvider);
    final scheduleState = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).checkSession();
          await ref.read(attendanceProvider.notifier).fetchTodayStatus();
          final locCheck = await LocationService.checkLocationPrerequisites(requestIfNotGranted: false);
          if (locCheck.isReady) {
            await ref.read(attendanceProvider.notifier).checkLocationAndDistance();
          }
          await ref.read(scheduleProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Header dengan background image background.jpeg & profil riil API
            SliverToBoxAdapter(child: _buildHeader(context, user, scheduleState)),

            // 2. Akses Cepat di atas Presensi
            SliverToBoxAdapter(child: _buildQuickActions(context, isDosen)),

            // 3. Card Absensi terintegrasi GPS & Presensi Pegawai
            SliverToBoxAdapter(child: _buildAttendanceCard(context, attState)),

            // 4. Jadwal Mengajar Dosen (Otomatis & ada pengingat)
            if (isDosen)
              SliverToBoxAdapter(
                  child: _buildDosenTeachingSchedule(context, scheduleState)),

            // 4b. Card Operasional Khusus Tendik / Staff (Non-Dosen)
            if (!isDosen)
              SliverToBoxAdapter(child: _buildStaffOperationalCard(context, user)),

            // Bottom padding agar tidak tertutup navigation bar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // 1. Header dengan Background Image background.jpeg & profil riil API
  Widget _buildHeader(
    BuildContext context,
    UserModel? user,
    ScheduleState scheduleState,
  ) {
    final isDosen = user?.isDosen ?? true;
    final schedule = scheduleState.schedule;
    final scheduleName = isDosen ? schedule?.lecturerName.trim() ?? '' : '';
    final scheduleNidn = isDosen ? schedule?.nidn.trim() ?? '' : '';

    // Sumber kebenaran identitas dosen adalah data jadwal mengajar SIAKAD
    // (nama + NIDN), sama seperti yang tampil di halaman Jadwal Mengajar.
    final rawName = scheduleName.isNotEmpty
        ? scheduleName
        : (user?.displayName ?? '-');
    final rawId = scheduleNidn.isNotEmpty
        ? scheduleNidn
        : (user?.displayId ?? '-');
    final name = rawName;
    final id = rawId;
    final idLabel = scheduleNidn.isNotEmpty
        ? 'NIDN'
        : (user?.displayIdLabel ?? 'NIP');
    final role = user != null
        ? (user.isDosen ? 'Dosen Pengajar' : user.position)
        : '-';
    final unit = (user?.department != null && user!.department.isNotEmpty)
        ? user.department
        : '-';
    final initial = user?.avatarInitial ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            // 1. Gambar latar background.jpeg tampil tegas & tajam
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.jpeg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (ctx, err, stack) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D47A1), Color(0xFF00388F)],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Overlay gradien biru transparan elegan untuk kontras teks yang optimal
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0D47A1).withValues(alpha: 0.38),
                      const Color(0xFF002A7A).withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Header Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _greetingText(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            name,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 21,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _HeaderBadge(
                                icon: (user?.isDosen ?? true)
                                    ? Icons.school_rounded
                                    : Icons.badge_rounded,
                                label: role,
                              ),
                              _HeaderBadge(
                                icon: Icons.account_balance_rounded,
                                label: unit,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.credit_card_outlined,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$idLabel: $id',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.80),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Avatar profil dengan kamera selector & indikator aktif
                    GestureDetector(
                      onTap: () => _showAvatarOptions(context, user),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.65),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildHomeAvatar(user, initial),
                            ),
                          ),
                          // Badge kamera di kanan bawah avatar
                          Positioned(
                            bottom: -1,
                            right: -1,
                            child: Container(
                              padding: const EdgeInsets.all(4.5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 12,
                                color: Colors.white,
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
          ],
        ),
      ),
    );
  }

  /// Pilih foto avatar dari Galeri atau Kamera langsung dari Header
  Future<void> _pickAvatarImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      final updated = await ref.read(authProvider.notifier).updateAvatar(
            avatarBase64: base64String,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: updated ? AppColors.primaryDark : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    !updated
                        ? 'Foto tersimpan di perangkat, tetapi gagal disinkronkan ke server.'
                        : (source == ImageSource.camera
                            ? 'Foto profil dari kamera berhasil diperbarui.'
                            : 'Foto profil dari galeri berhasil diperbarui.'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text('Gagal memilih foto: $e'),
          ),
        );
      }
    }
  }

  /// Dialog modal pemilihan sumber avatar
  void _showAvatarOptions(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto Profil Pengguna',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih sumber foto atau buka profil untuk informasi lengkap',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF0D47A1)),
                ),
                title: const Text('Ambil Foto Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan kamera langsung untuk swafoto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatarImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF16A34A)),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih gambar yang tersimpan di perangkat'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatarImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Color(0xFF64748B)),
                ),
                title: const Text('Buka Profil Lengkap',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Lihat detail akun dan pengaturan data diri'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/profile');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeAvatar(UserModel? user, String initial) {
    if (user?.avatarBase64 != null && user!.avatarBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(user.avatarBase64!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {}
    }
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      return Image.network(
        user.avatarUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) => Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
      );
    }
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }

  // 2. Card Absensi Terintegrasi Function Absensi indonusa/absen
  Widget _buildAttendanceCard(BuildContext context, AttendanceState state) {
    final hasIn = state.hasClockedIn;
    final hasOut = state.hasClockedOut;
    final isDone = state.isCompleted;

    final clockInText = state.clockInTime ?? '-- : --';
    final clockOutText = state.clockOutTime ?? '-- : --';

    final officeName = state.nearestOffice?.name ?? '-';
    final distanceText = state.currentDistanceMeters != null
        ? '${state.currentDistanceMeters!.round()} meter'
        : '-';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header status absensi
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presensi Pegawai Hari Ini',
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                    ),
                    Text(
                      _formatToday(),
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Status Badge Dinamis
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : hasIn
                          ? AppColors.successLight
                          : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDone
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : hasIn
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.primary
                            : hasIn
                                ? AppColors.success
                                : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isDone
                          ? 'Selesai'
                          : hasIn
                              ? 'Sudah Masuk'
                              : 'Belum Masuk',
                      style: AppTextStyles.caption.copyWith(
                        color: isDone
                            ? AppColors.primary
                            : hasIn
                                ? AppColors.success
                                : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Baris Waktu: MASUK : JAM | PULANG : JAM
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: [
                // Masuk
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: hasIn
                              ? AppColors.success.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.login_rounded,
                          color: hasIn ? AppColors.success : AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MASUK',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            clockInText,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hasIn ? AppColors.textPrimary : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Divider vertikal
                Container(
                  height: 32,
                  width: 1,
                  color: AppColors.divider,
                ),

                const SizedBox(width: 14),

                // Pulang
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: hasOut
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: hasOut ? AppColors.primary : AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PULANG',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            clockOutText,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hasOut ? AppColors.textPrimary : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Baris Lokasi Terdekat & Jarak GPS (Live dari LocationService)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi Terdekat:',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        officeName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge Jarak
                GestureDetector(
                  onTap: () {
                    ref.read(attendanceProvider.notifier).checkLocationAndDistance();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Memperbarui koordinat GPS...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.isWithinRadius
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: state.isWithinRadius
                            ? AppColors.success.withValues(alpha: 0.25)
                            : AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me_rounded,
                          color: state.isWithinRadius ? AppColors.success : AppColors.error,
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          distanceText,
                          style: AppTextStyles.caption.copyWith(
                            color: state.isWithinRadius ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (state.faceSimilarityScore != null ||
              state.minimumFaceSimilarity != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: state.faceSimilarityScore != null &&
                        state.minimumFaceSimilarity != null &&
                        state.faceSimilarityScore! < state.minimumFaceSimilarity!
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.faceSimilarityScore != null &&
                          state.minimumFaceSimilarity != null &&
                          state.faceSimilarityScore! < state.minimumFaceSimilarity!
                      ? AppColors.error.withValues(alpha: 0.25)
                      : AppColors.divider,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    state.faceSimilarityScore != null &&
                            state.minimumFaceSimilarity != null &&
                            state.faceSimilarityScore! <
                                state.minimumFaceSimilarity!
                        ? Icons.face_retouching_natural_rounded
                        : Icons.verified_user_outlined,
                    size: 18,
                    color: state.faceSimilarityScore != null &&
                            state.minimumFaceSimilarity != null &&
                            state.faceSimilarityScore! <
                                state.minimumFaceSimilarity!
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skor wajah: ${FaceVerificationInfo.formatPercent(state.faceSimilarityScore)} · minimum server: ${FaceVerificationInfo.formatPercent(state.minimumFaceSimilarity)}',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (state.faceVerificationMessage != null &&
                            state.faceVerificationMessage!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            state.faceVerificationMessage!,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (state.faceThresholdSource != null &&
                            state.faceThresholdSource!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            state.faceThresholdSource == 'database'
                                ? 'Batas berasal dari pengaturan web RAG yang tersimpan'
                                : 'Batas berasal dari konfigurasi server',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Tombol Aksi Presensi Wajah Kamera Dinamis
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Cek izin lokasi & GPS saat pengguna menekan tombol presensi
                final check = await LocationService.checkLocationPrerequisites();
                if (!context.mounted) return;
                if (!check.isReady) {
                  await LocationService.showLocationRequirementDialog(context, check);
                  return;
                }
                context.push('/scanner');
              },
              icon: Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.face_rounded,
                size: 20,
              ),
              label: Text(
                isDone
                    ? 'Presensi Hari Ini Lengkap'
                    : hasIn
                        ? 'Absen Wajah Pulang'
                        : 'Absen Wajah Masuk',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone
                    ? AppColors.success
                    : hasIn
                        ? const Color(0xFFE65100)
                        : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Informasi Mengajar Dosen Hari Ini (Otomatis & Ada Pengingat)
  Widget _buildDosenTeachingSchedule(
      BuildContext context, ScheduleState scheduleState) {
    final todayClasses = scheduleState.todayClasses;
    final allClasses = scheduleState.allClasses;
    final isLoading = scheduleState.isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section Mengajar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Jadwal Mengajar Hari Ini',
                        style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${todayClasses.length} Kelas',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Lihat Semua
              InkWell(
                onTap: () => context.push('/schedule'),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Banner Pengingat Otomatis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.alarm_on_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pengingat otomatis aktif H-15 menit sebelum setiap sesi kelas perkuliahan dimulai.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Daftar Card Kelas Mengajar atau State Kosong
          if (todayClasses.isNotEmpty)
            ...todayClasses.map((item) => _TeachingClassCard(item: item))
          else if (isLoading)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            InkWell(
              onTap: () => context.push('/schedule'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_available_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tidak ada kelas tatap muka hari ini',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            allClasses.isNotEmpty
                                ? '${allClasses.length} kelas terjadwal pada hari lain minggu ini. Ketuk untuk melihat.'
                                : 'Sinkronisasi jadwal SIAKAD RAG aktif.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 4b. Card Operasional Khusus Tenaga Kependidikan / Staff
  Widget _buildStaffOperationalCard(BuildContext context, UserModel? user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Operasional & Shift Kerja Pegawai',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Info SIMPEG',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Kerja Pegawai',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Detail jadwal tersedia di Portal SIMPEG',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Shortcut Cepat Status Cuti & Portal Kepegawaian (SIMPEG)
          InkWell(
            onTap: () => context.push('/simpeg'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFBFDBFE),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.beach_access_rounded,
                        color: Color(0xFF1D4ED8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cek sisa kuota cuti di Portal SIMPEG',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        Text(
                          'Ketuk untuk membuka Portal SIMPEG lengkap',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF1D4ED8), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Akses Cepat (di atas Card Presensi)
  Widget _buildQuickActions(BuildContext context, bool isDosen) {
    final actions = _getQuickActions(isDosen);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Akses Cepat',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go('/modules'),
                child: Row(
                  children: [
                    Text(
                      'Semua Modul',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryMid,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: AppColors.primaryMid,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((a) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    final route = a['route'] as String?;
                    if (route != null && route != '/modules') {
                      context.push(route);
                      return;
                    }
                    context.push(
                      '/under-construction',
                      extra: {
                        'title': a['label'] as String,
                        'category': 'Layanan Cepat Pegawai',
                        'subtitle':
                            'Layanan ${a['label']} sedang dipersiapkan untuk sinkronisasi langsung dengan sistem Project RAG Politeknik Indonusa.',
                        'icon': a['icon'] as IconData,
                        'color': a['color'] as Color,
                      },
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (a['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (a['color'] as Color).withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          a['icon'] as IconData,
                          color: a['color'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 28,
                        child: Text(
                          a['label'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi 👋';
    if (hour < 15) return 'Selamat Siang 👋';
    if (hour < 18) return 'Selamat Sore 👋';
    return 'Selamat Malam 👋';
  }

  String _formatToday() {
    final now = DateTime.now();
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
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
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}


// Widget Card Jadwal Mengajar Dosen
class _TeachingClassCard extends StatelessWidget {
  final TeachingClassItem item;
  const _TeachingClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/siakad/perkuliahan/${item.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isOngoing
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.divider,
            width: item.isOngoing ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris status & waktu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.isOngoing) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      item.status,
                      style: AppTextStyles.caption.copyWith(
                        color: item.statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.startTime} - ${item.endTime} WIB',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Nama Matakuliah
          Text(
            item.courseName,
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

          // Kode MK & Kelas
          Row(
            children: [
              Text(
                '${item.courseCode} • ${item.sks} SKS',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryMid,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${item.className}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Lokasi & Jumlah Mahasiswa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.room_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.room,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.group_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.studentCount} Mhs (Sesi ${item.session})',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tombol Aksi Dosen (Buka Presensi Mahasiswa & Jurnal BAP)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/siakad/perkuliahan/${item.id}'),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text(
                    'Presensi Kelas',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/siakad/perkuliahan/${item.id}'),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text(
                    'Materi LMS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}


class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

