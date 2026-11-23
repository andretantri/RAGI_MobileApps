import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/module_config.dart';
import '../../core/constants/mobile_feature_config.dart';
import '../../core/models/rag_module.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/rag_module_provider.dart';
import '../common/app_header.dart';

class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDosen = user?.isDosen ?? false;
    final userPosition = user?.position ?? '-';
    final modulesAsync = ref.watch(myRagModulesProvider(authState.token));

    // Sumber kebenaran hak akses ada di server RAG (/modules/my-modules),
    // sama seperti App Launcher di web. Katalog statis hanya dipakai untuk
    // memetakan ikon, warna, dan route lokal.
    final ragModules = modulesAsync.valueOrNull ?? const <RagModule>[];
    final modules = ragModules.map(_moduleFromRag).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Katalog Layanan',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Modul & Sistem',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.apps_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              modulesAsync.isLoading
                                  ? 'Memuat Modul'
                                  : '${modules.length} Modul',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Akses sistem akademik & operasional Politeknik Indonusa Surakarta',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (modulesAsync.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 48, 16, 0),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (modulesAsync.hasError)
            SliverToBoxAdapter(
              child: _ModuleStateCard(
                icon: Icons.cloud_off_outlined,
                title: 'Daftar modul belum dapat dimuat',
                message:
                    'Periksa koneksi lalu muat ulang. Daftar modul diambil langsung dari server RAG.',
                actionLabel: 'Coba Lagi',
                onPressed: () =>
                    ref.invalidate(myRagModulesProvider(authState.token)),
              ),
            )
          else if (modules.isEmpty)
            SliverToBoxAdapter(
              child: _ModuleStateCard(
                icon: Icons.apps_outlined,
                title: 'Belum ada modul yang dapat diakses',
                message:
                    'Hubungi administrator jika hak akses modul Anda belum diatur.',
                actionLabel: 'Muat Ulang',
                onPressed: () =>
                    ref.invalidate(myRagModulesProvider(authState.token)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    return _BigModuleCard(
                      module: modules[i],
                      hasAccess: true,
                      isDosen: isDosen,
                      userPosition: userPosition,
                    );
                  },
                  childCount: modules.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  ModuleConfig _moduleFromRag(RagModule rag) {
    final local = AppModules.findByCode(rag.code);
    return ModuleConfig(
      code: rag.code,
      name: local?.name ?? rag.name,
      shortName: rag.name.isNotEmpty
          ? rag.name
          : (local?.shortName ?? rag.description),
      description: rag.description.isNotEmpty
          ? rag.description
          : (local?.description ?? ''),
      color: _colorFromHex(rag.primaryColor) ??
          local?.color ??
          AppColors.primary,
      icon: local?.icon ?? Icons.apps_outlined,
      route: local?.route ?? '/modules/${rag.code}',
      isMobileModule: true,
      parentCode: local?.parentCode,
      dosenOnly: local?.dosenOnly ?? false,
    );
  }

  Color? _colorFromHex(String? value) {
    if (value == null || value.isEmpty) return null;
    var hex = value.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}

class _ModuleStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _ModuleStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 34, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigModuleCard extends StatelessWidget {
  final ModuleConfig module;
  final bool hasAccess;
  final bool isDosen;
  final String userPosition;

  const _BigModuleCard({
    required this.module,
    required this.hasAccess,
    required this.isDosen,
    required this.userPosition,
  });

  void _showSiakadBottomSheet(BuildContext context) {
    if (!isDosen) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF4338CA), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SIAKAD Politeknik Indonusa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Informasi Akses Akademik Staf',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Akses Khusus Dosen Pengajar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Akun Anda terdaftar sebagai Tenaga Kependidikan / Staf ($userPosition). Fitur operasional perkuliahan (Jadwal Mengajar, Input Nilai OBE, Bimbingan DPA, & Jurnal BAP) diperuntukkan khusus bagi akun Dosen Pengajar.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/simpeg');
                    },
                    icon: const Icon(Icons.badge_rounded, size: 18),
                    label: const Text(
                      'Buka Modul Kepegawaian (SIMPEG)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.siakad.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: AppColors.siakad, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIAKAD Politeknik Indonusa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Sistem Informasi Akademik Terintegrasi RAG',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSiakadTile(
                context: ctx,
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFD97706),
                title: 'Jadwal Mengajar Dosen',
                subtitle: 'Jadwal kuliah mingguan, ruangan, dan kelas hari ini',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/schedule');
                },
              ),
              const SizedBox(height: 8),
              _buildSiakadTile(
                context: ctx,
                icon: Icons.assignment_turned_in_rounded,
                color: const Color(0xFF0284C7),
                title: 'Input Nilai Mahasiswa (KHS & OBE)',
                subtitle:
                    'Form nilai tugas, UTS, UAS, dan konversi predikat nilai',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/siakad/grading');
                },
              ),
              const SizedBox(height: 8),
              _buildSiakadTile(
                context: ctx,
                icon: Icons.supervisor_account_rounded,
                color: const Color(0xFF059669),
                title: 'Bimbingan Akademik (DPA & KRS)',
                subtitle:
                    'Daftar mahasiswa bimbingan, review KRS, & catatan PA',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/siakad/advising');
                },
              ),
              const SizedBox(height: 8),
              _buildSiakadTile(
                context: ctx,
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF0F766E),
                title: 'Jurnal Perkuliahan & Presensi (BAP)',
                subtitle:
                    'Kelola 16 pertemuan kelas, token/QR presensi, & jurnal BAP',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/siakad/perkuliahan');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSiakadTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (hasAccess) {
          // Modul IAM/SSO dikirim server, tetapi di mobile hanya membuka
          // informasi data diri (read-only), bukan halaman under-construction.
          if (module.code == 'sso') {
            context.push(module.route);
            return;
          }
          if (module.code == 'siakad') {
            _showSiakadBottomSheet(context);
            return;
          }
          if (module.code == 'simpeg') {
            context.push('/simpeg');
            return;
          }
          // Modul RAG yang sudah dikurasi membuka hub fitur mobile.
          if (module.isMobileModule &&
              AppMobileFeatures.forModule(module.code).isNotEmpty) {
            context.push('/modules/${module.code}');
            return;
          }
          // Pintasan mobile sudah memiliki halaman nyata, langsung dibuka.
          if (module.isMobileModule && module.parentCode != null) {
            context.push(module.route);
            return;
          }
          context.push(
            '/under-construction',
            extra: {
              'title': '${module.name} - ${module.shortName}',
              'category': 'Portal Modul ${module.name}',
              'subtitle':
                  'Layanan ${module.description} sedang dalam tahap integrasi dengan server Project RAG Politeknik Indonusa.',
              'icon': module.icon,
              'color': module.color,
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Akun Anda belum memiliki izin hak akses untuk modul ${module.name}. Silakan hubungi Admin SDM/SIMPEG.'),
              backgroundColor: AppColors.textPrimary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: hasAccess ? AppColors.surface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasAccess
                ? module.color.withValues(alpha: 0.22)
                : AppColors.divider,
            width: 1,
          ),
          boxShadow: hasAccess
              ? [
                  BoxShadow(
                    color: module.color.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Background watermark icon
            Positioned(
              bottom: -6,
              right: -6,
              child: Icon(
                module.icon,
                size: 50,
                color: module.color.withValues(alpha: 0.07),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: hasAccess
                              ? module.color.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          module.icon,
                          color: hasAccess ? module.color : AppColors.textHint,
                          size: 20,
                        ),
                      ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: hasAccess
                              ? AppColors.success
                              : AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    module.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: hasAccess
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.shortName,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
