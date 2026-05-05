import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Wajib ada untuk menggunakan DateFormat

class RekapCabangHarianContent extends StatefulWidget {
  final String cabang; // Cabang user yang sedang login
  const RekapCabangHarianContent({super.key, required this.cabang});

  @override
  State<RekapCabangHarianContent> createState() => _RekapCabangHarianContentState();
}

class _RekapCabangHarianContentState extends State<RekapCabangHarianContent> {
  List _rekapData = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchRekap();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true; // Jalankan loading lagi
      });
      _fetchRekap(); // Panggil API lagi dengan filter tanggal
    }
  }

  Future<void> _fetchRekap() async {
    try {
      // Format tanggal ke YYYY-MM-DD
      String formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      final response = await http.get(
        Uri.parse("http://192.168.1.51/absensi_karyawan/rekabcabangharian.php?cabang=${Uri.encodeComponent(widget.cabang)}&tanggal=$formattedDate"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rekapData = data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFilterTanggal(),
                  _buildHeaderRekap(),
                  _rekapData.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          color: Colors.white,
                          child: const Text("Tidak ada data hari ini", textAlign: TextAlign.center),
                        )
                      : _buildListRekap(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterTanggal() {
    return InkWell(
      onTap: _pickDate, // Fungsi untuk buka kalender
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2), // Efek transparan mirip profil
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // KIRI
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                DateFormat('EEEE, dd MMMM yyyy','id_ID').format(_selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Sesuaikan ukuran font agar muat satu baris
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.calendar_month,
              color: Colors.green.shade800,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRekap() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "Nama Karyawan",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Masuk",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Pulang",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Poin",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRekap() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rekapData.length,
      itemBuilder: (context, index) {
        final item = _rekapData[index];

        final nama = item["nama"]?.toString() ?? "-";
        final masuk = item["jam_masuk"];
        final pulang = item["jam_pulang"];

        bool isComplete = (masuk != null && pulang != null);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: index % 2 == 0 ? Colors.white : Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              /// NAMA
              Expanded(
                flex: 3,
                child: Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              /// JAM
              Expanded(
                flex: 2, 
                child: Text(
                  masuk != null ? masuk.toString().substring(0, 5) : "-", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.blue.shade700, 
                  fontSize: 12
                  ),
                ),
              ),
              Expanded(
                flex: 2, 
                child: Text(
                  pulang != null ? pulang.toString().substring(0, 5) : "-", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.blue.shade700, 
                  fontSize: 12
                  ),
                ),
              ),
              Expanded(
              flex: 2,
              child: isComplete 
                ? const Icon(Icons.check_circle, 
                color: Colors.green, 
                size: 20) 
                : const Text(
                  "0", textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.grey)
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}