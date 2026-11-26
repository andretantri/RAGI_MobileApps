import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_release_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/app_header.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _activeFeatures = [
    {
      'title': 'SIMPEG — Pengajuan Cuti & Izin',
      'desc':
          'Pengajuan cuti online sesuai master SIMPEG. Jenis cuti berdurasi tetap cukup memilih tanggal mulai; tanggal selesai dan jumlah hari dihitung otomatis. Riwayat persetujuan mengikuti data server.',
      'icon': Icons.beach_access_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFFE65100),
    },
    {
      'title': 'SIMPEG — Rekap Kehadiran & Log Bulanan',
      'desc':
          'Ringkasan kehadiran bulanan dan rincian log harian. Tanggal yang belum dilewati tidak ditampilkan; status cuti muncul bila dikirim backend.',
      'icon': Icons.calendar_month_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF0284C7),
    },
    {
      'title': 'SIMPEG — Pengumuman Kampus & Broadcast SDM',
      'desc':
          'Feed agenda dan pengumuman kampus terpadu dengan kategori filter, serta fitur broadcast push notifikasi khusus Admin SIMPEG.',
      'icon': Icons.campaign_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF7C3AED),
    },
    {
      'title': 'SIAKAD — Input Nilai OBE & KHS',
      'desc':
          'Input nilai komponen CPMK (Harian 20%, UTS 25%, UAS 35%, Praktik 20%), konversi predikat nilai huruf (A–E), dan simpan nilai ke database RAG.',
      'icon': Icons.assignment_turned_in_rounded,
      'badge': 'Aktif',
      'color': AppColors.siakad,
    },
    {
      'title': 'SIAKAD — Bimbingan Akademik (DPA) & KRS',
      'desc':
          'Daftar mahasiswa perwalian, review dan persetujuan/revisi KRS rencana studi semester, serta logbook catatan konsultasi PA.',
      'icon': Icons.supervisor_account_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF059669),
    },
    {
      'title': 'SIAKAD — Jurnal Perkuliahan & Presensi (BAP)',
      'desc':
          'Monitoring 16 pertemuan kelas, pembukaan sesi perkuliahan, rotasi token QR dinamis (15 detik), dan presensi manual mahasiswa.',
      'icon': Icons.menu_book_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF0F766E),
    },
    {
      'title': 'Role-Based Access Control (Dosen vs Tendik)',
      'desc':
          'Personalisasi cerdas menu beranda, aksi cepat, dan proteksi katalog modul berdasarkan peran Tenaga Pendidik vs Tenaga Kependidikan.',
      'icon': Icons.admin_panel_settings_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF1E3A8A),
    },
    {
      'title': 'Presensi GPS Geofencing',
      'desc':
          'Validasi kehadiran berdasarkan koordinat dan radius kantor yang dikirim server RAG, lengkap dengan pengecekan lokasi tiruan.',
      'icon': Icons.location_on_rounded,
      'badge': 'Aktif',
      'color': AppColors.success,
    },
    {
      'title': 'Keamanan Biometrik Wajah 3-Pose',
      'desc':
          'Pendaftaran 3 pose (Tegap, Nunduk, Mendongak) dikirim ke server RAG. Pengambilan bisa otomatis saat wajah terdeteksi atau manual.',
      'icon': Icons.face_retouching_natural_rounded,
      'badge': 'Aktif',
      'color': AppColors.primary,
    },
    {
      'title': 'Verifikasi Wajah Presensi (Server-Driven)',
      'desc':
          'Foto wajah live diambil saat presensi. Skor kemiripan dan batas minimal ditampilkan dari respons server RAG; aplikasi tidak menentukan ambang batas sendiri.',
      'icon': Icons.verified_user_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF38BDF8),
    },
    {
      'title': 'Autentikasi Sidik Jari (Hardware)',
      'desc':
          'Otentikasi cepat memanfaatkan sensor biometrik aman bawaan HP (Android BiometricPrompt / iOS Secure Enclave).',
      'icon': Icons.fingerprint_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF0284C7),
    },
    {
      'title': 'Jadwal Mengajar Dosen Real-time',
      'desc':
          'Informasi perkuliahan harian dan satu semester lengkap dengan kode ruangan, SKS, hari, dan pengingat kelas.',
      'icon': Icons.calendar_today_rounded,
      'badge': 'Aktif',
      'color': AppColors.warning,
    },
    {
      'title': 'Pusat Pemberitahuan & Filter Notifikasi',
      'desc':
          'Filter notifikasi per modul, pengelompokan tanggal (Hari Ini, Kemarin), dan aksi geser untuk tandai/hapus.',
      'icon': Icons.notifications_active_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'title': 'Ganti & Sinkronisasi Foto Profil',
      'desc':
          'Unggah foto profil pegawai dari kamera atau galeri yang tersimpan langsung di server backend RAG.',
      'icon': Icons.account_circle_rounded,
      'badge': 'Aktif',
      'color': AppColors.primaryMid,
    },
    {
      'title': 'Single Sign-On (SSO) Kampus',
      'desc':
          'Akses terpadu berbasis NIP/NIDN/Username yang terdaftar pada ekosistem IT Politeknik Indonusa Surakarta.',
      'icon': Icons.shield_rounded,
      'badge': 'Aktif',
      'color': const Color(0xFF059669),
    },
  ];

  final List<Map<String, dynamic>> _developmentFeatures = [
    {
      'title': 'SIKEU — Rincian Slip Gaji & Payroll',
      'desc':
          'Unduh slip gaji resmi berformat digital (PDF), breakdown komponen gaji, dan rekapitulasi honorarium SKS mengajar.',
      'icon': Icons.receipt_long_rounded,
      'status': 'Menunggu data/deploy backend',
      'color': AppColors.sikeu,
    },
    {
      'title': 'SIPPM — Pengajuan Riset & PkM LPPM',
      'desc':
          'Pengajuan proposal hibah internal/eksternal, pengisian logbook mingguan, dan pelaporan kemajuan pengabdian masyarakat.',
      'icon': Icons.science_rounded,
      'status': 'Menunggu data/deploy backend',
      'color': AppColors.sippm,
    },
    {
      'title': 'ARSIP — E-Surat Tugas & Disposisi',
      'desc':
          'Penomoran surat tugas otomatis, tanda tangan digital tersertifikasi, dan alur disposisi persuratan dari direksi.',
      'icon': Icons.mark_email_read_rounded,
      'status': 'Menunggu data/deploy backend',
      'color': const Color(0xFF0891B2),
    },
    {
      'title': 'SINAPRA — Peminjaman Sarpras & Ruangan',
      'desc':
          'Pengecekan ketersediaan ruang rapat, aula, dan lab terpadu serta reservasi fasilitas langsung via smartphone.',
      'icon': Icons.meeting_room_rounded,
      'status': 'Menunggu data/deploy backend',
      'color': const Color(0xFFD97706),
    },
    {
      'title': 'LMS — Integrasi E-Learning & Materi Kuliah',
      'desc':
          'Sinkronisasi silabus, materi perkuliahan digital, bank soal quiz, dan pengumpulan tugas kuliah terpadu.',
      'icon': Icons.school_outlined,
      'status': 'Menunggu data/deploy backend',
      'color': const Color(0xFF4338CA),
    },
    {
      'title': 'SPMB — Informasi Pendaftaran Mahasiswa Baru',
      'desc':
          'Pantau informasi pendaftaran dan seleksi mahasiswa baru setelah kontrak API tersedia.',
      'icon': Icons.app_registration_rounded,
      'status': 'Menunggu data/deploy backend',
      'color': const Color(0xFFBE123C),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 1. Header dengan Background Image background.jpeg
          AppHeader(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
                        'Tentang MyIn-U Staff',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Card Info Singkat Aplikasi
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Text(
                            'mInU',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MyIn-U Staff — Poltek Indonusa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppReleaseInfo.aboutHeaderLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
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

          // 2. Tab Bar: Fitur Aktif vs Tahap Pengembangan
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Fitur Aktif (${_activeFeatures.length})'),
                Tab(text: 'Roadmap (${_developmentFeatures.length})'),
                Tab(text: 'Log Update (${AppReleaseInfo.changelog.length})'),
              ],
            ),
          ),

          // 3. Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Fitur yang sudah aktif & berjalan
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: _activeFeatures.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = _activeFeatures[i];
                    return _FeatureCard(
                      title: item['title'] as String,
                      desc: item['desc'] as String,
                      icon: item['icon'] as IconData,
                      badge: item['badge'] as String,
                      badgeColor: item['color'] as Color,
                      isActive: true,
                    );
                  },
                ),

                // Tab 2: Fitur yang sedang dalam tahap pengembangan
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: _developmentFeatures.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = _developmentFeatures[i];
                    return _FeatureCard(
                      title: item['title'] as String,
                      desc: item['desc'] as String,
                      icon: item['icon'] as IconData,
                      badge: item['status'] as String,
                      badgeColor: item['color'] as Color,
                      isActive: false,
                    );
                  },
                ),

                // Tab 3: Log Update / Riwayat Pembaruan Aplikasi
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: AppReleaseInfo.changelog.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final entry = AppReleaseInfo.changelog[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: i == 0
                              ? AppColors.primary.withValues(alpha: 0.35)
                              : AppColors.divider,
                          width: i == 0 ? 1.2 : 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.badge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: i == 0
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                entry.date,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...entry.highlights.map(
                            (h) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700)),
                                  Expanded(
                                    child: Text(
                                      h,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                        fontSize: 11.5,
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
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final bool isActive;

  const _FeatureCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppColors.success
                              : const Color(0xFFC67C00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
