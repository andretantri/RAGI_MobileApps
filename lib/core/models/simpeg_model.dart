import 'package:intl/intl.dart';

class MasterJenisCutiModel {
  final int id;
  final String nama;
  final String kode;
  final String tipeDurasi;
  final int durasiHari;
  final String satuan;
  final bool lampiranWajib;
  final String? keterangan;

  const MasterJenisCutiModel({
    required this.id,
    required this.nama,
    required this.kode,
    required this.tipeDurasi,
    required this.durasiHari,
    required this.satuan,
    required this.lampiranWajib,
    this.keterangan,
  });

  factory MasterJenisCutiModel.fromJson(Map<String, dynamic> json) {
    return MasterJenisCutiModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nama: json['nama']?.toString() ?? '',
      kode: json['kode']?.toString() ?? '',
      tipeDurasi: json['tipe_durasi']?.toString() ?? 'fleksibel',
      durasiHari: json['durasi_hari'] is int
          ? json['durasi_hari'] as int
          : int.tryParse(json['durasi_hari']?.toString() ?? '0') ?? 0,
      satuan: json['satuan']?.toString() ?? 'hari',
      lampiranWajib: json['lampiran_wajib'] == true || json['lampiran_wajib'] == 1,
      keterangan: json['keterangan']?.toString(),
    );
  }
}

class PengajuanCutiModel {
  final int id;
  final int? pegawaiId;
  final int masterJenisCutiId;
  final String jenisCuti;
  final String masterNama;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int jumlahHari;
  final String alasan;
  final String statusApproval; // pending / disetujui / ditolak
  final String? catatanApproval;
  final String? approvedByName;
  final String? filePendukungUrl;
  final String createdAt;

  const PengajuanCutiModel({
    required this.id,
    this.pegawaiId,
    required this.masterJenisCutiId,
    required this.jenisCuti,
    required this.masterNama,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlahHari,
    required this.alasan,
    required this.statusApproval,
    this.catatanApproval,
    this.approvedByName,
    this.filePendukungUrl,
    required this.createdAt,
  });

  factory PengajuanCutiModel.fromJson(Map<String, dynamic> json) {
    final master = json['master_jenis_cuti'] is Map ? json['master_jenis_cuti'] as Map<String, dynamic> : null;
    final approver = json['approver'] is Map ? json['approver'] as Map<String, dynamic> : null;

    return PengajuanCutiModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      pegawaiId: json['pegawai_id'] is int ? json['pegawai_id'] as int : null,
      masterJenisCutiId: json['master_jenis_cuti_id'] is int
          ? json['master_jenis_cuti_id'] as int
          : int.tryParse(json['master_jenis_cuti_id']?.toString() ?? '1') ?? 1,
      jenisCuti: json['jenis_cuti']?.toString() ?? 'tahunan',
      masterNama: master?['nama']?.toString() ?? json['jenis_cuti']?.toString() ?? 'Cuti',
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      jumlahHari: json['jumlah_hari'] is int
          ? json['jumlah_hari'] as int
          : int.tryParse(json['jumlah_hari']?.toString() ?? '1') ?? 1,
      alasan: json['alasan']?.toString() ?? '',
      statusApproval: json['status_approval']?.toString().toLowerCase() ?? 'pending',
      catatanApproval: json['catatan_approval']?.toString(),
      approvedByName: approver?['name']?.toString(),
      filePendukungUrl: json['file_pendukung_url']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class AttendanceRecapRow {
  final String date;
  final String tanggal;
  final String? scanMasuk;
  final String? scanPulang;
  final String? terlambat;
  final String status;
  final String? keterangan;

  const AttendanceRecapRow({
    required this.date,
    required this.tanggal,
    this.scanMasuk,
    this.scanPulang,
    this.terlambat,
    required this.status,
    this.keterangan,
  });

  factory AttendanceRecapRow.fromJson(Map<String, dynamic> json) {
    return AttendanceRecapRow(
      date: json['date']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? json['date']?.toString() ?? '',
      scanMasuk: json['scan_masuk']?.toString() ?? json['clock_in']?.toString(),
      scanPulang: json['scan_pulang']?.toString() ?? json['clock_out']?.toString(),
      terlambat: json['terlambat']?.toString(),
      status: json['status_badge']?.toString() ??
          json['status']?.toString() ??
          json['status_kehadiran']?.toString() ??
          '',
      keterangan: json['keterangan']?.toString() ?? json['notes']?.toString(),
    );
  }

  /// Baris libur/weekend yang dihasilkan server bukan merupakan aktivitas
  /// presensi pegawai, jadi tidak boleh tampil sebagai log kehadiran.
  bool get isCalendarOnly {
    final statusValue = status.trim().toLowerCase();
    final isLibur = statusValue.contains('libur') ||
        statusValue.contains('weekend') ||
        statusValue.contains('holiday') ||
        statusValue == 'off';
    if (!isLibur) return false;

    final noScan = (scanMasuk == null || scanMasuk!.trim().isEmpty) &&
        (scanPulang == null || scanPulang!.trim().isEmpty);
    final noNote = keterangan == null || keterangan!.trim().isEmpty;
    return noScan && noNote;
  }

  bool get isRealActivity => !isCalendarOnly;

  /// Server masih mengirim baris untuk tanggal yang belum dilewati dengan
  /// status `alpa`. Baris tersebut bukan fakta kehadiran, jadi disembunyikan.
  bool get isFuture {
    final parsed = _parseDate(date.isNotEmpty ? date : tanggal);
    if (parsed == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return parsed.isAfter(today);
  }

  static DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    for (final pattern in const [
      'd MMM yyyy',
      'dd MMM yyyy',
      'd MMMM yyyy',
      'dd MMMM yyyy',
    ]) {
      try {
        final parsed = DateFormat(pattern, 'id_ID').parse(trimmed);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {}
    }
    return null;
  }
}

class AttendanceRecapModel {
  final String employeeName;
  final String employeeCode;
  final String department;
  final String position;
  final String startDate;
  final String endDate;
  final int totalDays;
  final int totalHadir;
  final int totalTerlambat;
  final int totalAlpa;
  final int totalLibur;
  final int totalIzin;
  final int totalSakit;
  final int totalDinas;
  final int totalCuti;
  final List<AttendanceRecapRow> rows;

  const AttendanceRecapModel({
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalHadir,
    required this.totalTerlambat,
    required this.totalAlpa,
    required this.totalLibur,
    required this.totalIzin,
    required this.totalSakit,
    required this.totalDinas,
    required this.totalCuti,
    required this.rows,
  });

  factory AttendanceRecapModel.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] is Map ? json['employee'] as Map<String, dynamic> : {};
    final filter = json['filter'] is Map ? json['filter'] as Map<String, dynamic> : {};
    final summary = json['summary'] is Map ? json['summary'] as Map<String, dynamic> : {};
    final rawRows = json['rows'] as List? ?? [];

    return AttendanceRecapModel(
      employeeName: emp['name']?.toString() ?? '',
      employeeCode: emp['employee_code']?.toString() ?? '',
      department: emp['department']?.toString() ?? '',
      position: emp['position']?.toString() ?? '',
      startDate: filter['start_date']?.toString() ?? '',
      endDate: filter['end_date']?.toString() ?? '',
      totalDays: (summary['total_days'] as num?)?.toInt() ?? 0,
      totalHadir: (summary['total_hadir'] as num?)?.toInt() ?? 0,
      totalTerlambat: (summary['total_terlambat'] as num?)?.toInt() ?? 0,
      totalAlpa: (summary['total_alpa'] as num?)?.toInt() ?? 0,
      totalLibur: (summary['total_libur'] as num?)?.toInt() ?? 0,
      totalIzin: (summary['total_izin'] as num?)?.toInt() ?? 0,
      totalSakit: (summary['total_sakit'] as num?)?.toInt() ?? 0,
      totalDinas: (summary['total_dinas'] as num?)?.toInt() ?? 0,
      totalCuti: (summary['total_cuti'] as num?)?.toInt() ?? 0,
      rows: rawRows
          .whereType<Map>()
          .map((e) => AttendanceRecapRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Hanya baris yang benar-benar merekam kehadiran/cuti/izin dan sudah
  /// berlalu. Baris masa depan dari server tidak ditampilkan sebagai log.
  List<AttendanceRecapRow> get realRows => rows
      .where((row) => row.isRealActivity && !row.isFuture)
      .toList();

  /// False bila server hanya mengirim kalender/libur atau data kosong.
  bool get hasAttendanceData {
    if (realRows.isNotEmpty) return true;
    return totalHadir +
            totalTerlambat +
            totalAlpa +
            totalIzin +
            totalSakit +
            totalDinas +
            totalCuti >
        0;
  }
}

class CampusAnnouncementItem {
  final int id;
  final String title;
  final String category;
  final String targetRole;
  final String content;
  final bool isAgenda;
  final String? eventDate;
  final String? eventTime;
  final String? eventLocation;
  final String? eventUrl;
  final String priority;
  final int recipientsCount;
  final String createdAt;

  const CampusAnnouncementItem({
    required this.id,
    required this.title,
    required this.category,
    required this.targetRole,
    required this.content,
    required this.isAgenda,
    this.eventDate,
    this.eventTime,
    this.eventLocation,
    this.eventUrl,
    required this.priority,
    required this.recipientsCount,
    required this.createdAt,
  });

  factory CampusAnnouncementItem.fromJson(Map<String, dynamic> json) {
    return CampusAnnouncementItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'umum',
      targetRole: json['target_role']?.toString() ?? 'all_staff',
      content: json['content']?.toString() ?? '',
      isAgenda: json['is_agenda'] == true || json['is_agenda'] == 1,
      eventDate: json['event_date']?.toString(),
      eventTime: json['event_time']?.toString(),
      eventLocation: json['event_location']?.toString(),
      eventUrl: json['event_url']?.toString(),
      priority: json['priority']?.toString() ?? 'normal',
      recipientsCount: (json['recipients_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
