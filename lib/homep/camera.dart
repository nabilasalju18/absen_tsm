import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPage({super.key, required this.cameras});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  int selectedCameraIndex = 0;
  bool isFlashOn = false;
  bool isTakingPicture = false;

  late CameraController controller;
  late Future<void> initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    // default kamera depan kalau ada
    selectedCameraIndex = widget.cameras.indexWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    if (selectedCameraIndex == -1) {
      selectedCameraIndex = 0;
    }

    initCamera(widget.cameras[selectedCameraIndex]);
  }

  Future<void> initCamera(CameraDescription camera) async {
    controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    initializeControllerFuture = controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> ambilFoto() async {
    try {
      await initializeControllerFuture;

      setState(() => isTakingPicture = true);

      final image = await controller.takePicture();

      await Future.delayed(const Duration(milliseconds: 100));

      setState(() => isTakingPicture = false);

      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      setState(() {
        isTakingPicture = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(controller),

                /// efek flash putih
                if (isTakingPicture)
                  Container(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),

                /// tombol capture
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: ambilFoto,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                ),

                /// switch kamera
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.cameraswitch,
                        color: Colors.white, size: 30),
                    onPressed: () async {
                      selectedCameraIndex =
                          (selectedCameraIndex + 1) % widget.cameras.length;

                      await controller.dispose();
                      await initCamera(
                          widget.cameras[selectedCameraIndex]);
                    },
                  ),
                ),

                /// tombol back
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                /// flash
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Icon(
                      isFlashOn
                          ? Icons.flash_on
                          : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      isFlashOn = !isFlashOn;

                      await controller.setFlashMode(
                        isFlashOn
                            ? FlashMode.torch
                            : FlashMode.off,
                      );

                      setState(() {});
                    },
                  ),
                ),
              ],
            );
          } else {
            return const Center(
                child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}