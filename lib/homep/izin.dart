import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/profilp/loginprofil.dart';
import 'package:camera/camera.dart';
import 'camera.dart';
import 'dart:io';

class IzinPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const IzinPage({
    super.key, 
    required this.cameras
  });

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  final _formKey = GlobalKey<FormState>();
  
  final String baseUrl = "http://192.168.1.37/absensi_karyawan";

  String? userId, namaUser;
  String? jenis;
  DateTime selectedDate = DateTime.now();
  TextEditingController keteranganController = TextEditingController();
  bool isCameraReady = false;
  bool isLoading = true;
  File? fotoFile;
  bool isPickingImage = false;

  final List<String> _jenis = ['Sakit', 'Izin', 'Cuti'];
  String? _selectJenis;
  
  @override
  void initState() {
    super.initState();

    checkLoginAndLoad();
    getUser();

    isCameraReady = widget.cameras.isNotEmpty;
  }

  @override
  void dispose() {
    keteranganController.dispose();
    super.dispose();
  }

  Future<void> checkLoginAndLoad() async {
    final prefs = await SharedPreferences.getInstance();

    bool isLogin = prefs.getBool("profileLogin") ?? false;

    if (!isLogin) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginProfilPage(),
        ),
      );
      return;
    }

    setState(() {
      userId = prefs.getString("user_id")?.trim();
      namaUser = prefs.getString("namaUser");
      isLoading = false;
    });
  }

  Future<void> getUser() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    // Pastikan key-nya SAMA dengan yang ada di ProfilPage
    userId = prefs.getString("user_id")?.trim(); 
    namaUser = prefs.getString("namaUser") ?? "User";
    

    isLoading = false; 
  });

}

  Future<void> ambilFoto() async {
    if (isPickingImage) return;
    setState(() => isPickingImage = true);

    try {
      final path = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraPage(cameras: widget.cameras),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
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
  
  Future<void> submitIzin() async {
    if (userId == null || userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID User tidak ditemukan, silakan login ulang")),
      );
      return;
    }

    if (jenis == null || keteranganController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi jenis izin dan keterangan")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/izin.php"));
        request.fields['user_id'] = userId!;
        request.fields['jenis'] = jenis!;
        request.fields['tanggal'] = DateFormat('yyyy-MM-dd').format(selectedDate);
        request.fields['keterangan'] = keteranganController.text.trim();
      if (fotoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('bukti', fotoFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pengajuan izin berhasil terkirim")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Gagal mengirim data")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error koneksi: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)), // Bisa pilih tgl lalu dikit
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157), // Hijau sangat pudar agar bersih
      appBar: AppBar(
        title: const Text("Form Pengajuan Izin", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color.fromARGB(255, 233, 234, 233),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Nama (Tetap di atas, tidak ikut scroll)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      "Hi, $namaUser",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 222, 250, 223),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectJenis,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Izin',
                    border: OutlineInputBorder(),
                  ),
                  items: _jenis
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectJenis = val),
                ),
              ),

              const SizedBox(height: 20),

              Container(                      
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              child: GestureDetector(
                  onTap: pilihTanggal,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Row(               
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMMM yyyy').format(selectedDate),
                            style: const TextStyle(fontSize: 15)),
                        const Icon(Icons.calendar_month, color: Colors.green),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 222, 250, 223),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: keteranganController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Keterangan",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 20),
                Container(                      
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                  child:  GestureDetector(
                    onTap: ambilFoto,
                    child: Container(
                      height: 150, // Diberi tinggi tetap agar rapi
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:  Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: fotoFile != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(fotoFile!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text("Ketuk untuk ambil foto", 
                                style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                    ),    
                  ),
                ),
               
                  
              const SizedBox(height: 40),
                    
                    // Button Kirim
              ElevatedButton(
                onPressed: isLoading ? null : submitIzin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}