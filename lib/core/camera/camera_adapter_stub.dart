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
    final controller = _controller;
    if (controller == null || !_isReady || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // Kamera preview harus proporsional tanpa distorsi (tidak gepeng)
    // dan menutupi seluruh layar (BoxFit.cover).
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        if (screenWidth <= 0 || screenHeight <= 0) return const SizedBox.shrink();

        final screenAspect = screenWidth / screenHeight;
        final rawAspect = controller.value.aspectRatio;
        // Di orientasi portrait, rasio kamera (lebar / tinggi) selalu < 1.0 (misal 9/16 = 0.5625 atau 3/4 = 0.75)
        final cameraAspect = rawAspect > 1.0 ? (1.0 / rawAspect) : rawAspect;

        // Skala seragam (uniform scale) agar preview menutupi seluruh layar
        // tanpa mengubah rasio aspek kamera.
        final double scale;
        if (screenAspect < cameraAspect) {
          scale = screenHeight / (screenWidth / cameraAspect);
        } else {
          scale = screenWidth / (screenHeight * cameraAspect);
        }

        return ClipRect(
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: AspectRatio(
                aspectRatio: cameraAspect,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
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
