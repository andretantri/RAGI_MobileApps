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
- SHA-256:
  - `app-release.apk`: `0a5e4a917a98d1ecf0abdaf47f3ae1e0ca85ee01bc5e2d7a32760c667e0dfb51`
  - `app-release.aab`: `6d131046533527603559a12d6ff0b01475e97cbe64121f20b55728766e836f18`
- Sertifikat penandatangan: `CN=Politeknik Indonusa, OU=IT, O=Politeknik Indonusa Surakarta` (SHA-256 `FB:17:50:06:EA:4A:04:AD:76:F1:34:9E:28:5A:2B:4B:AE:CC:75:84:F2:AF:31:22:9B:73:DD:76:BE:3A:74:25`).

### Verifikasi

- `flutter analyze`: bersih.
- Test fokus (`identity_display_test.dart`, `modules_test.dart`, `mobile_features_test.dart`): 21 test lolos.

---

## v1.1.0 (Build 30)

Rilis fitur SIMPEG self-service, payroll/arsip detail, dukungan 16 KB page size, dan sinkronisasi QR presensi perkuliahan dengan backend RAG.
