import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'pcd_result_view.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;
  Timer? _mockTimer;
  bool _showOverlay = true;

  double _mockRawX = 0.5;
  double _mockRawY = 0.5;
  double _mockQuality = 0.92;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();

    _mockTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          final random = Random();
          _mockRawX = 0.1 + random.nextDouble() * 0.8;
          _mockRawY = 0.1 + random.nextDouble() * 0.8;
          _mockQuality = 0.5 + random.nextDouble() * 0.49;
        });
      }
    });
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _visionController.dispose();
    super.dispose();
  }

  Widget _buildVisionStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1 / _visionController.controller!.value.aspectRatio,
            child: CameraPreview(_visionController.controller!),
          ),
        ),

        if (_showOverlay)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(
                rawX: _mockRawX,
                rawY: _mockRawY,
                qualityScore: _mockQuality,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart-Patrol Vision"),
        actions: [
          Row(
            children: [
              const Text("Overlay", style: TextStyle(fontSize: 12)),
              Switch(
                value: _showOverlay,
                activeColor: Colors.redAccent,
                onChanged: (val) {
                  setState(() {
                    _showOverlay = val;
                  });
                },
              ),
            ],
          ),
          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) {
              return IconButton(
                icon: Icon(
                  _visionController.isFlashlightOn
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () {
                  _visionController.toggleFlashlight();
                },
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (_visionController.errorMessage == "No Camera Access") {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Akses Kamera Ditolak"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    child: const Text("Buka Settings"),
                  ),
                ],
              ),
            );
          }
          if (!_visionController.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke Sensor Visual..."),
                ],
              ),
            );
          }
          return _buildVisionStack();
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _visionController,
        builder: (context, _) {
          if (!_visionController.isInitialized || _visionController.errorMessage != null) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () async {
              if (_visionController.controller != null && _visionController.controller!.value.isInitialized) {
                try {
                  final xfile = await _visionController.controller!.takePicture();
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PcdResultView(capturedFile: xfile),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Gagal mengambil gambar: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal mengambil gambar")),
                  );
                }
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text("Capture Frame"),
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
