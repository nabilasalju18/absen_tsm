import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class IzinPage extends StatefulWidget {
  const IzinPage({super.key});

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  final String baseUrl = "http://192.168.1.39/absensi_karyawan";

  String namaUser = "User";
  String? jenis;
  DateTime selectedDate = DateTime.now();
  TextEditingController keteranganController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    final res = await http.get(
      Uri.parse("$baseUrl/profil.php?action=get"),
    );

    final data = jsonDecode(res.body);

    if (data['success'] == true) {
      setState(() {
        namaUser = data['data']['nama'];
      });
    }
  }

  Future<void> submitIzin() async {
  if (jenis == null || keteranganController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lengkapi data dulu")),
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
        "user_id": "1",
        "jenis": jenis!,
        "tanggal": DateFormat('yyyy-MM-dd').format(selectedDate),
        "keterangan": keteranganController.text,
      },
    );

    final data = jsonDecode(response.body);

    if (!mounted) return;

    if (data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengajuan berhasil")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Gagal")),
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
      firstDate: DateTime.now(),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 FORM
              Expanded(
                child: ListView(
                  children: [

                    /// JENIS IZIN
                    DropdownButtonFormField<String>(
                      value: jenis,
                      hint: const Text("Pilih Jenis Izin"),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "SAKIT", child: Text("Sakit")),
                        DropdownMenuItem(value: "CUTI", child: Text("Cuti")),
                        DropdownMenuItem(value: "IZIN", child: Text("Izin")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          jenis = value;

                          if (jenis == "SAKIT") {
                            selectedDate = DateTime.now();
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// TANGGAL
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                          TextButton(
                            onPressed: jenis == "SAKIT" ? null : pilihTanggal,
                            child: const Text("Pilih Tanggal"),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// KETERANGAN
                    TextField(
                      controller: keteranganController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Keterangan",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitIzin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Kirim Pengajuan"),
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