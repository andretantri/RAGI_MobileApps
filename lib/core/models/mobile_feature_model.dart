/// Item generik untuk fitur mobile yang datanya diambil dari API RAG.
///
/// Fitur seperti payroll, pengajuan SIKEU, e-file, proposal, dan referral
/// memiliki bentuk JSON yang berbeda. Model ini menyatukan field yang paling
/// sering dibutuhkan UI tanpa merekayasa data ketika field tidak tersedia.
class MobileFeatureItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final String date;
  final String amount;
  final Map<String, dynamic> raw;

  const MobileFeatureItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.amount,
    required this.raw,
  });

  bool get hasStatus => status.isNotEmpty;
  bool get hasDate => date.isNotEmpty;
  bool get hasAmount => amount.isNotEmpty;

  /// Kode referral dipakai tombol "Salin Kode" pada fitur SPMB.
  /// Fallback ke [id] bila backend memakai field generik.
  String get referralCode {
    final code = _pick(raw, const [
      'kode_referral',
      'referral_code',
      'kode',
      'code',
    ]);
    return code.isNotEmpty ? code : id;
  }

  /// URL pendukung dari response backend (file, foto, atau tautan referral).
  String get fileUrl =>
      _pick(raw, const ['file_proposal_url', 'file_url', 'foto_url', 'url']);

  String get shareUrl => _pick(raw, const ['share_url', 'link', 'url']);

  factory MobileFeatureItem.fromJson(Map<String, dynamic> json) {
    return MobileFeatureItem(
      id: _pick(json, const ['id', 'uuid', 'kode', 'code']),
      title: _pick(json, const [
        'title',
        'nama',
        'judul',
        'name',
        'course_name',
        'nama_kegiatan',
        'jenis',
      ]),
      subtitle: _pick(json, const [
        'subtitle',
        'keterangan',
        'description',
        'deskripsi',
        'nama_mahasiswa',
        'mahasiswa',
        'nomor_surat',
        'skema',
        'program',
      ]),
      status: _pick(json, const [
        'status',
        'status_approval',
        'status_pendaftaran',
        'status_pengajuan',
        'state',
      ]),
      date: _pick(json, const [
        'created_at',
        'tanggal',
        'date',
        'periode',
        'tanggal_pengajuan',
        'tanggal_mulai',
      ]),
      amount: _pick(json, const [
        'amount',
        'nominal',
        'jumlah',
        'gaji_bersih',
        'total',
      ]),
      raw: json,
    );
  }

  static String _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }
}
