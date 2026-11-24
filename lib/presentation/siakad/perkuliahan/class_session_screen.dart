import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/models/pertemuan_model.dart';
import '../../../core/services/academic_service.dart';
import '../../../core/theme/app_colors.dart';

class ClassSessionScreen extends StatefulWidget {
  final int pertemuanId;
  const ClassSessionScreen({super.key, required this.pertemuanId});

  @override
  State<ClassSessionScreen> createState() => _ClassSessionScreenState();
}

class _ClassSessionScreenState extends State<ClassSessionScreen> {
  bool _isLoading = true;
  PertemuanItem? _pertemuan;
  List<PresensiMahasiswaItem> _students = [];
  String _searchQuery = '';
  String? _error;
  bool _isSaving = false;

  // Dynamic Rotating Token (Anti Titip-Hadir)
  Timer? _rotateTimer;
  int _secondsLeft = 30;
  int _rotateIntervalSeconds = 30;
  bool _isRotating = false;
  String? _currentToken;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    super.dispose();
  }

  /// Token yang boleh ditampilkan/scan hanya saat sesi masih berlangsung.
  String _liveToken() {
    if (_pertemuan?.status != 'berlangsung') return '';
    return _currentToken ?? _pertemuan?.tokenAbsensi ?? '';
  }

  void _startRotateTimer() {
    _rotateTimer?.cancel();
    _secondsLeft = _rotateIntervalSeconds;

    if (_pertemuan?.status != 'berlangsung') return;

    _rotateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _rotateToken(auto: true);
      }
    });
  }

  Future<void> _rotateToken({bool auto = false}) async {
    if (_isRotating) return;
    if (_pertemuan?.status != 'berlangsung') return;

    setState(() {
      _isRotating = true;
    });

    String? errorMessage;
    try {
      final res = await AcademicService.rotateTokenPertemuan(widget.pertemuanId);
      final serverInterval = int.tryParse(res['rotate_interval_seconds']?.toString() ?? '');
      if (serverInterval != null && serverInterval >= 10) {
        _rotateIntervalSeconds = serverInterval;
      }
      final newToken = res['token_absensi']?.toString() ?? res['token']?.toString();
      if (newToken == null || newToken.isEmpty) {
        errorMessage = 'Server tidak mengirimkan token absensi baru.';
      } else if (mounted) {
        setState(() {
          _currentToken = newToken;
          if (_pertemuan != null) {
            _pertemuan = PertemuanItem(
              id: _pertemuan!.id,
              pertemuanKe: _pertemuan!.pertemuanKe,
              tanggal: _pertemuan!.tanggal,
              materi: _pertemuan!.materi,
              catatan: _pertemuan!.catatan,
              status: _pertemuan!.status,
              tokenAbsensi: newToken,
              jamMulai: _pertemuan!.jamMulai,
            );
          }
        });
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    if (mounted) {
      setState(() {
        _secondsLeft = _rotateIntervalSeconds;
        _isRotating = false;
      });
      if (errorMessage != null) {
        // Kegagalan rotasi otomatis juga wajib terlihat: QR diam di layar
        // tetapi sudah ditolak server saat mahasiswa scan.
        final message = auto
            ? 'Gagal memperbarui token otomatis: $errorMessage'
            : errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadSessionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await AcademicService.fetchPresensiPertemuan(widget.pertemuanId);
      if (mounted) {
        setState(() {
          _pertemuan = res['pertemuan'] as PertemuanItem?;
          _students = (res['mahasiswa'] as List<PresensiMahasiswaItem>?) ?? [];
          _currentToken = _pertemuan?.tokenAbsensi;
          _isLoading = false;
        });
        if (_pertemuan?.status == 'berlangsung') {
          _startRotateTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat sesi perkuliahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStudentStatus(PresensiMahasiswaItem student, String newStatus) async {
    final oldStatus = student.status;
    setState(() {
      student.status = newStatus;
    });

    final success = await AcademicService.updatePresensiMahasiswa(
      pertemuanId: widget.pertemuanId,
      items: [student],
    );

    if (!success && mounted) {
      setState(() {
        student.status = oldStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan perubahan presensi.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _finishSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Selesaikan Perkuliahan?'),
        content: Text(
          'Sesi Pertemuan ${_pertemuan?.pertemuanKe ?? ''} akan ditutup dan presensi mahasiswa akan dikunci.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    String? errorMessage;
    try {
      await AcademicService.selesaiSesiPertemuan(widget.pertemuanId);
    } catch (e) {
      errorMessage = e.toString();
    }
    if (mounted) setState(() => _isSaving = false);

    // Hentikan countdown segera setelah server mengonfirmasi penutupan sesi.
    if (errorMessage == null) {
      _rotateTimer?.cancel();
    }

    if (mounted) {
      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Perkuliahan Pertemuan ${_pertemuan?.pertemuanKe ?? ''} berhasil diselesaikan!'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
        _loadSessionData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showQrModal() {
    final tokenSaatIni = _liveToken();
    if (tokenSaatIni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token presensi belum tersedia dari server.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    // QR dirender lokal. Payload tetap berasal dari token API RAG dan tidak
    // dikirim ke layanan generator QR pihak ketiga.
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QR Presensi Mahasiswa',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // QR Container
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: _LiveQrCode(
                      pertemuanId: widget.pertemuanId,
                      tokenProvider: _liveToken,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Token Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'KODE TOKEN PRESENSI',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        _LiveTokenLabel(tokenProvider: _liveToken),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Token & QR berganti dinamis setiap $_rotateIntervalSeconds detik untuk mencegah titip-hadir mahasiswa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAllStudentsPresent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tandai Semua Hadir?'),
        content: Text('Semua (${_students.length}) mahasiswa pada pertemuan ini akan ditandai dengan status Hadir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Semua Hadir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final previousStatuses = {
      for (final m in _students) m.mahasiswaId: m.status,
    };
    setState(() {
      for (final m in _students) {
        m.status = 'hadir';
      }
    });

    final success = await AcademicService.setAllStudentsStatus(
      pertemuanId: widget.pertemuanId,
      students: _students,
      status: 'hadir',
    );

    if (!success && mounted) {
      setState(() {
        for (final m in _students) {
          m.status = previousStatuses[m.mahasiswaId] ?? m.status;
        }
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Semua mahasiswa berhasil ditandai Hadir.' : 'Gagal menyimpan presensi semua mahasiswa.'),
          backgroundColor: success ? const Color(0xFF16A34A) : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.nama.toLowerCase().contains(q) || m.nim.toLowerCase().contains(q);
    }).toList();

    final totalHadir = _students.where((m) => m.status == 'hadir').length;
    final totalIzin = _students.where((m) => m.status == 'izin').length;
    final totalSakit = _students.where((m) => m.status == 'sakit').length;
    final totalAlfa = _students.where((m) => m.status == 'alfa').length;

    final isOngoing = _pertemuan?.status == 'berlangsung';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _pertemuan != null
              ? 'Sesi Pertemuan ${_pertemuan!.pertemuanKe}'
              : 'Presensi Sesi Kuliah',
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
            onPressed: _loadSessionData,
          ),
        ],
      ),
      bottomNavigationBar: _pertemuan != null && isOngoing
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _finishSession,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.stop_circle_outlined, size: 20),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Selesaikan Perkuliahan',
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
              ),
            )
          : null,
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
                          onPressed: _loadSessionData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Token Presensi & QR Card (jika sedang berlangsung)
                    if (isOngoing && (_currentToken != null || _pertemuan?.tokenAbsensi != null))
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOKEN PRESENSI MAHASISWA',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_secondsLeft d',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Baris Token & Tombol Refresh
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _currentToken ?? _pertemuan!.tokenAbsensi!,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryDark,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: _isRotating ? null : () => _rotateToken(auto: false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isRotating
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.refresh_rounded,
                                            color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Countdown Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _secondsLeft / _rotateIntervalSeconds,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Tombol Buka Layar QR Code
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showQrModal,
                                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                label: const Text('Buka QR Code Layar Penuh',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Pertemuan Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Materi Perkuliahan',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _pertemuan?.statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _pertemuan?.statusLabel ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _pertemuan?.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _pertemuan?.materi ?? '-',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_pertemuan?.catatan != null &&
                              _pertemuan!.catatan!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Catatan: ${_pertemuan!.catatan}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                _pertemuan?.tanggal ?? 'Hari ini',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                              if (_pertemuan?.jamMulai != null) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.access_time_rounded,
                                    size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  'Mulai: ${_pertemuan!.jamMulai}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rekap Kehadiran Counters
                    Row(
                      children: [
                        _buildCounterBox('Hadir', totalHadir, const Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        _buildCounterBox('Izin', totalIzin, const Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        _buildCounterBox('Sakit', totalSakit, const Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        _buildCounterBox('Alfa', totalAlfa, const Color(0xFFDC2626)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Header Presensi Mahasiswa & Aksi Manual Cepat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Mahasiswa (${_students.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isOngoing)
                          TextButton.icon(
                            onPressed: _markAllStudentsPresent,
                            icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF16A34A)),
                            label: const Text(
                              'Semua Hadir',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Search box
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau NIM mahasiswa...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),

                    const SizedBox(height: 12),

                    // Student list
                    ...filtered.map((m) => _buildStudentCard(m)),
                  ],
                ),
    );
  }

  Widget _buildCounterBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(PresensiMahasiswaItem m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar circle
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              m.nama.isNotEmpty ? m.nama[0].toUpperCase() : 'M',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name and NIM
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nama,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  m.nim,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Toggle status buttons (Hadir, Izin, Sakit, Alfa)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusToggleBtn(m, 'hadir', 'H', const Color(0xFF16A34A)),
              const SizedBox(width: 4),
              _buildStatusToggleBtn(m, 'izin', 'I', const Color(0xFF2563EB)),
              const SizedBox(width: 4),
              _buildStatusToggleBtn(m, 'sakit', 'S', const Color(0xFFD97706)),
              const SizedBox(width: 4),
              _buildStatusToggleBtn(m, 'alfa', 'A', const Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggleBtn(
      PresensiMahasiswaItem m, String statusVal, String shortLabel, Color color) {
    final isSelected = m.status == statusVal;

    return InkWell(
      onTap: () => _updateStudentStatus(m, statusVal),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          shortLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

/// QR presensi yang dibangkitkan sepenuhnya di perangkat.
/// Token diambil langsung dari state sesi API RAG dan diperbarui saat token
/// berputar, tanpa memuat gambar dari layanan eksternal.
class _LiveQrCode extends StatefulWidget {
  final int pertemuanId;
  final String Function() tokenProvider;

  const _LiveQrCode({
    required this.pertemuanId,
    required this.tokenProvider,
  });

  @override
  State<_LiveQrCode> createState() => _LiveQrCodeState();
}

class _LiveQrCodeState extends State<_LiveQrCode> {
  Timer? _timer;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _token = widget.tokenProvider();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final token = widget.tokenProvider();
      if (mounted && token != _token) {
        setState(() => _token = token);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_token.isEmpty) {
      return const Center(
        child: Text(
          'Token presensi belum tersedia dari server.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    return QrImageView(
      data: 'RAG-PRESENSI:${widget.pertemuanId}:$_token',
      version: QrVersions.auto,
      size: 196,
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }
}

/// Angka token ikut mengikuti rotasi, sehingga tidak lagi berbeda dengan QR.
class _LiveTokenLabel extends StatefulWidget {
  final String Function() tokenProvider;

  const _LiveTokenLabel({required this.tokenProvider});

  @override
  State<_LiveTokenLabel> createState() => _LiveTokenLabelState();
}

class _LiveTokenLabelState extends State<_LiveTokenLabel> {
  Timer? _timer;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _token = widget.tokenProvider();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final token = widget.tokenProvider();
      if (mounted && token != _token) {
        setState(() => _token = token);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_token.isEmpty) {
      return const Text(
        'Sesi ditutup',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      );
    }

    return Text(
      _token,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.primaryDark),
    );
  }
}
