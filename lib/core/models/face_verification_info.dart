/// Informasi verifikasi wajah yang berasal dari server RAG.
///
/// Aplikasi tidak menentukan batas kemiripan sendiri. Nilai skor dan batas
/// minimal diambil dari payload API (field khusus atau teks `rejection_reason`).
class FaceVerificationInfo {
  final double? score;
  final double? minimum;
  final String? message;
  final String? source;
  final String? updatedAt;

  const FaceVerificationInfo({
    this.score,
    this.minimum,
    this.message,
    this.source,
    this.updatedAt,
  });

  bool get hasData => score != null || minimum != null;

  bool get isBelowMinimum =>
      score != null && minimum != null && score! < minimum!;

  /// Parsing dari envelope API. Mencoba field eksplisit lebih dulu, lalu
  /// teks penolakan yang dikirim backend (contoh: "Skor kemiripan: 0.5026,
  /// batas minimal 0.68").
  factory FaceVerificationInfo.fromJson(Map<String, dynamic> json) {
    final nested = json['face_verification'] is Map
        ? Map<String, dynamic>.from(json['face_verification'] as Map)
        : const <String, dynamic>{};
    final source = <String, dynamic>{...nested, ...json};

    final message = _firstText(source, const [
      'rejection_reason',
      'face_verification_message',
      'verification_message',
      'catatan',
      'notes',
    ]);

    final score = _firstNumber(source, const [
      'face_score',
      'face_similarity',
      'similarity_score',
      'clock_in_face_score',
      'clock_out_face_score',
    ]) ?? _numberAfter(message, const ['skor kemiripan', 'similarity', 'skor']);

    final minimum = _firstNumber(source, const [
      'minimum_face_similarity',
      'min_face_similarity',
      'face_similarity_threshold',
      'similarity_threshold',
      'face_threshold',
      'min_similarity',
      'batas_minimal_kemiripan',
    ]) ?? _numberAfter(message, const ['batas minimal', 'minimum', 'minimal']);

    final info = FaceVerificationInfo(
      score: score,
      minimum: minimum,
      message: message,
      source: _firstText(source, const ['source']),
      updatedAt: _firstText(source, const ['updated_at']),
    );
    return info.hasData ? info : const FaceVerificationInfo();
  }

  factory FaceVerificationInfo.fromMessage(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const FaceVerificationInfo();
    }
    return FaceVerificationInfo(
      score: _numberAfter(text, const ['skor kemiripan', 'similarity', 'skor']),
      minimum: _numberAfter(text, const ['batas minimal', 'minimum', 'minimal']),
      message: text,
    );
  }

  static String? _firstText(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static double? _firstNumber(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return _normalize(value.toDouble());
      if (value is String) {
        final parsed = _parseNumber(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _parseNumber(String value) {
    final cleaned = value
        .replaceAll('%', '')
        .replaceAll(RegExp(r'[^\d.,-]'), '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  /// Nilai di bawah 1 dipakai apa adanya (0.68). Nilai lebih besar dari 1
  /// dianggap persentase (68 atau 80) sehingga dinormalkan jadi 0.68/0.80.
  static double _normalize(double value) => value > 1 ? value / 100 : value;

  static double? _numberAfter(String? text, List<String> labels) {
    if (text == null || text.isEmpty) return null;
    final lower = text.toLowerCase();
    for (final label in labels) {
      final index = lower.indexOf(label);
      if (index == -1) continue;
      final tail = text.substring(index + label.length);
      final match = RegExp(r'[:]?\s*(\d+(?:[.,]\d+)?)').firstMatch(tail);
      if (match != null) {
        final parsed = _parseNumber(match.group(1) ?? '');
        if (parsed != null) return _normalize(parsed);
      }
    }
    return null;
  }

  /// Format persentase untuk ditampilkan, tanpa mengubah angka asli server.
  static String formatPercent(double? value) {
    if (value == null) return '-';
    final normalized = _normalize(value) * 100;
    final digits = normalized == normalized.roundToDouble() ? 0 : 2;
    return '${normalized.toStringAsFixed(digits).replaceAll('.', ',')}%';
  }
}

/// Batas kemiripan wajah aktif yang dikirim server RAG.
///
/// Mobile tidak menentukan nilai sendiri. Field [source] memberi tahu apakah
/// nilai berasal dari pengaturan web yang tersimpan (`database`) atau fallback
/// environment server (`environment`).
class FaceSimilaritySettings {
  final double minimum;
  final String source;
  final String? updatedAt;

  const FaceSimilaritySettings({
    required this.minimum,
    this.source = 'unknown',
    this.updatedAt,
  });

  bool get isSavedFromWeb => source == 'database';

  factory FaceSimilaritySettings.fromJson(Map<String, dynamic> json) {
    final nested = json['face_similarity_settings'] is Map
        ? Map<String, dynamic>.from(json['face_similarity_settings'] as Map)
        : const <String, dynamic>{};
    final source = <String, dynamic>{...nested, ...json};

    final minimum = FaceVerificationInfo._firstNumber(source, const [
          'minimum_face_similarity',
          'face_score_threshold',
          'min_face_similarity',
          'face_similarity_threshold',
          'similarity_threshold',
          'face_threshold',
          'min_similarity',
        ]) ??
        FaceVerificationInfo.fromJson(source).minimum;

    if (minimum == null) {
      throw const FormatException('Server tidak mengirim batas kemiripan wajah');
    }

    return FaceSimilaritySettings(
      minimum: minimum,
      source: source['source']?.toString() ?? 'unknown',
      updatedAt: source['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'minimum_face_similarity': minimum,
        'face_score_threshold': minimum,
        'source': source,
        'updated_at': updatedAt,
      };
}
