import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/academic_provider.dart';
import '../../../core/models/grading_model.dart';
import '../../common/app_header.dart';

class ClassGradingScreen extends ConsumerStatefulWidget {
  final int kelasId;

  const ClassGradingScreen({super.key, required this.kelasId});

  @override
  ConsumerState<ClassGradingScreen> createState() => _ClassGradingScreenState();
}

class _ClassGradingScreenState extends ConsumerState<ClassGradingScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradingProvider.notifier).loadClassDetail(widget.kelasId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _getGradeColor(String? grade) {
    if (grade == null) return Colors.grey;
    if (grade.startsWith('A')) return const Color(0xFF10B981);
    if (grade.startsWith('B')) return const Color(0xFF2563EB);
    if (grade.startsWith('C')) return const Color(0xFFF59E0B);
    if (grade.startsWith('D')) return const Color(0xFFEA580C);
    return const Color(0xFFEF4444);
  }

  void _showEditGradeModal(BuildContext context, StudentGradeItem student,
      Map<String, double> bobot) {
    final harianCtrl = TextEditingController(
        text: student.nilaiHarian != null ? student.nilaiHarian.toString() : '');
    final utsCtrl = TextEditingController(
        text: student.nilaiUts != null ? student.nilaiUts.toString() : '');
    final uasCtrl = TextEditingController(
        text: student.nilaiUas != null ? student.nilaiUas.toString() : '');
    final praktikCtrl = TextEditingController(
        text: student.nilaiPraktik != null ? student.nilaiPraktik.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(bCtx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      student.nama.isNotEmpty ? student.nama[0] : 'M',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.nama,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          'NIM: ${student.nim}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'Komponen Penilaian (Skala 0 - 100):',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: harianCtrl,
                      label: 'Tugas/Harian',
                      weight: _formatBobot(bobot['harian']),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: utsCtrl,
                      label: 'Nilai UTS',
                      weight: _formatBobot(bobot['uts']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: uasCtrl,
                      label: 'Nilai UAS',
                      weight: _formatBobot(bobot['uas']),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: praktikCtrl,
                      label: 'Praktikum',
                      weight: _formatBobot(bobot['praktik']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final h = double.tryParse(harianCtrl.text.trim());
                    final t = double.tryParse(utsCtrl.text.trim());
                    final u = double.tryParse(uasCtrl.text.trim());
                    final p = double.tryParse(praktikCtrl.text.trim());

                    ref.read(gradingProvider.notifier).updateStudentGrade(
                          krsDetailId: student.krsDetailId,
                          nilaiHarian: h,
                          nilaiUts: t,
                          nilaiUas: u,
                          nilaiPraktik: p,
                        );

                    Navigator.pop(bCtx);
                  },
                  child: const Text('Simpan Nilai Siswa',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String weight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            Text(weight,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0 - 100',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
      ],
    );
  }

  void _showFinalizeDialog() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Finalisasi Nilai Kelas?'),
        content: const Text(
          'Nilai yang telah difinalisasi akan otomatis tersinkron ke transkrip akademik KHS mahasiswa dan BAAK. Anda tetap dapat melakukan koreksi nilai melalui pengajuan resmi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              final success = await ref
                  .read(gradingProvider.notifier)
                  .saveGrades(isFinal: true);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor:
                      success ? AppColors.success : AppColors.error,
                  content: Text(success
                      ? 'Nilai berhasil difinalisasi ke SIAKAD & KHS.'
                      : 'Gagal memfinalisasi nilai.'),
                ),
              );
              if (success) context.pop();
            },
            child: const Text('Ya, Finalisasi'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveDraft() async {
    final success =
        await ref.read(gradingProvider.notifier).saveGrades(isFinal: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            success ? AppColors.primaryDark : AppColors.error,
        content: Text(success
            ? 'Draft nilai berhasil disimpan.'
            : 'Gagal menyimpan draft.'),
      ),
    );
  }

  String _formatBobot(double? value) =>
      value == null || value <= 0 ? '-' : '${(value * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradingProvider);
    final detail = state.selectedClassDetail;
    final isLoading = state.isLoading;
    final isSaving = state.isSaving;

    final allStudents = detail?.students ?? [];
    final filteredStudents = _searchQuery.isEmpty
        ? allStudents
        : allStudents.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.nama.toLowerCase().contains(q) ||
                s.nim.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Header
          SliverToBoxAdapter(
            child: AppHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail?.namaMk ?? 'Input Nilai Kelas',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${detail?.kodeMk ?? ''} • ${detail?.sks ?? 3} SKS • ${detail?.kodeKelas ?? ''}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Info Bobot Penilaian
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BobotPill(
                      'Tugas', _formatBobot(detail?.bobot['harian'])),
                  _BobotPill('UTS', _formatBobot(detail?.bobot['uts'])),
                  _BobotPill('UAS', _formatBobot(detail?.bobot['uas'])),
                  _BobotPill(
                      'Praktik', _formatBobot(detail?.bobot['praktik'])),
                ],
              ),
            ),
          ),

          // 3. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIM mahasiswa...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
            ),
          ),

          // 4. Daftar Mahasiswa
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final student = filteredStudents[i];
                    final gradeColor = _getGradeColor(student.nilaiHuruf);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.divider, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  student.nama.isNotEmpty
                                      ? student.nama[0]
                                      : 'M',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.nama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      student.nim,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Grade Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: gradeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: gradeColor.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      student.nilaiHuruf ?? '-',
                                      style: TextStyle(
                                        color: gradeColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      student.nilaiAkhir != null
                                          ? student.nilaiAkhir!.toStringAsFixed(1)
                                          : '--',
                                      style: TextStyle(
                                        color: gradeColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          // Nilai komponen detail
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _NilaiPill(
                                  'Tugas', student.nilaiHarian?.toString()),
                              _NilaiPill('UTS', student.nilaiUts?.toString()),
                              _NilaiPill('UAS', student.nilaiUas?.toString()),
                              _NilaiPill(
                                  'Praktik', student.nilaiPraktik?.toString()),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _showEditGradeModal(
                                    context, student, detail!.bobot),
                                child: const Text(
                                  'Edit Nilai',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: filteredStudents.length,
                ),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: isSaving ? null : _handleSaveDraft,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan Draft',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isSaving ? null : _showFinalizeDialog,
                  child: const Text('Finalisasi Nilai',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BobotPill extends StatelessWidget {
  final String label;
  final String weight;

  const _BobotPill(this.label, this.weight);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        Text(weight,
            style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.primary,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _NilaiPill extends StatelessWidget {
  final String label;
  final String? value;

  const _NilaiPill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9.5, color: AppColors.textSecondary)),
        const SizedBox(height: 1),
        Text(
          value != null ? double.parse(value!).toStringAsFixed(0) : '--',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
