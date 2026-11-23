import 'package:flutter_test/flutter_test.dart';
import 'package:myinu_staff/core/providers/notification_provider.dart';

void main() {
  group('NotificationItem deep link', () {
    test('memakai url internal dari API bila tersedia', () {
      final item = NotificationItem.fromApi({
        'id': 1,
        'title': 'Pemberitahuan',
        'message': 'Cek detail di halaman absen.',
        'url': '/scanner?source=inbox',
        'is_read': false,
      });

      expect(item.route, '/scanner?source=inbox');
    });

    test('notifikasi belum absen membuka halaman scanner', () {
      final item = NotificationItem.fromApi({
        'id': 2,
        'title': 'Anda belum absen hari ini',
        'message': 'Ayo segera lakukan presensi masuk.',
        'type': 'ATTENDANCE',
        'url': null,
        'is_read': false,
      });

      expect(item.route, '/scanner');
    });

    test('informasi admin SIMPEG membuka halaman pengumuman', () {
      final item = NotificationItem.fromApi({
        'id': 3,
        'title': 'Informasi dari admin SIMPEG',
        'message': 'Pengumuman terbaru telah dipublikasikan.',
        'module': {'code': 'SIMPEG', 'name': 'SIMPEG'},
        'type': 'ANNOUNCEMENT',
        'is_read': false,
      });

      expect(item.module, 'SIMPEG');
      expect(item.route, '/simpeg/announcements');
    });

    test('notifikasi jadwal mengajar membuka halaman jadwal', () {
      final item = NotificationItem.fromApi({
        'id': 4,
        'title': 'Pengingat jadwal mengajar',
        'message': 'Kelas dimulai 15 menit lagi.',
        'module': {'code': 'SIAKAD'},
        'is_read': true,
      });

      expect(item.route, '/schedule');
    });

    test('url detail tanpa route jatuh ke halaman induk yang aman', () {
      final item = NotificationItem.fromApi({
        'id': 6,
        'title': 'Pengumuman SIMPEG',
        'message': 'Informasi terbaru untuk pegawai.',
        'module': {'code': 'SIMPEG'},
        'url': '/simpeg/announcements/9',
        'is_read': false,
      });

      expect(item.route, '/simpeg/announcements');
    });

    test('route tersimpan di cache dan tetap terbaca kembali', () {
      final original = NotificationItem.fromApi({
        'id': 5,
        'title': 'Anda belum absen',
        'message': 'Segera absen.',
        'is_read': false,
      });

      final restored = NotificationItem.fromApi(original.toJson());

      expect(restored.route, '/scanner');
      expect(NotificationItem.fromJson(original.toJson()).route, '/scanner');
    });
  });
}
