import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const _tokenKey = 'auth_token';
  static const _userDataKey = 'user_data';
  static const _employeeDataKey = 'employee_data';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  static Future<void> saveUserData(String json) =>
      _storage.write(key: _userDataKey, value: json);
  static Future<String?> getUserData() => _storage.read(key: _userDataKey);
  static Future<void> deleteUserData() =>
      _storage.delete(key: _userDataKey);

  static Future<void> saveEmployeeData(String json) =>
      _storage.write(key: _employeeDataKey, value: json);
  static Future<String?> getEmployeeData() =>
      _storage.read(key: _employeeDataKey);
  static Future<void> deleteEmployeeData() =>
      _storage.delete(key: _employeeDataKey);

  static Future<void> clearAll() => _storage.deleteAll();
}
