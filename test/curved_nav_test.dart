import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:myinu_staff/presentation/dashboard/main_shell.dart';
import 'package:myinu_staff/core/providers/notification_provider.dart';

class _TestNotificationNotifier extends NotificationNotifier {
  _TestNotificationNotifier() {
    state = const NotificationState(
      items: [
        NotificationItem(
            id: '1',
            title: 'T1',
            body: 'B1',
            icon: Icons.notifications,
            color: Colors.blue,
            time: '1m',
            isRead: false,
            module: 'SIAKAD'),
        NotificationItem(
            id: '2',
            title: 'T2',
            body: 'B2',
            icon: Icons.notifications,
            color: Colors.blue,
            time: '2m',
            isRead: false,
            module: 'SIMPEG'),
        NotificationItem(
            id: '3',
            title: 'T3',
            body: 'B3',
            icon: Icons.notifications,
            color: Colors.blue,
            time: '3m',
            isRead: false,
            module: 'PRESENSI'),
      ],
      isLoading: false,
    );
  }
}

void main() {
  testWidgets(
      'MainShell renders curved nav bar with center scan button, badge, and no floating FAB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationProvider
              .overrideWith((ref) => _TestNotificationNotifier()),
        ],
        child: const MaterialApp(
          home: MainShell(
            child: Text('Content Beranda'),
          ),
        ),
      ),
    );

    // Verify 4 tabs
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Modul'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Verify notification badge '3' initially appears
    expect(find.text('3'), findsOneWidget);

    // Verify center scan / absen button in navigation bar
    expect(find.text('Absen Wajah'), findsOneWidget);
    expect(find.byIcon(Icons.face_rounded), findsOneWidget);

    // Verify floating action button is completely removed
    expect(find.byType(FloatingActionButton), findsNothing);

    // Verify PageTransitionSwitcher is used for smooth animated transitions
    expect(find.byType(PageTransitionSwitcher), findsOneWidget);

    // Verify initial content rendered
    expect(find.text('Content Beranda'), findsOneWidget);

    // Tap on Notifikasi tab -> badge disappears!
    await tester.tap(find.text('Notifikasi'));
    await tester.pumpAndSettle();

    // Verify notification badge '3' is gone!
    expect(find.text('3'), findsNothing);
  });
}
