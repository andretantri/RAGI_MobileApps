/// Informasi versi rilis dan catatan pembaruan (changelog) aplikasi MyIn-U Staff.
///
/// Setiap kali melakukan pembaruan/rilis aplikasi, perbarui konstanta versi dan
/// tambahkan entri terbaru di [changelog] agar selaras dengan `pubspec.yaml`.
class AppReleaseEntry {
  final String version;
  final int buildNumber;
  final String date;
  final String title;
  final List<String> highlights;

  const AppReleaseEntry({
    required this.version,
    required this.buildNumber,
    required this.date,
    required this.title,
    required this.highlights,
  });

  String get badge => 'v$version (Build $buildNumber)';
}

class AppReleaseInfo {
  AppReleaseInfo._();

  static const String version = '1.1.2';
  static const int buildNumber = 32;

  static const String loginLabel = 'Versi $version • Build $buildNumber';
  static const String footerLabel =
      'MyIn-U Staff • Versi $version (Build $buildNumber)';
  static const String aboutHeaderLabel =
      'Versi $version (Build $buildNumber) • Ekosistem SIAKAD & SIMPEG Terpadu';
  static const String buildLabel = 'Build $buildNumber (Release)';

  static const List<AppReleaseEntry> changelog = [
    AppReleaseEntry(
      version: '1.1.2',
      buildNumber: 32,
      date: '26 Nov 2026',
      title: 'Widget Home Screen Adaptif & Log Update In-App',
      highlights: [
        'Penambahan Widget Home Screen Android adaptif (MyIn-U Staff: Jadwal Mengajar untuk Dosen & Pengumuman Kampus untuk Pegawai/Tendik) dengan desain gradien biru senada aplikasi.',
        'Penambahan pilihan Widget khusus Pengumuman Kampus MyIn-U di layar utama perangkat.',
        'Penambahan tab Log Update pada menu Tentang Aplikasi serta ringkasan pembaruan di Informasi Sistem.',
      ],
    ),
    AppReleaseEntry(
      version: '1.1.1',
      buildNumber: 31,
      date: '26 Nov 2026',
      title: 'Widget Adaptif, Perbaikan Kamera, & Notifikasi H-15 Menit',
      highlights: [
        'Penambahan Widget Home Screen Android adaptif (Jadwal Mengajar untuk Dosen & Pengumuman Kampus untuk Pegawai/Tendik) dengan tema gradien biru senada aplikasi.',
        'Scan wajah ulang saat gagal kini langsung membuka kamera wajah tanpa layar perantara.',
        'Perbaikan format jam masuk/pulang ke waktu lokal ringkas (HH:mm WIB) agar tidak overflow.',
        'Penambahan banner informasi libur nasional pada tombol absen sesuai konfigurasi shift.',
        'Aktivasi penjadwalan alarm notifikasi lokal H-15 menit sebelum jam masuk & pulang serta penerapan RBAC pada preferensi notifikasi.',
      ],
    ),
    AppReleaseEntry(
      version: '1.1.0',
      buildNumber: 30,
      date: '24 Nov 2026',
      title: 'Informasi Sistem & Kepatuhan Memori 16 KB',
      highlights: [
        'Penambahan menu Informasi Sistem pada halaman Profil pengguna.',
        'Dukungan penuh arsitektur memori 16 KB page size untuk Android 15+ & Google Play.',
        'Pembaruan tampilan versi dan sinkronisasi QR presensi perkuliahan.',
      ],
    ),
    AppReleaseEntry(
      version: '1.1.0',
      buildNumber: 29,
      date: '24 Nov 2026',
      title: 'Optimasi Izin Lokasi On-Demand',
      highlights: [
        'Izin lokasi & GPS hanya diminta saat pengguna mengakses fitur presensi.',
        'Penambahan dialog panduan aktivasi GPS ketika lokasi perangkat mati.',
      ],
    ),
    AppReleaseEntry(
      version: '1.1.0',
      buildNumber: 28,
      date: '24 Nov 2026',
      title: 'Perbaikan Deteksi Wajah Biometrik',
      highlights: [
        'Optimalisasi deteksi wajah multi-rotasi & tombol ambil foto manual yang selalu aktif.',
        'Pemulihan tampilan nama lengkap dan NIDN tanpa penyamaran bintang.',
      ],
    ),
  ];
}
