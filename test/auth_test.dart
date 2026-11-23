import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/providers/auth_provider.dart';
import 'package:myinu_staff/core/services/attendance_service.dart';
import 'package:myinu_staff/presentation/auth/login_screen.dart';
import 'package:myinu_staff/presentation/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('UserModel.fromApi parses backend trial user correctly', () {
    final mockUser = {
      'id': 32,
      'name': 'DWI ISKANDAR',
      'username': '603048802',
      'email': '603048802@campus.ac.id',
      'roles': ['dosen'],
    };

    final mockEmployee = {
      'id': 26,
      'employee_code': '230810016',
      'nip': '230810016',
      'nidn': '603048802',
      'position': 'dosen',
      'department': 'General',
      'is_active': true,
      'office': {
        'id': 1,
        'name': 'Kampus 1 Politeknik Indonusa Surakarta',
      },
    };

    final user = UserModel.fromApi(user: mockUser, employee: mockEmployee);

    expect(user.name, equals('DWI ISKANDAR'));
    expect(user.nip, equals('230810016'));
    expect(user.position, equals('dosen'));
    expect(user.department, equals('General'));
    expect(user.isDosen, isTrue);
    expect(user.avatarInitial, equals('DI'));
  });

  test('UserModel.fromApi tidak menjadikan username/NIDN sebagai nama', () {
    final mockUser = {
      'id': 32,
      'name': '603048802',
      'username': '603048802',
      'email': '603048802@campus.ac.id',
      'roles': ['dosen'],
    };
    final mockEmployee = {
      'employee_code': '230810016',
      'nip': '230810016',
      'nidn': '603048802',
      'name': 'DWI ISKANDAR, M.Kom',
      'position': 'Dosen',
      'department': 'Teknik Informatika',
      'is_active': true,
    };

    final user = UserModel.fromApi(user: mockUser, employee: mockEmployee);

    expect(user.name, equals('DWI ISKANDAR, M.Kom'));
    expect(user.nidn, equals('603048802'));
    expect(user.nip, equals('230810016'));
    expect(user.displayName, equals('DWI ISKANDAR, M.Kom'));
    expect(user.displayId, equals('603048802'));
    expect(user.displayIdLabel, equals('NIDN'));

    // Bila employee tidak mengirim nama, jangan fallback ke NIDN/username.
    final withoutEmployeeName = UserModel.fromApi(
      user: mockUser,
      employee: {...mockEmployee}..remove('name'),
    );
    expect(withoutEmployeeName.name, equals('Pegawai Indonusa'));
    expect(withoutEmployeeName.displayName, equals('Pegawai Indonusa'));
  });

  test('UserModel.fromApi parses Tendik (non-dosen staff) correctly', () {
    final mockUser = {
      'id': 45,
      'name': 'Siti Rahmawati',
      'username': 'tendik_it',
      'email': 'siti@poltekindonusa.ac.id',
      'roles': ['tendik', 'staf'],
    };

    final mockEmployee = {
      'id': 30,
      'employee_code': '202109015',
      'nip': '202109015',
      'position': 'Staf IT & Jaringan',
      'department': 'Biro Sistem Informasi',
      'is_active': true,
      'jenis_pegawai': 'tendik',
      'office': {
        'id': 1,
        'name': 'Kampus Utama Politeknik Indonusa Surakarta',
      },
    };

    final user = UserModel.fromApi(user: mockUser, employee: mockEmployee);

    expect(user.name, equals('Siti Rahmawati'));
    expect(user.position, equals('Staf IT & Jaringan'));
    expect(user.department, equals('Biro Sistem Informasi'));
    expect(user.isDosen, isFalse);
    expect(user.isTendik, isTrue);
    expect(user.isAdminSimpeg, isFalse);
    expect(user.avatarInitial, equals('SR'));
  });

  test('isAllowedStaffRole permits Dosen and Tendik but rejects Mahasiswa', () {
    // Dosen -> Allowed
    expect(
      AuthNotifier.isAllowedStaffRole(
        user: {'name': 'Dosen Test'},
        employee: {'position': 'Dosen Pengajar', 'is_active': true},
      ),
      isTrue,
    );

    // Tendik / Staff -> Allowed
    expect(
      AuthNotifier.isAllowedStaffRole(
        user: {'name': 'Staff Test'},
        employee: {'position': 'Staff IT & Tendik', 'is_active': true},
      ),
      isTrue,
    );

    // Mahasiswa -> Rejected
    expect(
      AuthNotifier.isAllowedStaffRole(
        user: {'name': 'Mahasiswa Test'},
        employee: {'position': 'Mahasiswa', 'is_active': true},
      ),
      isFalse,
    );

    // Inactive Employee -> Rejected
    expect(
      AuthNotifier.isAllowedStaffRole(
        user: {'name': 'Inactive Staff'},
        employee: {'position': 'Staff', 'is_active': false},
      ),
      isFalse,
    );
  });

  test('AuthNotifier logout clears token and user', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test_token',
      'user_data': '{"id":1,"name":"Test User"}',
      'employee_data': '{"id":1,"employee_code":"123"}',
    });
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'test_token',
      'user_data': '{"id":1,"name":"Test User"}',
      'employee_data': '{"id":1,"employee_code":"123"}',
    });

    final notifier = AuthNotifier();
    await notifier.logout();

    expect(notifier.state.isAuthenticated, isFalse);
    expect(notifier.state.user, isNull);
    expect(notifier.state.token, isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
    expect(prefs.getString('user_data'), isNull);
    expect(await AttendanceService.getToken(), isNull);
  });

  testWidgets('LoginScreen displays full labels and updated UTI SSO dialog', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Title & Subtitle
    expect(find.text('Portal Dosen & Tenaga Kependidikan'), findsOneWidget);
    expect(find.text('POLITEKNIK INDONUSA SURAKARTA'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/logo.png')),
      findsOneWidget,
    );

    // Verify Expanded / Full Form Labels
    expect(find.text('Nomor Induk Dosen / Pegawai (NIDN / NIP / Username)'), findsOneWidget);
    expect(find.text('Contoh: 61234123'), findsOneWidget);
    expect(find.text('Kata Sandi Akun SSO (Password)'), findsOneWidget);
    expect(find.text('Single Sign-On (SSO) Kampus Terpadu'), findsOneWidget);

    // Tap Lupa Kata Sandi?
    await tester.tap(find.text('Lupa Kata Sandi?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify SSO Dialog Content
    expect(find.text('Bantuan Akun SSO'), findsOneWidget);
    expect(find.text('Unit Teknologi Informasi (UTI):'), findsOneWidget);
    expect(find.text('uti@poltekindonusa.ac.id'), findsOneWidget);
    expect(find.text('Ruang IT Kampus 1 Gedung C'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);

    // Tap Tutup to close dialog
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Bantuan Akun SSO'), findsNothing);
  });

  testWidgets('ProfileScreen photo modal opens and displays Gallery and Camera options',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Seed logged in user
    container.read(authProvider.notifier).state = const AuthState(
      isAuthenticated: true,
      user: UserModel(
        id: 1,
        name: 'Dwi Iskandar',
        email: 'dwi@poltekindonusa.ac.id',
        nip: '230810016',
        position: 'Dosen',
        department: 'Teknik Informatika',
        isDosen: true,
        avatarInitial: 'DI',
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Profile Name & Initial
    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Dwi Iskandar'), findsOneWidget);
    expect(find.text('DI'), findsOneWidget);

    // Tap Avatar to open modal
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Modal Contents
    expect(find.text('Ubah Foto Profil'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);
    expect(find.text('Ambil Foto (Kamera)'), findsOneWidget);

    // Verify official campus preset avatars are NOT present
    expect(find.text('PILIH AVATAR RESMI KAMPUS'), findsNothing);
    expect(find.text('Dosen Formal Pria'), findsNothing);
  });
}
