import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/simpeg_provider.dart';
import '../../core/services/simpeg_service.dart';
import '../common/app_header.dart';

class AnnouncementBroadcastScreen extends ConsumerStatefulWidget {
  const AnnouncementBroadcastScreen({super.key});

  @override
  ConsumerState<AnnouncementBroadcastScreen> createState() =>
      _AnnouncementBroadcastScreenState();
}

class _AnnouncementBroadcastScreenState
    extends ConsumerState<AnnouncementBroadcastScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _urlController = TextEditingController();

  String _formatIndonesianDate(DateTime d) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // Selected states
  String _selectedCategory = 'seragam'; // seragam, rapat, deadline, umum
  String _targetRole = 'all_staff'; // all_staff, dosen, tendik
  bool _isAgenda = true;
  bool _isHighPriority = false;
  DateTime _selectedDate = DateTime.now();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _getTargetRoleLabel() {
    switch (_targetRole) {
      case 'dosen':
        return 'Dosen';
      case 'tendik':
        return 'Tendik / Staff';
      default:
        return 'Semua Pegawai (Dosen & Tendik)';
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'seragam':
        return Icons.checkroom_rounded;
      case 'rapat':
        return Icons.groups_rounded;
      case 'deadline':
        return Icons.alarm_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'seragam':
        return const Color(0xFF0284C7); // Sky Blue
      case 'rapat':
        return const Color(0xFF7C3AED); // Purple
      case 'deadline':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _confirmAndBroadcast() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Judul Pengumuman terlebih dahulu.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Pesan Pengumuman.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Konfirmasi Broadcast',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengumuman dan push notification akan segera dikirimkan ke perangkat pegawai dengan rincian:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                      'Target Role', _getTargetRoleLabel(), isBold: true),
                  const Divider(height: 14),
                  _buildSummaryRow('Kategori', _selectedCategory.toUpperCase()),
                  const Divider(height: 14),
                  if (_isAgenda) ...[
                    const Divider(height: 14),
                    _buildSummaryRow('Jadwal Agenda',
                        DateFormat('dd MMM yyyy').format(_selectedDate)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '⚠️ Mahasiswa otomatis dikecualikan dari siaran ini.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _executeBroadcast();
            },
            child: const Text('Siarkan Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? valColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _executeBroadcast() async {
    final isAdmin = ref.read(authProvider).user?.isAdminSimpeg ?? false;
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Ditolak: Anda tidak memiliki role admin_simpeg untuk mengirim broadcast.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final eventTime = _timeController.text.trim();
    final eventLocation = _locationController.text.trim();
    final eventDateStr = _isAgenda ? DateFormat('yyyy-MM-dd').format(_selectedDate) : null;
    final priorityStr = _isHighPriority ? 'high' : 'normal';

    Map<String, dynamic> apiResult;
    try {
      apiResult = await SimpegService.broadcastAnnouncement(
        title: title,
        category: _selectedCategory,
        targetRole: _targetRole,
        content: content,
        isAgenda: _isAgenda,
        eventDate: eventDateStr,
        eventTime: eventTime.isNotEmpty ? eventTime : null,
        eventLocation: eventLocation.isNotEmpty ? eventLocation : null,
        priority: priorityStr,
      );
    } catch (e) {
      apiResult = {'success': false, 'message': e.toString()};
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final success = apiResult['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.success : AppColors.error,
        content: Text(
          success
              ? 'Broadcast pengumuman berhasil dikirimkan ke server!'
              : 'Gagal mengirim broadcast: ${apiResult['message'] ?? 'server tidak mengonfirmasi pengiriman.'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );

    if (!success) return;

    // Riwayat tidak disimpan lokal; seluruh data berasal dari API.
    ref.invalidate(announcementsProvider);
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authProvider).user?.isAdminSimpeg ?? false;
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            AppHeader(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/simpeg');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Akses Dibatasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_person_rounded, size: 52, color: Color(0xFFD32F2F)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Khusus Hak Akses Admin SIMPEG',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fitur broadcast pengumuman dan pengiriman notifikasi massal hanya dapat diakses oleh staf berwenang dengan role admin_simpeg / Pengelola SDM kampus.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/simpeg');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Kembali ke Menu SIMPEG'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 1. Header Konsisten Brand Politeknik Indonusa
          AppHeader(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/modules');
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Broadcast Pengumuman & Agenda',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Admin SIMPEG — Biro Kepegawaian Kampus',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab Selector
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Buat Broadcast'),
                      Tab(text: 'Riwayat Terkirim'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Form Buat Broadcast ──
  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pesan ini akan dikirim seketika sebagai Push Notification ke smartphone pegawai target.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Section 1: Kategori Pengumuman
          _buildSectionTitle('1. KATEGORI INFORMASI'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('seragam', '👕 Seragam Kerja'),
                const SizedBox(width: 8),
                _buildCategoryChip('rapat', '📅 Undangan Rapat'),
                const SizedBox(width: 8),
                _buildCategoryChip('deadline', '⏰ Batas Waktu / BKD'),
                const SizedBox(width: 8),
                _buildCategoryChip('umum', '📢 Pengumuman Umum'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Filter Target Audiens (Role Filter)
          _buildSectionTitle('2. TARGET AUDIENS (ROLE FILTER)'),
          const SizedBox(height: 4),
          Text(
            'Pilih siapa saja yang berhak menerima pemberitahuan ini:',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 10),

          _buildRoleOption(
            key: 'all_staff',
            title: 'Semua Pegawai (Dosen & Tendik)',
            desc:
                'Dikecualikan mahasiswa. Cocok untuk seragam harian, upacara, dan pengumuman umum kampus.',
            icon: Icons.groups_rounded,
            badge: 'Semua Pegawai',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _buildRoleOption(
            key: 'dosen',
            title: 'Dosen Saja',
            desc:
                'Dosen Tetap & LB. Cocok untuk rapat prodi, tridharma, jadwal mengajar, dan pengingat BKD.',
            icon: Icons.school_rounded,
            badge: 'Dosen',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 8),
          _buildRoleOption(
            key: 'tendik',
            title: 'Tendik / Staff Saja',
            desc:
                'Staf Administrasi, TU, Lab, IT, & Keuangan. Cocok untuk jadwal piket & operasional kantor.',
            icon: Icons.badge_rounded,
            badge: 'Tendik',
            color: const Color(0xFF0284C7),
          ),

          const SizedBox(height: 20),

          // Section 3: Konten Informasi
          _buildSectionTitle('3. ISI PENGUMUMAN'),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Judul Pengumuman / Agenda *',
                    hintText: 'Contoh: Seragam Batik Hari Rabu',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contentController,
                  onChanged: (_) => setState(() {}),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detail Pesan / Edaran *',
                    hintText:
                        'Tuliskan instruksi atau ringkasan pengumuman di sini...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 4: Fitur Agenda / Rapat (Opsional)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_available_rounded,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Sertakan Jadwal Agenda / Rapat',
                          style: AppTextStyles.titleMedium
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isAgenda,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isAgenda = val),
                    ),
                  ],
                ),
                if (_isAgenda) ...[
                  const Divider(height: 20),
                  // Tanggal
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                _formatIndonesianDate(_selectedDate),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Text('Ganti',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Jam & Tempat
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _timeController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Jam / Waktu',
                            hintText: '09:00 - 11:30 WIB',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Lokasi / Ruang',
                            hintText: 'Ruang Rapat Lt. 2',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Switch Prioritas Tinggi (Urgent / Penting)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notification_important_rounded,
                        color: _isHighPriority ? AppColors.error : AppColors.textSecondary,
                        size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tandai Prioritas Tinggi (Urgent)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Pesan disorot khusus dengan warna merah mencolok',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _isHighPriority,
                  activeThumbColor: AppColors.error,
                  onChanged: (val) => setState(() => _isHighPriority = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live Preview Card: Tampilan di Ponsel Pegawai
          _buildSectionTitle('PRATINJAU PADA PONSEL PEGAWAI'),
          const SizedBox(height: 8),
          _buildLiveNotificationPreview(),

          const SizedBox(height: 24),

          // Tombol Kirim Broadcast
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isSubmitting ? null : _confirmAndBroadcast,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _isSubmitting
                    ? 'Sedang Menyiarkan...'
                    : 'Kirim Broadcast',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Riwayat Broadcast (data dari API SIMPEG RAG) ──
  Widget _buildHistoryTab() {
    final announcementsAsync = ref.watch(announcementsProvider);

    return announcementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 44, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat riwayat pengumuman: $error',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(announcementsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('Belum ada pengumuman dari server.'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(announcementsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final item = items[idx];
              final cat = item.category;
              final color = _getCategoryColor(cat);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 0.8),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getCategoryIcon(cat),
                                  color: color, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cat.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.createdAt,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.content,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary, height: 1.35),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Target: ${item.targetRole}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        if (item.recipientsCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.recipientsCount} Penerima',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    final color = _getCategoryColor(key);

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: color,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
        width: 1,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedCategory = key);
      },
    );
  }

  Widget _buildRoleOption({
    required String key,
    required String title,
    required String desc,
    required IconData icon,
    required String badge,
    required Color color,
  }) {
    final isSelected = _targetRole == key;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _targetRole = key),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.8 : 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isSelected ? color : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveNotificationPreview() {
    final title = _titleController.text.trim().isEmpty
        ? 'Judul Pengumuman Kampus'
        : _titleController.text.trim();
    final body = _contentController.text.trim().isEmpty
        ? 'Ringkasan edaran atau instruksi resmi akan tampil di sini...'
        : _contentController.text.trim();
    final color = _getCategoryColor(_selectedCategory);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getCategoryIcon(_selectedCategory),
                    color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SIMPEG • PENGUMUMAN RESMI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const Text(
                          'Baru saja',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          if (_isAgenda) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 35),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_note_rounded, size: 13, color: color),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(_selectedDate)} • ${_timeController.text.isNotEmpty ? _timeController.text : "Waktu Rapat"}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
