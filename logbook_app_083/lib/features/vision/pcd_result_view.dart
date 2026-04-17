import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class PcdResultView extends StatefulWidget {
  final XFile capturedFile;
  const PcdResultView({super.key, required this.capturedFile});

  @override
  State<PcdResultView> createState() => _PcdResultViewState();
}

class _PcdResultViewState extends State<PcdResultView> {
  Uint8List? _processedImageBytes;
  late cv.Mat _originalMat;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.capturedFile.readAsBytes();
      _originalMat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      _updateImage(_originalMat);
    } catch (e) {
      debugPrint("Gagal load image PCD: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateImage(cv.Mat mat) {
    try {
      final encoded = cv.imencode(".jpg", mat);
      setState(() {
        _processedImageBytes = encoded.$2;
      });
    } catch (e) {
      debugPrint("PCD Encode Error: $e");
    }
  }

  void _reset() {
    _updateImage(_originalMat);
  }

  void _applyContrast() {
    try {
      final dst = cv.convertScaleAbs(_originalMat, alpha: 1.5, beta: 20.0);
      _updateImage(dst);
    } catch (e) {
      debugPrint("Contrast Error: $e");
    }
  }

  void _applyHistogram() {
    try {
      final gray = cv.cvtColor(_originalMat, cv.COLOR_BGR2GRAY);
      final dst = cv.equalizeHist(gray);
      _updateImage(dst);
    } catch (e) {
      debugPrint("Histogram Error: $e");
    }
  }

  void _applyConvolution() {
    try {
      final dst = cv.canny(_originalMat, 100, 200);
      _updateImage(dst);
    } catch (e) {
      debugPrint("Convolution Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasil Manipulasi PCD"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    maxScale: 5.0,
                    child: _processedImageBytes != null
                        ? Image.memory(_processedImageBytes!)
                        : const Center(child: Text("Gagal merender gambar.")),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Menu Fitur Pengolahan Citra Digital",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[50]),
                              onPressed: _applyContrast, 
                              child: const Text("Kontras")
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: ElevatedButton(
                               style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[50]),
                              onPressed: _applyHistogram, 
                              child: const Text("Histogram")
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: ElevatedButton(
                               style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[50]),
                              onPressed: _applyConvolution, 
                              child: const Text("Konvolusi")
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: _reset, 
                              child: const Text("Reset")
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
