import '../constants/mobile_feature_config.dart';

/// Payload aksi tulis untuk fitur mobile.
///
/// Field mengikuti kontrak `MobileStaffController.md`. Nilai kosong/opsional
/// dibuang supaya backend tidak menerima `null` pada field yang tidak diisi.
class MobileFeatureSubmission {
  final MobileFeatureFormType type;
  final Map<String, dynamic> values;

  const MobileFeatureSubmission({required this.type, required this.values});

  /// Nama field multipart yang dipakai backend untuk berkas lampiran.
  String get fileKey => switch (type) {
    MobileFeatureFormType.proposalSippm => 'file_proposal',
    MobileFeatureFormType.pengajuanSikeu => 'file_lampiran',
    MobileFeatureFormType.tiketSinapra => 'foto',
    MobileFeatureFormType.cutiSimpeg => 'file_pendukung',
    MobileFeatureFormType.izinKerjaSimpeg => 'file_bukti',
    MobileFeatureFormType.suratTugasSimpeg => 'file_surat_tugas',
    MobileFeatureFormType.skPegawaiSimpeg => 'file_sk',
    MobileFeatureFormType.eFileArsip => 'file',
    MobileFeatureFormType.referralSpmb || MobileFeatureFormType.none => '',
  };

  bool get supportsFile => fileKey.isNotEmpty;

  Map<String, dynamic> toJson() {
    final data = Map<String, dynamic>.from(switch (type) {
      MobileFeatureFormType.proposalSippm => {
        'judul': _text('judul'),
        'abstrak': _text('abstrak'),
        'rumpun_ilmu': _text('rumpun_ilmu'),
        'skema_id': _int('skema_id'),
        'periode_id': _int('periode_id'),
        'target_tkt': _int('target_tkt'),
        'anggaran_diajukan': _rupiah('anggaran_diajukan'),
      },
      MobileFeatureFormType.pengajuanSikeu => {
        'judul_pengajuan': _text('judul_pengajuan'),
        'deskripsi': _text('deskripsi'),
        'jenis_pengajuan': _text('jenis_pengajuan'),
        'nominal_diajukan': _rupiah('nominal_diajukan'),
        'nama_bank_penerima': _text('nama_bank_penerima'),
        'nomor_rekening_penerima': _text('nomor_rekening_penerima'),
        'nama_rekening_penerima': _text('nama_rekening_penerima'),
      },
      MobileFeatureFormType.tiketSinapra => {
        'judul': _text('judul'),
        'deskripsi_kerusakan': _text('deskripsi_kerusakan'),
        'prioritas': _text('prioritas'),
        'ruangan_id': _int('ruangan_id'),
        'aset_id': _int('aset_id'),
      },
      MobileFeatureFormType.cutiSimpeg => {
        'master_jenis_cuti_id': _int('master_jenis_cuti_id'),
        'tanggal_mulai': _text('tanggal_mulai'),
        'tanggal_selesai': _text('tanggal_selesai'),
        'jumlah_hari': _int('jumlah_hari'),
        'alasan': _text('alasan'),
      },
      MobileFeatureFormType.izinKerjaSimpeg => {
        'master_jenis_izin_id': _int('master_jenis_izin_id'),
        'tanggal': _text('tanggal'),
        'jam_mulai': _text('jam_mulai'),
        'jam_selesai': _text('jam_selesai'),
        'alasan': _text('alasan'),
      },
      MobileFeatureFormType.suratTugasSimpeg => {
        'kategori_kegiatan_id': _int('kategori_kegiatan_id'),
        'jenis_transportasi_id': _int('jenis_transportasi_id'),
        'nama_kegiatan': _text('nama_kegiatan'),
        'jam_pelaksanaan': _text('jam_pelaksanaan'),
        'penyelenggara': _text('penyelenggara'),
        'tempat_berangkat': _text('tempat_berangkat'),
        'lokasi_tujuan': _text('lokasi_tujuan'),
        'tanggal_berangkat': _text('tanggal_berangkat'),
        'tanggal_kembali': _text('tanggal_kembali'),
        'tanggal_mulai': _text('tanggal_mulai'),
        'tanggal_selesai': _text('tanggal_selesai'),
        'maksud_tujuan': _text('maksud_tujuan'),
        'estimasi_biaya': _rupiah('estimasi_biaya'),
        'keterangan': _text('keterangan'),
      },
      MobileFeatureFormType.skPegawaiSimpeg => {
        'kategori_sk_id': _int('kategori_sk_id'),
        'nomor_sk': _text('nomor_sk'),
        'judul_sk': _text('judul_sk'),
        'tanggal_sk': _text('tanggal_sk'),
        'tmt_sk': _text('tmt_sk'),
        'tmt_selesai': _text('tmt_selesai'),
        'pejabat_penetap': _text('pejabat_penetap'),
        'keterangan': _text('keterangan'),
      },
      MobileFeatureFormType.eFileArsip => {
        'nama_dokumen': _text('nama_dokumen'),
        'jenis_dokumen': _text('jenis_dokumen'),
      },
      MobileFeatureFormType.referralSpmb ||
      MobileFeatureFormType.none => const <String, dynamic>{},
    });

    return data..removeWhere((_, value) => value == null);
  }

  String? _text(String key) {
    final value = values[key]?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  int? _int(String key) {
    final value = values[key]?.toString().trim() ?? '';
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  int? _rupiah(String key) {
    final value = values[key]?.toString().trim() ?? '';
    if (value.isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }
}
