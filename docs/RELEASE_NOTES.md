# Catatan Rilis MyIn-U Staff

## v1.1.1 (Build 31) — 25 November 2026

Rilis patch untuk menyelaraskan menu profil dengan akses modul web RAG dan membuka referral SPMB self-service bagi seluruh dosen dan tenaga kependidikan.

### Perubahan

- **Menu profil tendik lebih fleksibel**
  - Menu akademik (`Jadwal Mengajar`, `Input Nilai`, `Bimbingan Akademik`, `Proposal & Hibah`, `Bahan Ajar & RPS`) hanya ditampilkan untuk dosen dan disaring mengikuti kode modul yang diberikan web RAG melalui `/api/modules/my-modules`.
  - Untuk tendik, bagian akademik diganti menjadi **Layanan & Referral**; Referral SPMB tetap tersedia.
  - Tombol baru **Buka Menu Modul** di `Pengaturan & Info` untuk menuju daftar modul sesuai akses web RAG.

- **Referral SPMB self-service**
  - Referral SPMB dapat diakses dan dicek sendiri oleh dosen maupun tendik aktif, tanpa memerlukan permission admin SPMB.
  - Kode referral, statistik, dan mahasiswa binaan tetap dibatasi pada akun yang login.

### Persyaratan Backend

Fitur referral tendik memerlukan backend RAG `main` **829e473** (`fix(mobile): referral SPMB self-service untuk dosen dan tendik`) atau lebih baru. Jika backend belum di-deploy, endpoint referral masih dapat mengembalikan `403` untuk tendik.

### Detail Build

- `versionName`: `1.1.1`
- `versionCode`: `31`
- Android: release signed dengan upload keystore, minify & resource shrinking aktif, dukungan 16 KB page size dipertahankan.
- Aset: `app-release.apk` (universal) dan `app-release.aab` (Android App Bundle).

### Verifikasi

- `flutter analyze`: bersih.
- Test fokus (`identity_display_test.dart`, `modules_test.dart`, `mobile_features_test.dart`): 21 test lolos.

---

## v1.1.0 (Build 30)

Rilis fitur SIMPEG self-service, payroll/arsip detail, dukungan 16 KB page size, dan sinkronisasi QR presensi perkuliahan dengan backend RAG.
