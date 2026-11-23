import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Jenis form tulis yang tersedia untuk sebuah fitur mobile.
///
/// Sesuai kontrak `MobileStaffController.md` (2026-11-22).
enum MobileFeatureFormType {
  none,
  proposalSippm,
  pengajuanSikeu,
  tiketSinapra,
  referralSpmb,
}

/// Satu fitur mobile yang dikurasi dari modul RAG.
///
/// `endpoint` boleh kosong untuk fitur yang masih menunggu API backend; UI
/// akan menampilkan kondisi "belum tersedia" tanpa data rekaan.
class MobileFeature {
  final String code;
  final String title;
  final String subtitle;
  final String moduleCode;
  final String? endpoint;
  final IconData icon;
  final Color color;
  final bool dosenOnly;
  final String description;
  final String? submitEndpoint;
  final MobileFeatureFormType formType;
  final String submitLabel;

  const MobileFeature({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.moduleCode,
    required this.icon,
    required this.color,
    required this.description,
    this.endpoint,
    this.dosenOnly = false,
    this.submitEndpoint,
    this.formType = MobileFeatureFormType.none,
    this.submitLabel = 'Kirim',
  });

  bool get hasEndpoint => endpoint != null && endpoint!.isNotEmpty;
  bool get hasSubmit => submitEndpoint != null && submitEndpoint!.isNotEmpty;
  bool get isSubmittable => hasSubmit && formType != MobileFeatureFormType.none;
}

class AppMobileFeatures {
  static const List<MobileFeature> all = [
    // SIMPEG
    MobileFeature(
      code: 'data-diri',
      title: 'Data Diri & Biodata',
      subtitle: 'Identitas kepegawaian akun Anda',
      moduleCode: 'simpeg',
      icon: Icons.person_outline_rounded,
      color: AppColors.primary,
      description:
          'Menampilkan nama gelar, NIDN/NIP, jabatan, unit, dan email akun.',
    ),

    // SIPPM
    MobileFeature(
      code: 'proposal-hibah',
      title: 'Proposal & Hibah',
      subtitle: 'Proposal penelitian dan PkM Anda',
      moduleCode: 'sippm',
      endpoint: '/mobile/staff/sippm/proposal',
      icon: Icons.science_outlined,
      color: AppColors.sippm,
      dosenOnly: true,
      description: 'Daftar proposal, skema, status review, dan aksi ajukan.',
      submitEndpoint: '/mobile/staff/sippm/proposal',
      formType: MobileFeatureFormType.proposalSippm,
      submitLabel: 'Ajukan Proposal',
    ),
    MobileFeature(
      code: 'luaran-penelitian',
      title: 'Luaran Penelitian',
      subtitle: 'Publikasi dan hasil PkM',
      moduleCode: 'sippm',
      endpoint: '/mobile/staff/sippm/luaran',
      icon: Icons.article_outlined,
      color: AppColors.sippm,
      dosenOnly: true,
      description: 'Daftar luaran/publikasi yang sudah tercatat di SIPPM.',
    ),

    // SIKEU
    MobileFeature(
      code: 'payroll',
      title: 'Riwayat Payroll',
      subtitle: 'Slip gaji dan potongan bulanan',
      moduleCode: 'sikeu',
      endpoint: '/mobile/staff/sikeu/payroll',
      icon: Icons.receipt_long_outlined,
      color: AppColors.sikeu,
      description: 'Slip payroll per bulan beserta ringkasan potongan.',
    ),
    MobileFeature(
      code: 'pengajuan-sikeu',
      title: 'Pengajuan Saya',
      subtitle: 'Reimbes, kas bon, dan pengajuan lain',
      moduleCode: 'sikeu',
      endpoint: '/mobile/staff/sikeu/pengajuan',
      icon: Icons.request_quote_outlined,
      color: AppColors.sikeu,
      description: 'Status pengajuan keuangan milik akun yang login.',
      submitEndpoint: '/mobile/staff/sikeu/pengajuan',
      formType: MobileFeatureFormType.pengajuanSikeu,
      submitLabel: 'Kirim Pengajuan',
    ),

    // SINAPRA
    MobileFeature(
      code: 'tiket-sinapra',
      title: 'Tiket Sarana',
      subtitle: 'Lapor kerusakan dan status perbaikan',
      moduleCode: 'sinapra',
      endpoint: '/mobile/staff/sinapra/tiket',
      icon: Icons.build_outlined,
      color: AppColors.sinapra,
      description: 'Laporan kerusakan dan tiket perbaikan yang diajukan.',
      submitEndpoint: '/mobile/staff/sinapra/tiket',
      formType: MobileFeatureFormType.tiketSinapra,
      submitLabel: 'Lapor Kerusakan',
    ),
    MobileFeature(
      code: 'pinjam-ruang',
      title: 'Peminjaman Ruangan',
      subtitle: 'Status peminjaman fasilitas',
      moduleCode: 'sinapra',
      endpoint: '/mobile/staff/sinapra/peminjaman',
      icon: Icons.meeting_room_outlined,
      color: AppColors.sinapra,
      description: 'Daftar peminjaman ruangan/fasilitas milik akun.',
    ),

    // ARSIP
    MobileFeature(
      code: 'e-file',
      title: 'Dokumen E-File',
      subtitle: 'SK, surat, dan dokumen pribadi',
      moduleCode: 'arsip',
      endpoint: '/mobile/staff/arsip/e-file',
      icon: Icons.folder_outlined,
      color: AppColors.arsip,
      description: 'Dokumen kepegawaian yang tersimpan di arsip digital.',
    ),
    MobileFeature(
      code: 'surat-arsip',
      title: 'Surat Masuk & Keluar',
      subtitle: 'Arsip persuratan terbaru',
      moduleCode: 'arsip',
      endpoint: '/mobile/staff/arsip/surat',
      icon: Icons.mark_email_unread_outlined,
      color: AppColors.arsip,
      description: 'Daftar surat masuk dan keluar yang terkait dengan akun.',
    ),

    // LMS
    MobileFeature(
      code: 'bahan-ajar',
      title: 'Bahan Ajar & RPS',
      subtitle: 'Materi kelas dan RPS',
      moduleCode: 'lms',
      endpoint: '/mobile/staff/lms/bahan-ajar',
      icon: Icons.menu_book_outlined,
      color: AppColors.lms,
      dosenOnly: true,
      description: 'Materi perkuliahan, RPS, dan file pendukung dosen.',
    ),
    MobileFeature(
      code: 'pengumuman-kelas',
      title: 'Pengumuman Kelas',
      subtitle: 'Info terbaru untuk mahasiswa',
      moduleCode: 'lms',
      endpoint: '/mobile/staff/lms/pengumuman',
      icon: Icons.campaign_outlined,
      color: AppColors.lms,
      dosenOnly: true,
      description: 'Pengumuman singkat dari kelas yang diampu.',
    ),

    // SPMB
    MobileFeature(
      code: 'referral-spmb',
      title: 'Referral SPMB',
      subtitle: 'Kode referral & mahasiswa binaan',
      moduleCode: 'spmb',
      endpoint: '/mobile/staff/spmb/referral',
      icon: Icons.card_giftcard_outlined,
      color: AppColors.spmb,
      description:
          'Bagikan kode/QR referral dan pantau mahasiswa yang dibawa.',
      submitEndpoint: '/mobile/staff/spmb/referral',
      formType: MobileFeatureFormType.referralSpmb,
      submitLabel: 'Buat Link Referral',
    ),
    MobileFeature(
      code: 'info-spmb',
      title: 'Info Penerimaan',
      subtitle: 'Periode, syarat, dan agenda SPMB',
      moduleCode: 'spmb',
      endpoint: null,
      icon: Icons.info_outline_rounded,
      color: AppColors.spmb,
      description: 'Informasi umum program penerimaan mahasiswa baru.',
    ),
  ];

  static MobileFeature? findByCode(String code) {
    for (final feature in all) {
      if (feature.code == code) return feature;
    }
    return null;
  }

  static List<MobileFeature> forModule(String moduleCode) =>
      all.where((feature) => feature.moduleCode == moduleCode).toList();

  static List<String> codesForModule(String moduleCode) =>
      forModule(moduleCode).map((feature) => feature.code).toList();

  static List<MobileFeature> get submittable =>
      all.where((feature) => feature.isSubmittable).toList();
}
