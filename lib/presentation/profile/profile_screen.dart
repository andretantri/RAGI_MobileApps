import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/rag_module_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/router/app_router.dart';
import '../common/app_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader(context, ref, user)),
          SliverToBoxAdapter(child: _buildInfoCards(user)),
          SliverToBoxAdapter(child: _buildMenuSection(context, ref)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, WidgetRef ref, UserModel? user) {
    final schedule = ref.watch(scheduleProvider).schedule;
    final isDosen = user?.isDosen ?? false;
    final scheduleName = isDosen ? schedule?.lecturerName.trim() ?? '' : '';
    final scheduleNidn = isDosen ? schedule?.nidn.trim() ?? '' : '';

    // Samakan dengan Jadwal Mengajar: nama dosen & NIDN berasal dari SIAKAD.
    final rawName = scheduleName.isNotEmpty
        ? scheduleName
        : (user?.displayName ?? 'Pegawai Indonusa');
    final rawId = scheduleNidn.isNotEmpty
        ? scheduleNidn
        : (user?.displayId ?? '-');
    final name = rawName;
    final id = rawId;
    final idLabel = scheduleNidn.isNotEmpty
        ? 'NIDN'
        : (user?.displayIdLabel ?? 'NIP');
    final initial = user?.avatarInitial ?? 'ST';
    final role = user != null
        ? (user.isDosen ? 'Dosen Pengajar' : user.position)
        : 'Pegawai';
    final unit = user?.department ?? 'Politeknik Indonusa Surakarta';

    return AppHeader(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          // Header typography konsisten dengan Beranda, Notifikasi, & Modul
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akun & Kepegawaian',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profil Saya',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'SSO Terpadu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Avatar Interaktif — Ketuk untuk Mengganti Foto Profil
          InkWell(
            onTap: () => _showChangePhotoModal(context, ref, user),
            borderRadius: BorderRadius.circular(50),
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 3),
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(user, initial),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18.5,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$idLabel: $id',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _Chip(role),
              _Chip(unit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(UserModel? user, String initial) {
    if (user?.avatarBase64 != null && user!.avatarBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(user.avatarBase64!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      return Image.network(
        user.avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
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
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Pilih gambar dari Galeri atau Kamera langsung
  Future<void> _pickProfileImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
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

      if (context.mounted) {
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
                            ? 'Foto kamera berhasil diperbarui & disimpan.'
                            : 'Foto dari galeri berhasil diperbarui & disimpan.'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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

  /// Modal Ganti Foto Profil (Galeri atau Kamera) & Sinkronisasi ke RAG Backend
  void _showChangePhotoModal(
      BuildContext context, WidgetRef ref, UserModel? user) {
    final hasCustomPhoto =
        (user?.avatarBase64 != null && user!.avatarBase64!.isNotEmpty) ||
            (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty);
    final initial = user?.avatarInitial ?? 'ST';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubah Foto Profil',
                            style: TextStyle(
                                fontSize: 16.5, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih foto dari galeri perangkat atau ambil dengan kamera.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current Avatar Preview
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryDark,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(user, initial),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasCustomPhoto
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasCustomPhoto
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          hasCustomPhoto
                              ? 'Foto Kustom Aktif'
                              : 'Inisial Nama Akun: $initial',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasCustomPhoto
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Opsi 1: Pilih dari Galeri (Gallery)
                _PhotoOptionTile(
                  icon: Icons.photo_library_rounded,
                  iconColor: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                  title: 'Pilih dari Galeri',
                  subtitle:
                      'Unggah foto profil dari penyimpanan galeri perangkat',
                  onTap: () {
                    Navigator.pop(modalCtx);
                    _pickProfileImage(context, ref, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),

                // Opsi 2: Ambil Foto Kamera (Take a Photo)
                _PhotoOptionTile(
                  icon: Icons.camera_alt_rounded,
                  iconColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                  title: 'Ambil Foto (Kamera)',
                  subtitle:
                      'Buka kamera perangkat untuk mengambil foto langsung',
                  onTap: () {
                    Navigator.pop(modalCtx);
                    _pickProfileImage(context, ref, ImageSource.camera);
                  },
                ),

                // Opsi 3: Hapus / Reset ke Inisial (jika foto kustom ada)
                if (hasCustomPhoto) ...[
                  const SizedBox(height: 10),
                  _PhotoOptionTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.error,
                    bgColor: AppColors.errorLight,
                    title: 'Hapus Foto Profil',
                    subtitle: 'Kembalikan ke inisial nama bawaan ($initial)',
                    onTap: () async {
                      Navigator.pop(modalCtx);
                      final updated = await ref
                          .read(authProvider.notifier)
                          .updateAvatar(removeAvatar: true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor:
                                updated ? AppColors.primaryDark : AppColors.error,
                            content: Text(updated
                                ? 'Foto profil berhasil dihapus dan kembali ke inisial nama.'
                                : 'Foto dihapus di perangkat, tetapi gagal disinkronkan ke server.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards(UserModel? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              label: 'Peran Akun',
              value: user?.isDosen == true ? 'Dosen' : 'Tendik',
              icon: Icons.badge_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InfoCard(
              label: 'Unit Kerja',
              value: user?.department ?? 'General',
              icon: Icons.apartment_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InfoCard(
              label: 'Status',
              value: user == null
                  ? '-'
                  : (user.isActive ? 'Aktif' : 'Nonaktif'),
              icon: Icons.verified_outlined,
              valueColor:
                  user?.isActive == true ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isDosen = auth.user?.isDosen ?? false;
    // Sama seperti tab Modul: katalog modul dari web RAG menjadi sumber
    // kebenaran akses. Bila belum termuat, izinkan sinkronisasi lama agar
    // menu tidak berkedip saat profil dibuka.
    final moduleCodes = ref
            .watch(myRagModulesProvider(auth.token))
            .valueOrNull
            ?.map((module) => module.code.toLowerCase())
            .toSet() ??
        <String>{};
    final sections = <Map<String, dynamic>>[
      {
        'section': 'Kepegawaian',
        'items': <Map<String, dynamic>>[
          {
            'icon': Icons.person_outline,
            'label': 'Data Diri & Biodata',
            'color': AppColors.primary,
            'route': '/profile/data-diri',
          },
          {
            'icon': Icons.folder_outlined,
            'label': 'Dokumen E-File',
            'color': AppColors.primaryMid,
            'route': '/features/e-file',
          },
          {
            'icon': Icons.receipt_long_outlined,
            'label': 'Riwayat Payroll',
            'color': AppColors.sikeu,
            'route': '/features/payroll',
          },
          {
            'icon': Icons.request_quote_outlined,
            'label': 'Pengajuan Saya',
            'color': AppColors.sikeu,
            'route': '/features/pengajuan-sikeu',
          },
        ],
      },
      {
        // Tendik tidak punya jadwal mengajar/nilai/bimbingan, jadi judul
        // bagian ini cukup menyebut referral saja.
        'section': isDosen ? 'Akademik, Riset & Referral' : 'Layanan & Referral',
        'items': <Map<String, dynamic>>[
          {
            'icon': Icons.school_outlined,
            'label': 'Jadwal Mengajar',
            'color': AppColors.siakad,
            'route': '/schedule',
            'dosenOnly': true,
            'module': 'siakad',
          },
          {
            'icon': Icons.assignment_turned_in_outlined,
            'label': 'Input Nilai (KHS & OBE)',
            'color': const Color(0xFF0284C7),
            'route': '/siakad/grading',
            'dosenOnly': true,
            'module': 'siakad',
          },
          {
            'icon': Icons.supervisor_account_outlined,
            'label': 'Bimbingan Akademik (DPA)',
            'color': const Color(0xFF059669),
            'route': '/siakad/advising',
            'dosenOnly': true,
            'module': 'siakad',
          },
          {
            'icon': Icons.science_outlined,
            'label': 'Proposal & Hibah',
            'color': AppColors.sippm,
            'route': '/features/proposal-hibah',
            'dosenOnly': true,
            'module': 'sippm',
          },
          {
            'icon': Icons.menu_book_outlined,
            'label': 'Bahan Ajar & RPS',
            'color': const Color(0xFF6366F1),
            'route': '/features/bahan-ajar',
            'dosenOnly': true,
            'module': 'lms',
          },
          {
            // Referral bersifat self-service untuk semua dosen & tendik.
            'icon': Icons.card_giftcard_outlined,
            'label': 'Referral SPMB',
            'color': AppColors.spmb,
            'route': '/features/referral-spmb',
          },
        ],
      },
      {
        'section': 'Pengaturan & Info',
        'items': <Map<String, dynamic>>[
          {
            'icon': Icons.apps_outlined,
            'label': 'Buka Menu Modul',
            'subtitle': 'Sesuai akses yang diberikan web RAG',
            'color': AppColors.primaryMid,
            'action': 'open_modules',
          },
          {
            'icon': Icons.security_rounded,
            'label': 'Keamanan Biometrik',
            'color': const Color(0xFF0D47A1),
            'route': '/profile/biometric',
          },
          {
            'icon': Icons.notifications_none_outlined,
            'label': 'Preferensi Notifikasi',
            'color': AppColors.warning,
            'route': '/profile/notification-preferences',
          },
          {
            'icon': Icons.info_outline_rounded,
            'label': 'Tentang Aplikasi',
            'color': AppColors.textSecondary,
            'route': '/profile/about',
          },
          {
            'icon': Icons.devices_rounded,
            'label': 'Informasi Sistem',
            'color': const Color(0xFF0284C7),
            'action': 'system_info',
          },
        ],
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...sections.map((sec) {
            final allItems =
                (sec['items'] as List).cast<Map<String, dynamic>>();
            final items = allItems.where((item) {
              if (item['dosenOnly'] == true && !isDosen) return false;
              final moduleCode = item['module'] as String?;
              if (moduleCode != null &&
                  moduleCodes.isNotEmpty &&
                  !moduleCodes.contains(moduleCode)) {
                return false;
              }
              return true;
            }).toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sec['section'] as String,
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final isLast = i == items.length - 1;
                        return Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (item['color'] as Color)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(item['icon'] as IconData,
                                      color: item['color'] as Color, size: 20),
                                ),
                                title: Text(item['label'] as String,
                                    style: AppTextStyles.bodyMedium),
                                subtitle: item['subtitle'] != null
                                    ? Text(item['subtitle'] as String,
                                        style: AppTextStyles.caption)
                                    : null,
                                trailing: const Icon(Icons.chevron_right,
                                    size: 18, color: AppColors.textSecondary),
                                onTap: () {
                                  if (item['action'] == 'system_info') {
                                    _showSystemInfoModal(context);
                                    return;
                                  }
                                  if (item['action'] == 'open_modules') {
                                    context.go('/modules');
                                    return;
                                  }
                                  final label = item['label'] as String? ?? '';
                                  final route = item['route'] as String?;
                                  if (route != null && route.isNotEmpty) {
                                    context.push(route);
                                    return;
                                  }
                                  context.push(
                                    '/under-construction',
                                    extra: {
                                      'title': label,
                                      'category': sec['section'],
                                      'icon': item['icon'],
                                      'color': item['color'],
                                    },
                                  );
                                },
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                  height: 1,
                                  indent: 56,
                                  color: AppColors.divider),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),

          // Logout button
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text('Keluar dari Akun',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  useRootNavigator: true,
                  builder: (dialogCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text('Keluar?', style: AppTextStyles.headlineSmall),
                    content: const Text(
                        'Apakah Anda yakin ingin keluar dari akun?',
                        style: TextStyle(fontSize: 13.5)),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(dialogCtx, rootNavigator: true).pop(),
                        child: Text('Batal',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogCtx, rootNavigator: true).pop();
                          AppRouter.router.go('/login');
                          ref.read(attendanceProvider.notifier).reset();
                          ref.read(scheduleProvider.notifier).reset();
                          await ref.read(authProvider.notifier).logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Keluar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Informasi Sistem & Versi Footer
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  'MyIn-U Staff • Versi 1.1.1 (Build 31)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ekosistem SIAKAD & SIMPEG Terpadu',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Politeknik Indonusa Surakarta',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.65),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.devices_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Sistem',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'MyIn-U Staff • Ekosistem Terpadu',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                children: [
                  _SystemInfoRow(
                    label: 'Versi Aplikasi',
                    value: 'v1.1.0',
                    isHighlight: true,
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _SystemInfoRow(
                    label: 'Kode Build (Version Code)',
                    value: 'Build 31 (Release)',
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _SystemInfoRow(
                    label: 'Arsitektur Memori',
                    value: '16 KB Page Aligned (Android 15+)',
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _SystemInfoRow(
                    label: 'Lingkungan Backend',
                    value: 'Server Produksi RAG (HTTPS)',
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _SystemInfoRow(
                    label: 'Otentikasi',
                    value: 'Single Sign-On (SSO Terpadu)',
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _SystemInfoRow(
                    label: 'Keamanan Biometrik',
                    value: 'ML Kit Face AI + Hardware Auth',
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _SystemInfoRow(
                    label: 'Institusi',
                    value: 'Politeknik Indonusa Surakarta',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SystemInfoRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoOptionTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: Colors.white)),
    );
  }
}



class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryMid),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}
