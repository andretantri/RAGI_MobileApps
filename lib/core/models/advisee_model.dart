class AdviseeStudent {
  final int id;
  final String nim;
  final String nama;
  final String? avatar;
  final String prodi;
  final String angkatan;
  final int semester;
  final double ipk;
  final int totalSksLulus;
  final AdviseeKrsInfo? krs;

  const AdviseeStudent({
    required this.id,
    required this.nim,
    required this.nama,
    this.avatar,
    required this.prodi,
    required this.angkatan,
    required this.semester,
    required this.ipk,
    required this.totalSksLulus,
    this.krs,
  });

  bool get needsApproval => krs?.status == 'menunggu_persetujuan';
  bool get isApproved => krs?.status == 'disetujui';

  factory AdviseeStudent.fromJson(Map<String, dynamic> json) {
    return AdviseeStudent(
      id: json['id'] as int? ?? 0,
      nim: json['nim']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      prodi: json['prodi']?.toString() ?? '-',
      angkatan: json['angkatan']?.toString() ?? '-',
      semester: (json['semester'] as num?)?.toInt() ?? 0,
      ipk: (json['ipk'] as num?)?.toDouble() ?? 0,
      totalSksLulus: (json['total_sks_lulus'] as num?)?.toInt() ?? 0,
      krs: json['krs'] is Map<String, dynamic>
          ? AdviseeKrsInfo.fromJson(json['krs'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AdviseeKrsInfo {
  final int? id;
  final String status; // 'menunggu_persetujuan' | 'disetujui' | 'revisi' | 'draft'
  final int totalSks;
  final String? disetujuiAt;

  const AdviseeKrsInfo({
    this.id,
    required this.status,
    required this.totalSks,
    this.disetujuiAt,
  });

  factory AdviseeKrsInfo.fromJson(Map<String, dynamic> json) {
    return AdviseeKrsInfo(
      id: json['id'] as int?,
      status: json['status']?.toString() ?? 'draft',
      totalSks: (json['total_sks'] as num?)?.toInt() ?? 0,
      disetujuiAt: json['disetujui_at']?.toString(),
    );
  }
}

class KrsCourseItem {
  final int krsDetailId;
  final int? kelasId;
  final String kodeMk;
  final String namaMk;
  final int sks;
  final String kelas;
  final String hari;
  final String jam;
  final String ruangan;

  const KrsCourseItem({
    required this.krsDetailId,
    this.kelasId,
    required this.kodeMk,
    required this.namaMk,
    required this.sks,
    required this.kelas,
    required this.hari,
    required this.jam,
    required this.ruangan,
  });

  factory KrsCourseItem.fromJson(Map<String, dynamic> json) {
    return KrsCourseItem(
      krsDetailId: json['krs_detail_id'] as int? ?? 0,
      kelasId: json['kelas_id'] as int?,
      kodeMk: json['kode_mk']?.toString() ?? '',
      namaMk: json['nama_mk']?.toString() ?? '',
      sks: (json['sks'] as num?)?.toInt() ?? 3,
      kelas: json['kelas']?.toString() ?? 'Kelas A',
      hari: json['hari']?.toString() ?? '-',
      jam: json['jam']?.toString() ?? '-',
      ruangan: json['ruangan']?.toString() ?? '-',
    );
  }
}

class KrsApprovalDetail {
  final int krsId;
  final int mahasiswaId;
  final String nim;
  final String nama;
  final String prodi;
  final int semester;
  final double ipk;
  final String tahunAkademik;
  final int totalSks;
  final String status;
  final String? disetujuiAt;
  final List<KrsCourseItem> courses;

  const KrsApprovalDetail({
    required this.krsId,
    required this.mahasiswaId,
    required this.nim,
    required this.nama,
    required this.prodi,
    required this.semester,
    required this.ipk,
    required this.tahunAkademik,
    required this.totalSks,
    required this.status,
    this.disetujuiAt,
    required this.courses,
  });

  bool get isApproved => status == 'disetujui';
  bool get needsApproval => status == 'menunggu_persetujuan';

  factory KrsApprovalDetail.fromJson(Map<String, dynamic> json) {
    final m = json['mahasiswa'] as Map<String, dynamic>? ?? {};
    final rawCourses = json['matakuliah'] as List? ?? [];
    final courses = rawCourses
        .map((c) => KrsCourseItem.fromJson(c as Map<String, dynamic>))
        .toList();

    return KrsApprovalDetail(
      krsId: json['krs_id'] as int? ?? 0,
      mahasiswaId: m['id'] as int? ?? 0,
      nim: m['nim']?.toString() ?? '',
      nama: m['nama']?.toString() ?? '',
      prodi: m['prodi']?.toString() ?? 'Politeknik Indonusa',
      semester: (m['semester'] as num?)?.toInt() ?? 1,
      ipk: (m['ipk'] as num?)?.toDouble() ?? 0,
      tahunAkademik: json['tahun_akademik']?.toString() ?? '-',
      totalSks: (json['total_sks'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'menunggu_persetujuan',
      disetujuiAt: json['disetujui_at']?.toString(),
      courses: courses,
    );
  }
}

class PaConsultationNote {
  final int id;
  final String tanggal;
  final String kategori;
  final String isi;
  final String? kesimpulan;
  final String dosen;

  const PaConsultationNote({
    required this.id,
    required this.tanggal,
    required this.kategori,
    required this.isi,
    this.kesimpulan,
    required this.dosen,
  });

  factory PaConsultationNote.fromJson(Map<String, dynamic> json) {
    return PaConsultationNote(
      id: json['id'] as int? ?? 0,
      tanggal: json['tanggal']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? 'Akademik',
      isi: json['isi']?.toString() ?? '',
      kesimpulan: json['kesimpulan']?.toString(),
      dosen: json['dosen']?.toString() ?? 'Dosen PA',
    );
  }
}
