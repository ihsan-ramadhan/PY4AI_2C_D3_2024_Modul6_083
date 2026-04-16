import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  String? errorMessage;
  bool isFlashlightOn = false;

  VisionController() {
    // Mendaftarkan observer agar bisa memantau status aplikasi (Lifecycle)
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied || status.isDenied) {
        errorMessage = "No Camera Access";
        notifyListeners();
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = "No camera detected on device.";
        notifyListeners();
        return;
      }

      // Memilih Kamera Belakang (Index 0)
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium, // Keseimbangan antara akurasi AI & performa
        enableAudio: false,      // Kita hanya butuh visual untuk deteksi jalan
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Failed to initialize camera: $e";
    }
    notifyListeners();
  }

  Future<void> toggleFlashlight() async {
    if (controller == null || !controller!.value.isInitialized) return;
    
    try {
      if (isFlashlightOn) {
        await controller!.setFlashMode(FlashMode.off);
        isFlashlightOn = false;
      } else {
        await controller!.setFlashMode(FlashMode.torch);
        isFlashlightOn = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Flashlight toggle error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final CameraController? cameraController = controller;

    // Jika controller belum ada atau belum siap, abaikan
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Melepaskan resource kamera saat aplikasi tidak terlihat
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      // Menginisialisasi ulang saat pengguna kembali ke aplikasi
      initCamera();
    }
  }

  @override
  void dispose() {
    // Menghapus observer agar tidak terjadi memory leak
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }
}
