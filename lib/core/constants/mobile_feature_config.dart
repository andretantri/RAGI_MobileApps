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
  cutiSimpeg,
  izinKerjaSimpeg,
  suratTugasSimpeg,
  skPegawaiSimpeg,
  eFileArsip,
}

/// Nilai tetap domain e-file (`DokumenPegawai::JENIS_DOKUMEN` di backend).
/// Bukan entitas master, jadi boleh statis dan terpusat di sini.
const List<String> mobileEfileJenisDokumen = <String>[
  'ktp',
  'kk',
  'ijazah',
  'sk',
  'serdos',
  'sertifikat',
  'lainnya',
];

/// Sumber data kompetensi pada endpoint `/mobile/staff/simpeg/kompetensi`.
const List<String> mobileKompetensiJenis = <String>[
  'sertifikasi',
  'tes',
  'pelatihan',
];

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

  /// Fitur dengan detail dedicated memakai layar `MobileStaffDetailScreen`.
  final bool hasDetail;

  /// Template endpoint detail; `{id}` diganti ID item dari daftar.
  final String? detailEndpoint;

  /// Template endpoint unduh biner/signed URL; `{id}` diganti ID item.
  final String? downloadEndpoint;

  /// Kunci master SIMPEG yang wajib dipilih pada form (ID dari API master).
  final List<String> masterKeys;

  /// Query default saat memuat daftar (mis. jenis kompetensi).
  final Map<String, dynamic> queryParams;

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
    this.hasDetail = false,
    this.detailEndpoint,
    this.downloadEndpoint,
    this.masterKeys = const <String>[],
    this.queryParams = const <String, dynamic>{},
  });

  bool get hasEndpoint => endpoint != null && endpoint!.isNotEmpty;
  bool get hasSubmit => submitEndpoint != null && submitEndpoint!.isNotEmpty;
  bool get isSubmittable => hasSubmit && formType != MobileFeatureFormType.none;

  /// Form self-service baru memakai layar khusus dengan master dinamis.
  bool get usesDedicatedForm => const <MobileFeatureFormType>{
    MobileFeatureFormType.cutiSimpeg,
    MobileFeatureFormType.izinKerjaSimpeg,
    MobileFeatureFormType.suratTugasSimpeg,
    MobileFeatureFormType.skPegawaiSimpeg,
    MobileFeatureFormType.eFileArsip,
  }.contains(formType);

  static String resolveId(String template, String id) =>
      template.replaceAll('{id}', id);
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
    MobileFeature(
      code: 'cuti',
      title: 'Pengajuan Cuti',
      subtitle: 'Riwayat dan pengajuan cuti pegawai',
      moduleCode: 'simpeg',
      endpoint: '/mobile/staff/simpeg/cuti',
      icon: Icons.event_available_outlined,
      color: AppColors.primary,
      description: 'Ajukan cuti dengan jenis dari master dan pantau statusnya.',
      submitEndpoint: '/mobile/staff/simpeg/cuti',
      formType: MobileFeatureFormType.cutiSimpeg,
      submitLabel: 'Ajukan Cuti',
      masterKeys: ['jenis_cuti'],
    ),
    MobileFeature(
      code: 'izin-kerja',
      title: 'Izin Jam Kerja',
      subtitle: 'Izin keluar kantor dan jam kerja',
      moduleCode: 'simpeg',
      endpoint: '/mobile/staff/simpeg/izin-kerja',
      icon: Icons.schedule_outlined,
      color: AppColors.primary,
      description: 'Ajukan izin jam kerja beserta bukti opsional.',
      submitEndpoint: '/mobile/staff/simpeg/izin-kerja',
      formType: MobileFeatureFormType.izinKerjaSimpeg,
      submitLabel: 'Ajukan Izin',
      masterKeys: ['jenis_izin'],
    ),
    MobileFeature(
      code: 'surat-tugas',
      title: 'Surat Tugas',
      subtitle: 'Penugasan, perjalanan, dan LPJ',
      moduleCode: 'simpeg',
      endpoint: '/mobile/staff/simpeg/surat-tugas',
      icon: Icons.assignment_outlined,
      color: AppColors.primary,
      description:
          'Ajukan surat tugas dan unggah LPJ setelah penugasan disetujui.',
      submitEndpoint: '/mobile/staff/simpeg/surat-tugas',
      formType: MobileFeatureFormType.suratTugasSimpeg,
      submitLabel: 'Ajukan Surat Tugas',
      hasDetail: true,
      masterKeys: ['kategori_kegiatan', 'jenis_transportasi'],
    ),
    MobileFeature(
      code: 'sk-pegawai',
      title: 'SK Pegawai',
      subtitle: 'Riwayat SK dan dokumen kepegawaian',
      moduleCode: 'simpeg',
      endpoint: '/mobile/staff/simpeg/sk-pegawai',
      icon: Icons.description_outlined,
      color: AppColors.primary,
      description: 'Simpan SK pegawai dengan kategori dari master data.',
      submitEndpoint: '/mobile/staff/simpeg/sk-pegawai',
      formType: MobileFeatureFormType.skPegawaiSimpeg,
      submitLabel: 'Tambah SK',
      masterKeys: ['kategori_sk'],
    ),
    MobileFeature(
      code: 'kompetensi',
      title: 'Kompetensi',
      subtitle: 'Sertifikasi, tes, dan pelatihan',
      moduleCode: 'simpeg',
      endpoint: '/mobile/staff/simpeg/kompetensi',
      icon: Icons.verified_outlined,
      color: AppColors.primary,
      description: 'Daftar kompetensi pegawai login (default: sertifikasi).',
      queryParams: {'jenis': 'sertifikasi'},
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
      hasDetail: true,
      detailEndpoint: '/mobile/staff/sikeu/payroll/{id}',
      downloadEndpoint: '/mobile/staff/sikeu/payroll/{id}/slip',
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
      submitEndpoint: '/mobile/staff/arsip/e-file',
      formType: MobileFeatureFormType.eFileArsip,
      submitLabel: 'Unggah Dokumen',
      hasDetail: true,
      detailEndpoint: '/mobile/staff/arsip/e-file/{id}',
      downloadEndpoint: '/mobile/staff/arsip/e-file/{id}/download',
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
      description: 'Bagikan kode/QR referral dan pantau mahasiswa yang dibawa.',
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
