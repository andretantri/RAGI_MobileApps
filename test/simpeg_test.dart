import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/models/simpeg_model.dart';
import 'package:myinu_staff/core/providers/auth_provider.dart';
import 'package:myinu_staff/core/providers/simpeg_provider.dart';
import 'package:myinu_staff/presentation/simpeg/simpeg_dashboard_screen.dart';
import 'package:myinu_staff/presentation/simpeg/cuti_screen.dart';
import 'package:myinu_staff/presentation/simpeg/activity_log_screen.dart';
import 'package:myinu_staff/presentation/simpeg/attendance_recap_screen.dart';
import 'package:myinu_staff/presentation/simpeg/announcements_screen.dart';
import 'package:myinu_staff/presentation/simpeg/announcement_broadcast_screen.dart';

void main() {
  group('SIMPEG Models Tests', () {
    test('MasterJenisCutiModel parses correctly from json', () {
      final json = {
        'id': 1,
        'nama': 'Cuti Tahunan',
        'kode': 'CUTI_TAHUNAN',
        'tipe_durasi': 'fleksibel',
        'durasi_hari': 0,
        'satuan': 'hari',
        'lampiran_wajib': false,
        'keterangan': 'Cuti tahunan reguler',
      };

      final model = MasterJenisCutiModel.fromJson(json);

      expect(model.id, 1);
      expect(model.nama, 'Cuti Tahunan');
      expect(model.kode, 'CUTI_TAHUNAN');
      expect(model.tipeDurasi, 'fleksibel');
      expect(model.lampiranWajib, isFalse);
    });

    test('PengajuanCutiModel parses correctly from json', () {
      final json = {
        'id': 10,
        'pegawai_id': 106,
        'master_jenis_cuti_id': 1,
        'jenis_cuti': 'tahunan',
        'tanggal_mulai': '2026-12-01',
        'tanggal_selesai': '2026-12-03',
        'jumlah_hari': 3,
        'alasan': 'Keperluan keluarga',
        'status_approval': 'pending',
        'created_at': '2026-11-21T13:53:37.000000Z',
        'master_jenis_cuti': {
          'id': 1,
          'nama': 'Cuti Tahunan',
        },
      };

      final model = PengajuanCutiModel.fromJson(json);

      expect(model.id, 10);
      expect(model.masterNama, 'Cuti Tahunan');
      expect(model.tanggalMulai, '2026-12-01');
      expect(model.jumlahHari, 3);
      expect(model.statusApproval, 'pending');
    });

    test('AttendanceRecapModel parses summary and rows correctly', () {
      final json = {
        'employee': {
          'name': 'Anisa Rahmawati, M.Kom.',
          'employee_code': '199008152015122001',
          'department': 'Teknologi Informasi',
          'position': 'Dosen',
        },
        'filter': {
          'start_date': '2026-11-01',
          'end_date': '2026-11-30',
        },
        'summary': {
          'total_days': 30,
          'total_hadir': 20,
          'total_terlambat': 2,
          'total_alpa': 0,
          'total_libur': 8,
          'total_izin': 0,
          'total_sakit': 0,
          'total_dinas': 0,
          'total_cuti': 0,
        },
        'rows': [
          {
            'tanggal': '2026-11-21',
            'scan_masuk': '07:45:00',
            'scan_pulang': '16:05:00',
            'terlambat': '0',
            'status': 'hadir',
            'keterangan': 'Tepat Waktu',
          }
        ],
      };

      final recap = AttendanceRecapModel.fromJson(json);

      expect(recap.employeeName, 'Anisa Rahmawati, M.Kom.');
      expect(recap.totalHadir, 20);
      expect(recap.totalTerlambat, 2);
      expect(recap.rows.length, 1);
      expect(recap.rows.first.status, 'hadir');
    });

    test('AttendanceRecapModel filters out calendar-only holiday rows', () {
      final recap = AttendanceRecapModel.fromJson({
        'employee': {
          'name': 'Dwi Iskandar, M.Kom.',
          'employee_code': '0603048802',
        },
        'summary': {
          'total_days': 3,
          'total_hadir': 1,
          'total_libur': 2,
        },
        'rows': [
          {'tanggal': '2026-11-21', 'status': 'libur'},
          {'tanggal': '2026-11-22', 'status': 'weekend', 'keterangan': ''},
          {
            'tanggal': '2026-11-23',
            'status': 'hadir',
            'scan_masuk': '07:45:00',
          },
        ],
      });

      expect(recap.rows.length, 3);
      expect(recap.realRows.length, 1);
      expect(recap.realRows.first.tanggal, '2026-11-23');
      expect(recap.hasAttendanceData, isTrue);
    });

    test('AttendanceRecapModel hides future dates sent by server', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      final recap = AttendanceRecapModel.fromJson({
        'employee': {'employee_code': '0603048802'},
        'summary': {'total_days': 2, 'total_alpa': 2},
        'rows': [
          {
            'date': date.toIso8601String().substring(0, 10),
            'tanggal': '${date.day} Nov ${date.year}',
            'status_badge': 'alpa',
          },
          {
            'date': today.toIso8601String().substring(0, 10),
            'tanggal': '${today.day} Nov ${today.year}',
            'status_badge': 'hadir',
            'scan_masuk': '07:45:00',
          },
        ],
      });

      expect(recap.rows.length, 2);
      expect(recap.realRows.length, 1);
      expect(recap.realRows.first.date,
          today.toIso8601String().substring(0, 10));
      expect(recap.realRows.first.status, 'hadir');
    });

    test('AttendanceRecapModel reports no attendance for calendar-only data', () {
      final recap = AttendanceRecapModel.fromJson({
        'employee': {'employee_code': '0603048802'},
        'summary': {'total_days': 2, 'total_libur': 2},
        'rows': [
          {'tanggal': '2026-11-21', 'status': 'libur'},
          {'tanggal': '2026-11-22', 'status': 'weekend'},
        ],
      });

      expect(recap.rows.length, 2);
      expect(recap.realRows, isEmpty);
      expect(recap.hasAttendanceData, isFalse);
    });

    test('CampusAnnouncementItem parses correctly from json', () {
      final json = {
        'id': 5,
        'title': 'Himbauan Seragam Batik',
        'category': 'seragam',
        'target_role': 'all_staff',
        'content': 'Mengenakan batik rapi',
        'is_agenda': true,
        'event_date': '2026-11-25',
        'priority': 'normal',
        'recipients_count': 50,
        'created_at': '2026-11-21',
      };

      final item = CampusAnnouncementItem.fromJson(json);

      expect(item.id, 5);
      expect(item.title, 'Himbauan Seragam Batik');
      expect(item.category, 'seragam');
      expect(item.isAgenda, isTrue);
      expect(item.recipientsCount, 50);
    });
  });

  group('SIMPEG Role Separation & UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Regular staff/dosen sees Log Aktivitas and NO broadcast button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const regularUser = UserModel(
        id: 5,
        name: 'Dosen Biasa, M.Kom.',
        email: 'dosen@kampus.ac.id',
        nip: '19900101',
        position: 'Dosen Pengajar',
        department: 'Teknik Informatika',
        isDosen: true,
        avatarInitial: 'DB',
        roles: ['dosen'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => AuthNotifier()
                ..state = const AuthState(isAuthenticated: true, user: regularUser),
            ),
          ],
          child: const MaterialApp(
            home: SimpegDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SIMPEG & Kepegawaian'), findsOneWidget);
      expect(find.text('Izin & Cuti'), findsOneWidget);
      expect(find.text('Laporan Presensi'), findsOneWidget);
      expect(find.text('Info Kampus'), findsOneWidget);
      // For regular staff: 'Log Aktivitas' is shown instead of 'Broadcast SDM'
      expect(find.text('Log Aktivitas'), findsOneWidget);
      expect(find.text('Broadcast SDM'), findsNothing);
    });

    testWidgets('Admin SIMPEG user sees Broadcast SDM menu card', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const adminUser = UserModel(
        id: 1,
        name: 'Admin SDM Kampus',
        email: 'admin.simpeg@kampus.ac.id',
        nip: '19850101',
        position: 'Admin SIMPEG',
        department: 'Bagian Kepegawaian',
        isDosen: false,
        avatarInitial: 'AS',
        roles: ['admin_simpeg'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => AuthNotifier()
                ..state = const AuthState(isAuthenticated: true, user: adminUser),
            ),
          ],
          child: const MaterialApp(
            home: SimpegDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // For admin SIMPEG: 'Broadcast SDM' is rendered
      expect(find.text('Broadcast SDM'), findsOneWidget);
      expect(find.text('Log Aktivitas'), findsNothing);
    });

    testWidgets('AnnouncementsScreen hides FAB for regular staff', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const regularUser = UserModel(
        id: 5,
        name: 'Staff Biasa',
        email: 'staff@kampus.ac.id',
        nip: '19900101',
        position: 'Staff Administrasi',
        department: 'Akademik',
        isDosen: false,
        avatarInitial: 'SB',
        roles: ['tendik'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => AuthNotifier()
                ..state = const AuthState(isAuthenticated: true, user: regularUser),
            ),
          ],
          child: const MaterialApp(
            home: AnnouncementsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pengumuman Kampus'), findsOneWidget);
      expect(find.text('Kirim Broadcast (Admin)'), findsNothing);
    });

    testWidgets('AnnouncementsScreen shows FAB for Admin SIMPEG', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const adminUser = UserModel(
        id: 2,
        name: 'Admin SIMPEG',
        email: 'admin@kampus.ac.id',
        nip: '19850101',
        position: 'Admin SIMPEG',
        department: 'Kepegawaian',
        isDosen: false,
        avatarInitial: 'AS',
        roles: ['admin_simpeg'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => AuthNotifier()
                ..state = const AuthState(isAuthenticated: true, user: adminUser),
            ),
          ],
          child: const MaterialApp(
            key: ValueKey('admin_announcements_test'),
            home: AnnouncementsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pengumuman Kampus'), findsOneWidget);
      expect(find.text('Kirim Broadcast (Admin)'), findsOneWidget);
    });

    testWidgets('AnnouncementBroadcastScreen blocks regular staff with access denied UI', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const regularUser = UserModel(
        id: 5,
        name: 'Dosen Biasa',
        email: 'dosen@kampus.ac.id',
        nip: '19900101',
        position: 'Dosen',
        department: 'Teknik',
        isDosen: true,
        avatarInitial: 'DB',
        roles: ['dosen'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => AuthNotifier()
                ..state = const AuthState(isAuthenticated: true, user: regularUser),
            ),
          ],
          child: const MaterialApp(
            home: AnnouncementBroadcastScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Akses Dibatasi'), findsOneWidget);
      expect(find.text('Khusus Hak Akses Admin SIMPEG'), findsOneWidget);
      expect(find.text('Kembali ke Menu SIMPEG'), findsOneWidget);
      // Form should NOT be rendered
      expect(find.text('Target Audiens'), findsNothing);
    });

    testWidgets('CutiScreen renders tabs and form controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CutiScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Izin & Cuti Pegawai'), findsOneWidget);
      expect(find.text('Riwayat Pengajuan'), findsOneWidget);
      expect(find.text('Ajukan Cuti/Izin'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
    });

    testWidgets('AttendanceRecapScreen renders metrics and period selector', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AttendanceRecapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Laporan Kehadiran'), findsOneWidget);
      expect(find.textContaining('Rekap bulanan'), findsOneWidget);
    });

    testWidgets('AnnouncementsScreen renders empty state for empty list', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsProvider.overrideWith(
              (ref) async => <CampusAnnouncementItem>[],
            ),
          ],
          child: const MaterialApp(home: AnnouncementsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Belum ada pengumuman kampus'), findsOneWidget);
      expect(find.text('Muat Ulang'), findsOneWidget);
      expect(find.text('Server tidak mengirimkan daftar pengumuman.'), findsNothing);
    });

    testWidgets('AnnouncementsScreen renders retry state on error', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsProvider.overrideWith((ref) async {
              throw Exception('Koneksi terputus');
            }),
          ],
          child: const MaterialApp(home: AnnouncementsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pengumuman belum dapat dimuat'), findsOneWidget);
      expect(
        find.text('Pengumuman tidak dapat dimuat saat ini.'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('AttendanceRecapScreen renders empty state without data', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRecapProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: AttendanceRecapScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Belum ada data kehadiran pada bulan ini'), findsOneWidget);
      expect(find.text('Rincian Log Presensi Harian'), findsNothing);
    });

    testWidgets('ActivityLogScreen renders empty state without attendance', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRecapProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: ActivityLogScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Log Aktivitas'), findsOneWidget);
      expect(find.text('Belum ada aktivitas presensi'), findsOneWidget);
    });
  });
}
