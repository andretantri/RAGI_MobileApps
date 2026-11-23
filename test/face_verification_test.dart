import 'package:flutter_test/flutter_test.dart';
import 'package:myinu_staff/core/models/face_verification_info.dart';

void main() {
  group('FaceVerificationInfo', () {
    test('membaca skor dan batas minimal dari pesan server RAG', () {
      const rejection =
          'Presensi masuk ditolak: Wajah tidak cocok (Skor kemiripan: 0.5026, batas minimal 0.68).';

      final info = FaceVerificationInfo.fromMessage(rejection);

      expect(info.score, 0.5026);
      expect(info.minimum, 0.68);
      expect(info.isBelowMinimum, isTrue);
      expect(FaceVerificationInfo.formatPercent(info.score), '50,26%');
      expect(FaceVerificationInfo.formatPercent(info.minimum), '68%');
    });

    test('menerima nilai persentase dari server', () {
      final info = FaceVerificationInfo.fromJson({
        'face_score': 80,
        'face_similarity_threshold': 85,
        'rejection_reason': 'Skor kemiripan: 80%, batas minimal 85%.',
      });

      expect(info.score, 0.8);
      expect(info.minimum, 0.85);
      expect(info.isBelowMinimum, isTrue);
    });

    test('tidak mengarang nilai bila server tidak mengirim data', () {
      final info = FaceVerificationInfo.fromJson({'status': 'hadir'});

      expect(info.hasData, isFalse);
      expect(info.score, isNull);
      expect(info.minimum, isNull);
    });
  });
}
