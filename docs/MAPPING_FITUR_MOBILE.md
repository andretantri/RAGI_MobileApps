# Mapping Fitur Mobile — RAG Politeknik Indonusa Surakarta

Dokumen ini menjadi acuan **fitur mana yang layak ditampilkan di aplikasi mobile** untuk setiap modul RAG, termasuk menu yang muncul di halaman **Profil**. Prinsipnya: mobile bukan versi penuh web, melainkan **pintasan kontekstual + aksi ringan + status**.

## Prinsip umum

1. **Maksimal 3–4 fitur per modul.** Lebih dari itu membuat katalog berat dan membingungkan.
2. **Read-only sebagai default.** Aksi tulis hanya yang risikonya rendah: ajukan, laporkan, unggah lampiran, unduh dokumen.
3. **Satu aksi utama per modul.** Contoh: SINAPRA → `Lapor Kerusakan`, SIPPM → `Cek Status Proposal`.
4. **Jangan duplikasi modul yang sudah ada.** SIAKAD sudah memiliki jadwal, nilai, bimbingan, dan jurnal; SIMPEG sudah memiliki absensi, cuti, dan pengumuman.
5. **Data sensitif butuh perlindungan tambahan.** Payroll, e-file, dan data diri sebaiknya memakai autentikasi ulang/biometrik serta tidak disimpan permanen di cache.
6. **Fallback aman.** Jika endpoint mobile belum tersedia, arahkan ke halaman `under-construction`, bukan menampilkan data simulasi.

---

## 1. Pemetaan modul RAG

| Modul | Fitur mobile yang disarankan | Rujukan data RAG | Role | Yang **tidak** ditampilkan di mobile | Penempatan |
|---|---|---|---|---|---|
| **SIPPM** | 1. **Proposal & Hibah Saya** — daftar proposal, skema, tahun, status.<br>2. **Timeline Review** — catatan reviewer & riwayat status (read-only).<br>3. **Ajukan Proposal** — form ringkas + unggah lampiran PDF.<br>4. **Luaran & Publikasi** — daftar artikel/PkM (read-only). | Modul penelitian & PkM; pola endpoint `/api/v1/mobile/staff/...` bila tersedia | Dosen / peneliti | Manajemen skema, penelaah, review proposal orang lain, laporan keuangan hibah admin, grafik analitik riset | Kartu modul + menu profil `Proposal & Hibah` |
| **SIKEU** | 1. **Slip Payroll** — riwayat gaji per bulan + unduh PDF.<br>2. **Pengajuan Saya** — daftar semua pengajuan keuangan (termasuk reimbes/kas bon) beserta status & catatan; tersedia aksi buat pengajuan ringkas.<br>3. **Ringkasan Potongan** — pajak, BPJS, iuran (read-only). | Modul keuangan & penggajian, menu **Pengajuan** di RAG | Semua pegawai (data sendiri) | Jurnal umum, posting transaksi, rekonsiliasi bank, approval anggaran, laporan keuangan lintas unit | Menu profil `Riwayat Payroll` & `Pengajuan Saya` + kartu modul |
| **SINAPRA** | 1. **Lapor Kerusakan** — foto, lokasi, keterangan.<br>2. **Tiket Saya** — status perbaikan & riwayat.<br>3. **Peminjaman Ruangan/Fasilitas** — status + ajukan singkat. | Modul sarana & prasarana | Semua pegawai | Inventaris aset, mutasi aset, pengadaan, jadwal maintenance admin, manajemen satuan kerja | Kartu modul |
| **ARSIP** | 1. **Dokumen E-File Saya** — SK, surat, kontrak; filter berdasarkan tahun/jenis.<br>2. **Surat Masuk/Keluar** — daftar ringkas (read-only).<br>3. **Ajakan Unduh/Pinjaman Dokumen** — aksi ringan dengan alasan. | Modul persuratan & arsip dinamis | Semua pegawai | Generate nomor surat, kop surat, klasifikasi/retensi, manajemen user arsip, tanda tangan digital admin | Menu profil `Dokumen E-File` + kartu modul |
| **LMS** | 1. **Materi & Bahan Ajar** — RPS, PDF, video per kelas.<br>2. **Pengumuman Kelas** — info terbaru dosen.<br>3. **Diskusi Ringan** — balas thread singkat.<br>Catatan: token presensi & jurnal tetap di **SIAKAD → perkuliahan**. | Modul pembelajaran | Dosen pengajar | Course builder, quiz engine, gradebook lengkap, analitik belajar, backup/restore kursus | Menu profil `Bahan Ajar & RPS` + kartu modul |
| **SPMB** | 1. **Info Program Referral** — syarat, periode, target, dan cara bagikan.<br>2. **Kode/QR Referral Saya** — salin/bagikan ke calon mahasiswa.<br>3. **Mahasiswa Referral Saya** — daftar calon mahasiswa yang dibawa + status pendaftaran.<br>4. **Status Poin/Insentif Referral** — ringkasan bila tersedia di backend (read-only). | Modul penerimaan mahasiswa baru, fitur referral dosen/staff | Dosen & tendik yang memiliki kode referral | Formulir pendaftaran mahasiswa, seleksi & penilaian, ujian, cetak kartu, pembayaran, wizard admin, statistik umum (kecuali panitia) | Kartu modul + menu profil `Referral SPMB` |

### Ringkasan aksi mobile per modul

| Modul | Aksi utama (1) | Aksi pendukung | Sifat |
|---|---|---|---|
| SIPPM | Ajukan proposal | Lihat status, unduh lampiran | Dosen |
| SIKEU | Unduh slip payroll | Lihat **Pengajuan Saya**, buat pengajuan ringkas, lihat potongan | Sensitif |
| SINAPRA | Lapor kerusakan | Cek tiket, pinjam ruang | Ringan |
| ARSIP | Unduh e-file | Cek surat, ajukan pinjam | Sensitif |
| LMS | Buka bahan ajar | Cek pengumuman, balas diskusi | Dosen |
| SPMB | Bagikan kode/QR referral | Lihat mahasiswa referral, cek status poin/insentif | Dosen & tendik |

---

## 2. Pemetaan menu Profil pengguna

Menu profil sebaiknya **bukan duplikat katalog modul**, melainkan pintasan personal ke data milik akun yang sedang login.

| Menu profil saat ini | Modul sumber | Fitur yang ditampilkan | Route usulan | Role | Prioritas |
|---|---|---|---|---|---|
| **Data Diri & Biodata** | SIMPEG / Auth | Nama gelar, NIDN/NIP, jabatan, unit, kontak, alamat kantor. Bisa edit fields aman (no HP/email). | `/profile/data-diri` | Semua | **P0** |
| **Dokumen E-File** | ARSIP | Daftar dokumen pribadi, unduh, filter jenis/tahun. | `/profile/e-file` | Semua | P1 |
| **Riwayat Payroll** | SIKEU | Slip gaji bulanan, rekap potongan, unduh PDF. | `/profile/payroll` | Semua | P1 |
| **Pengajuan Saya** | SIKEU | Daftar pengajuan keuangan (reimbes/kas bon/lainnya), status, catatan, dan form pengajuan ringkas. | `/profile/pengajuan-sikeu` | Semua | P1 |
| **Proposal & Hibah** | SIPPM | Proposal saya, status review, ajukan baru (dosen). | `/profile/proposal-hibah` | Dosen | P1 |
| **Bahan Ajar & RPS** | LMS | Materi per kelas, RPS, unggah bahan ajar baru (dosen). | `/profile/bahan-ajar` | Dosen | P1 |
| **Referral SPMB** | SPMB | Kode/QR referral, daftar mahasiswa yang dibawa, status poin/insentif. | `/profile/referral-spmb` | Dosen & tendik | P2 |
| Jadwal Mengajar | SIAKAD | Sudah tersedia | `/schedule` | Dosen | Sudah ada |
| Input Nilai (KHS & OBE) | SIAKAD | Sudah tersedia | `/siakad/grading` | Dosen | Sudah ada |
| Bimbingan Akademik (DPA) | SIAKAD | Sudah tersedia | `/siakad/advising` | Dosen | Sudah ada |
| Keamanan Biometrik | Lokal | Sudah tersedia | `/profile/biometric` | Semua | Sudah ada |
| Preferensi Notifikasi | Lokal | Sudah tersedia | `/profile/notification-preferences` | Semua | Sudah ada |
| Tentang Aplikasi | Lokal | Sudah tersedia | `/profile/about` | Semua | Sudah ada |

### Rekomendasi penyesuaian menu profil

- Pisahkan menjadi 3 grup agar lebih mudah dipindai:
  1. **Data Pribadi & Keuangan** → Data Diri, E-File, Payroll, Pengajuan Saya.
  2. **Akademik, Riset & Referral** → Jadwal, Nilai, Bimbingan, Proposal & Hibah, Bahan Ajar, Referral SPMB.
  3. **Pengaturan** → Biometrik, Notifikasi, Tentang.
- Sembunyikan `Proposal & Hibah` dan `Bahan Ajar & RPS` untuk tendik (`dosenOnly`).
- Tambahkan label kecil **“Terhubung ke SIPPM”**, **“Terhubung ke SIKEU”**, dll. agar pengguna tahu sumber data.
- Untuk `Payroll`, `E-File`, dan `Pengajuan Saya`, minta konfirmasi biometrik/PIN sebelum membuka daftar.
- Untuk `Referral SPMB`, tampilkan kode/QR di bagian atas agar bisa langsung dibagikan; status poin/insentif hanya muncul bila backend mengirim data tersebut.

---

## 3. Prioritas implementasi

| Prioritas | Fitur | Alasan |
|---|---|---|
| **P0** | Data Diri & Biodata | Menuntaskan identitas akun yang sudah diperbaiki di Home/Profile. |
| **P0** | Riwayat Payroll | Paling sering dibutuhkan pegawai; terkait langsung dengan SIKEU. |
| **P1** | Pengajuan Saya (SIKEU) | Menu Pengajuan memang ada di RAG; cukup status + form ringkas. |
| **P1** | Dokumen E-File | Nilai guna tinggi, tapi butuh penanganan file & izin. |
| **P1** | Proposal & Hibah | Sesuai kebutuhan dosen; status tracking saja cukup. |
| **P1** | Bahan Ajar & RPS | Dekat dengan fitur perkuliahan yang sudah ada. |
| **P2** | SINAPRA & ARSIP lanjutan | Butuh alur tiket/verifikasi backend. |
| **P2** | Referral SPMB | Fokus ke kode/QR & mahasiswa binaan, bukan alur pendaftaran penuh. |

---

## 4. Catatan teknis untuk implementasi

- Katalog mobile memuat modul RAG sebagai **hub fitur ringkas** (`isMobileModule: true` + `AppMobileFeatures.forModule`), bukan modul web penuh. Jangan menambahkan pintasan web mentah tanpa kurasi fitur.
- Gunakan pola endpoint mobile yang sudah dipakai: `/api/v1/mobile/staff/...`. Jika backend untuk modul tertentu belum menyediakan, tampilkan kartu informasi "Menunggu integrasi backend" di halaman fitur tanpa data rekaan.
- Pertahankan aturan RBAC yang sudah ada: `parentCode` untuk mewarisi akses, `dosenOnly` untuk fitur dosen.
- Jangan simpan slip payroll/e-file di SharedPreferences; cukup cache sesi singkat di memori atau secure storage bila benar-benar perlu.
- Untuk menu profil yang belum punya halaman, gunakan route `/under-construction` dengan `extra.title`, `category`, `icon`, dan `color` seperti pola saat ini, lalu ganti bertahap.

---

## 5. Hubungan dengan kode saat ini

- Daftar modul yang ditampilkan berasal langsung dari `GET /api/modules/my-modules`, endpoint yang sama dipakai App Launcher web RAG (`http://localhost:57135/#/modules`).
- Service: `lib/core/services/rag_module_service.dart`; provider: `lib/core/providers/rag_module_provider.dart`.
- Provider modul di-key oleh token SSO (`FutureProvider.family`), sehingga daftar modul diambil ulang otomatis saat akun/token berganti — mengikuti perilaku App Launcher web yang me-refetch saat `authToken` berubah.
- `AppModules.mobileModules` di `lib/core/constants/module_config.dart` kini hanya berisi delapan modul bisnis RAG (SIMPEG, SIPPM, SIAKAD, SIKEU, SINAPRA, ARSIP, LMS, SPMB) dan dipakai sebagai pemetaan ikon/warna/route, bukan daftar statis.
- Modul `sso` (IAM & Auth Center) tetap ditampilkan bila dikirim server, tetapi dipetakan ke `/profile/data-diri` (read-only) dan tidak menambah entri `mobileModules`. Tidak ada endpoint backend untuk mengubah profil umum; yang bisa diperbarui di aplikasi hanya avatar.
- Menu profil ada di `lib/presentation/profile/profile_screen.dart` (`_buildMenuSection`).
- Route tersedia di `lib/core/router/app_router.dart`.
- Modul dalam dokumen ini adalah **rencana konten mobile**, bukan perubahan hak akses web.

---

## 6. Status implementasi mobile (update)

Sudah direalisasikan:

- Kartu modul mobile untuk **SIPPM, SIKEU, SINAPRA, ARSIP, LMS, SPMB** yang membuka hub fitur ringkas.
- Halaman hub per modul: `lib/presentation/features/module_feature_hub_screen.dart`.
- Halaman daftar data generik per fitur: `lib/presentation/features/mobile_feature_list_screen.dart`.
- Katalog fitur & endpoint: `lib/core/constants/mobile_feature_config.dart`.
- Service dan provider generik: `lib/core/services/mobile_feature_service.dart`, `lib/core/providers/mobile_feature_provider.dart`.
- Menu profil baru: `Data Diri & Biodata`, `Dokumen E-File`, `Riwayat Payroll`, `Pengajuan Saya`, `Proposal & Hibah`, `Bahan Ajar & RPS`, `Referral SPMB`.
- Halaman `Data Diri & Biodata` penuh: `lib/presentation/profile/data_diri_screen.dart`.
- Empty state, error state, retry, dan filter `dosenOnly`.
- Endpoint auditor (`/mobile/staff/sikeu/payroll`, `/mobile/staff/sikeu/pengajuan`, `/mobile/staff/arsip/e-file`) yang mengembalikan HTTP 200 `status: success` dengan `data: []` ditampilkan sebagai empty state valid, bukan error.
- Izin kamera dan lokasi diminta sekali saat memasuki shell terautentikasi lewat `lib/core/services/app_permission_service.dart` (`permission_handler`); izin notifikasi tetap memakai `LocalNotificationService.instance.requestPermissions()`. Layar pendaftaran wajah meminta ulang izin kamera tepat sebelum inisialisasi kamera.

Aksi tulis sudah direalisasikan mengikuti kontrak `MobileStaffController.md` (2026-11-22):

- **Ajukan Proposal** → `POST /api/v1/mobile/staff/sippm/proposal` (multipart, PDF wajib).
- **Kirim Pengajuan** → `POST /api/v1/mobile/staff/sikeu/pengajuan` (JSON/multipart, lampiran opsional).
- **Lapor Kerusakan** → `POST /api/v1/mobile/staff/sinapra/tiket` (JSON/multipart, foto opsional).
- **Buat Link Referral** → `POST /api/v1/mobile/staff/spmb/referral` (tanpa body), dengan tombol **Salin Kode** tetap tersedia di daftar referral.

Pendukung aksi tulis:

- Form generik: `lib/presentation/features/mobile_feature_form_screen.dart`.
- Payload sesuai kontrak: `lib/core/models/mobile_feature_submission.dart`.
- Submit service: `MobileFeatureService.submit`.
- Master skema/periode SIPPM: `lib/core/services/sippm_master_service.dart` memakai `GET /api/sippm/skema` dan `GET /api/sippm/periode` (prefix `/api`, bukan `/api/v1`).
- Route form: `/features/:featureCode/form`.

Catatan: kontrak belum menyediakan endpoint untuk **Info Penerimaan SPMB**, sehingga fitur `info-spmb` sengaja tetap tanpa endpoint dan menampilkan kondisi "Menunggu integrasi backend" tanpa data rekaan.

### Status deploy endpoint (24 November 2026)

Pengecekan langsung ke server produksi menunjukkan:

- Sudah aktif: `/mobile/staff/jadwal-mengajar`, `/home`, `/avatar`, `/agendas`, `/nilai/*`, `/bimbingan-pa/*`, `/perkuliahan/*`, `/mobile/staff/lms/*`, `/mobile/mahasiswa/presensi/scan`, dan `/attendance/settings` (respon `401` tanpa token = route terdaftar; `405` pada endpoint POST = route terdaftar tapi method berbeda).
- **Belum ter-deploy**: `/mobile/staff/sippm/*`, `/sikeu/*`, `/sinapra/*`, `/arsip/*`, `/spmb/*` (respon `404 The route ... could not be found`), serta alias baru `/mobile/mahasiswa/presensi/check-in` (masih `404`; perbaikan ini perlu deploy backend RAG).

Route tersebut sudah ada di `routes/api.php` lokal, jadi ini masalah deploy backend, bukan salah prefix di Flutter. Sementara backend belum di-deploy, halaman fitur menampilkan pesan **"Fitur ... belum tersedia di server"** dan tombol muat ulang, bukan pesan route Laravel. `ApiException.from` juga menyaring pesan `could not be found` secara global.

---

## 7. Presensi, rekap, dan cuti (update 24 November 2026)

### 7.1 Batas kemiripan wajah

- Aplikasi **tidak mengirim** skor/batas kemiripan ke server dan **tidak hardcode** angka 0,80. Payload `clock-in`/`clock-out` hanya berisi GPS, timestamp, QR (saat ada), dan `face_image`.
- Sumber kebenaran batas wajah adalah pengaturan web RAG `face_score_threshold` di `core_system_settings`, kini dipakai langsung oleh `AttendanceService`, `PythonFaceService`, dan endpoint mobile. Fallback server memakai `FACE_SERVICE_MIN_SIMILARITY` (default `0.68`).
- Endpoint baru `GET /api/v1/attendance/settings` sudah ditambahkan di source RAG (`backend/routes/api.php`) dan mengembalikan `face_score_threshold`, `minimum_face_similarity`, `source`, serta `updated_at`. Payload `GET /attendance/today` juga menyertakan field yang sama.
- Mobile memanggil endpoint settings saat beranda dibuka, menyimpan hasilnya di `SharedPreferences`, lalu memakai nilai terakhir bila offline. Pengecekan 24 November 2026 menunjukkan endpoint sudah terdaftar di produksi (respon `401` tanpa token); bila gagal dipanggil, mobile tetap fallback ke payload `/attendance/today` dan teks `rejection_reason` tanpa menunjukkan error.
- `FaceVerificationInfo` (`lib/core/models/face_verification_info.dart`) mem-parsing field eksplisit atau teks `Skor kemiripan`/`batas minimal` dari `rejection_reason`. Nilai `80%` dinormalkan jadi `0.80`, nilai `0.68` dipakai apa adanya. `FaceSimilaritySettings` menangani payload endpoint settings beserta metadata sumbernya.
- Kartu presensi di beranda menampilkan skor, minimum server, dan asal batas (`pengaturan web RAG yang tersimpan` atau `konfigurasi server`); status `clock-in`/`clock-out` tidak lagi menganggap HTTP 200 dengan `success: false`/`status: ditolak` sebagai keberhasilan.
- Endpoint settings tidak lagi perlu deploy khusus; yang masih menunggu deploy backend RAG adalah alias `/mobile/mahasiswa/presensi/check-in` (produksi masih `404`). Hingga backend di-deploy, scanner mahasiswa tetap memakai jalur `/presensi/scan` yang sudah aktif.

### 7.2 Rincian log presensi harian

- `GET /api/v1/attendance/recap` produksi masih mengirim baris masa depan (mis. 24–30 Nov 2026) dengan `status_badge: alpa`, meskipun `filter.end_date` adalah 30 Nov 2026.
- `AttendanceRecapRow` sekarang menyimpan field `date` (ISO) dari server. `realRows` menyaring baris libur/weekend tanpa aktivitas **dan** baris dengan tanggal setelah hari ini.
- KPI dan persentase dihitung dari `realRows`, sehingga angka alpa tidak lagi memasukkan tanggal yang belum dilewati.
- Baris tanpa status dari server tidak lagi diberi `status: 'hadir'` rekaan; UI menampilkan "Tanpa Keterangan".
- Status `cuti` akan tampil di rincian bila backend mengirim `status_badge: 'cuti'`. Sampel produksi saat ini masih `total_cuti: 0`, jadi aplikasi belum mengklaim adanya baris cuti.

### 7.3 Pengajuan cuti berdurasi tetap

- Master `GET /api/simpeg/master-jenis-cuti` mengirim `tipe_durasi` dan `durasi_hari`: `ditetapkan` (Cuti Tahunan 12, Melahirkan 90, Haji 45, Umroh 14) dan `fleksibel` (Cuti Sakit, Cuti Alasan Penting).
- Untuk `ditetapkan`, pengguna hanya memilih tanggal mulai. Tanggal selesai dihitung `tanggal_mulai + durasi_hari - 1` dan `jumlah_hari` dikirim sesuai master.
- Untuk `fleksibel`, alur mulai/selesai tetap seperti sebelumnya.
- Route kamera presensi: `/face-capture` (`lib/presentation/profile/face_capture_screen.dart`), dipanggil dari `ScannerScreen` lewat `context.push<String>('/face-capture')`. `ImagePicker` tidak lagi dipakai untuk foto wajah presensi.

### 7.4 Pengamanan sesi QR perkuliahan (24 November 2026)

- **Otorisasi pengampu:** seluruh aksi perkuliahan di mobile staff — detail kelas, daftar pertemuan, mulai sesi, rotasi token, tutup sesi, baca dan ubah presensi — kini diverifikasi terhadap Dosen Pengampu kelas. Superadmin/role lain tidak mendapat bypass di endpoint ini, selaras dengan `LmsService::assertDosenPengampuKelas()` pada jalur web.
- **Token tidak bocor:** `token_absensi` dan `qr_payload` tidak dikirim lagi ke mahasiswa lewat overview kelas, detail pertemuan, maupun daftar pertemuan; status `token_aktif`/`is_token_active` tetap tersedia. Audit log juga menyensor `token_absensi` dan `qr_payload`.
- **TTL & rotasi mengikuti server:** default `lms_token_rotate_seconds` adalah 30 detik. Token awal maksimal aktif dua interval rotasi (minimal 60 detik), dan rotasi mengembalikan `rotate_interval_seconds`, `expired_at`, serta `qr_payload` berformat `RAG-PRESENSI:{pertemuan_id}:{token}` — sama dengan format scanner mahasiswa.
- **Sinkronisasi Flutter:** layar sesi memakai interval dari server untuk countdown dan progress bar; QR serta angka token mengikuti token live terbaru; kegagalan rotasi otomatis tetap ditampilkan; timer dihentikan segera setelah server mengonfirmasi sesi ditutup; token kosong/null ditolak sebelum rotate.
- **Status deploy:** perbaikan backend ini masih uncommitted/undeployed. Setelah deploy, verifikasi singkat: dosen bukan pengampu harus mendapat `403`, mahasiswa tidak menerima kode token, dan alias `/mobile/mahasiswa/presensi/check-in` tidak lagi `404`.

### 7.5 Penguatan P1/P2: mode presensi, geofence opsional, dan jendela sesi (24 November 2026)

- **Mode presensi per pertemuan:** kolom baru `mode_presensi` dengan default `online`. Modal "Mulai Pertemuan" di `class_journal_screen.dart` menyediakan pilihan **Online / Zoom** (default) dan **Tatap muka**; nilai dikirim sebagai `mode_presensi` oleh `AcademicService.mulaiSesiPertemuan`. Jalur web `buka-sesi` menerima field yang sama.
- **Geofence tidak wajib:** pengecekan lokasi hanya berjalan bila ketiga kondisi terpenuhi — pertemuan ber-mode `offline`, setting `lms_presensi_geofence_wajib` bernilai truthy, dan ada `OfficeLocation` aktif. Pertemuan Zoom/daring default `online` tetap menerima scan tanpa `latitude`/`longitude` meskipun flag geofence aktif. Jika lokasi wajib tetapi tidak dikirim atau di luar radius, respon `422` pada field `latitude`.
- **Jendela scan mengikuti aktivitas dosen:** batas akhir dihitung dari `token_rotated_at + window_menit`, bukan tanggal jadwal. Rotasi ditolak (`422`) setelah jendela berakhir. Command `lms:tutup-presensi-otomatis` berjalan tiap 5 menit, menutup sesi yang jadwalnya lewat **atau** jendela rotasinya habis, lalu menghapus token dan menandai status `selesai`.
- **Anti brute-force token:** rotasi token dibatasi 15 kali per menit per dosen per pertemuan lewat limiter `lms-token-rotate`; kelebihan kuota menghasilkan `429`. Rotasi normal 30 detik, jadi batas ini masih memberi ruang retry.
- **Presensi manual tervalidasi:** dosen hanya dapat mengubah presensi mahasiswa yang benar-benar terdaftar di kelas pertemuan melalui KRS valid; mahasiswa dari kelas lain dan status absensi tidak dikenal ditolak (`422`). Rekap peserta juga hanya memakai KRS dengan status valid.
- **Feature flag konsisten:** `lms_fitur_presensi` kini dijaga di endpoint presensi web dan mobile (dosen maupun mahasiswa). Saat dimatikan, aksi presensi mendapat `403`; pengguna dengan permission `lms.presensi.manage` (admin/support) tetap dikecualikan.
- **Verifikasi:** 49 test pada `SiakadLmsTest`, `MobileStaffApiTest`, dan `MobileMahasiswaApiTest` lolos (662 assertion), termasuk 7 regression test baru untuk geofence opsional, jendela/auto-close, rate limit, feature flag, dan presensi lintas kelas. `flutter analyze` bersih. Perubahan backend masih uncommitted/undeployed.

### 7.6 Self-service SIMPEG, payroll detail, dan e-file (24 November 2026)

Flutter sudah di-wire ke 15 endpoint baru `/api/v1/mobile/staff/...` (commit backend `0b87e53`). Semua endpoint v1 memakai `AttendanceService.getBaseUrl()`; master SIMPEG tetap lewat jalur lama `/api/simpeg/...` yang diupas `/v1` oleh `getApiBaseUrl()`.

| Fitur mobile | Endpoint v1 | Aksi Flutter |
|---|---|---|
| `cuti` | `GET/POST /mobile/staff/simpeg/cuti` | `MobileStaffFormScreen` (jenis cuti dari `GET /simpeg/master-jenis-cuti`) |
| `izin-kerja` | `GET/POST /mobile/staff/simpeg/izin-kerja` | `MobileStaffFormScreen` (master `GET /simpeg/master/jenis-izin-jam-kerja`) |
| `surat-tugas` | `GET/POST /mobile/staff/simpeg/surat-tugas` | Form + detail; `POST .../lpj` untuk unggah LPJ (PDF ≤10 MB) |
| `sk-pegawai` | `GET/POST /mobile/staff/simpeg/sk-pegawai` | Form dengan master `GET /simpeg/master/kategori-sk` |
| `kompetensi` | `GET /mobile/staff/simpeg/kompetensi` | Daftar dengan query `?jenis=sertifikasi\|tes\|pelatihan` |
| `payroll` | `GET .../payroll`, `.../payroll/{id}`, `.../payroll/{id}/slip` | Detail komponen gaji + unduh slip PDF biner |
| `e-file` | `GET/POST /mobile/staff/arsip/e-file`, `.../{id}`, `.../{id}/download` | Detail, signed URL 900 detik, unggah dokumen |
| `referral-spmb` | `GET/POST /mobile/staff/spmb/referral` | Kartu statistik dari `stats` pada item pertama |

Catatan implementasi:

- ID master **tidak pernah hardcode** — dropdown mengambil `id` dari endpoint master di atas. Durasi cuti `ditetapkan` memakai `tipe_durasi`/`durasi_hari` dari master yang sama.
- `jenis_dokumen` e-file dan `jenis` kompetensi adalah nilai tetap domain (bukan tabel master), didefinisikan sekali sebagai `mobileEfileJenisDokumen` dan `mobileKompetensiJenis` di `mobile_feature_config.dart`.
- Form baru memakai route `/mobile-staff/form/:featureCode`; detail memakai `/mobile-staff/detail/:featureCode/:id` dengan `extra: MobileFeatureItem` agar tidak perlu fetch ulang saat list sudah memuat data.
- Slip PDF diunduh sebagai bytes, divalidasi header `%PDF`, nama file diambil dari `Content-Disposition`, lalu dibuka lewat `url_launcher` dengan fallback pesan path lokal.
- E-file membuka signed URL via `url_launcher`; bila tidak ada handler, tautan disalin ke clipboard (masa berlaku 900 detik ditampilkan ke user).
- Statistik referral memakai alias backend `total`/`mahasiswa_baru`, `qualified`/`dapat_direimburse`, dan `rewarded`/`sudah_direimburse`. Fitur `info-spmb` sengaja tetap tanpa endpoint.
- Belum ada perubahan role/profile/Gate baru; administrator oversight dan academic participation tetap terpisah. Flutter **belum** di-commit atau di-push.
