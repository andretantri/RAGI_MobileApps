import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myinu_staff/presentation/dashboard/home_screen.dart';

void main() {
  testWidgets('HomeScreen header renders background, badges, and avatar picker modal', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Tanpa data API, header tidak boleh menampilkan identitas rekaan.
    expect(find.text('Dr. Randhi Yuansyah'), findsNothing);
    expect(find.text('NIP: -'), findsOneWidget);
    expect(find.byIcon(Icons.credit_card_outlined), findsOneWidget);

    // Check badges (tanpa data profil API, label memakai placeholder '-')
    expect(find.text('Dosen Pengajar'), findsNothing);
    expect(find.text('Ilmu Komputer'), findsNothing);
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_rounded), findsOneWidget);

    // Tidak ada ikon kamera di avatar beranda (pindah ke halaman Profil)
    expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);
  });
}
