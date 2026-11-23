import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/pertemuan_model.dart';
import '../../../core/services/academic_service.dart';
import '../../../core/theme/app_colors.dart';

class ClassJournalScreen extends StatefulWidget {
  final int kelasId;
  const ClassJournalScreen({super.key, required this.kelasId});

  @override
  State<ClassJournalScreen> createState() => _ClassJournalScreenState();
}

class _ClassJournalScreenState extends State<ClassJournalScreen> {
  bool _isLoading = true;
  KelasPertemuanItem? _kelas;
  List<PertemuanItem> _pertemuanList = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await AcademicService.fetchPertemuanList(widget.kelasId);
      if (mounted) {
        setState(() {
          _kelas = res['kelas'] as KelasPertemuanItem?;
          _pertemuanList = (res['pertemuan'] as List<PertemuanItem>?) ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat jurnal pertemuan: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showStartMeetingModal(PertemuanItem item) {
    final materiController = TextEditingController(text: item.materi ?? '');
    final catatanController = TextEditingController(text: item.catatan ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 24,
            ),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.play_circle_fill_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mulai Pertemuan ke-${item.pertemuanKe}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _kelas?.namaMk ?? 'Mata Kuliah',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Input Materi Pokok Bahasan
                const Text(
                  'Pokok Bahasan / Materi Perkuliahan *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: materiController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Konsep OOP, Class, dan Objek pada Java',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Input Catatan / Tugas
                const Text(
                  'Catatan Perkuliahan / Penugasan (Opsional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: catatanController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Mahasiswa mengerjakan praktikum Modul 3',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final materi = materiController.text.trim();
                            if (materi.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Harap isi materi perkuliahan.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(bottomSheetCtx);
                            final router = GoRouter.of(context);

                            setModalState(() => isSubmitting = true);

                            Map<String, dynamic>? res;
                            String? errorMessage;
                            try {
                              res = await AcademicService.mulaiSesiPertemuan(
                                kelasId: widget.kelasId,
                                pertemuanKe: item.pertemuanKe,
                                materi: materi,
                                catatan: catatanController.text.trim(),
                              );
                            } catch (e) {
                              errorMessage = e.toString();
                            }

                            nav.pop();
                            if (!mounted) return;

                            final pertemuanIdRaw = res?['id'] ?? res?['pertemuan_id'];
                            final pertemuanId = int.tryParse(pertemuanIdRaw?.toString() ?? '') ?? 0;

                            if (errorMessage == null && pertemuanId > 0) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Pertemuan ${item.pertemuanKe} dimulai! Token: ${res?['token_absensi'] ?? ''}'),
                                  backgroundColor: AppColors.primaryDark,
                                ),
                              );

                              // Reload and open session
                              _loadData();
                              router.push('/siakad/perkuliahan/session/$pertemuanId');
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage ??
                                      'Server tidak mengirimkan detail sesi perkuliahan.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.qr_code_rounded, size: 20),
                    label: Text(
                      isSubmitting ? 'Memulai Sesi...' : 'Mulai Perkuliahan & Buka Presensi',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = _pertemuanList.cast<PertemuanItem?>().firstWhere(
          (p) => p?.isActive == true,
          orElse: () => null,
        );

    final selesaiCount = _pertemuanList.where((p) => p.status == 'selesai').length;
final totalPertemuan = _kelas?.totalPertemuan ?? _pertemuanList.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _kelas != null ? '${_kelas!.kodeMk} - ${_kelas!.namaKelas}' : 'Jurnal Pertemuan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Active session banner if any
                      if (activeItem != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.sensors_rounded,
                                    color: AppColors.warning, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pertemuan ${activeItem.pertemuanKe} Sedang Berlangsung!',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Token Presensi: ${activeItem.tokenAbsensi ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (activeItem.id != null) {
                                    context.push(
                                        '/siakad/perkuliahan/session/${activeItem.id}');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Buka QR',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                      // Class details header card
                      if (_kelas != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_kelas!.kodeMk} • ${_kelas!.sks} SKS',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$selesaiCount/$totalPertemuan Selesai',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _kelas!.namaMk,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_kelas!.kodeKelas} • ${_kelas!.namaKelas}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(_kelas!.ruangan,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.people_outline_rounded,
                                        size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text('${_kelas!.totalMahasiswa} Mahasiswa',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Agenda $totalPertemuan Pertemuan (BAP)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$selesaiCount dari $totalPertemuan Pertemuan',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ..._pertemuanList.map((p) => _buildPertemuanCard(p)),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPertemuanCard(PertemuanItem item) {
    final isDone = item.status == 'selesai';
    final isOngoing = item.status == 'berlangsung';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOngoing
              ? AppColors.warning
              : (isDone ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider),
          width: isOngoing ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isOngoing || isDone) {
              if (item.id != null) {
                context.push('/siakad/perkuliahan/session/${item.id}');
              }
            } else {
              _showStartMeetingModal(item);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Pertemuan Ke & Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOngoing
                                  ? AppColors.warningLight
                                  : (isDone
                                      ? AppColors.primary.withValues(alpha: 0.08)
                                      : AppColors.background),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pertemuan ${item.pertemuanKe}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOngoing
                                    ? AppColors.warning
                                    : (isDone ? AppColors.primaryDark : AppColors.textPrimary),
                              ),
                            ),
                          ),
                          if (item.tanggal != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item.tanggal!,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: item.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Materi Pokok Bahasan
                Text(
                  item.materi != null && item.materi!.isNotEmpty
                      ? item.materi!
                      : 'Pokok bahasan belum diisi (Klik untuk input).',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: item.materi != null ? FontWeight.w700 : FontWeight.normal,
                    fontStyle: item.materi != null ? FontStyle.normal : FontStyle.italic,
                    color: item.materi != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),

                if (item.catatan != null && item.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.catatan!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Kehadiran summary if done or ongoing
                if (isDone || isOngoing) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPresensiChip('Hadir', item.totalHadir, AppColors.success),
                        _buildPresensiChip('Izin', item.totalIzin, AppColors.info),
                        _buildPresensiChip('Sakit', item.totalSakit, AppColors.warning),
                        _buildPresensiChip('Alfa', item.totalAlfa, AppColors.error),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action button
                Align(
                  alignment: Alignment.centerRight,
                  child: isOngoing
                      ? ElevatedButton.icon(
                          onPressed: () {
                            if (item.id != null) {
                              context.push('/siakad/perkuliahan/session/${item.id}');
                            }
                          },
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: const Text('Buka Presensi & QR',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : isDone
                          ? OutlinedButton.icon(
                              onPressed: () {
                                if (item.id != null) {
                                  context.push('/siakad/perkuliahan/session/${item.id}');
                                }
                              },
                              icon: const Icon(Icons.checklist_rounded, size: 16),
                              label: const Text('Detail Presensi Mahasiswa',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _showStartMeetingModal(item),
                              icon: const Icon(Icons.play_arrow_rounded, size: 16),
                              label: const Text('Mulai Perkuliahan',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresensiChip(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
