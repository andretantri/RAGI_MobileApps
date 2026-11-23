import '../constants/mobile_feature_config.dart';

/// Payload aksi tulis untuk fitur mobile.
///
/// Field mengikuti kontrak `MobileStaffController.md`. Nilai kosong/opsional
/// dibuang supaya backend tidak menerima `null` pada field yang tidak diisi.
class MobileFeatureSubmission {
  final MobileFeatureFormType type;
  final Map<String, dynamic> values;

  const MobileFeatureSubmission({
    required this.type,
    required this.values,
  });

  /// Nama field multipart yang dipakai backend untuk berkas lampiran.
  String get fileKey => switch (type) {
        MobileFeatureFormType.proposalSippm => 'file_proposal',
        MobileFeatureFormType.pengajuanSikeu => 'file_lampiran',
        MobileFeatureFormType.tiketSinapra => 'foto',
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
          'unit_kas_id': _int('unit_kas_id'),
        },
      MobileFeatureFormType.tiketSinapra => {
          'judul': _text('judul'),
          'deskripsi_kerusakan': _text('deskripsi_kerusakan'),
          'prioritas': _text('prioritas'),
          'ruangan_id': _int('ruangan_id'),
          'aset_id': _int('aset_id'),
        },
      MobileFeatureFormType.referralSpmb ||
      MobileFeatureFormType.none =>
        const <String, dynamic>{},
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
