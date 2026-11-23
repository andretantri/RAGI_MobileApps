import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/services/app_permission_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _previousIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Diminta sekali setelah sesi login terdeteksi. Gunakan unawaited agar
    // dialog izin OS tidak memblokir render shell pertama.
    unawaited(AppPermissionService.requestOnAuthenticatedStart());
  }

  int _locationToIndex(String loc) {
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/modules')) return 1;
    if (loc.startsWith('/notifications')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    if (index == _currentIndex) return;

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });

    try {
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          context.go('/modules');
          break;
        case 2:
          context.go('/notifications');
          break;
        case 3:
          context.go('/profile');
          break;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    String location = '/home';
    try {
      location = GoRouterState.of(context).uri.toString();
    } catch (_) {}
    final newIndex = _locationToIndex(location);
    if (newIndex != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = newIndex;
    }

    final isForward = _currentIndex >= _previousIndex;
    final unreadCount = ref.watch(notificationProvider).unreadCount;

    return Scaffold(
      extendBody: true,
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 320),
        reverse: !isForward,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: _CurvedBottomNavWithCenterScan(
        currentIndex: _currentIndex,
        unreadCount: unreadCount,
        onTapTab: (index) {
          if (index == 2) {
            // Ketika tab notifikasi ditekan, otomatis tandai semua sudah dibaca & hilangkan badge
            ref.read(notificationProvider.notifier).markAllAsRead();
          }
          _onTap(context, index);
        },
        onTapCenterScan: () {
          HapticFeedback.mediumImpact();
          try {
            context.push('/scanner');
          } catch (_) {}
        },
      ),
    );
  }
}

class _CurvedBottomNavWithCenterScan extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTapTab;
  final VoidCallback onTapCenterScan;

  const _CurvedBottomNavWithCenterScan({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTapTab,
    required this.onTapCenterScan,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const barHeight = 68.0;
    const topFloat = 14.0;
    final totalHeight = barHeight + topFloat + bottomPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final centerX = totalWidth / 2;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Custom painted bar putih dengan cekungan lembut di tengah (center notch)
              CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: _CenterNotchedBarPainter(
                  centerX: centerX,
                  topOffset: topFloat,
                  barColor: Colors.white,
                  shadowColor: Colors.black.withValues(alpha: 0.10),
                ),
              ),

              // 2. Tombol Scan QR di Tengah (Hero Center Button)
              Positioned(
                left: centerX - 27.0,
                top: 0.0,
                child: GestureDetector(
                  onTap: onTapCenterScan,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0D47A1),
                          Color(0xFF1976D2),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withValues(alpha: 0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 2.8,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.face_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Row Navigasi 5 Slot (Beranda, Modul, Center Scan Spacer, Notifikasi, Profil)
              Positioned(
                left: 0,
                right: 0,
                top: topFloat,
                height: barHeight,
                child: Row(
                  children: [
                    // Tab 0: Beranda
                    Expanded(
                      child: _buildTabItem(
                        index: 0,
                        icon: Icons.home_rounded,
                        label: 'Beranda',
                        isSelected: currentIndex == 0,
                        onTap: () => onTapTab(0),
                      ),
                    ),

                    // Tab 1: Modul
                    Expanded(
                      child: _buildTabItem(
                        index: 1,
                        icon: Icons.apps_rounded,
                        label: 'Modul',
                        isSelected: currentIndex == 1,
                        onTap: () => onTapTab(1),
                      ),
                    ),

                    // Slot Tengah: Scan QR Label & Hotspot
                    Expanded(
                      child: GestureDetector(
                        onTap: onTapCenterScan,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          height: barHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Absen Wajah',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab 2: Notifikasi (dengan badge unreadCount)
                    Expanded(
                      child: _buildTabItem(
                        index: 2,
                        icon: Icons.notifications_rounded,
                        label: 'Notifikasi',
                        isSelected: currentIndex == 2,
                        badgeCount: unreadCount,
                        onTap: () => onTapTab(2),
                      ),
                    ),

                    // Tab 3: Profil
                    Expanded(
                      child: _buildTabItem(
                        index: 3,
                        icon: Icons.person_rounded,
                        label: 'Profil',
                        isSelected: currentIndex == 3,
                        onTap: () => onTapTab(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    final activeColor = AppColors.primary;
    const inactiveColor = Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                // Badge counter yang otomatis hilang saat ditekan (unreadCount == 0)
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter untuk bar putih dengan cekungan halus di tengah (center notch)
class _CenterNotchedBarPainter extends CustomPainter {
  final double centerX;
  final double topOffset;
  final Color barColor;
  final Color shadowColor;

  _CenterNotchedBarPainter({
    required this.centerX,
    required this.topOffset,
    required this.barColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const r = 38.0;
    const depth = 26.0;
    final top = topOffset;

    path.moveTo(0, top);

    // Garis lurus horizontal kiri sampai awal cekungan tengah
    final startX = (centerX - r).clamp(0.0, size.width);
    path.lineTo(startX, top);

    // Cekungan melingkar halus di tengah
    path.cubicTo(
      centerX - r * 0.55,
      top,
      centerX - r * 0.55,
      top + depth,
      centerX,
      top + depth,
    );
    path.cubicTo(
      centerX + r * 0.55,
      top + depth,
      centerX + r * 0.55,
      top,
      (centerX + r).clamp(0.0, size.width),
      top,
    );

    // Garis lurus ke tepi kanan dan menutup poligon ke bawah
    path.lineTo(size.width, top);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Gambar bayangan halus
    canvas.drawShadow(path, shadowColor, 12.0, false);

    // Gambar background putih
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CenterNotchedBarPainter oldDelegate) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.topOffset != topOffset ||
        oldDelegate.barColor != barColor;
  }
}
