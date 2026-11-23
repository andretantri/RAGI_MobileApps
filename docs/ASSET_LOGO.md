# Aset Logo & Ikon myInU Staff

Ikon aplikasi sekarang berasal dari `tools/myin-u-staff-icons.zip` (salinan dari
`myin-u-staff-icons.zip` yang diberikan). File `logo.png` di root project tetap
dipakai sebagai banner halaman login.

## Regenerasi aset

```bash
python3 tools/generate_logo_assets.py
```

Script memakai Pillow dan melakukan tiga hal:

1. Menyalin `logo.png` ke `assets/images/logo.png` (banner login).
2. Memasang launcher Android dan `AppIcon.appiconset` iOS dari zip.
3. Membuat ikon notifikasi Android dari `ic_launcher_monochrome.png` dan
   `playstore-512.png` yang ada di dalam zip.

## Daftar aset

| Lokasi | Fungsi |
| --- | --- |
| `assets/images/logo.png` | Logo utuh, dipakai sebagai banner pada halaman login (dari `logo.png`). |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | App icon Android legacy. |
| `android/app/src/main/res/mipmap-*/ic_launcher_round.png` | App icon Android bentuk lingkaran. |
| `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png` | Foreground adaptive icon (API 26+). |
| `android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png` | Versi monokrom untuk themed icon Android 13+. |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher*.xml` | Komposisi adaptive icon, termasuk tag `<monochrome>`. |
| `android/app/src/main/res/values/ic_launcher_background.xml` | Latar adaptive icon dari zip: `#FFFFFF`. |
| `android/app/src/main/res/values/notification_colors.xml` | Warna tint notifikasi `#0B52B3`. |
| `android/app/src/main/res/drawable-*/ic_stat_logo.png` | Ikon notifikasi monokrom putih-transparan untuk status bar. |
| `android/app/src/main/res/drawable-*/ic_notification_large.png` | Large icon notifikasi berwarna. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` | Seluruh ukuran AppIcon iOS mengikuti `Contents.json` dari zip. |

`android/playstore-512.png` dan `preview.png` tetap berada di dalam zip sebagai
referensi; keduanya tidak dipasang ke resource aplikasi.

## Keputusan desain

- Ikon baru memakai latar putih, aksen biru `#0B52B3`, dan merah `#F83532`
  (sampled dari `playstore-512.png`).
- Karena latar adaptive icon sekarang putih, warna tint notifikasi sengaja
  dipisah ke `notification_color`. Jika tetap memakai
  `ic_launcher_background`, fallback FCM akan berwarna putih dan small icon
  tidak terlihat.
- Small icon notifikasi dibuat dari alpha `ic_launcher_monochrome.png` lalu
  diwarnai putih, sehingga tidak tampil sebagai kotak abu-abu di status bar.
- Large icon notifikasi memakai `playstore-512.png` yang sudah persegi dan
  opaque, jadi tidak perlu dikomposisi ulang dengan mark seperti sebelumnya.
- `AndroidManifest.xml` mendaftarkan `@drawable/ic_stat_logo` dan
  `@color/notification_color` sebagai default FCM. Saat ini notifikasi dikirim
  lewat `flutter_local_notifications` dengan warna yang sama
  (`lib/core/services/local_notification_service.dart`).
- `AppColors.primary` di UI Flutter sengaja tidak diubah; perubahaninya hanya
  aset ikon aplikasi dan warna notifikasi agar konsisten dengan ikon baru.
