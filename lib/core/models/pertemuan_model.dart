import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

int _parseId(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Item kelas perkuliahan dengan progres pertemuan
class KelasPertemuanItem {
  final int kelasId;
  final String kodeKelas;
  final String namaKelas;
  final String kodeMk;
  final String namaMk;
  final int sks;
  final String ruangan;
  final String hari;
  final String jam;
  final int totalMahasiswa;
  final int totalPertemuan;
  final int pertemuanSelesai;
  final bool hasActiveSession;
  final int? activeSessionId;
  final int? activeSessionKe;

  const KelasPertemuanItem({
    required this.kelasId,
    required this.kodeKelas,
    required this.namaKelas,
    required this.kodeMk,
    required this.namaMk,
    required this.sks,
    required this.ruangan,
    required this.hari,
    required this.jam,
    required this.totalMahasiswa,
    this.totalPertemuan = 0,
    required this.pertemuanSelesai,
    this.hasActiveSession = false,
    this.activeSessionId,
    this.activeSessionKe,
  });

  factory KelasPertemuanItem.fromJson(Map<String, dynamic> json) {
    return KelasPertemuanItem(
      kelasId: _parseId(json['kelas_id'] ?? json['id']),
      kodeKelas: json['kode_kelas']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      kodeMk: json['kode_mk']?.toString() ?? '',
      namaMk: json['nama_mk']?.toString() ?? '',
      sks: json['sks'] is int
          ? json['sks']
          : int.tryParse(json['sks']?.toString() ?? '0') ?? 0,
      ruangan: json['ruangan']?.toString() ?? '-',
      hari: json['hari']?.toString() ?? '-',
      jam: json['jam']?.toString() ?? '-',
      totalMahasiswa: json['total_mahasiswa'] is int
          ? json['total_mahasiswa']
          : int.tryParse(json['total_mahasiswa']?.toString() ?? '0') ?? 0,
      totalPertemuan: json['total_pertemuan'] is int
          ? json['total_pertemuan']
          : int.tryParse(json['total_pertemuan']?.toString() ?? '0') ?? 0,
      pertemuanSelesai: json['pertemuan_selesai'] is int
          ? json['pertemuan_selesai']
          : int.tryParse(json['pertemuan_selesai']?.toString() ?? '0') ?? 0,
      hasActiveSession: json['has_active_session'] == true,
      activeSessionId: json['active_session_id'] is int
          ? json['active_session_id']
          : int.tryParse(json['active_session_id']?.toString() ?? ''),
      activeSessionKe: json['active_session_ke'] is int
          ? json['active_session_ke']
          : int.tryParse(json['active_session_ke']?.toString() ?? ''),
    );
  }

  double get progressFraction =>
      totalPertemuan > 0 ? (pertemuanSelesai / totalPertemuan).clamp(0.0, 1.0) : 0.0;

  int get progressPercent => (progressFraction * 100).round();
}

/// Item per-pertemuan (1 s/d 16)
class PertemuanItem {
  final int? id;
  final int pertemuanKe;
  final String? tanggal;
  final String? tanggalRaw;
  final String? jamMulai;
  final String? jamSelesai;
  final String? materi;
  final String? catatan;
  final String status; // 'belum', 'berlangsung', 'selesai'
  final String? tokenAbsensi;
  final bool isActive;
  final int totalHadir;
  final int totalIzin;
  final int totalSakit;
  final int totalAlfa;
  final int totalMahasiswa;

  const PertemuanItem({
    this.id,
    required this.pertemuanKe,
    this.tanggal,
    this.tanggalRaw,
    this.jamMulai,
    this.jamSelesai,
    this.materi,
    this.catatan,
    this.status = 'belum',
    this.tokenAbsensi,
    this.isActive = false,
    this.totalHadir = 0,
    this.totalIzin = 0,
    this.totalSakit = 0,
    this.totalAlfa = 0,
    this.totalMahasiswa = 0,
  });

  factory PertemuanItem.fromJson(Map<String, dynamic> json) {
    return PertemuanItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      pertemuanKe: json['pertemuan_ke'] is int
          ? json['pertemuan_ke']
          : int.tryParse(json['pertemuan_ke']?.toString() ?? '1') ?? 1,
      tanggal: json['tanggal']?.toString(),
      tanggalRaw: json['tanggal_raw']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      jamSelesai: json['jam_selesai']?.toString(),
      materi: json['materi']?.toString(),
      catatan: json['catatan']?.toString(),
      status: json['status']?.toString() ?? 'belum',
      tokenAbsensi: json['token_absensi']?.toString(),
      isActive: json['is_active'] == true,
      totalHadir: json['total_hadir'] is int
          ? json['total_hadir']
          : int.tryParse(json['total_hadir']?.toString() ?? '0') ?? 0,
      totalIzin: json['total_izin'] is int
          ? json['total_izin']
          : int.tryParse(json['total_izin']?.toString() ?? '0') ?? 0,
      totalSakit: json['total_sakit'] is int
          ? json['total_sakit']
          : int.tryParse(json['total_sakit']?.toString() ?? '0') ?? 0,
      totalAlfa: json['total_alfa'] is int
          ? json['total_alfa']
          : int.tryParse(json['total_alfa']?.toString() ?? '0') ?? 0,
      totalMahasiswa: json['total_mahasiswa'] is int
          ? json['total_mahasiswa']
          : int.tryParse(json['total_mahasiswa']?.toString() ?? '0') ?? 0,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'berlangsung':
        return 'Sedang Berlangsung';
      case 'selesai':
        return 'Selesai';
      default:
        return 'Belum Dimulai';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'berlangsung':
        return AppColors.warning;
      case 'selesai':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// Mahasiswa dan status presensinya pada suatu pertemuan
class PresensiMahasiswaItem {
  final int mahasiswaId;
  final String nim;
  final String nama;
  String status; // 'hadir', 'izin', 'sakit', 'alfa'
  String? catatan;
  final bool isSubmitted;

  PresensiMahasiswaItem({
    required this.mahasiswaId,
    required this.nim,
    required this.nama,
    required this.status,
    this.catatan,
    this.isSubmitted = false,
  });

  factory PresensiMahasiswaItem.fromJson(Map<String, dynamic> json) {
    return PresensiMahasiswaItem(
      mahasiswaId: json['mahasiswa_id'] is int
          ? json['mahasiswa_id']
          : int.tryParse(json['mahasiswa_id']?.toString() ?? '0') ?? 0,
      nim: json['nim']?.toString() ?? '-',
      nama: json['nama']?.toString() ?? 'Mahasiswa',
      status: json['status']?.toString() ?? 'hadir',
      catatan: json['catatan']?.toString(),
      isSubmitted: json['is_submitted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'mahasiswa_id': mahasiswaId,
        'status': status,
        if (catatan != null) 'catatan': catatan,
      };
}
