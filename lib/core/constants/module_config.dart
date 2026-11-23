import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ModuleConfig {
  final String code;
  final String name;
  final String shortName;
  final String description;
  final Color color;
  final IconData icon;
  final String route;

  /// Kode modul induk di web. Dipakai untuk mewarisi hak akses saat backend
  /// hanya mengirim kode modul tingkat tinggi (misalnya `simpeg`).
  final String? parentCode;

  /// Modul khusus dosen pengajar (disembunyikan untuk tendik/staf).
  final bool dosenOnly;

  /// Termasuk katalog modul mobile yang dikurasi.
  final bool isMobileModule;

  const ModuleConfig({
    required this.code,
    required this.name,
    required this.shortName,
    required this.description,
    required this.color,
    required this.icon,
    required this.route,
    this.parentCode,
    this.dosenOnly = false,
    this.isMobileModule = false,
  });
}

class AppModules {
  /// Seluruh modul web yang dikenal aplikasi (termasuk pintasan mobile).
  static const List<ModuleConfig> all = [
    // Modul induk / web
    ModuleConfig(
      code: 'simpeg',
      name: 'SIMPEG',
      shortName: 'Kepegawaian',
      description: 'Presensi, Cuti, Payroll & Kinerja',
      color: AppColors.simpeg,
      icon: Icons.badge_outlined,
      route: '/modules/simpeg',
      isMobileModule: true,
    ),
    ModuleConfig(
      code: 'sippm',
      name: 'SIPPM',
      shortName: 'Kampus',
      description: 'Proposal Riset & PkM',
      color: AppColors.sippm,
      icon: Icons.science_outlined,
      route: '/modules/sippm',
      isMobileModule: true,
    ),
    ModuleConfig(
      code: 'siakad',
      name: 'SIAKAD',
      shortName: 'Akademik',
      description: 'Jadwal, Nilai & Mahasiswa',
      color: AppColors.siakad,
      icon: Icons.school_outlined,
      route: '/modules/siakad',
      isMobileModule: true,
    ),
    ModuleConfig(
      code: 'sikeu',
      name: 'SIKEU',
      shortName: 'Kampus',
      description: 'Tagihan, Akuntansi & Laporan',
      color: AppColors.sikeu,
      icon: Icons.account_balance_wallet_outlined,
      route: '/modules/sikeu',
      isMobileModule: true,
    ),
    ModuleConfig(
      code: 'sinapra',
      name: 'SINAPRA',
      shortName: 'Sarana & Prasarana',
      description: 'Aset, Ruangan & Maintenance',
      color: AppColors.sinapra,
      icon: Icons.business_outlined,
      route: '/modules/sinapra',
      isMobileModule: true,
    ),
    ModuleConfig(
      code: 'arsip',
      name: 'ARSIP',
      shortName: 'Tata Persuratan',
      description: 'Nomor Surat & Kop Surat',
      color: AppColors.arsip,
      icon: Icons.folder_outlined,
      route: '/modules/arsip',
      isMobileModule: true,
    ),
    ModuleConfig(
      code: 'lms',
      name: 'LMS',
      shortName: 'Learning Management',
      description: 'Forum & Presensi Kelas',
      color: AppColors.lms,
      icon: Icons.cast_for_education_outlined,
      route: '/modules/lms',
      isMobileModule: true,
    ),
    ModuleConfig(
      code: 'spmb',
      name: 'SPMB',
      shortName: 'Penerimaan Mahasiswa',
      description: 'Penerimaan Mahasiswa Baru',
      color: AppColors.spmb,
      icon: Icons.how_to_reg_outlined,
      route: '/modules/spmb',
      isMobileModule: true,
    ),

    // IAM/SSO dikirim server sebagai modul aktif, tetapi di mobile dipetakan
    // ke data diri (read-only) dan sengaja tidak masuk katalog modul bisnis.
    ModuleConfig(
      code: 'sso',
      name: 'IAM',
      shortName: 'Akun & Keamanan',
      description: 'Informasi akun dan data diri pegawai',
      color: AppColors.primary,
      icon: Icons.manage_accounts_outlined,
      route: '/profile/data-diri',
    ),

    // Pintasan SIMPEG yang memang relevan di mobile
    ModuleConfig(
      code: 'rekap',
      name: 'Rekap Kehadiran',
      shortName: 'Presensi',
      description: 'Laporan presensi & tingkat kehadiran bulanan',
      color: Color(0xFF00897B),
      icon: Icons.bar_chart_rounded,
      route: '/simpeg/rekap',
      parentCode: 'simpeg',
    ),
    ModuleConfig(
      code: 'cuti',
      name: 'Izin & Cuti',
      shortName: 'Pengajuan',
      description: 'Ajukan cuti dan pantau status persetujuan',
      color: Color(0xFFE65100),
      icon: Icons.event_note_rounded,
      route: '/simpeg/cuti',
      parentCode: 'simpeg',
    ),
    ModuleConfig(
      code: 'pengumuman',
      name: 'Info Kampus',
      shortName: 'Pengumuman',
      description: 'Edaran resmi, rapat, dan agenda kampus',
      color: Color(0xFF7C3AED),
      icon: Icons.campaign_rounded,
      route: '/simpeg/announcements',
      parentCode: 'simpeg',
    ),
    ModuleConfig(
      code: 'log-aktivitas',
      name: 'Log Aktivitas',
      shortName: 'Riwayat',
      description: 'Catatan scan absen, izin, dan cuti Anda',
      color: Color(0xFF5E35B1),
      icon: Icons.history_rounded,
      route: '/simpeg/log-aktivitas',
      parentCode: 'simpeg',
    ),

    // Pintasan SIAKAD khusus dosen pengajar
    ModuleConfig(
      code: 'jadwal',
      name: 'Jadwal Mengajar',
      shortName: 'Mengajar',
      description: 'Jadwal kuliah mingguan dan kelas hari ini',
      color: Color(0xFFD97706),
      icon: Icons.calendar_today_rounded,
      route: '/schedule',
      parentCode: 'siakad',
      dosenOnly: true,
    ),
    ModuleConfig(
      code: 'nilai',
      name: 'Input Nilai',
      shortName: 'Penilaian',
      description: 'Nilai KHS dan konversi OBE mahasiswa',
      color: Color(0xFF0284C7),
      icon: Icons.assignment_turned_in_rounded,
      route: '/siakad/grading',
      parentCode: 'siakad',
      dosenOnly: true,
    ),
    ModuleConfig(
      code: 'bimbingan',
      name: 'Bimbingan Akademik',
      shortName: 'DPA / KRS',
      description: 'Mahasiswa bimbingan, persetujuan KRS, & catatan PA',
      color: Color(0xFF059669),
      icon: Icons.supervisor_account_rounded,
      route: '/siakad/advising',
      parentCode: 'siakad',
      dosenOnly: true,
    ),
    ModuleConfig(
      code: 'jurnal',
      name: 'Jurnal Kelas',
      shortName: 'BAP',
      description: 'Pertemuan kelas, token presensi, & jurnal BAP',
      color: Color(0xFF0F766E),
      icon: Icons.menu_book_rounded,
      route: '/siakad/perkuliahan',
      parentCode: 'siakad',
      dosenOnly: true,
    ),
  ];

  /// Katalog cadangan yang dipakai hanya sebagai pemetaan ikon/route.
  ///
  /// Daftar yang benar-benar ditampilkan di `ModulesScreen` berasal dari
  /// `GET /api/modules/my-modules` (sumber yang sama dengan web RAG), jadi
  /// jumlah dan nama modul mengikuti hak akses server — untuk dosen biasanya
  /// delapan modul bisnis (tanpa `sso`).
  static final List<ModuleConfig> mobileModules =
      all.where((module) => module.isMobileModule).toList();

  static ModuleConfig? findByCode(String code) {
    try {
      return all.firstWhere((m) => m.code == code);
    } catch (_) {
      return null;
    }
  }
}
