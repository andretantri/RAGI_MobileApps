import 'package:flutter_test/flutter_test.dart';
import 'package:myinu_staff/core/models/pertemuan_model.dart';

void main() {
  group('Perkuliahan & Jurnal Pertemuan (BAP) Model Tests', () {
    test('KelasPertemuanItem parses correctly from JSON', () {
      final json = {
        'kelas_id': 13,
        'kode_kelas': 'IF1A-ALGO',
        'nama_kelas': 'Algoritma Pemrograman Kelas A',
        'kode_mk': 'IF101',
        'nama_mk': 'Algoritma & Pemrograman I',
        'sks': 3,
        'ruangan': 'Lab Komputer 1',
        'hari': 'Senin',
        'jam': '08:00 - 10:30',
        'total_mahasiswa': 32,
        'total_pertemuan': 16,
        'pertemuan_selesai': 4,
        'has_active_session': true,
        'active_session_id': 8,
        'active_session_ke': 5,
      };

      final item = KelasPertemuanItem.fromJson(json);

      expect(item.kelasId, 13);
      expect(item.kodeKelas, 'IF1A-ALGO');
      expect(item.namaMk, 'Algoritma & Pemrograman I');
      expect(item.sks, 3);
      expect(item.pertemuanSelesai, 4);
      expect(item.totalPertemuan, 16);
      expect(item.progressPercent, 25);
      expect(item.hasActiveSession, true);
      expect(item.activeSessionKe, 5);
    });

    test('PertemuanItem parses correctly from JSON', () {
      final json = {
        'id': 8,
        'pertemuan_ke': 2,
        'tanggal': '21 Nov 2026',
        'jam_mulai': '08:00',
        'jam_selesai': '10:30',
        'materi': 'Struktur Kontrol Kondisional',
        'catatan': 'Praktikum Lab',
        'status': 'berlangsung',
        'token_absensi': '494731',
        'is_active': true,
        'total_hadir': 28,
        'total_izin': 2,
        'total_sakit': 1,
        'total_alfa': 1,
        'total_mahasiswa': 32,
      };

      final item = PertemuanItem.fromJson(json);

      expect(item.id, 8);
      expect(item.pertemuanKe, 2);
      expect(item.status, 'berlangsung');
      expect(item.statusLabel, 'Sedang Berlangsung');
      expect(item.tokenAbsensi, '494731');
      expect(item.isActive, true);
      expect(item.totalHadir, 28);
    });

    test('PresensiMahasiswaItem parses and converts to JSON', () {
      final json = {
        'mahasiswa_id': 1,
        'nim': '2301001001',
        'nama': 'Ahmad Fadillah',
        'status': 'hadir',
        'catatan': 'Tepat waktu',
        'is_submitted': true,
      };

      final item = PresensiMahasiswaItem.fromJson(json);

      expect(item.mahasiswaId, 1);
      expect(item.nim, '2301001001');
      expect(item.status, 'hadir');
      expect(item.catatan, 'Tepat waktu');

      final serialized = item.toJson();
      expect(serialized['mahasiswa_id'], 1);
      expect(serialized['status'], 'hadir');
      expect(serialized['catatan'], 'Tepat waktu');
    });
  });
}
