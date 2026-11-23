import 'package:flutter_test/flutter_test.dart';
import 'package:myinu_staff/core/models/face_verification_info.dart';

void main() {
  group('Batas kemiripan wajah dari server', () {
    test('membaca payload endpoint pengaturan mobile', () {
      final settings = FaceSimilaritySettings.fromJson({
        'face_score_threshold': 0.72,
        'minimum_face_similarity': 0.72,
        'source': 'database',
        'updated_at': '2026-11-23T08:00:00+07:00',
      });

      expect(settings.minimum, 0.72);
      expect(settings.source, 'database');
      expect(settings.isSavedFromWeb, isTrue);
    });

    test('fallback ke payload today bila endpoint settings belum ada', () {
      final info = FaceVerificationInfo.fromJson({
        'minimum_face_similarity': 0.68,
        'source': 'environment',
        'rejection_reason': 'Skor kemiripan: 0.5026, batas minimal 0.68',
      });

      expect(info.score, 0.5026);
      expect(info.minimum, 0.68);
      expect(info.source, 'environment');
      expect(info.isBelowMinimum, isTrue);
    });

    test('tidak membuat batas rekaan saat server tidak mengirim nilai', () {
      expect(
        () => FaceSimilaritySettings.fromJson({'status': 'success'}),
        throwsA(isA<FormatException>()),
      );
      expect(FaceVerificationInfo.fromJson({}).hasData, isFalse);
    });
  });
}
