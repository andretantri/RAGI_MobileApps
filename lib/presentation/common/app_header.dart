import 'package:flutter/material.dart';

/// Reusable App Header dengan background image `background.jpeg`,
/// gradien biru khas MyIn-U Staff, dan sudut lengkung bawah yang presisi.
class AppHeader extends StatelessWidget {
  final Widget child;
  final double bottomRadius;
  final EdgeInsetsGeometry padding;

  const AppHeader({
    super.key,
    required this.child,
    this.bottomRadius = 28.0,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
        child: Stack(
          children: [
            // 1. Gambar latar background.jpeg tampil tegas & tajam
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.jpeg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (ctx, err, stack) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D47A1), Color(0xFF00388F)],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Overlay gradien biru transparan elegan untuk kontras teks yang optimal
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0D47A1).withValues(alpha: 0.38),
                      const Color(0xFF002A7A).withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Header Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
