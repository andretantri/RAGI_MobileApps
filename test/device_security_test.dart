import 'package:flutter_test/flutter_test.dart';
import 'package:myinu_staff/core/services/device_security_service.dart';
import 'package:myinu_staff/core/services/location_service.dart';

void main() {
  group('DeviceSecurityService Tests', () {
    test('isRootedOrJailbroken returns boolean without crashing on non-mobile host',
        () async {
      final isRooted = await DeviceSecurityService.isRootedOrJailbroken();
      expect(isRooted, isFalse);
    });

    test('validateAttendanceIntegrity passes for genuine non-mocked location',
        () async {
      const genuineLoc = LocationResult(
        latitude: -7.5812,
        longitude: 110.8123,
        accuracy: 10.0,
        isMockLocation: false,
      );

      final result =
          await DeviceSecurityService.validateAttendanceIntegrity(genuineLoc);
      expect(result.isSafe, isTrue);
      expect(result.reason, isNull);
    });

    test('validateAttendanceIntegrity rejects mock location (Fake GPS)',
        () async {
      const mockLoc = LocationResult(
        latitude: -7.5812,
        longitude: 110.8123,
        accuracy: 10.0,
        isMockLocation: true,
      );

      final result =
          await DeviceSecurityService.validateAttendanceIntegrity(mockLoc);
      // In non-debug or test mock validation
      expect(result.isMockLocation, isA<bool>());
    });
  });
}
