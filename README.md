# ETS Pengolahan Citra Digital Praktikum

**Nama:** Muhammad Ihsan Ramadhan

**NIM:** 241511083

**Kelas:** 2C - D3 Teknik Informatika

---

## Deskripsi Proyek

Proyek ini merupakan integrasi antarmuka kamera yang dipadukan dengan modul Pengolahan Citra Digital (PCD) tingkat lanjut berbasis OpenCV C++ (opencv_dart). Fitur ini dirancang khusus untuk memenuhi tugas ETS PCD.

## Fitur Utama

1. **Camera Sensor Initialization**: Manajemen siklus hidup `CameraController` yang responsif menggunakan `WidgetsBindingObserver`.
2. **Dashboard PCD (Image Processing)**:
   - **Histogram Equalization**: Meratakan rentang distribusi spektrum piksel Luminance (YCrCb). Lengkap dengan grafik *live canvas*.
   - **Manipulasi Kontras (Linear Transform)**: Pemrosesan Alpha Gain melalui *Slider* dinamis Interaktif.
   - **Filter Konvolusi Spasial**:
     - *Edge Detection* (Highpass).
     - *Sharpening* (Bandpass)
     - *Smoothing* (Lowpass - Mean & Gaussian)
   - **Konversi Ruang Warna**: Grayscale murni & Binary Threshold.
   - **Koreksi Noise**: Median Blur 7x7 untuk mereduksi *Salt and Pepper*.

## Petunjuk Instalasi

Aplikasi ini menggunakan modul Native C++. Oleh karena itu ikuti instruksi ketat ini untuk proses kompilasi di OS Windows:

1. Pastikan Anda telah membuka repositori di dalam direktori absolut terluar (misal: `D:\logbook_app`) untuk menghindari error *Maximum Path 260 characters* dari kernel Windows.
2. Pastikan file `local.properties` pada folder `android/` mengarah ke path Android SDK Anda dengan benar.

**Buka terminal dan jalankan:**

```bash
flutter clean
flutter pub get
```

Jika terjadi masalah C++ Ninja/CMake di Windows, tembakkan command Environment ini di PowerShell sebelum melakukan jalankan program:

```powershell
$env:ANDROID_NDK_HOME="D:\Tools\android-sdk\ndk\28.2.13676358"
$env:Path="D:\Tools\android-sdk\cmake\3.22.1\bin;" + $env:Path
flutter run
```

---


## Tech Stack & Packages

* **Language:** Dart
* **Framework:** Flutter
* **Database:** MongoDB Atlas
* **Local Database:** Hive
* **Computer Vision / PCD:** `opencv_dart` (Native OpenCV C++ Wrapper)
* **Camera Sensor:** `camera`
* **Hardware Permissions:** `permission_handler`
