/// Opsi master SIPPM untuk form proposal mobile.
class SippmLookup {
  final int id;
  final String name;
  final String subtitle;

  const SippmLookup({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  factory SippmLookup.fromJson(Map<String, dynamic> json) {
    return SippmLookup(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['nama'] ?? json['nama_skema'] ?? json['nama_gelombang'] ?? '')
          .toString(),
      subtitle: (json['kode'] ??
              json['tahun_anggaran'] ??
              json['tipe'] ??
              '')
          .toString(),
    );
  }
}

class SippmLookups {
  final List<SippmLookup> skema;
  final List<SippmLookup> periode;

  const SippmLookups({
    this.skema = const <SippmLookup>[],
    this.periode = const <SippmLookup>[],
  });
}
