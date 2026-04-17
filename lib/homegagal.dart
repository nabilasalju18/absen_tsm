import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
   State<HomePageContent> createState() => _HomePageContentState();
   
}

class _HomePageContentState extends State<HomePageContent> {

 final String baseUrl = "http://192.168.1.45/absensi_karyawan";

   // 1. CONTROLLER
  TextEditingController manualController = TextEditingController();

  // 2. STATE VARIABLES
  bool bolehAbsen = false;

  String? jamMasuk;
  String? jamPulang;

  String? hasilScan;
  bool isScanning = false;
  bool isScanned = false;

  String jam = "";
  String tanggal = "";
  Timer? timer;

  double latitude = 0.0;
  double longitude = 0.0;

  // Di dalam State class
  double latKantor = -7.6002444;
  double longKantor = 112.1018223;
  double radiusKantor = 100;
  bool isLoadingLokasi = true; // Untuk loading indicator jika mau

  XFile? foto;

  String lokasiText = "Mencari lokasi...";

  // 3. INIT / DISPOSE
  @override
  void initState() {
          super.initState();

          updateWaktu();
          ambilLokasi();      

          timer = Timer.periodic(const Duration(seconds: 30), (timer) {
            updateWaktu();
          });

          // kalau kamu sudah pakai lokasi
        }

  @override
  void dispose() {
          timer?.cancel();
          super.dispose();
        }

  void updateWaktu() {
        final now = DateTime.now();

        setState(() {
          jam ="${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
              
          tanggal =
              "${now.day}/${now.month}/${now.year}";
          });
        }

  void onScanDetected(BarcodeCapture capture) {
  if (isScanned) return;

  if (capture.barcodes.isEmpty) return;

  final code = capture.barcodes.first.rawValue;

  if (code == null) return;

  setState(() {
    hasilScan = code;
    isScanned = true;
    isScanning = false;
  });
}

  Future<void> ambilLokasi() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    setState(() {
      lokasiText = "GPS belum aktif";
    });
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        lokasiText = "Izin lokasi ditolak";
      });
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    setState(() {
      lokasiText = "Izin lokasi ditolak permanen";
    });
    return;
  }

  Position pos = await Geolocator.getCurrentPosition();

  setState(() {
    latitude = pos.latitude;
    longitude = pos.longitude;
    lokasiText = "Lat: $latitude, Long: $longitude";
  });
} 

  Future<void> ambilFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        foto = picked;
      });
    }
  }

  Future<void> kirimAbsensi() async {
  if (!bolehAbsen) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kamu di luar area absensi")),
    );
    return;
  }

  var uri = Uri.parse("$baseUrl/absen.php");
  var request = http.MultipartRequest("POST", uri);

  request.fields['user_id'] = "1";
  request.fields['kode_user'] = "NABILA";

  request.fields['tanggal'] = tanggal;
  request.fields['jam'] = jam;

  request.fields['latitude'] = latitude.toString();
  request.fields['longitude'] = longitude.toString();

  request.fields['kode_qr'] = hasilScan ?? "";

  if (foto != null) {
    request.files.add(
      await http.MultipartFile.fromPath('foto', foto!.path),
    );
  }

  try {
    var response = await request.send();

    if (response.statusCode == 200) {
      setState(() {
        hasilScan = null;
        foto = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Absensi berhasil dikirim")),
      );
    } else {
      throw Exception();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gagal kirim absensi")),
    );
  }
}

  Future<void> cekLokasi() async {
  Position pos = await Geolocator.getCurrentPosition();

  double latUser = pos.latitude;
  double longUser = pos.longitude;

  double jarak = Geolocator.distanceBetween(
    latUser,
    longUser,
    latKantor,
    longKantor,
  );

  setState(() {
    latitude = latUser;
    longitude = longUser;
    lokasiText = "Jarak: ${jarak.toStringAsFixed(0)} meter";

    if (jarak <= radiusKantor) {
      bolehAbsen = true;
    } else {
      bolehAbsen = false;
    }

  });
}

  @override
  Widget build(BuildContext context) {
    return isScanning
        ? _buildScannerView()
        : Scaffold(
            backgroundColor: const Color.fromARGB(255, 149, 246, 157),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildScanResult(),
                    

                    const SizedBox(height: 15),

                    _buildHeader(),

                    const SizedBox(height: 20),

                    _buildStatusRow(),

                    const SizedBox(height: 30),

                    _buildActionMenu(),

                    const SizedBox(height: 20),

                    _buildLocationCard(),

                    const SizedBox(height: 20),

                    _buildManualInput(),
                  ],
                ),
              ),
            ),
          );
  }
 
  Widget _buildScannerView() {
  return Stack(
    children: [
      MobileScanner(
        onDetect: onScanDetected,
      ),

      Positioned(
        top: 50,
        left: 20,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                isScanning = false;
              });
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      /// 🔹 KIRI: Nama + Tanggal
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hallo, Nabila",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tanggal,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),

      /// 🔹 KANAN: Jam
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            jam,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "WIB",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildScanResult() {
  if (hasilScan == null && foto == null) {
    return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.all(15),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 🔹 TITLE
        const Text(
          "Hasil Scan:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        /// 🔹 QR RESULT 
        if (hasilScan != null)
          Text(
            hasilScan!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),

        /// 🔹 FOTO VALIDASI
        if (foto != null) ...[
          const SizedBox(height: 12),
          const Text(
            "Foto Validasi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(foto!.path),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    ),
  );
}

  Widget _buildStatusRow() {
  return Row(
    children: [
      Expanded(child: _buildStatusCard("Masuk", jamMasuk ?? "--", Colors.green)),
      const SizedBox(width: 15),
      Expanded(child: _buildStatusCard("Pulang", jamPulang ?? "--", Colors.red)),
    ],
  );
}

  Widget _buildActionMenu() {
  final bool canUseFeature = bolehAbsen == true;

  return Row(
    children: [

      /// SCAN QR
      Expanded(
        child: GestureDetector(
          onTap: () {
            if (bolehAbsen) {
              setState(() {
                isScanning = true;
                isScanned = false;
              });
            } else {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Akses Ditolak"),
                  content: const Text("Kamu harus berada di area kantor untuk absen"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    )
                  ],
                ),
              );
            }
          },
  
          child: Opacity(
            opacity: canUseFeature ? 1 : 0.4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 50,
                    color: Color.fromARGB(255, 9, 79, 3),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("SCAN QR"),
              ],
            ),
          ),
        ),
      ),

      const SizedBox(width: 20),

      // CAMERA
      Expanded(
        child: GestureDetector(
          onTap: () async {
            if (bolehAbsen) {
              await ambilFoto();
            } else {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Akses Ditolak"),
                  content: const Text("Kamu harus berada di area kantor untuk absen"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    )
                  ],
                ),
              );
            }
          },
          child: Opacity(
            opacity: canUseFeature ? 1 : 0.4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 50,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                const Text("FOTO"),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildLocationCard() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      /// 🔹 BUTTON CEK LOKASI
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: cekLokasi,
          child: const Text("CEK LOKASI"),
        ),
      ),

      const SizedBox(height: 10),

      /// 🔹 CARD INFO LOKASI
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [

            /// ICON
            const Icon(Icons.location_on, color: Colors.green),

            const SizedBox(width: 10),

            /// TEXT INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Lokasi Anda saat ini",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    lokasiText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// STATUS ABSESNSI
                  Text(
                    bolehAbsen
                        ? "Status: DIIZINKAN"
                        : "Status: DILUAR AREA",
                    style: TextStyle(
                      fontSize: 12,
                      color: bolehAbsen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildManualInput() {
  final bool canUse = bolehAbsen == true;

  return Opacity(
    opacity: canUse ? 1 : 0.4,
    child: TextField(
      controller: manualController,
      enabled: canUse,
      decoration: InputDecoration(
        labelText: "Input Manual QR / Kode",
        hintText: canUse
            ? "Ketik kode absensi..."
            : "Aktifkan lokasi dulu",
        prefixIcon: const Icon(Icons.keyboard),

        /// 🔥 BUTTON DI DALAM INPUT
        suffixIcon: IconButton(
          icon: const Icon(Icons.send),
          onPressed: canUse
              ? () {
                  if (manualController.text.isEmpty) return;

                  setState(() {
                    hasilScan = manualController.text;
                  });

                  manualController.clear();
                  FocusScope.of(context).unfocus();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Data manual berhasil dikirim"),
                    ),
                  );
                }
              : ()
              {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lokasi tidak valid untuk absensi"),
                    ),
                  );
                },
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
);
}
  
  Widget _buildStatusCard(String label, String time, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}