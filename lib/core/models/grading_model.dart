class GradingClassItem {
  final int kelasId;
  final String kodeKelas;
  final String namaKelas;
  final String kodeMk;
  final String namaMk;
  final int sks;
  final String prodi;
  final String hari;
  final String jam;
  final int totalMahasiswa;
  final int jumlahDinilai;
  final String statusPenilaian; // 'belum_dinilai' | 'draft' | 'selesai'
  final Map<String, double> bobot;

  const GradingClassItem({
    required this.kelasId,
    required this.kodeKelas,
    required this.namaKelas,
    required this.kodeMk,
    required this.namaMk,
    required this.sks,
    required this.prodi,
    required this.hari,
    required this.jam,
    required this.totalMahasiswa,
    required this.jumlahDinilai,
    required this.statusPenilaian,
    required this.bobot,
  });

  bool get isCompleted => statusPenilaian == 'selesai';
  bool get isDraft => statusPenilaian == 'draft';
  double get progress =>
      totalMahasiswa > 0 ? (jumlahDinilai / totalMahasiswa).clamp(0.0, 1.0) : 0.0;

  factory GradingClassItem.fromJson(Map<String, dynamic> json) {
    final bobotRaw = json['bobot'] as Map<String, dynamic>? ?? {};
    final bobot = <String, double>{
      'harian': (bobotRaw['harian'] as num?)?.toDouble() ?? 0.0,
      'uts': (bobotRaw['uts'] as num?)?.toDouble() ?? 0.0,
      'uas': (bobotRaw['uas'] as num?)?.toDouble() ?? 0.0,
      'praktik': (bobotRaw['praktik'] as num?)?.toDouble() ?? 0.0,
    };

    return GradingClassItem(
      kelasId: json['kelas_id'] as int? ?? 0,
      kodeKelas: json['kode_kelas']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      kodeMk: json['kode_mk']?.toString() ?? '',
      namaMk: json['nama_mk']?.toString() ?? '',
      sks: (json['sks'] as num?)?.toInt() ?? 0,
      prodi: json['prodi']?.toString() ?? '-',
      hari: json['hari']?.toString() ?? '-',
      jam: json['jam']?.toString() ?? '-',
      totalMahasiswa: (json['total_mahasiswa'] as num?)?.toInt() ?? 0,
      jumlahDinilai: (json['jumlah_dinilai'] as num?)?.toInt() ?? 0,
      statusPenilaian: json['status_penilaian']?.toString() ?? 'belum_dinilai',
      bobot: bobot,
    );
  }
}

class StudentGradeItem {
  final int krsDetailId;
  final int mahasiswaId;
  final String nim;
  final String nama;
  final String? avatar;
  double? nilaiHarian;
  double? nilaiUts;
  double? nilaiUas;
  double? nilaiPraktik;
  double? nilaiAkhir;
  String? nilaiHuruf;
  double? bobotMutu;
  bool isFinal;

  StudentGradeItem({
    required this.krsDetailId,
    required this.mahasiswaId,
    required this.nim,
    required this.nama,
    this.avatar,
    this.nilaiHarian,
    this.nilaiUts,
    this.nilaiUas,
    this.nilaiPraktik,
    this.nilaiAkhir,
    this.nilaiHuruf,
    this.bobotMutu,
    this.isFinal = false,
  });

  void recalculate(Map<String, double> bobot) {
    if (nilaiHarian == null &&
        nilaiUts == null &&
        nilaiUas == null &&
        nilaiPraktik == null) {
      nilaiAkhir = null;
      nilaiHuruf = null;
      bobotMutu = null;
      return;
    }

    final h = nilaiHarian ?? 0.0;
    final t = nilaiUts ?? 0.0;
    final u = nilaiUas ?? 0.0;
    final p = nilaiPraktik ?? 0.0;

    final bh = bobot['harian'] ?? 0.20;
    final bt = bobot['uts'] ?? 0.25;
    final bu = bobot['uas'] ?? 0.35;
    final bp = bobot['praktik'] ?? 0.20;

    final total = (h * bh) + (t * bt) + (u * bu) + (p * bp);
    nilaiAkhir = double.parse(total.toStringAsFixed(2));

    if (total >= 85) {
      nilaiHuruf = 'A';
      bobotMutu = 4.00;
    } else if (total >= 80) {
      nilaiHuruf = 'A-';
      bobotMutu = 3.75;
    } else if (total >= 75) {
      nilaiHuruf = 'B+';
      bobotMutu = 3.50;
    } else if (total >= 70) {
      nilaiHuruf = 'B';
      bobotMutu = 3.00;
    } else if (total >= 65) {
      nilaiHuruf = 'B-';
      bobotMutu = 2.75;
    } else if (total >= 60) {
      nilaiHuruf = 'C+';
      bobotMutu = 2.50;
    } else if (total >= 55) {
      nilaiHuruf = 'C';
      bobotMutu = 2.00;
    } else if (total >= 45) {
      nilaiHuruf = 'D';
      bobotMutu = 1.00;
    } else {
      nilaiHuruf = 'E';
      bobotMutu = 0.00;
    }
  }

  factory StudentGradeItem.fromJson(Map<String, dynamic> json) {
    return StudentGradeItem(
      krsDetailId: json['krs_detail_id'] as int? ?? 0,
      mahasiswaId: json['mahasiswa_id'] as int? ?? 0,
      nim: json['nim']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      nilaiHarian: (json['nilai_harian'] as num?)?.toDouble(),
      nilaiUts: (json['nilai_uts'] as num?)?.toDouble(),
      nilaiUas: (json['nilai_uas'] as num?)?.toDouble(),
      nilaiPraktik: (json['nilai_praktik'] as num?)?.toDouble(),
      nilaiAkhir: (json['nilai_akhir'] as num?)?.toDouble(),
      nilaiHuruf: json['nilai_huruf']?.toString(),
      bobotMutu: (json['bobot_mutu'] as num?)?.toDouble(),
      isFinal: json['is_final'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'krs_detail_id': krsDetailId,
        'nilai_harian': nilaiHarian,
        'nilai_uts': nilaiUts,
        'nilai_uas': nilaiUas,
        'nilai_praktik': nilaiPraktik,
        'is_final': isFinal,
      };
}

class GradingClassDetail {
  final int kelasId;
  final String kodeKelas;
  final String namaKelas;
  final String kodeMk;
  final String namaMk;
  final int sks;
  final String prodi;
  final Map<String, double> bobot;
  final List<StudentGradeItem> students;

  const GradingClassDetail({
    required this.kelasId,
    required this.kodeKelas,
    required this.namaKelas,
    required this.kodeMk,
    required this.namaMk,
    required this.sks,
    required this.prodi,
    required this.bobot,
    required this.students,
  });

  factory GradingClassDetail.fromJson(Map<String, dynamic> json) {
    final bobotRaw = json['bobot'] as Map<String, dynamic>? ?? {};
    final bobot = <String, double>{
      'harian': (bobotRaw['harian'] as num?)?.toDouble() ?? 0.0,
      'uts': (bobotRaw['uts'] as num?)?.toDouble() ?? 0.0,
      'uas': (bobotRaw['uas'] as num?)?.toDouble() ?? 0.0,
      'praktik': (bobotRaw['praktik'] as num?)?.toDouble() ?? 0.0,
    };

    final rawStudents = json['students'] as List? ?? [];
    final students = rawStudents
        .map((s) => StudentGradeItem.fromJson(s as Map<String, dynamic>))
        .toList();

    return GradingClassDetail(
      kelasId: json['kelas_id'] as int? ?? 0,
      kodeKelas: json['kode_kelas']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      kodeMk: json['kode_mk']?.toString() ?? '',
      namaMk: json['nama_mk']?.toString() ?? '',
      sks: (json['sks'] as num?)?.toInt() ?? 3,
      prodi: json['prodi']?.toString() ?? '-',
      bobot: bobot,
      students: students,
    );
  }
}
