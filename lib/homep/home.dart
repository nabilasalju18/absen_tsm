import 'package:absensi/main.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'izin.dart';
import 'camera.dart';
import 'scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/login.dart';


class HomePageContent extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomePageContent({
    super.key,
    required this.cameras
  });

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final String baseUrl = "http://192.168.1.37/absensi_karyawan";

  final FocusNode inputFocus = FocusNode();
  // controller
  final TextEditingController manualController = TextEditingController();
  final TextEditingController textController = TextEditingController();

  // state

  String? namaUser;
  String? kodeAbsen;
  String? cabangDevice;
  String? cabangUser;
  String? statusUser;

  bool bolehAbsen = false;
  String? tipeAbsen; // scan / manual
  bool isValidAbsen = false;
  String? scanMessage;
  String? kirimMessage;
  bool isScanning = false;
  bool isScanned = false;

  bool isCameraReady = false;

  String tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
  String jam = DateFormat('HH:mm').format(DateTime.now());
  Timer? timer;

  double latitude = 0.0;
  double longitude = 0.0;

  double latKantor = -7.6002444;
  double longKantor = 112.1018223;
  double radiusKantor = 100;

  bool isLoadingLokasi = true;
  bool isLoading = false;

  String statusAbsen = "belum";
  bool isMoreOpen = false;

  File? fotoFile;
  bool isPickingImage = false;

  String lokasiText = "Mencari lokasi...";

  late final MobileScannerController cameraController;


  @override
  void initState() {
    super.initState();

    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    updateWaktu();
    cekLokasi();
    loadCabang();
    loadStatus();
    

    isCameraReady = widget.cameras.isNotEmpty;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      setState(() {
        tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
        jam = DateFormat('HH:mm').format(now);
      });
    });
  }

  @override
  void dispose() {
    cameraController.stop();
    cameraController.dispose();
    timer?.cancel();
    manualController.dispose();
    textController.dispose();
    inputFocus.dispose();
    super.dispose();
  }

  void resetAbsen() {
  setState(() {
    isValidAbsen = false;
    isScanned = false;
    kodeAbsen = null;
    namaUser = null;
    cabangUser = null;
    fotoFile = null;
    tipeAbsen = null;
    scanMessage = "";
    statusAbsen = "belum"; // atau default kamu
  });
}

  void updateWaktu() {
    final now = DateTime.now();
    if (!mounted) return;

    setState(() {
      tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
      jam = DateFormat('HH:mm').format(now);
    });
  }

  Future<void> _showDialog(String message) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Text(message),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadCabang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? c = prefs.getString("cabangDevice");
    setState(() {
      cabangDevice = c;
    });
  }

  Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      statusUser = prefs.getString('status');
    });
  }

  Future<void> _submitManual(String value) async {
    setState(() {
      statusAbsen = "belum"; // 🔥 WAJIB
    });
    if (value.trim().isEmpty) return;

    tipeAbsen = "manual";

    FocusScope.of(context).unfocus();
    textController.clear();
    final cleanCode = value.trim();
    setState(() {
      scanMessage = "Memvalidasi...";
      isScanned = false;
      kodeAbsen = cleanCode;
      isValidAbsen = false;
    });

    final isValid = await validasiKode(cleanCode);

    if (!mounted) return;

    setState(() {
      isScanned = isValid;
      scanMessage = isValid ? "✅ Kode valid" : "❌ Kode salah";
      isValidAbsen = isValid;
    });
  }

  Future<void> bukaScanner() async {
    setState(() {
      statusAbsen = "belum";
    });

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );

    if (!mounted || result == null) return;

    final code = result.toString();

    // 🔍 TAMPILKAN DULU KE USER
    setState(() {
      kodeAbsen = code;
      scanMessage = "Hasil scan: $code";
      isValidAbsen = false;
    });

    //  kasih delay dikit biar user lihat
    await Future.delayed(const Duration(milliseconds: 500));

    //  BARU VALIDASI
    final isValid = await validasiKode(code);

    if (!mounted) return;

    setState(() {
      isScanned = isValid;
      scanMessage = isValid ? "✅ Scan valid" : "❌ Kode tidak ditemukan";
      isValidAbsen = isValid;
    });
  }

  Future<bool> validasiKode(String kode) async {
    
    final safeKode = kode.trim();

    //  ringan → SnackBar
    if (safeKode.isEmpty) {
      _showMessage("Kode kosong");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/cekkode.php"),
        body: {
          'kode_qr': safeKode,
          'cabang_device': cabangDevice ?? '',
        },
      );

      if (!mounted) return false;

      // ❌ server error → dialog (penting)
      if (response.statusCode != 200) {
        await _showDialog("Server error");
        return false;
      }

      final data = jsonDecode(response.body);

      // gagal dari backend → dialog (WAJIB)
      if (data['status'] != 'success') {
        final message = data['message'] ?? "Kode tidak valid";

        await _showDialog(message);

        if (!mounted) return false;

        setState(() {
          isValidAbsen = false;
          namaUser = null;
          kodeAbsen = null;
          cabangUser = null;
        });

        return false;
      }

      if (!mounted) return false;

      // SUCCESS (tidak perlu dialog)
      setState(() {
        namaUser = data['nama'];
        kodeAbsen = data['user_id'];
        cabangUser = data['cabang'];
        isValidAbsen = true;
      });

      return true;

    } catch (e) {
      if (!context.mounted) return false;

      await _showDialog("Error: $e");
      return false;
    }
  }

  Future<void> cekLokasi() async {
    setState(() => isLoadingLokasi = true);
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek GPS aktif atau tidak
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        lokasiText = "GPS belum aktif";
        bolehAbsen = false;
      });
      return;
    }

    // 2. Cek izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          lokasiText = "Izin lokasi ditolak";
          bolehAbsen = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        lokasiText = "Izin lokasi ditolak permanen";
        bolehAbsen = false;
      });
      return;
    }

    // 3. Ambil posisi user
    Position pos = await Geolocator.getCurrentPosition();

    double latUser = pos.latitude;
    double longUser = pos.longitude;

    // 4. Hitung jarak ke kantor
    double jarak = Geolocator.distanceBetween(
      latUser,
      longUser,
      latKantor,
      longKantor,
    );

    // 5. Set semua state sekaligus
    setState(() {
      latitude = latUser;
      longitude = longUser;

      lokasiText = "Jarak: ${jarak.toStringAsFixed(0)} meter";

      bolehAbsen = jarak <= radiusKantor;

    });
    setState(() => isLoadingLokasi = false);
  }

  Future<void> ambilFoto() async {
    inputFocus.unfocus();
    FocusScope.of(context).requestFocus(FocusNode());

    if (isPickingImage) return;
    setState(() => isPickingImage = true);

    try {
      // 1. DISPOSE total controller di halaman ini sebelum pindah
      // Menggunakan stop() terkadang tidak cukup melepaskan hardware lock
      if (cameraController.value.isInitialized) {
        await cameraController.dispose(); 
      }

      if (!mounted) return;

      // 2. Tunggu hasil dari CameraPage
      final path = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraPage(cameras: widget.cameras),
        ),
      );

      // 3. Setelah balik, inisialisasi ulang controller halaman utama jika perlu
      // Tapi tunggu sebentar agar hardware kamera dilepaskan oleh CameraPage
      await Future.delayed(const Duration(milliseconds: 300));
      
      /* PANGGIL FUNGSI INIT KAMERA HALAMAN UTAMA LAGI DISINI 
        Misal: await initMainPageCamera(); 
      */

      if (path != null && path.isNotEmpty) {
        File file = File(path);
        if (await file.exists()) {
          setState(() => fotoFile = file);
        }
      }
    } catch (e) {
      debugPrint("Error di ambilFoto: $e");
    } finally {
      if (mounted) {
        setState(() => isPickingImage = false);
      }
    }
  }

  Future<void> kirimAbsensi() async {
    if (isLoading) return;

    final safeKode = kodeAbsen?.trim();
    final safeFoto = fotoFile;

    if (safeKode == null || safeKode.isEmpty) {
      _showMessage("QR belum diisi / belum scan");
      return;
    }

    if (safeFoto == null) {
      _showMessage("Ambil foto dulu ya 📸");
      return;
    }

    if (namaUser == null) {
      _showMessage("Scan QR dulu");
      return;
    }

    setState(() => isLoading = true);

    try {
      final uri = Uri.parse("$baseUrl/absen.php");
      final request = http.MultipartRequest("POST", uri);

      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['kode_qr'] = safeKode;

      request.files.add(
        await http.MultipartFile.fromPath('foto', safeFoto.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw "Server error: ${response.statusCode}";
      }

      final data = jsonDecode(response.body);
      final message = data['message'] ?? "Tidak ada pesan";

      //  ERROR
      if (data['status'] == 'error') {
        await _showDialog(message);
        return;
      }

      //  COMPLETED (HARUS DIDAHULUKAN)
      if (data['status'] == 'completed') {
        await _showDialog(message);

        if (!mounted) return;

        setState(() {
          statusAbsen = "lengkap";
          isValidAbsen = false;
          namaUser = null;
          kodeAbsen = null;
          fotoFile = null;
          cabangUser = null;
        });

        return;
      }

      //  SUCCESS
      await _showDialog(message);

      if (!mounted) return;

      setState(() {
        kodeAbsen = null;
        fotoFile = null;
        isScanned = false;
        isValidAbsen = false;
        namaUser = null;
        cabangUser = null;
        scanMessage = "";
        kirimMessage = message;
        statusAbsen = "selesai";
      });

    } catch (e) {
      if (mounted) {
        _showMessage("Gagal: $e");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> logout() async {
    bool konfirmasi = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Ya, Keluar")),
        ],
      ),
    ) ?? false;

    if (konfirmasi) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginDevicePage()),
        (route) => false,
      );
    }
  }
  
  @override
  
  Widget build(BuildContext context) {
    // TULIS DI SINI: Bungkus Scaffold dengan GestureDetector
    return GestureDetector(
      onTap: () {
        // Fungsi untuk menutup keyboard saat area mana saja diketuk
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 149, 246, 157),
        body: SafeArea(
          child: SingleChildScrollView(
            // Tambahkan ini juga agar scroll tidak menahan fokus keyboard
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildLocationCard(),
                const SizedBox(height: 20),
                _buildActionButton(),
                const SizedBox(height: 20),
                _buildKirimButton(),
                const SizedBox(height: 20),
                _buildLogout(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [

          //  BARIS ATAS (CABANG & JAM)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cabangDevice ?? "loading...",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    jam,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    tanggal,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildLogout() {
    return Center(
      child: ElevatedButton(
        onPressed: logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,

          side: const BorderSide(
            color: Colors.red,
            width: 1,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
        ),
        child: const Text(
          "Logout",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // 🔥 ROW ATAS: CEK LOKASI + IZIN
      Row(
        children: [

          Expanded(
            child: ElevatedButton(
              onPressed: cekLokasi,
              child: const Text("CEK LOKASI"),
            ),
          ),

          const SizedBox(width: 20),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Material(
                color: Colors.grey.shade100,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.person_off, color: Color.fromARGB(255, 30, 99, 32)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IzinPage(cameras: availableCamerasList)),
                      
                    );
                  },
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                "Izin",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        ],
      ),

      const SizedBox(height: 3),

      // 🔥 CARD LOKASI (tanpa tombol izin)
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [

            const Icon(Icons.location_on, color: Colors.green),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Lokasi Anda saat ini",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
  
  Widget _buildActionButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Memaksa anak Row mengikuti tinggi parent
            children: [
            /// 🔹 KIRI 
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12), // Jarak dalam kotak besar
                decoration: BoxDecoration(
                  color: Colors.white, // Warna background blok kiri
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // QR tetap di kiri
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    /// 1. Container QR (Bentuk Lingkaran)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: bukaScanner,
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                      ),
                    ),

                    const SizedBox(height: 12), // Jarak antara QR dan Input

                    /// 2. Container Input (Ketik Manual)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100], // Warna beda tipis agar kontras
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              focusNode: inputFocus,
                              autofocus: false,
                              decoration: const InputDecoration(
                                hintText: "Ketik kode...",
                                border: InputBorder.none,
                              ),
                              onSubmitted: _submitManual,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _submitManual(textController.text),
                            icon: const Icon(Icons.send, size: 20),
                          ),
                        ],
                      ),
                    ),                
                  ],
                ),
                
              ),
            ),

            const SizedBox(width: 12),

            /// 🔹 KANAN (KAMERA)
            Expanded(
              child: GestureDetector(
                onTap: ambilFoto, // Agar seluruh kotak bisa diklik untuk ambil foto
                child: Container(
                  // Padding dan Decoration dibuat sama dengan sisi kiri agar simetris
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  // Gunakan Center agar ikon tepat di tengah kotak
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(15), // Jarak ikon ke lingkaran
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt, // Atau Icons.camera_front
                        color: Colors.orange,
                        size: 40, // Ukuran ikon dibuat agak besar
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
        const SizedBox(height: 16),
          
        /// 🔽 MORE CHOICE
        GestureDetector(
          onTap: () {
            setState(() {
              isMoreOpen = !isMoreOpen;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "More Choice",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Icon(
                isMoreOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              )
            ],
          ),
        ),

        /// 🔥 EXPAND
        if (isMoreOpen) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.nfc),
                  label: const Text("RFID"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.face),
                  label: const Text("Face ID"),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKirimButton() {
  if (namaUser == null || statusAbsen == "selesai"|| statusAbsen == "lengkap") {
    return const SizedBox(); 
  }

  final bool siapKirim =
      bolehAbsen &&
      (kodeAbsen?.isNotEmpty ?? false) &&
      fotoFile != null;

  String textButton;

  if (statusAbsen == "belum") {
    textButton = siapKirim ? "ABSEN MASUK" : "LENGKAPI DATA";
  } else if (statusAbsen == "masuk") {
    textButton = siapKirim ? "ABSEN PULANG" : "LENGKAPI DATA";
  } else {
    textButton = "SUDAH ABSEN";
  }

  return Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 10,
        ),
      ],
    ),
    child: Column(
      children: [

        /// 🔹 ATAS: DATA + FOTO
        Row(
          children: [
            /// KIRI → DATA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nama: $namaUser"),
                  Text("Kode: $kodeAbsen"),
                  Text("Cabang: $cabangUser"),
                ],
              ),
            ),

            const SizedBox(width: 16),

            /// KANAN → FOTO
            Expanded(
              child: GestureDetector(
                onTap: ambilFoto, 
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200], 
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ), 
                  child: fotoFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        fotoFile!,
                        fit: BoxFit.cover,
                        width: double.infinity, // Biar menempuh lebar kotak
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.grey)
                )
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        /// 🔹 BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading || statusAbsen == "selesai" 
                ? null
                : () {
                  if (!siapKirim) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lengkapi data dulu ya")),
                    );
                    return;
                  }
                  kirimAbsensi();
                },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    textButton,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    ),
  );
}

}