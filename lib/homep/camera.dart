import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPage({super.key, required this.cameras});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    // Default cari kamera depan
    _selectedCameraIndex = widget.cameras.indexWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );
    if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

    _initCurrentCamera();
  }

  Future<void> _initCurrentCamera() async {
    // Matikan controller lama jika ada
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Gagal inisialisasi: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2 || _isTakingPicture) return;

    // 1. Matikan controller lama
    if (_controller != null) {
      await _controller!.dispose();
    }

    // 2. KUNCI: Set null agar UI tahu kamera sedang "kosong"
    // Ini akan mencegah layar merah karena UI tidak akan 
    // memanggil CameraPreview(_controller!).
    setState(() {
      _controller = null; // UI akan menampilkan loading
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    });

    // 3. Inisialisasi kamera baru
    // Fungsi ini sudah punya setState() internal untuk me-refresh UI
    // saat kamera baru sudah siap.
    await _initCurrentCamera();
  }

  Future<void> _ambilFoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;

    try {
      setState(() => _isTakingPicture = true);
      final image = await _controller!.takePicture();
      
      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      debugPrint("Error capture: $e");
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER (Hitung mundur / Flash / Back) ---
            Container(
              height: 60,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: _isFlashOn ? Colors.yellow : Colors.white,
                    ),
                    onPressed: () async {
                      if (_controller == null) return;
                      _isFlashOn = !_isFlashOn;
                      await _controller!.setFlashMode(
                        _isFlashOn ? FlashMode.torch : FlashMode.off,
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            // --- AREA KAMERA (Tengah) ---
            Expanded(
              child: Center(
                child: (_controller != null && _controller!.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: 1 / _controller!.value.aspectRatio,
                        child: Stack(
                          children: [
                            CameraPreview(_controller!),
                            if (_isTakingPicture)
                              Container(color: Colors.black54),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),

            // --- FOOTER (Capture & Switch) ---
            Container(
              height: 150,
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Spacing supaya simetris
                  const SizedBox(width: 60),

                  // Tombol Capture
                  GestureDetector(
                    onTap: _ambilFoto,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Tombol Switch
                  IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}