import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simpeg_model.dart';
import '../services/simpeg_service.dart';
import 'auth_provider.dart';

/// Provider Master Jenis Cuti
final masterJenisCutiProvider = FutureProvider<List<MasterJenisCutiModel>>((ref) async {
  return await SimpegService.fetchMasterJenisCuti();
});

/// Filter status cuti yang dipilih ('semua', 'pending', 'disetujui', 'ditolak')
final cutiStatusFilterProvider = StateProvider<String>((ref) => 'semua');

/// Provider Daftar Cuti
final cutiListProvider = FutureProvider<List<PengajuanCutiModel>>((ref) async {
  final filter = ref.watch(cutiStatusFilterProvider);
  return await SimpegService.fetchCutiList(
    status: filter == 'semua' ? null : filter,
  );
});

/// State filter bulan dan tahun untuk rekap presensi
class AttendanceRecapFilter {
  final int month;
  final int year;

  const AttendanceRecapFilter({required this.month, required this.year});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecapFilter &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;
}

final attendanceRecapFilterProvider = StateProvider<AttendanceRecapFilter>((ref) {
  final now = DateTime.now();
  return AttendanceRecapFilter(month: now.month, year: now.year);
});

/// Provider Rekapitulasi Presensi Bulanan
final attendanceRecapProvider = FutureProvider<AttendanceRecapModel?>((ref) async {
  final filter = ref.watch(attendanceRecapFilterProvider);
  final user = ref.watch(authProvider).user;
  final recap = await SimpegService.fetchAttendanceRecap(
    month: filter.month,
    year: filter.year,
  );
  if (recap == null) return null;

  // Pastikan rekap benar-benar milik akun yang login (bukan data demo/data
  // pegawai lain yang kadang dikirim backend saat data belum tersedia).
  final expectedCodes = <String>{
    if (user?.nip != null && user!.nip.isNotEmpty && user.nip != '-') user.nip,
    if (user?.nidn != null && user!.nidn.isNotEmpty) user.nidn,
  };
  final actualCode = recap.employeeCode.trim();
  if (expectedCodes.isNotEmpty &&
      actualCode.isNotEmpty &&
      !expectedCodes.contains(actualCode)) {
    return null;
  }

  return recap.hasAttendanceData ? recap : null;
});

/// Filter kategori pengumuman
final announcementCategoryFilterProvider = StateProvider<String>((ref) => 'semua');

/// Provider Pengumuman Kampus
final announcementsProvider = FutureProvider<List<CampusAnnouncementItem>>((ref) async {
  final category = ref.watch(announcementCategoryFilterProvider);
  return await SimpegService.fetchAnnouncements(
    category: category == 'semua' ? null : category,
  );
});
