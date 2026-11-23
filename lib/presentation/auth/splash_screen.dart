import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late DateTime _startTime;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    // Inisialisasi controller untuk animasi logo & loading bar
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.forward();

    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    // Beri waktu 2.6 detik agar animasi pembentukan logo & loading bar selesai 100%
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted || _navigating) return;

    _navigating = true;

    try {
      final isLoggedIn = await ref.read(authProvider.notifier).checkSession();
      if (!mounted) return;

      if (isLoggedIn) {
        debugPrint('[Splash] Sesi ditemukan, menuju ke Beranda (/home)...');
        context.go('/home');
      } else {
        debugPrint('[Splash] Belum login, menuju ke Halaman Login (/login)...');
        context.go('/login');
      }
    } catch (e) {
      debugPrint('[Splash] checkSession error: $e. Fallback ke /login');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double elapsed =
        DateTime.now().difference(_startTime).inMicroseconds / 1000000.0;
    final double progress = _easeInOutCubic((elapsed / 2.5).clamp(0.0, 1.0));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            // Decorative circles background (tetap sesuai konfigurasi asli)
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Dot pattern dekoratif (tetap sesuai konfigurasi asli)
            Positioned(
              top: 100,
              right: 30,
              child: _DotPattern(),
            ),
            Positioned(
              bottom: 160,
              left: 30,
              child: _DotPattern(),
            ),

            // Center content: Logo teranimasi sesuai animate.html + slogan & badge
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: math.min(320.0, MediaQuery.of(context).size.width - 48),
                    height: 105,
                    child: _AnimatedMyInULogo(time: elapsed),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kampus dalam genggamanmu',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Staff & Dosen',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom watermark & animated loading bar (sesuai animate.html)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedProgressBar(progress: progress),
                  const SizedBox(height: 16),
                  Text(
                    'Politeknik Indonusa • Build v1.0',
                    style: AppTextStyles.caption.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ANIMATED PROGRESS BAR (SESUAI ANIMATE.HTML)
// ==========================================
class _AnimatedProgressBar extends StatelessWidget {
  final double progress;

  const _AnimatedProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 220,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(99),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Memuat… ${(progress.clamp(0.0, 1.0) * 100).toInt()}%',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// ANIMATED LOGO CANVAS (SESUAI ANIMATE.HTML)
// ==========================================
class _AnimatedMyInULogo extends StatelessWidget {
  final double time;

  const _AnimatedMyInULogo({required this.time});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MyInULogoPainter(time: time),
    );
  }
}

class _MyInULogoPainter extends CustomPainter {
  final double time;

  _MyInULogoPainter({required this.time});

  static final List<_LetterModel> _letters = _buildLetters();
  static const List<Offset> _offs = [
    Offset(-110, -160),
    Offset(50, 170),
    Offset(-30, -190),
    Offset(70, 165),
    Offset(130, -170),
    Offset(100, -150),
  ];
  static const List<double> _rots = [-.9, .8, -.6, .9, -1.2, .7];

  @override
  void paint(Canvas canvas, Size size) {
    const double targetWidth = 260.0;
    const double scale = targetWidth / 1040.0; // 0.25
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Pass 1: Gambar garis tepi putih (white outline) terlebih dahulu di semua huruf
    // agar menyatu mulus membentuk kontur resmi logo di atas background biru gelap
    for (int i = 0; i < _letters.length; i++) {
      _drawLetter(
        canvas: canvas,
        letterIndex: i,
        center: center,
        scale: scale,
        isWhiteOutline: true,
      );
    }

    // Pass 2: Gambar garis warna utama (Biru, Merah, Kuning/Orange) di atas kontur putih
    for (int i = 0; i < _letters.length; i++) {
      _drawLetter(
        canvas: canvas,
        letterIndex: i,
        center: center,
        scale: scale,
        isWhiteOutline: false,
      );
    }
  }

  void _drawLetter({
    required Canvas canvas,
    required int letterIndex,
    required Offset center,
    required double scale,
    required bool isWhiteOutline,
  }) {
    final letter = _letters[letterIndex];
    final double intro = _clamp((time - 0.14 * letterIndex) / 1.5);
    final double p = intro;
    if (p <= 0.0) return;

    final double e1 = _clamp(p / 0.22);
    final double e2 = _clamp((p - 0.22) / 0.3);
    final double e3 = _clamp((p - 0.52) / 0.48);
    final double wf =
        e2 > 0 ? _lerp(0.3, 1.0, _easeOutCubic(e2)) : 0.3 * _easeOutBack(e1);
    final double len = 0.22 * _easeOutCubic(e2);
    final double e = _easeInOutCubic(e3);
    final double back = 1.0 - _easeOutBack(e3);
    final double drift = (1.0 - e3) * math.sin(time * 1.6 + letterIndex) * 10;

    double posX = (letter.home.dx + _offs[letterIndex].dx * back + drift) * scale;
    double posY = (letter.home.dy + _offs[letterIndex].dy * back + drift * 0.6) * scale;
    final double rot = _rots[letterIndex] * back;
    if (p >= 0.999) {
      posY += math.sin(time * 2.2 + letterIndex * 0.7) * 4.5 * scale;
    }

    final double a = _lerp(0.5 - len / 2, 0.0, e);
    final double b = _lerp(0.5 + len / 2, 1.0, e);
    final double strokeWf = wf;

    if (b - a < 0.005) return;

    canvas.save();
    canvas.translate(center.dx + posX, center.dy + posY);
    canvas.rotate(rot);
    canvas.scale(scale);

    for (final stroke in letter.strokes) {
      canvas.save();
      canvas.translate(stroke.off.dx * back, stroke.off.dy * back);

      final Path? subPath = stroke.getSubPath(a, b);
      if (subPath != null) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (isWhiteOutline) {
          paint
            ..color = Colors.white
            ..strokeWidth = (stroke.width * strokeWf + 24.0);
        } else {
          paint
            ..color = letter.color
            ..strokeWidth = (stroke.width * strokeWf);
        }

        canvas.drawPath(subPath, paint);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MyInULogoPainter oldDelegate) =>
      oldDelegate.time != time;
}

// ==========================================
// STRUKTUR DATA MODEL & KOORDINAT HURUF
// ==========================================
class _LetterModel {
  final Color color;
  final Offset home;
  final List<_StrokeModel> strokes;

  _LetterModel({
    required this.color,
    required this.home,
    required this.strokes,
  });
}

class _StrokeModel {
  final List<Offset> points;
  final double width;
  final Offset off;
  final List<double> cumDistances;
  final double totalLength;

  _StrokeModel({
    required this.points,
    required this.width,
    required this.off,
    required this.cumDistances,
    required this.totalLength,
  });

  Offset at(double s) {
    final double dist = s.clamp(0.0, totalLength);
    int i = 1;
    while (i < cumDistances.length - 1 && cumDistances[i] < dist) {
      i++;
    }
    final double d0 = cumDistances[i - 1];
    final double d1 = cumDistances[i];
    final double span = d1 - d0;
    final double t = span > 0.0001 ? (dist - d0) / span : 0.0;
    return Offset.lerp(points[i - 1], points[i], t)!;
  }

  Path? getSubPath(double a, double b) {
    final double s0 = (a * totalLength).clamp(0.0, totalLength);
    final double s1 = (b * totalLength).clamp(0.0, totalLength);
    if (s1 - s0 < 0.5) return null;

    final path = Path();
    final p0 = at(s0);
    path.moveTo(p0.dx, p0.dy);

    for (int i = 0; i < points.length; i++) {
      final double c = cumDistances[i];
      if (c > s0 + 0.01 && c < s1 - 0.01) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    final p1 = at(s1);
    path.lineTo(p1.dx, p1.dy);
    return path;
  }
}

// ==========================================
// FUNGSI MATEMATIKA & EASING DARI ANIMATE.HTML
// ==========================================
double _clamp(double x, [double a = 0.0, double b = 1.0]) =>
    math.min(b, math.max(a, x));

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _easeOutCubic(double t) => 1.0 - math.pow(1.0 - t, 3).toDouble();

double _easeInOutCubic(double t) =>
    t < 0.5 ? 4.0 * t * t * t : 1.0 - math.pow(-2.0 * t + 2.0, 3).toDouble() / 2.0;

double _easeOutBack(double t) {
  const c1 = 1.9;
  const c3 = c1 + 1.0;
  return 1.0 + c3 * math.pow(t - 1.0, 3) + c1 * math.pow(t - 1.0, 2);
}

double _rnd(double a, double b) {
  final double s = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return (s - s.floor()) * 2.0 - 1.0;
}

List<Offset> _line(Offset a, Offset b) {
  final int n = math.max(1, ((b - a).distance / 5.0).ceil());
  return List.generate(n + 1, (i) => Offset.lerp(a, b, i / n)!);
}

List<Offset> _arc(
    double cx, double cy, double rx, double ry, double a0, double a1) {
  final int n = ((a1 - a0).abs() / 4.0).ceil();
  return List.generate(n + 1, (i) {
    final double t = (a0 + (a1 - a0) * (i / n)) * math.pi / 180.0;
    return Offset(cx + rx * math.cos(t), cy + ry * math.sin(t));
  });
}

List<Offset> _cubic(Offset p0, Offset p1, Offset p2, Offset p3) {
  return List.generate(25, (i) {
    final double t = i / 24.0;
    final double u = 1.0 - t;
    final double x = u * u * u * p0.dx +
        3 * u * u * t * p1.dx +
        3 * u * t * t * p2.dx +
        t * t * t * p3.dx;
    final double y = u * u * u * p0.dy +
        3 * u * u * t * p1.dy +
        3 * u * t * t * p2.dy +
        t * t * t * p3.dy;
    return Offset(x, y);
  });
}

List<Offset> _join(List<List<Offset>> pieces) {
  final result = <Offset>[];
  for (final piece in pieces) {
    if (result.isNotEmpty && piece.isNotEmpty) {
      result.addAll(piece.skip(1));
    } else {
      result.addAll(piece);
    }
  }
  return result;
}

// Inisialisasi model huruf & goresan berdasarkan koordinat persis dari animate.html
List<_LetterModel> _buildLetters() {
  const double ox = 769.0;
  const double oy = 470.0;

  // Warna sesuai animate.html (BLUE dark mode 0x5b9bff untuk kontras optimal di background biru)
  const Color blue = Color(0xFF5B9BFF);
  const Color red = Color(0xFFF83734);
  const Color orange = Color(0xFFF9A516);

  final rawDefs = [
    // 0: 'm' (Blue)
    {
      'color': blue,
      'strokes': [
        {'pts': _line(const Offset(246.5, 541.5), const Offset(246.5, 418.5)), 'w': 65.0},
        {'pts': _arc(298, 455, 51.5, 42, 180, 360), 'w': 54.0},
        {'pts': _line(const Offset(349.5, 541.5), const Offset(349.5, 455)), 'w': 65.0},
        {'pts': _arc(400, 455, 51, 42, 180, 360), 'w': 54.0},
        {'pts': _line(const Offset(451, 541.5), const Offset(451, 455)), 'w': 65.0},
      ]
    },
    // 1: 'y' (Blue)
    {
      'color': blue,
      'strokes': [
        {'pts': _line(const Offset(519, 417), const Offset(572, 540)), 'w': 64.0},
        {
          'pts': _join([
            _line(const Offset(632, 417), const Offset(566, 556)),
            _cubic(const Offset(566, 556), const Offset(549, 592), const Offset(526, 607), const Offset(499, 607))
          ]),
          'w': 64.0
        },
      ]
    },
    // 2: 'I' (Blue)
    {
      'color': blue,
      'strokes': [
        {'pts': _line(const Offset(709.5, 539.5), const Offset(709.5, 335.5)), 'w': 73.0},
      ]
    },
    // 3: 'n' (Red)
    {
      'color': red,
      'strokes': [
        {'pts': _line(const Offset(794.5, 540), const Offset(794.5, 440)), 'w': 71.0},
        {'pts': _arc(857.5, 440, 63, 48, 180, 360), 'w': 70.0},
        {'pts': _line(const Offset(920.5, 540), const Offset(920.5, 440)), 'w': 73.0},
      ]
    },
    // 4: '-' (Orange/Yellow)
    {
      'color': orange,
      'strokes': [
        {'pts': _line(const Offset(1000, 467.5), const Offset(1055, 467.5)), 'w': 56.0},
      ]
    },
    // 5: 'U' (Blue)
    {
      'color': blue,
      'strokes': [
        {
          'pts': _join([
            _line(const Offset(1136, 356), const Offset(1136, 477)),
            _arc(1210.75, 477, 74.75, 75, 180, 0),
            _line(const Offset(1285.5, 477), const Offset(1285.5, 356))
          ]),
          'w': 76.0
        },
      ]
    },
  ];

  final result = <_LetterModel>[];

  for (int i = 0; i < rawDefs.length; i++) {
    final def = rawDefs[i];
    final color = def['color'] as Color;
    final strokesRaw = def['strokes'] as List<Map<String, dynamic>>;

    double minX = 1e9, maxX = -1e9, minY = 1e9, maxY = -1e9;
    for (final s in strokesRaw) {
      final pts = s['pts'] as List<Offset>;
      for (final p in pts) {
        minX = math.min(minX, p.dx);
        maxX = math.max(maxX, p.dx);
        minY = math.min(minY, p.dy);
        maxY = math.max(maxY, p.dy);
      }
    }

    final Offset c = Offset((minX + maxX) / 2.0, (minY + maxY) / 2.0);
    final Offset home = Offset(c.dx - ox, c.dy - oy);

    final strokeModels = <_StrokeModel>[];
    for (int j = 0; j < strokesRaw.length; j++) {
      final s = strokesRaw[j];
      final pts = s['pts'] as List<Offset>;
      final double w = s['w'] as double;

      final relPoints = pts.map((p) => Offset(p.dx - c.dx, p.dy - c.dy)).toList();
      final cum = <double>[0.0];
      for (int k = 1; k < relPoints.length; k++) {
        cum.add(cum[k - 1] + (relPoints[k] - relPoints[k - 1]).distance);
      }
      final double totalL = cum.last;
      final Offset off = Offset(
        _rnd(i.toDouble(), j.toDouble()) * 50.0,
        _rnd(j.toDouble(), (i + 3).toDouble()) * 50.0,
      );

      strokeModels.add(_StrokeModel(
        points: relPoints,
        width: w,
        off: off,
        cumDistances: cum,
        totalLength: totalL,
      ));
    }

    result.add(_LetterModel(
      color: color,
      home: home,
      strokes: strokeModels,
    ));
  }

  return result;
}

// ==========================================
// BACKGROUND DOT PATTERN
// ==========================================
class _DotPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          9,
          (i) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }
}
