import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/mobile_feature_config.dart';
import '../../core/models/mobile_feature_model.dart';
import '../../core/models/mobile_staff_models.dart';
import '../../core/providers/mobile_feature_provider.dart';
import '../../core/providers/mobile_staff_provider.dart';
import '../../core/services/api_exception.dart';
import '../../core/services/mobile_staff_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/app_header.dart';

/// Detail item mobile staff: payroll, e-file, dan surat tugas (LPJ).
class MobileStaffDetailScreen extends ConsumerStatefulWidget {
  final String featureCode;
  final String id;
  final MobileFeatureItem? initialItem;

  const MobileStaffDetailScreen({
    super.key,
    required this.featureCode,
    required this.id,
    this.initialItem,
  });

  @override
  ConsumerState<MobileStaffDetailScreen> createState() =>
      _MobileStaffDetailScreenState();
}

class _MobileStaffDetailScreenState
    extends ConsumerState<MobileStaffDetailScreen> {
  String? _busy;
  MobileFeatureItem? _lpjResult;
  MobileFeatureItem? _updatedEfile;

  MobileFeature? get _feature =>
      AppMobileFeatures.findByCode(widget.featureCode);

  static String _raw(MobileFeatureItem item, List<String> keys) {
    for (final key in keys) {
      final value = item.raw[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyLink(String url, [String label = 'Tautan']) async {
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    _showMessage('$label disalin.');
  }

  Future<void> _downloadSlip() async {
    setState(() => _busy = 'slip');
    try {
      final result = await MobileStaffService.downloadPayrollSlip(widget.id);
      final dir = await Directory.systemTemp.createTemp('slip-gaji-');
      final file = File('${dir.path}/${result.fileName}');
      await file.writeAsBytes(result.bytes);

      var opened = false;
      try {
        opened = await launchUrl(Uri.file(file.path));
      } catch (_) {
        // Platform tanpa handler file: tetap laporkan lokasi berkas.
      }
      _showMessage(
        opened ? 'Slip gaji dibuka.' : 'Slip gaji tersimpan: ${file.path}',
      );
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage(
        'Gagal menyimpan slip gaji. Periksa koneksi lalu coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _openEfile() async {
    setState(() => _busy = 'efile');
    try {
      final link = await MobileStaffService.fetchEfileDownload(widget.id);
      try {
        final opened = await launchUrl(
          Uri.parse(link.fileUrl),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) throw const ApiException('Tautan tidak dapat dibuka.');
      } catch (_) {
        await _copyLink(link.fileUrl, 'Tautan unduh');
        _showMessage(
          'Tautan unduh disalin (berlaku ${link.expiresInSeconds} detik).',
        );
      }
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage(
        'Gagal membuat tautan unduh. Periksa koneksi lalu coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _editEfile(
    MobileFeatureItem item,
    String? detailEndpoint,
  ) async {
    final nameController = TextEditingController(text: item.title);
    final currentJenis = _raw(item, ['jenis_dokumen']);
    String selectedJenis = mobileEfileJenisDokumen.contains(currentJenis)
        ? currentJenis
        : mobileEfileJenisDokumen.first;
    PlatformFile? pickedFile;
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Dokumen E-File',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama dokumen *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama dokumen wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedJenis,
                      decoration: const InputDecoration(
                        labelText: 'Jenis dokumen *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final jenis in mobileEfileJenisDokumen)
                          DropdownMenuItem(value: jenis, child: Text(jenis)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedJenis = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
                        );
                        if (res != null && res.files.isNotEmpty) {
                          setModalState(() => pickedFile = res.files.first);
                        }
                      },
                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                      label: Text(
                        pickedFile == null
                            ? 'Ganti berkas (opsional: PDF/JPG/PNG)'
                            : 'Berkas baru: ${pickedFile!.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          Navigator.of(ctx).pop(true);
                        }
                      },
                      child: const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    final updatedName = nameController.text.trim();
    nameController.dispose();
    if (saved != true || !mounted) return;

    setState(() => _busy = 'edit_efile');
    try {
      final updated = await MobileStaffService.updateEfile(
        id: widget.id,
        namaDokumen: updatedName,
        jenisDokumen: selectedJenis,
        file: pickedFile?.xFile,
      );
      ref.invalidate(mobileFeatureItemsProvider(widget.featureCode));
      final listEndpoint = _feature?.endpoint;
      if (listEndpoint != null) {
        ref.invalidate(mobileStaffPageProvider(listEndpoint));
      }
      if (detailEndpoint != null) {
        ref.invalidate(mobileStaffDetailProvider(detailEndpoint));
      }
      if (!mounted) return;
      setState(() => _updatedEfile = updated);
      _showMessage('Dokumen e-file berhasil diperbarui.');
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Gagal memperbarui dokumen. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _deleteEfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen E-File?'),
        content: const Text(
          'Berkas dokumen akan dihapus permanen dari arsip digital Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = 'delete_efile');
    try {
      await MobileStaffService.deleteEfile(widget.id);
      ref.invalidate(mobileFeatureItemsProvider(widget.featureCode));
      final listEndpoint = _feature?.endpoint;
      if (listEndpoint != null) {
        ref.invalidate(mobileStaffPageProvider(listEndpoint));
      }
      if (!mounted) return;
      _showMessage('Dokumen e-file berhasil dihapus.');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/features/${widget.featureCode}');
      }
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Gagal menghapus dokumen. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _uploadLpj() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() => _busy = 'lpj');
    try {
      final result = await MobileStaffService.uploadLpj(
        suratTugasId: widget.id,
        file: picked.files.first.xFile,
      );
      ref.invalidate(mobileFeatureItemsProvider(widget.featureCode));
      if (!mounted) return;
      setState(() => _lpjResult = result);
      _showMessage('Berkas LPJ berhasil diunggah.');
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Gagal mengunggah LPJ. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feature = _feature;
    final color = feature?.color ?? AppColors.primary;
    final icon = feature?.icon ?? Icons.article_outlined;

    final payrollAsync = (feature?.code == 'payroll')
        ? ref.watch(mobileStaffPayrollDetailProvider(widget.id))
        : null;
    final endpoint = feature?.detailEndpoint;
    final detailAsync = (endpoint != null && widget.initialItem == null)
        ? ref.watch(
            mobileStaffDetailProvider(
              MobileFeature.resolveId(endpoint, widget.id),
            ),
          )
        : null;

    AsyncValue<dynamic>? active;
    if (payrollAsync != null) {
      active = payrollAsync;
    } else if (detailAsync != null) {
      active = detailAsync;
    }

    if (active?.isLoading == true) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (active?.hasError == true) {
      final error = active!.error!;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiException
                      ? error.message
                      : 'Data belum dapat dimuat.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(
                    payrollAsync != null
                        ? mobileStaffPayrollDetailProvider(widget.id)
                        : mobileStaffDetailProvider(
                            MobileFeature.resolveId(endpoint!, widget.id),
                          ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final payroll = payrollAsync?.valueOrNull;
    final item =
        _updatedEfile ??
        payroll?.item ??
        detailAsync?.valueOrNull ??
        widget.initialItem;
    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Detail tidak tersedia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/features/${widget.featureCode}');
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title.isNotEmpty
                              ? item.title
                              : (feature?.title ?? 'Detail'),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.subtitle.isNotEmpty
                              ? item.subtitle
                              : (feature?.subtitle ?? ''),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Card(
                    children: [
                      if (item.hasStatus)
                        _row('Status', item.status.toUpperCase()),
                      if (item.hasDate) _row('Tanggal', item.date),
                      if (item.hasAmount) _row('Nominal', item.amount),
                      if (feature?.code == 'payroll' && payroll != null) ...[
                        _row('Periode', payroll.periode),
                        _row('Gaji Pokok', payroll.gajiPokok),
                        _row('Total Tunjangan', payroll.totalTunjangan),
                        _row('Total Potongan', payroll.totalPotongan),
                        _row('Gaji Bersih', payroll.gajiBersih),
                      ],
                      if (feature?.code == 'e-file') ...[
                        _row('Jenis Dokumen', _raw(item, ['jenis_dokumen'])),
                        _row('Ukuran Berkas', _raw(item, ['file_size'])),
                        _row(
                          'Catatan Verifikasi',
                          _raw(item, ['catatan_verifikasi']),
                        ),
                      ],
                      if (feature?.code == 'surat-tugas') ...[
                        _row('Nomor Surat', _raw(item, ['nomor_surat'])),
                        _row(
                          'Tujuan',
                          _raw(item, ['lokasi_tujuan', 'tempat_berangkat']),
                        ),
                      ],
                      _row('ID', item.id),
                    ],
                  ),
                  if (feature?.code == 'payroll' && payroll != null) ...[
                    const SizedBox(height: 14),
                    _ListCard(title: 'Pendapatan', rows: payroll.pendapatan),
                    const SizedBox(height: 14),
                    _ListCard(title: 'Potongan', rows: payroll.potongan),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy == null ? _downloadSlip : null,
                      icon: _busy == 'slip'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Unduh Slip PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                  if (feature?.code == 'e-file') ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy == null ? _openEfile : null,
                      icon: _busy == 'efile'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.open_in_new_rounded),
                      label: const Text('Buka / Unduh Dokumen'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy == null
                                ? () => _editEfile(
                                    item,
                                    endpoint == null
                                        ? null
                                        : MobileFeature.resolveId(
                                            endpoint,
                                            widget.id,
                                          ),
                                  )
                                : null,
                            icon: _busy == 'edit_efile'
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Berkas'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy == null ? _deleteEfile : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            icon: _busy == 'delete_efile'
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.error,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                            label: const Text('Hapus'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (feature?.code == 'surat-tugas') ...[
                    const SizedBox(height: 14),
                    _Card(
                      children: [
                        Text(
                          'Laporan Pertanggungjawaban (LPJ)',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_lpjResult != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _lpjResult!.title.isNotEmpty
                                  ? _lpjResult!.title
                                  : 'LPJ berhasil diunggah.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        for (final entry in <(String, String)>[
                          ('Surat Tugas', _raw(item, ['file_surat_tugas_url'])),
                          ('LPJ', _raw(item, ['file_lpj_url'])),
                        ])
                          if (entry.$2.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OutlinedButton.icon(
                                onPressed: () => _copyLink(entry.$2, entry.$1),
                                icon: const Icon(Icons.link_rounded, size: 16),
                                label: Text('Salin Tautan ${entry.$1}'),
                              ),
                            ),
                        const SizedBox(height: 4),
                        FilledButton.icon(
                          onPressed: _busy == null ? _uploadLpj : null,
                          icon: _busy == 'lpj'
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded),
                          label: const Text('Unggah LPJ (PDF)'),
                          style: FilledButton.styleFrom(backgroundColor: color),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final List<MobileStaffPayrollComponent> rows;

  const _ListCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text(
              'Tidak ada komponen.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(row.komponen, style: AppTextStyles.caption),
                  ),
                  Text(
                    row.formattedNominal,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
