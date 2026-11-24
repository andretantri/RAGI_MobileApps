import 'package:intl/intl.dart';

import 'mobile_feature_model.dart';

/// Informasi halaman dari envelope `{status, message, data, meta}`.
class MobileStaffMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final int? from;
  final int? to;

  const MobileStaffMeta({
    this.currentPage = 1,
    this.perPage = 15,
    this.total = 0,
    this.lastPage = 1,
    this.from,
    this.to,
  });

  static const empty = MobileStaffMeta();

  factory MobileStaffMeta.fromJson(Map<String, dynamic> json) {
    return MobileStaffMeta(
      currentPage: _int(json['current_page']) ?? 1,
      perPage: _int(json['per_page']) ?? 15,
      total: _int(json['total']) ?? 0,
      lastPage: _int(json['last_page']) ?? 1,
      from: _int(json['from']),
      to: _int(json['to']),
    );
  }

  static int? _int(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}

/// Satu halaman daftar mobile staff: item generik + meta backend.
class MobileStaffPage {
  final List<MobileFeatureItem> items;
  final MobileStaffMeta meta;

  const MobileStaffPage({
    this.items = const <MobileFeatureItem>[],
    this.meta = MobileStaffMeta.empty,
  });

  factory MobileStaffPage.fromJson(dynamic payload) {
    if (payload is! Map) return const MobileStaffPage();

    final raw = payload['data'];
    final list = raw is List
        ? raw
        : (raw is Map && raw['data'] is List ? raw['data'] as List : const []);
    final meta = payload['meta'] is Map
        ? MobileStaffMeta.fromJson(
            Map<String, dynamic>.from(payload['meta'] as Map),
          )
        : MobileStaffMeta.empty;

    return MobileStaffPage(
      items: list
          .whereType<Map>()
          .map((e) => MobileFeatureItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      meta: meta,
    );
  }
}

/// Opsi master SIMPEG yang dipakai form self-service.
///
/// ID selalu berasal dari API master (`/api/simpeg/...`), bukan nilai hardcode.
class MobileStaffMasterOption {
  final int id;
  final String name;
  final String subtitle;
  final String durationType;
  final int? fixedDurationDays;

  const MobileStaffMasterOption({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.durationType = '',
    this.fixedDurationDays,
  });

  bool get isFixedDuration => durationType == 'ditetapkan';

  factory MobileStaffMasterOption.fromJson(Map<String, dynamic> json) {
    return MobileStaffMasterOption(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: _pick(json, const [
        'nama',
        'nama_jenis',
        'nama_kategori',
        'jenis',
        'name',
      ]),
      subtitle: _pick(json, const [
        'kode',
        'tipe_durasi',
        'keterangan',
        'keterangan_singkat',
      ]),
      durationType: json['tipe_durasi']?.toString() ?? '',
      fixedDurationDays: json['durasi_hari'] is int
          ? json['durasi_hari'] as int
          : int.tryParse(json['durasi_hari']?.toString() ?? ''),
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

/// Kumpulan master yang dibutuhkan form SIMPEG mobile.
class MobileStaffLookups {
  final List<MobileStaffMasterOption> jenisCuti;
  final List<MobileStaffMasterOption> jenisIzin;
  final List<MobileStaffMasterOption> kategoriKegiatan;
  final List<MobileStaffMasterOption> jenisTransportasi;
  final List<MobileStaffMasterOption> kategoriSk;

  /// Master yang gagal dimuat, dipakai form untuk menampilkan peringatan.
  final Map<String, String> errors;

  const MobileStaffLookups({
    this.jenisCuti = const <MobileStaffMasterOption>[],
    this.jenisIzin = const <MobileStaffMasterOption>[],
    this.kategoriKegiatan = const <MobileStaffMasterOption>[],
    this.jenisTransportasi = const <MobileStaffMasterOption>[],
    this.kategoriSk = const <MobileStaffMasterOption>[],
    this.errors = const <String, String>{},
  });

  List<MobileStaffMasterOption> optionsFor(String key) => switch (key) {
    'jenis_cuti' => jenisCuti,
    'jenis_izin' => jenisIzin,
    'kategori_kegiatan' => kategoriKegiatan,
    'jenis_transportasi' => jenisTransportasi,
    'kategori_sk' => kategoriSk,
    _ => const <MobileStaffMasterOption>[],
  };

  String labelFor(String key) => switch (key) {
    'jenis_cuti' => 'Jenis cuti',
    'jenis_izin' => 'Jenis izin jam kerja',
    'kategori_kegiatan' => 'Kategori kegiatan',
    'jenis_transportasi' => 'Jenis transportasi',
    'kategori_sk' => 'Kategori SK',
    _ => key,
  };
}

/// Baris komponen pendapatan/potongan pada detail payroll.
class MobileStaffPayrollComponent {
  final String komponen;
  final String nominalText;
  final String? keterangan;

  const MobileStaffPayrollComponent({
    required this.komponen,
    required this.nominalText,
    this.keterangan,
  });

  double get nominal => double.tryParse(nominalText) ?? 0;

  String get formattedNominal => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(nominal);

  static List<MobileStaffPayrollComponent> listFromJson(dynamic value) {
    if (value is! List) return const <MobileStaffPayrollComponent>[];
    return value
        .whereType<Map>()
        .map(
          (e) => MobileStaffPayrollComponent(
            komponen: e['komponen']?.toString() ?? 'Komponen',
            nominalText: e['nominal']?.toString() ?? '0',
            keterangan: e['keterangan']?.toString(),
          ),
        )
        .toList();
  }
}

/// Detail slip gaji milik pegawai login (endpoint §47).
class MobileStaffPayrollDetail {
  final MobileFeatureItem item;
  final String periode;
  final String gajiPokok;
  final String totalTunjangan;
  final String totalPotongan;
  final String gajiBersih;
  final List<MobileStaffPayrollComponent> pendapatan;
  final List<MobileStaffPayrollComponent> potongan;

  const MobileStaffPayrollDetail({
    required this.item,
    this.periode = '',
    this.gajiPokok = '',
    this.totalTunjangan = '',
    this.totalPotongan = '',
    this.gajiBersih = '',
    this.pendapatan = const <MobileStaffPayrollComponent>[],
    this.potongan = const <MobileStaffPayrollComponent>[],
  });

  factory MobileStaffPayrollDetail.fromJson(Map<String, dynamic> json) {
    return MobileStaffPayrollDetail(
      item: MobileFeatureItem.fromJson(json),
      periode: json['periode']?.toString() ?? '',
      gajiPokok: json['gaji_pokok']?.toString() ?? '',
      totalTunjangan: json['total_tunjangan']?.toString() ?? '',
      totalPotongan: json['total_potongan']?.toString() ?? '',
      gajiBersih: json['gaji_bersih']?.toString() ?? '',
      pendapatan: MobileStaffPayrollComponent.listFromJson(json['pendapatan']),
      potongan: MobileStaffPayrollComponent.listFromJson(json['potongan']),
    );
  }
}

/// Hasil endpoint signed URL e-file (§51).
class MobileStaffDownloadLink {
  final String id;
  final String namaDokumen;
  final String fileUrl;
  final int expiresInSeconds;

  const MobileStaffDownloadLink({
    required this.id,
    required this.namaDokumen,
    required this.fileUrl,
    this.expiresInSeconds = 900,
  });

  factory MobileStaffDownloadLink.fromJson(Map<String, dynamic> json) {
    return MobileStaffDownloadLink(
      id: json['id']?.toString() ?? '',
      namaDokumen: json['nama_dokumen']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      expiresInSeconds:
          int.tryParse(json['expires_in_seconds']?.toString() ?? '') ?? 900,
    );
  }
}

/// Statistik referral SPMB yang dikirim pada kartu pertama response §referral.
class MobileStaffReferralStats {
  final int total;
  final int claimed;
  final int qualified;
  final int rewarded;
  final int cancelled;

  const MobileStaffReferralStats({
    this.total = 0,
    this.claimed = 0,
    this.qualified = 0,
    this.rewarded = 0,
    this.cancelled = 0,
  });

  factory MobileStaffReferralStats.fromJson(dynamic value) {
    if (value is! Map) return const MobileStaffReferralStats();
    final data = Map<String, dynamic>.from(value);
    return MobileStaffReferralStats(
      total: _count(data, const ['total', 'mahasiswa_baru']),
      claimed: _count(data, const ['claimed']),
      qualified: _count(data, const ['qualified', 'dapat_direimburse']),
      rewarded: _count(data, const ['rewarded', 'sudah_direimburse']),
      cancelled: _count(data, const ['cancelled']),
    );
  }

  List<(String label, int value)> get rows => [
    ('Mahasiswa baru', total),
    ('Diklaim', claimed),
    ('Dapat direimburse', qualified),
    ('Sudah direimburse', rewarded),
    ('Dibatalkan', cancelled),
  ];

  static int _count(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }
}
