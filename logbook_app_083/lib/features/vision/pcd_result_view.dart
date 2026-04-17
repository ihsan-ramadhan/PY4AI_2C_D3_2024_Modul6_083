import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'dart:math';

enum PcdMode { histogram, contrast, convolution, conversion, median }

class PcdResultView extends StatefulWidget {
  final XFile capturedFile;
  const PcdResultView({super.key, required this.capturedFile});

  @override
  State<PcdResultView> createState() => _PcdResultViewState();
}

class _PcdResultViewState extends State<PcdResultView> {
  Uint8List? _processedImageBytes;
  late cv.Mat _originalMat;
  late cv.Mat _currentMat;
  bool _isLoading = true;
  
  PcdMode _currentMode = PcdMode.histogram;
  
  double _contrastValue = 1.0;
  List<int> _histogramData = [];

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.capturedFile.readAsBytes();
      _originalMat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      _currentMat = _originalMat.clone();
      _updateImage(_currentMat);
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
      _calculateLiveHistogram(mat);
    } catch (e) {
      debugPrint("PCD Encode Error: $e");
    }
  }

  void _reset() {
    _currentMat = _originalMat.clone();
    _contrastValue = 1.0;
    _updateImage(_currentMat);
  }

  void _calculateLiveHistogram(cv.Mat mat) {
    try {
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);
      final bytes = gray.data;
      List<int> counts = List.filled(256, 0);
      for(int i=0; i<bytes.length; i++){
        counts[bytes[i]]++;
      }
      setState(() {
         _histogramData = counts;
      });
    } catch (e) {
      debugPrint("Histogram calculation error: $e");
    }
  }

  void _applyHistogramEqualization() {
    try {
      final ycrcb = cv.cvtColor(_originalMat, cv.COLOR_BGR2YCrCb);
      final channels = cv.split(ycrcb);
      
      final eqY = cv.equalizeHist(channels[0]);
      
      final merged = cv.merge(cv.VecMat.fromList([eqY, channels[1], channels[2]]));
      final result = cv.cvtColor(merged, cv.COLOR_YCrCb2BGR);
      
      _currentMat = result;
      _updateImage(result);
    } catch (e) {
      debugPrint("Histogram Error: $e");
    }
  }


  void _applyContrast(double alphaValue) {
    try {
      final dst = cv.convertScaleAbs(_originalMat, alpha: alphaValue, beta: 10.0);
      _currentMat = dst;
      _updateImage(dst);
    } catch (e) {
      debugPrint("Contrast Error: $e");
    }
  }

  void _applyEdgeDetection() {
    try {
      final dst = cv.canny(_originalMat, 100, 200);
      final result = cv.cvtColor(dst, cv.COLOR_GRAY2BGR);
      _currentMat = result;
      _updateImage(result);
    } catch (e) {
      debugPrint("Edge Detection Error: $e");
    }
  }

  void _applySharpening() {
    try {
      final blurred = cv.gaussianBlur(_originalMat, (0, 0), 3.0);
      final dst = cv.addWeighted(_originalMat, 1.5, blurred, -0.5, 0.0);
      _currentMat = dst;
      _updateImage(dst);
    } catch (e) {
      debugPrint("Sharpen Error: $e");
    }
  }

  void _applyMeanFilter() {
    try {
      final dst = cv.blur(_originalMat, (15, 15));
      _currentMat = dst;
      _updateImage(dst);
    } catch (e) {
      debugPrint("Mean Filter Error: $e");
    }
  }

  void _applyGaussian() {
    try {
      final dst = cv.gaussianBlur(_originalMat, (15, 15), 0);
      _currentMat = dst;
      _updateImage(dst);
    } catch (e) {
      debugPrint("Gaussian Error: $e");
    }
  }

  void _applyGrayscale() {
    try {
      final gray = cv.cvtColor(_originalMat, cv.COLOR_BGR2GRAY);
      final result = cv.cvtColor(gray, cv.COLOR_GRAY2BGR);
      _currentMat = result;
      _updateImage(result);
    } catch (e) {
      debugPrint("Grayscale Error: $e");
    }
  }

  void _applyBinary() {
    try {
      final gray = cv.cvtColor(_originalMat, cv.COLOR_BGR2GRAY);
      final th = cv.threshold(gray, 127.0, 255.0, cv.THRESH_BINARY);
      final result = cv.cvtColor(th.$2, cv.COLOR_GRAY2BGR);
      _currentMat = result;
      _updateImage(result);
    } catch (e) {
      debugPrint("Binary Error: $e");
    }
  }

  void _applyMedian() {
    try {
      final dst = cv.medianBlur(_originalMat, 7);
      _currentMat = dst;
      _updateImage(dst);
    } catch (e) {
      debugPrint("Median Error: $e");
    }
  }

  Widget _buildHistogramPanel() {
    return Column(
      key: const ValueKey("histogram"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("1. Live Canvas Histogram", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Grafik frekuensi intensitas kecerahan dari matriks gambar secara real-time.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: HistogramPainter(_histogramData, Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _applyHistogramEqualization,
          child: const Text("Jalankan Histogram Equalization"),
        )
      ],
    );
  }

  Widget _buildContrastPanel() {
    return Column(
      key: const ValueKey("contrast"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("2. Pengaturan Kontras", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Manipulasi skala linier Alpha (Gain) Matrix. 1.0 adalah kondisi original.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.contrast_outlined, color: Theme.of(context).colorScheme.primary),
            Expanded(
              child: Slider(
                value: _contrastValue,
                min: 0.1,
                max: 3.0,
                divisions: 29,
                activeColor: Theme.of(context).colorScheme.primary,
                label: _contrastValue.toStringAsFixed(1),
                onChanged: (val) {
                  setState(() {
                    _contrastValue = val;
                  });
                },
                onChangeEnd: (val) {
                  _applyContrast(val);
                },
              ),
            ),
            Text(_contrastValue.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildConvolutionPanel() {
    return Column(
      key: const ValueKey("convolution"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("3. Operasi Konvolusi (Kernel Filter)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Operasi neighborhood filtering menggunakan matriks kernel 2 dimensi.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
             OutlinedButton.icon(icon: const Icon(Icons.border_clear), onPressed: _applyEdgeDetection, label: const Text("Edge Detection (Highpass)")),
             OutlinedButton.icon(icon: const Icon(Icons.hdr_strong), onPressed: _applySharpening, label: const Text("Sharpening (Bandpass)")),
             OutlinedButton.icon(icon: const Icon(Icons.blur_linear), onPressed: _applyMeanFilter, label: const Text("Mean (Lowpass)")),
             OutlinedButton.icon(icon: const Icon(Icons.blur_circular), onPressed: _applyGaussian, label: const Text("Gaussian (Lowpass)")),
          ],
        )
      ],
    );
  }

  Widget _buildConversionPanel() {
    return Column(
      key: const ValueKey("conversion"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("4. Konversi Ruang Warna", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Ubah citra asli berwarna menjadi matriks abstraksi Hitam-Putih.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
           children: [
              Expanded(child: OutlinedButton.icon(
                 icon: const Icon(Icons.monochrome_photos),
                 style: OutlinedButton.styleFrom(foregroundColor: Colors.black87),
                 onPressed: _applyGrayscale,
                 label: const Text("Grayscale"),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                 icon: const Icon(Icons.contrast),
                 style: OutlinedButton.styleFrom(foregroundColor: Colors.black87),
                 onPressed: _applyBinary,
                 label: const Text("Binary"),
              ))
           ]
        )
      ],
    );
  }

  Widget _buildMedianPanel() {
    return Column(
      key: const ValueKey("median"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("5. Koreksi Salt & Pepper Noise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Menggunakan matriks nonlinear median 7x7 pixel.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
           icon: const Icon(Icons.filter_center_focus),
           onPressed: _applyMedian, 
           label: const Text("Terapkan Median Filter"),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Hasil Manipulasi PCD"),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _reset,
            tooltip: "Reset Original",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        maxScale: 5.0,
                        child: _processedImageBytes != null
                            ? Image.memory(_processedImageBytes!, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
                            : const Center(child: Text("Gagal render", style: TextStyle(color:Colors.white))),
                      ),
                    ),
                  ),
                ),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 60,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            children: PcdMode.values.map((mode) {
                              final isSel = _currentMode == mode;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(mode.name.toUpperCase()),
                                  selected: isSel,
                                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: isSel ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.grey.shade700,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal
                                  ),
                                  onSelected: (sel) {
                                    if (sel) {
                                      setState(() {
                                        _currentMode = mode;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        Divider(height: 1, color: Colors.grey.shade200),
                        
                        SizedBox(
                          height: 250, // Mengunci tinggi jendela panel agar selalu konstan
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: SingleChildScrollView(
                              key: ValueKey(_currentMode),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              child: () {
                                switch (_currentMode) {
                                  case PcdMode.histogram: return _buildHistogramPanel();
                                  case PcdMode.contrast: return _buildContrastPanel();
                                  case PcdMode.convolution: return _buildConvolutionPanel();
                                  case PcdMode.conversion: return _buildConversionPanel();
                                  case PcdMode.median: return _buildMedianPanel();
                                }
                              }(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}

class HistogramPainter extends CustomPainter {
  final List<int> histogramData;
  final Color barColor;
  HistogramPainter(this.histogramData, this.barColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (histogramData.isEmpty) return;
    
    int maxVal = histogramData.reduce(max);
    if (maxVal == 0) maxVal = 1;

    final paint = Paint()
      ..color = barColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 256;

    for (int i = 0; i < 256; i++) {
      final height = (histogramData[i] / maxVal) * size.height;
      
      canvas.drawRect(
        Rect.fromLTWH(i * barWidth, size.height - height, barWidth, height), 
        paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant HistogramPainter oldDelegate) {
    return oldDelegate.histogramData != histogramData;
  }
}