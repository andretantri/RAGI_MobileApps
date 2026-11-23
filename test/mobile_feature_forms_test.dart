import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myinu_staff/core/constants/mobile_feature_config.dart';
import 'package:myinu_staff/core/models/mobile_feature_submission.dart';
import 'package:myinu_staff/core/models/mobile_feature_model.dart';
import 'package:myinu_staff/core/models/sippm_lookup_model.dart';
import 'package:myinu_staff/core/providers/mobile_feature_provider.dart';
import 'package:myinu_staff/presentation/features/mobile_feature_form_screen.dart';
import 'package:myinu_staff/presentation/features/mobile_feature_list_screen.dart';

Widget _screen(Widget child) {
  return ProviderScope(
    overrides: [
      sippmLookupsProvider.overrideWith(
        (ref) async => const SippmLookups(
          skema: [
            SippmLookup(id: 1, name: 'Penelitian Dosen Pemula', subtitle: 'PDP'),
          ],
          periode: [
            SippmLookup(id: 2, name: 'Hibah Gelombang I', subtitle: '2026/2027'),
          ],
        ),
      ),
      mobileFeatureItemsProvider.overrideWith(
        (ref, code) async => <MobileFeatureItem>[],
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('Kontrak endpoint MobileStaffController', () {
    test('endpoint tulis sesuai kontrak backend', () {
      expect(
        AppMobileFeatures.findByCode('proposal-hibah')?.submitEndpoint,
        '/mobile/staff/sippm/proposal',
      );
      expect(
        AppMobileFeatures.findByCode('pengajuan-sikeu')?.submitEndpoint,
        '/mobile/staff/sikeu/pengajuan',
      );
      expect(
        AppMobileFeatures.findByCode('tiket-sinapra')?.submitEndpoint,
        '/mobile/staff/sinapra/tiket',
      );
      expect(
        AppMobileFeatures.findByCode('referral-spmb')?.submitEndpoint,
        '/mobile/staff/spmb/referral',
      );
      expect(AppMobileFeatures.submittable.length, 4);
    });

    test('payload proposal SIPPM memakai field kontrak', () {
      final submission = MobileFeatureSubmission(
        type: MobileFeatureFormType.proposalSippm,
        values: {
          'judul': 'Sistem Mobile Kampus',
          'abstrak': '',
          'rumpun_ilmu': 'Ilmu Komputer',
          'skema_id': 1,
          'periode_id': 2,
          'target_tkt': 3,
          'anggaran_diajukan': '15000000',
        },
      );

      expect(submission.fileKey, 'file_proposal');
      expect(submission.toJson(), {
        'judul': 'Sistem Mobile Kampus',
        'rumpun_ilmu': 'Ilmu Komputer',
        'skema_id': 1,
        'periode_id': 2,
        'target_tkt': 3,
        'anggaran_diajukan': 15000000,
      });
    });

    test('payload pengajuan SIKEU dan tiket SINAPRA memakai field kontrak', () {
      final pengajuan = MobileFeatureSubmission(
        type: MobileFeatureFormType.pengajuanSikeu,
        values: {
          'judul_pengajuan': 'Reimbursement IoT',
          'nominal_diajukan': 'Rp 750.000',
          'jenis_pengajuan': 'reimbursement',
        },
      );
      expect(pengajuan.fileKey, 'file_lampiran');
      expect(pengajuan.toJson()['nominal_diajukan'], 750000);

      final tiket = MobileFeatureSubmission(
        type: MobileFeatureFormType.tiketSinapra,
        values: {
          'judul': 'AC rusak',
          'deskripsi_kerusakan': 'Tidak dingin',
          'prioritas': 'tinggi',
          'ruangan_id': 2,
        },
      );
      expect(tiket.fileKey, 'foto');
      expect(tiket.toJson(), {
        'judul': 'AC rusak',
        'deskripsi_kerusakan': 'Tidak dingin',
        'prioritas': 'tinggi',
        'ruangan_id': 2,
      });

      const referral = MobileFeatureSubmission(
        type: MobileFeatureFormType.referralSpmb,
        values: {},
      );
      expect(referral.toJson(), isEmpty);
      expect(referral.supportsFile, isFalse);
    });
  });

  group('Form aksi tulis', () {
    Future<void> pumpForm(WidgetTester tester, String code) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _screen(MobileFeatureFormScreen(featureCode: code)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('form proposal menampilkan skema, periode, dan lampiran PDF',
        (tester) async {
      await pumpForm(tester, 'proposal-hibah');

      expect(find.text('Ajukan Proposal'), findsAtLeastNWidgets(1));
      expect(find.text('Judul proposal *'), findsOneWidget);
      expect(find.text('Rumpun ilmu *'), findsOneWidget);
      expect(find.text('Skema hibah *'), findsOneWidget);
      expect(find.text('Periode hibah *'), findsOneWidget);
      expect(find.text('Berkas proposal PDF *'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsNWidgets(2));
    });

    testWidgets('form pengajuan SIKEU menampilkan jenis dan nominal',
        (tester) async {
      await pumpForm(tester, 'pengajuan-sikeu');

      expect(find.text('Kirim Pengajuan'), findsAtLeastNWidgets(1));
      expect(find.text('Judul pengajuan *'), findsOneWidget);
      expect(find.text('Nominal diajukan (Rp) *'), findsOneWidget);
      expect(find.text('Jenis pengajuan'), findsOneWidget);
      expect(find.text('Lampiran opsional (PDF/JPG/PNG)'), findsOneWidget);
    });

    testWidgets('form tiket SINAPRA menampilkan prioritas dan deskripsi',
        (tester) async {
      await pumpForm(tester, 'tiket-sinapra');

      expect(find.text('Lapor Kerusakan'), findsAtLeastNWidgets(1));
      expect(find.text('Judul kerusakan *'), findsOneWidget);
      expect(find.text('Deskripsi kerusakan *'), findsOneWidget);
      expect(find.text('Prioritas'), findsOneWidget);
    });

    testWidgets('form referral tidak meminta input manual', (tester) async {
      await pumpForm(tester, 'referral-spmb');

      expect(find.text('Buat Link Referral'), findsAtLeastNWidgets(1));
      expect(
        find.textContaining('Backend akan membuat atau memperbarui'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('daftar fitur menampilkan FAB aksi tulis', (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _screen(
          const MobileFeatureListScreen(featureCode: 'pengajuan-sikeu'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Kirim Pengajuan'), findsOneWidget);
    });
  });
}
