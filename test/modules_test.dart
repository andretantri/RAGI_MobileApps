import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/constants/module_config.dart';
import 'package:myinu_staff/core/models/rag_module.dart';
import 'package:myinu_staff/core/providers/auth_provider.dart';
import 'package:myinu_staff/core/providers/rag_module_provider.dart';
import 'package:myinu_staff/presentation/modules/modules_screen.dart';

List<RagModule> _ragModules(List<String> codes) => codes
    .map(
      (code) => RagModule(
        id: codes.indexOf(code) + 1,
        code: code,
        name: switch (code) {
          'simpeg' => 'SIMPEG (Kepegawaian)',
          'sippm' => 'SIPPM Kampus',
          'siakad' => 'SIAKAD (Akademik)',
          'sikeu' => 'SIKEU Kampus',
          'sinapra' => 'SINAPRA (Sarana & Prasarana)',
          'arsip' => 'ARSIP (Tata Persuratan)',
          'lms' => 'LMS (Learning Management)',
          'spmb' => 'SPMB (Penerimaan Mahasiswa)',
          _ => code.toUpperCase(),
        },
        description: 'Modul RAG $code',
        primaryColor: '#2563EB',
      ),
    )
    .toList();

const _dosen = UserModel(
  id: 5,
  name: 'Dwi Iskandar, M.Kom.',
  email: 'dwi@kampus.ac.id',
  nip: '0603048802',
  nidn: '0603048802',
  position: 'Dosen Pengajar',
  department: 'Teknik Informatika',
  isDosen: true,
  avatarInitial: 'DI',
  roles: ['simpeg', 'siakad'],
);

const _tendik = UserModel(
  id: 8,
  name: 'Anisa Rahmawati',
  email: 'anisa@kampus.ac.id',
  nip: '199008152015122001',
  position: 'Staf Administrasi',
  department: 'Akademik',
  isDosen: false,
  avatarInitial: 'AR',
  roles: ['simpeg'],
);

Widget _screen(UserModel user, List<RagModule> modules) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => AuthNotifier()
          ..state = AuthState(isAuthenticated: true, user: user),
      ),
      myRagModulesProvider.overrideWith((ref, token) async => modules),
    ],
    child: const MaterialApp(home: ModulesScreen()),
  );
}

void main() {
  group('Mobile Module Catalog Tests', () {
    test('katalog statis hanya berisi 8 modul bisnis RAG', () {
      final codes = AppModules.mobileModules.map((m) => m.code).toList();

      expect(
        codes,
        [
          'simpeg',
          'sippm',
          'siakad',
          'sikeu',
          'sinapra',
          'arsip',
          'lms',
          'spmb',
        ],
      );
      expect(AppModules.mobileModules.length, 8);
      expect(codes, isNot(contains('rekap')));
      expect(codes, isNot(contains('jadwal')));
    });

    test('RagModule membaca payload /modules/my-modules', () {
      final module = RagModule.fromJson({
        'id': 7,
        'code': 'SIAKAD',
        'name': 'SIAKAD (Akademik)',
        'description': 'Sistem Informasi Akademik',
        'primary_color': '#2563EB',
        'is_active': true,
      });

      expect(module.id, 7);
      expect(module.code, 'siakad');
      expect(module.name, 'SIAKAD (Akademik)');
      expect(module.primaryColor, '#2563EB');
      expect(module.isActive, isTrue);
    });

    test('shortcut tetap menyimpan metadata induk & dosenOnly', () {
      expect(AppModules.findByCode('rekap')?.parentCode, 'simpeg');
      expect(AppModules.findByCode('cuti')?.parentCode, 'simpeg');
      expect(AppModules.findByCode('jadwal')?.parentCode, 'siakad');
      expect(AppModules.findByCode('jadwal')?.dosenOnly, isTrue);
      expect(AppModules.findByCode('bimbingan')?.dosenOnly, isTrue);
      expect(AppModules.findByCode('rekap')?.dosenOnly, isFalse);
    });

    test('modul sso dipetakan ke data diri dan tidak masuk katalog bisnis', () {
      expect(AppModules.findByCode('sso')?.route, '/profile/data-diri');
      expect(
        AppModules.mobileModules.map((m) => m.code),
        isNot(contains('sso')),
      );
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> pumpScreen(
      WidgetTester tester,
      UserModel user,
      List<RagModule> modules,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_screen(user, modules));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('Dosen melihat 8 modul sesuai /modules/my-modules',
        (tester) async {
      final modules = _ragModules([
        'simpeg',
        'sippm',
        'siakad',
        'sikeu',
        'sinapra',
        'arsip',
        'lms',
        'spmb',
      ]);
      await pumpScreen(tester, _dosen, modules);

      expect(find.text('Katalog Layanan'), findsOneWidget);
      expect(find.text('8 Modul'), findsOneWidget);
      expect(find.text('SIPPM'), findsOneWidget);
      expect(find.text('SIPPM Kampus'), findsOneWidget);
      expect(find.text('SIAKAD'), findsOneWidget);
      expect(find.text('Rekap Kehadiran'), findsNothing);
      expect(find.text('Input Nilai'), findsNothing);
    });

    testWidgets('Tendik hanya melihat modul yang dikirim server',
        (tester) async {
      await pumpScreen(
        tester,
        _tendik,
        _ragModules(['simpeg', 'arsip']),
      );

      expect(find.text('2 Modul'), findsOneWidget);
      expect(find.text('SIMPEG'), findsOneWidget);
      expect(find.text('ARSIP'), findsOneWidget);
      expect(find.text('SIAKAD'), findsNothing);
      expect(find.text('Input Nilai'), findsNothing);
    });

    testWidgets('modul kosong menampilkan informasi, bukan data rekaan',
        (tester) async {
      await pumpScreen(tester, _dosen, const []);

      expect(
        find.text('Belum ada modul yang dapat diakses'),
        findsOneWidget,
      );
      expect(find.text('0 Modul'), findsOneWidget);
    });
  });
}
