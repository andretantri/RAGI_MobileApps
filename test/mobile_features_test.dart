import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/constants/mobile_feature_config.dart';
import 'package:myinu_staff/core/models/mobile_feature_model.dart';
import 'package:myinu_staff/core/models/teaching_schedule_model.dart';
import 'package:myinu_staff/core/providers/auth_provider.dart';
import 'package:myinu_staff/core/providers/mobile_feature_provider.dart';
import 'package:myinu_staff/core/providers/schedule_provider.dart';
import 'package:myinu_staff/core/services/api_exception.dart';
import 'package:myinu_staff/presentation/features/mobile_feature_list_screen.dart';
import 'package:myinu_staff/presentation/features/module_feature_hub_screen.dart';
import 'package:myinu_staff/presentation/profile/data_diri_screen.dart';

class _FakeScheduleNotifier extends ScheduleNotifier {
  _FakeScheduleNotifier(super.ref, ScheduleState initial) {
    state = initial;
  }

  @override
  Future<void> loadSchedule() async {}
}

Widget _appWithAuth(Widget child, UserModel user) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) =>
            AuthNotifier()
              ..state = AuthState(isAuthenticated: true, user: user),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  const dosen = UserModel(
    id: 32,
    name: 'DWI ISKANDAR, M.Kom',
    email: 'dwi@kampus.ac.id',
    nip: '230810016',
    nidn: '0603048802',
    position: 'Dosen Pengajar',
    department: 'Teknik Informatika',
    isDosen: true,
    avatarInitial: 'DI',
    roles: ['dosen'],
  );

  const tendik = UserModel(
    id: 45,
    name: 'Anisa Rahmawati',
    email: 'anisa@kampus.ac.id',
    nip: '199008152015122001',
    position: 'Staf Administrasi',
    department: 'Akademik',
    isDosen: false,
    avatarInitial: 'AR',
    roles: ['tendik'],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Mobile Feature Catalog', () {
    test('module features are curated and dosenOnly flags are set', () {
      expect(
        AppMobileFeatures.codesForModule('sikeu'),
        containsAll(['payroll', 'pengajuan-sikeu']),
      );
      expect(
        AppMobileFeatures.codesForModule('spmb'),
        contains('referral-spmb'),
      );
      expect(AppMobileFeatures.findByCode('bahan-ajar')?.dosenOnly, isTrue);
      expect(AppMobileFeatures.findByCode('proposal-hibah')?.dosenOnly, isTrue);
      expect(AppMobileFeatures.findByCode('referral-spmb')?.dosenOnly, isFalse);
    });

    test('MobileFeatureItem parses flexible API payload', () {
      final item = MobileFeatureItem.fromJson({
        'id': 7,
        'nama': 'Slip November 2026',
        'keterangan': 'Gaji bulanan',
        'status_approval': 'disetujui',
        'created_at': '2026-11-21',
        'nominal': '8500000',
      });

      expect(item.id, '7');
      expect(item.title, 'Slip November 2026');
      expect(item.subtitle, 'Gaji bulanan');
      expect(item.status, 'disetujui');
      expect(item.date, '2026-11-21');
      expect(item.amount, '8500000');
    });

    test('MobileFeatureItem.referralCode supports backend field variants', () {
      expect(
        MobileFeatureItem.fromJson({
          'id': 1,
          'referral_code': 'REF-SPMB-01',
        }).referralCode,
        'REF-SPMB-01',
      );
      expect(
        MobileFeatureItem.fromJson({
          'id': 2,
          'kode': 'REF-SPMB-02',
        }).referralCode,
        'REF-SPMB-02',
      );
      expect(MobileFeatureItem.fromJson({'id': 9}).referralCode, '9');
    });
  });

  group('Mobile Feature Screens', () {
    testWidgets('SIKEU hub shows payroll and Pengajuan Saya', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _appWithAuth(const ModuleFeatureHubScreen(moduleCode: 'sikeu'), tendik),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SIKEU'), findsOneWidget);
      expect(find.text('Riwayat Payroll'), findsOneWidget);
      expect(find.text('Pengajuan Saya'), findsOneWidget);
    });

    testWidgets('LMS hub hides dosen-only features for tendik', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _appWithAuth(const ModuleFeatureHubScreen(moduleCode: 'lms'), tendik),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Belum ada fitur mobile yang tersedia untuk modul ini.'),
        findsOneWidget,
      );
      expect(find.text('Bahan Ajar & RPS'), findsNothing);
    });

    testWidgets('LMS hub shows dosen-only features for dosen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _appWithAuth(const ModuleFeatureHubScreen(moduleCode: 'lms'), dosen),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bahan Ajar & RPS'), findsOneWidget);
      expect(find.text('Pengumuman Kelas'), findsOneWidget);
    });

    testWidgets('Feature list renders empty state without data', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mobileFeatureItemsProvider.overrideWith(
              (ref, code) async => <MobileFeatureItem>[],
            ),
          ],
          child: const MaterialApp(
            home: MobileFeatureListScreen(featureCode: 'payroll'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Riwayat Payroll'), findsOneWidget);
      expect(find.text('Belum ada data'), findsOneWidget);
      expect(find.text('Muat Ulang'), findsOneWidget);
    });

    testWidgets('submission list groups items by approval status', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mobileFeatureItemsProvider.overrideWith((ref, code) async {
              return [
                MobileFeatureItem.fromJson({
                  'id': '1',
                  'judul_pengajuan': 'Reimbursement perjalanan',
                  'status_approval': 'pending',
                }),
                MobileFeatureItem.fromJson({
                  'id': '2',
                  'judul_pengajuan': 'Kas kegiatan',
                  'status_approval': 'disetujui',
                }),
                MobileFeatureItem.fromJson({
                  'id': '3',
                  'judul_pengajuan': 'Pembelian alat',
                  'status_approval': 'ditolak',
                }),
              ];
            }),
          ],
          child: const MaterialApp(
            home: MobileFeatureListScreen(featureCode: 'pengajuan-sikeu'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Disetujui'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(find.text('Reimbursement perjalanan'), findsOneWidget);
      expect(find.text('Kas kegiatan'), findsNothing);
      expect(find.text('Pembelian alat'), findsNothing);

      await tester.tap(find.text('Disetujui'));
      await tester.pumpAndSettle();
      expect(find.text('Kas kegiatan'), findsOneWidget);
    });

    testWidgets('Referral list shows Salin Kode when data exists', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mobileFeatureItemsProvider.overrideWith((ref, code) async {
              return [
                MobileFeatureItem.fromJson({
                  'id': 'r1',
                  'nama': 'Mahasiswa Binaan',
                  'kode_referral': 'REF-SPMB-01',
                }),
              ];
            }),
          ],
          child: const MaterialApp(
            home: MobileFeatureListScreen(featureCode: 'referral-spmb'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Referral SPMB'), findsOneWidget);
      expect(find.text('Mahasiswa Binaan'), findsOneWidget);
      expect(find.byTooltip('Salin Kode'), findsOneWidget);
      expect(find.text('Buat Link Referral'), findsNothing);
    });

    testWidgets('Feature list renders API error with retry', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mobileFeatureItemsProvider.overrideWith((ref, code) async {
              throw const ApiException('Server SIKEU belum merespons.');
            }),
          ],
          child: const MaterialApp(
            home: MobileFeatureListScreen(featureCode: 'pengajuan-sikeu'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pengajuan Saya'), findsOneWidget);
      expect(find.text('Data belum dapat dimuat'), findsOneWidget);
      expect(find.text('Server SIKEU belum merespons.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('Data Diri shows SIAKAD name and NIDN', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const schedule = TeachingScheduleResult(
        lecturerName: 'DWI ISKANDAR, M.Kom',
        nidn: '0603048802',
        todayDay: '-',
        todayClasses: [],
        allClasses: [],
        totalSks: 0,
        totalClasses: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) =>
                  AuthNotifier()
                    ..state = AuthState(isAuthenticated: true, user: dosen),
            ),
            scheduleProvider.overrideWith(
              (ref) => _FakeScheduleNotifier(
                ref,
                const ScheduleState(schedule: schedule),
              ),
            ),
          ],
          child: const MaterialApp(home: DataDiriScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Data Diri & Biodata'), findsOneWidget);
      expect(find.text('DWI ISKANDAR, M.Kom'), findsAtLeastNWidgets(1));
      expect(find.text('NIDN'), findsOneWidget);
      expect(find.text('0603048802'), findsAtLeastNWidgets(1));
    });
  });
}
