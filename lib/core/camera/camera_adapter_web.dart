import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'camera_adapter.dart';

CameraAdapter getCameraAdapterInstance() => WebCameraAdapter();

class WebCameraAdapter implements CameraAdapter {
  web.HTMLVideoElement? _videoElement;
  web.MediaStream? _stream;
  bool _isReady = false;
  String? _errorMessage;
  static int _viewIdCounter = 0;
  late final String _viewType;

  WebCameraAdapter() {
    // ignore: avoid_print
    print('[CameraAdapter] >>> WebCameraAdapter instantiated! <<<');
    _viewType = 'web-camera-view-${_viewIdCounter++}';

    _videoElement =
        web.document.createElement('video') as web.HTMLVideoElement;
    _videoElement!
      ..autoplay = true
      ..muted = true
      ..playsInline = true;
    _videoElement!.style.width = '100%';
    _videoElement!.style.height = '100%';
    _videoElement!.style.objectFit = 'cover';
    _videoElement!.style.transform = 'scaleX(-1)';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int id) => _videoElement!,
    );
  }

  @override
  bool get isReady => _isReady;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<bool> initialize() async {
    try {
      final mediaDevices = web.window.navigator.mediaDevices;

      final constraints = web.MediaStreamConstraints(
        video: true.toJS,
        audio: false.toJS,
      );

      final jsPromise = mediaDevices.getUserMedia(constraints);
      final stream = await jsPromise.toDart;
      _stream = stream;
      _videoElement!.srcObject = stream;

      try {
        await _videoElement!.play().toDart;
      } catch (playErr) {
        // play() error can occur if browser requires user gesture; autoplay will trigger on DOM mount
        // ignore: avoid_print
        print('[WebCameraAdapter] play() info: $playErr');
      }

      _isReady = true;
      _errorMessage = null;
      return true;
    } catch (e, stack) {
      // ignore: avoid_print
      print('[WebCameraAdapter] Exception during initialize: $e');
      // ignore: avoid_print
      print('[WebCameraAdapter] Stack: $stack');
      _errorMessage =
          'Izin kamera belum aktif atau kamera sedang digunakan aplikasi lain.';
      _isReady = false;
      return false;
    }
  }

  @override
  Widget buildPreview() {
    if (_isReady) {
      return HtmlElementView(viewType: _viewType);
    }
    return const SizedBox.shrink();
  }

  @override
  Future<String?> takePictureBase64() async {
    if (_videoElement == null || !_isReady) return null;
    final w = _videoElement!.videoWidth;
    final h = _videoElement!.videoHeight;
    final targetW = w > 0 ? w : 640;
    final targetH = h > 0 ? h : 480;

    final canvas =
        web.document.createElement('canvas') as web.HTMLCanvasElement;
    canvas.width = targetW;
    canvas.height = targetH;

    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    ctx.translate(targetW.toDouble(), 0);
    ctx.scale(-1, 1);
    ctx.drawImage(_videoElement!, 0, 0);

    final dataUrl = canvas.toDataURL('image/jpeg', 0.9.toJS);
    if (dataUrl.contains(',')) {
      return dataUrl.split(',').last;
    }
    return dataUrl;
  }

  @override
  Future<void> dispose() async {
    if (_stream != null) {
      final tracks = _stream!.getTracks().toDart;
      for (var i = 0; i < tracks.length; i++) {
        tracks[i].stop();
      }
      _stream = null;
    }
    _isReady = false;
  }
}
