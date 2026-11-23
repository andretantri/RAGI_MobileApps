import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/models/teaching_schedule_model.dart';
import 'package:myinu_staff/core/providers/attendance_provider.dart';
import 'package:myinu_staff/core/providers/auth_provider.dart';
import 'package:myinu_staff/core/providers/schedule_provider.dart';
import 'package:myinu_staff/presentation/dashboard/home_screen.dart';
import 'package:myinu_staff/presentation/profile/profile_screen.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(AuthState initial) : super() {
    state = initial;
  }

  @override
  Future<bool> checkSession() async => true;
}

class _FakeAttendanceNotifier extends AttendanceNotifier {
  _FakeAttendanceNotifier() {
    state = const AttendanceState();
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> fetchTodayStatus() async {}

  @override
  Future<void> checkLocationAndDistance() async {}
}

class _FakeScheduleNotifier extends ScheduleNotifier {
  _FakeScheduleNotifier(super.ref, ScheduleState initial) {
    state = initial;
  }

  @override
  Future<void> loadSchedule() async {}

  @override
  Future<void> refresh() async {}

  @override
  void reset() {}
}

void main() {
  const dosen = UserModel(
    id: 32,
    // Data lama/username berisi NIDN. Tidak boleh tampil sebagai nama.
    name: '0603048802',
    email: '0603048802@campus.ac.id',
    nip: '230810016',
    nidn: '0603048802',
    position: 'Dosen Pengajar',
    department: 'Teknik Informatika',
    isDosen: true,
    avatarInitial: 'DI',
    roles: ['dosen'],
  );

  const schedule = TeachingScheduleResult(
    lecturerName: 'DWI ISKANDAR, M.Kom',
    nidn: '0603048802',
    todayDay: '-',
    todayClasses: [],
    allClasses: [],
    totalSks: 0,
    totalClasses: 0,
  );

  const scheduleState = ScheduleState(schedule: schedule);

  Widget buildApp(Widget child) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(
            AuthState(isAuthenticated: true, user: dosen),
          ),
        ),
        attendanceProvider.overrideWith((ref) => _FakeAttendanceNotifier()),
        scheduleProvider.overrideWith(
          (ref) => _FakeScheduleNotifier(ref, scheduleState),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home shows lecturer name and NIDN from SIAKAD schedule',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp(const HomeScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DWI ISKANDAR, M.Kom'), findsOneWidget);
    expect(find.text('NIDN: 0603048802'), findsOneWidget);
    expect(find.text('0603048802'), findsNothing);
  });

  testWidgets('Profile shows lecturer name and NIDN from SIAKAD schedule',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp(const ProfileScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('DWI ISKANDAR, M.Kom'), findsOneWidget);
    expect(find.text('NIDN: 0603048802'), findsOneWidget);
    expect(find.text('0603048802'), findsNothing);
  });

  testWidgets('Home falls back to safe display identity without schedule',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const tendik = UserModel(
      id: 45,
      name: 'Anisa Rahmawati, M.Kom.',
      email: 'anisa@kampus.ac.id',
      nip: '199008152015122001',
      position: 'Staf Administrasi',
      department: 'Akademik',
      isDosen: false,
      avatarInitial: 'AR',
      roles: ['tendik'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              AuthState(isAuthenticated: true, user: tendik),
            ),
          ),
          attendanceProvider.overrideWith((ref) => _FakeAttendanceNotifier()),
          scheduleProvider.overrideWith(
            (ref) => _FakeScheduleNotifier(ref, const ScheduleState()),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Anisa Rahmawati, M.Kom.'), findsOneWidget);
    expect(find.text('NIP: 199008152015122001'), findsOneWidget);
  });
}
