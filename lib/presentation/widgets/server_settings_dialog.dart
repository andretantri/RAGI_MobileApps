import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/attendance_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ServerSettingsDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const ServerSettingsDialog({super.key, this.onSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    if (!kDebugMode) {
      return showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Server terkunci'),
          content: const Text(
            'Build release selalu menggunakan API produksi RAG. Pengaturan URL hanya tersedia di build debug.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    }
    return showDialog(
      context: context,
      builder: (_) => ServerSettingsDialog(onSaved: onSaved),
    );
  }

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final current = await AttendanceService.getBaseUrl();
    if (mounted) {
      setState(() {
        _urlController.text = current;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _applyPreset(String url) {
    setState(() {
      _urlController.text = url;
    });
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    // Validasi: hanya izinkan HTTPS di production
    if (const bool.fromEnvironment('dart.vm.product') && !url.startsWith('https://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL harus menggunakan HTTPS untuk keamanan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final result = await AttendanceService.setCustomBaseUrl(url);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat server diperbarui ke:\n$result'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
      widget.onSaved?.call();
    }
  }

  Future<void> _resetDefault() async {
    await AttendanceService.resetBaseUrl();
    final defaultUrl = AttendanceService.defaultProdBaseUrl;
    setState(() {
      _urlController.text = defaultUrl;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat server direset ke default:\n$defaultUrl'),
          backgroundColor: AppColors.primary,
        ),
      );
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'Pengaturan Server API',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih server backend presensi atau masukkan URL custom:',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  // Preset Buttons
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Produksi (Cloud)'),
                        backgroundColor: _urlController.text == AttendanceService.defaultProdBaseUrl
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : null,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _urlController.text == AttendanceService.defaultProdBaseUrl
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        onPressed: () => _applyPreset(AttendanceService.defaultProdBaseUrl),
                      ),
                      if (!const bool.fromEnvironment('dart.vm.product')) ...[
                        ActionChip(
                          label: const Text('Localhost (:8001)'),
                          backgroundColor: _urlController.text == AttendanceService.defaultLocalBaseUrl
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : null,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _urlController.text == AttendanceService.defaultLocalBaseUrl
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          onPressed: () => _applyPreset(AttendanceService.defaultLocalBaseUrl),
                        ),
                        ActionChip(
                          label: const Text('Emulator Android (:8001)'),
                          labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          onPressed: () => _applyPreset('http://10.0.2.2:8001/api/v1'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Base URL API',
                      hintText: 'https://...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _resetDefault,
          child: const Text('Reset Default', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _save,
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
