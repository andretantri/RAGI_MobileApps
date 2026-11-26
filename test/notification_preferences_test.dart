import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/providers/auth_provider.dart';
import 'package:myinu_staff/presentation/profile/notification_preferences_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'notif_teaching_enabled': true,
      'notif_teaching_minutes': 15,
      'notif_attendance_morning': true,
      'notif_attendance_evening': true,
      'notif_deadline_enabled': true,
      'notif_deadline_hours': 3,
      'notif_announcements': true,
      'notif_sound': true,
      'notif_vibration': true,
    });
  });

  group('Notification Preferences Tests', () {
    testWidgets('NotificationPreferencesScreen renders all sections and controls',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationPreferencesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title & Header
      expect(find.text('Preferensi Notifikasi'), findsOneWidget);
      expect(find.textContaining('Pengingat Otomatis Berjalan Lokal'), findsOneWidget);

      // Section 1: Jadwal Mengajar
      expect(find.text('PENGINGAT JADWAL MENGAJAR'), findsOneWidget);
      expect(find.text('Notifikasi Sebelum Kuliah'), findsOneWidget);
      expect(find.text('15 Menit'), findsOneWidget);
      expect(find.text('30 Menit'), findsOneWidget);
      expect(find.text('1 Jam Sebelum'), findsOneWidget);
      expect(find.text('+ Atur Sendiri...'), findsOneWidget);

      // Section 2: Presensi Kerja
      expect(find.text('PENGINGAT PRESENSI KERJA'), findsOneWidget);
      expect(find.text('Pengingat Clock In (Pagi)'), findsOneWidget);
      expect(find.text('Pengingat Clock Out (Sore)'), findsOneWidget);

      // Section 3: Tugas & Deadline
      expect(find.text('PENGINGAT TUGAS & DEADLINE'), findsOneWidget);
      expect(find.text('Deadline Nilai & Tugas'), findsOneWidget);
      expect(find.text('3 Jam Sebelum'), findsOneWidget);
      expect(find.text('H-1 (24 Jam)'), findsOneWidget);
      expect(find.text('+ Atur Jam...'), findsOneWidget);

      // Section 4 & 5: Pengumuman & Suara/Getar
      expect(find.text('INFORMASI & PENGUMUMAN'), findsOneWidget);
      expect(find.text('Pengumuman BAAK & Rektorat'), findsOneWidget);
      expect(find.text('SUARA & GETARAN'), findsOneWidget);
      expect(find.text('Bunyikan Suara Notifikasi'), findsOneWidget);
      expect(find.text('Getar Perangkat'), findsOneWidget);

      // Test Button
      expect(find.text('Uji Notifikasi Pengingat Sekarang'), findsOneWidget);

      // Tap Test Button
      await tester.tap(find.text('Uji Notifikasi Pengingat Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify SnackBar feedback
      expect(find.text('Simulasi notifikasi pengingat berhasil ditembakkan!'),
          findsOneWidget);

      // Hanya satu notifikasi sistem yang dipancarkan (tanpa overlay ganda).
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Tendik (non-dosen) hides teaching and task reminder sections (RBAC)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final tendik = const UserModel(
        id: 2,
        name: 'Staf Tendik',
        email: 'tendik@poltekindonusa.ac.id',
        nip: '19900101',
        position: 'Staf Administrasi',
        department: 'BAAK',
        isDosen: false,
        avatarInitial: 'ST',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => AuthNotifier()..state = AuthState(
                  isAuthenticated: true,
                  user: tendik,
                )),
          ],
          child: const MaterialApp(
            home: NotificationPreferencesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PENGINGAT PRESENSI KERJA'), findsOneWidget);
      expect(find.text('INFORMASI & PENGUMUMAN'), findsOneWidget);
      expect(find.text('PENGINGAT JADWAL MENGAJAR'), findsNothing);
      expect(find.text('PENGINGAT TUGAS & DEADLINE'), findsNothing);
    });
  });
}
