import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/profilp/loginprofil.dart';

class IzinPage extends StatefulWidget {
  const IzinPage({super.key});

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  final String baseUrl = "http://192.168.1.51/absensi_karyawan/izin.php";

  String? userId, namaUser;
  String? jenis;
  DateTime selectedDate = DateTime.now();
  TextEditingController keteranganController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkLoginAndLoad();
    getUser();
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
      final response = await http.post(
        Uri.parse("$baseUrl/izin.php"),
        body: {
          "user_id": userId, 
          "jenis": jenis!,
          "tanggal": DateFormat('yyyy-MM-dd').format(selectedDate),
          "keterangan": keteranganController.text,
        },
      );

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
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      appBar: AppBar(
        title: const Text("Form Pengajuan Izin"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Nama (Biar User tau sistem sudah kenal mereka)
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

              Expanded(
                child: ListView(
                  children: [
                    const Text("Jenis Izin", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: jenis,
                      hint: const Text("Pilih Jenis Izin"),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Sakit", child: Text("Sakit")),
                        DropdownMenuItem(value: "Cuti", child: Text("Cuti")),
                        DropdownMenuItem(value: "Izin", child: Text("Izin")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          jenis = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text("Tanggal Izin", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: pilihTanggal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                            const Icon(Icons.calendar_month, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text("Keterangan", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: keteranganController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Contoh: Izin bimbingan dosen atau Sakit demam",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitIzin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("KIRIM LAPORAN", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}