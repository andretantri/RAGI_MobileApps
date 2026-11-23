import 'package:flutter/widgets.dart';

import 'camera_adapter_stub.dart'
    if (dart.library.html) 'camera_adapter_web.dart'
    if (dart.library.js_interop) 'camera_adapter_web.dart';

abstract class CameraAdapter {
  bool get isReady;
  String? get errorMessage;
  Future<bool> initialize();
  Widget buildPreview();
  Future<String?> takePictureBase64();
  Future<void> dispose();
}

CameraAdapter createCameraAdapter() => getCameraAdapterInstance();
