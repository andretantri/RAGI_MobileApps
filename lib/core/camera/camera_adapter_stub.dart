import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'camera_adapter.dart';

CameraAdapter getCameraAdapterInstance() => NativeCameraAdapter();

class NativeCameraAdapter implements CameraAdapter {
  NativeCameraAdapter() {
    // ignore: avoid_print
    print('[CameraAdapter] >>> NativeCameraAdapter instantiated! <<<');
  }
  CameraController? _controller;
  bool _isReady = false;
  String? _errorMessage;

  @override
  bool get isReady => _isReady;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'Tidak ada perangkat kamera yang terdeteksi.';
        _isReady = false;
        return false;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isReady = true;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage =
          'Izin kamera belum aktif atau kamera sedang digunakan aplikasi lain.';
      _isReady = false;
      return false;
    }
  }

  @override
  Widget buildPreview() {
    if (_controller != null && _isReady) {
      // Preview harus mengisi layar agar tidak tampil sebagai kotak kecil
      // di tengah halaman saat kamera langsung dinyalakan.
      return SizedBox.expand(child: CameraPreview(_controller!));
    }
    return const SizedBox.shrink();
  }

  @override
  Future<String?> takePictureBase64() async {
    if (_controller == null || !_isReady) return null;
    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isReady = false;
  }
}
