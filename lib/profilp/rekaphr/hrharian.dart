import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 

class RekapHrHarianContent extends StatefulWidget {
final String cabang;
  const RekapHrHarianContent({super.key, required this.cabang});

  @override
  State<RekapHrHarianContent> createState() => _RekapHrHarianContentState();
}

class _RekapHrHarianContentState extends State<RekapHrHarianContent> {
  List _rekapData = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
 
  @override
  void initState() {
    super.initState();
    _fetchRekap();
  }

  void _showZoomableImage(BuildContext context, String? fotoName) {
  if (fotoName == null || fotoName.isEmpty) return;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Widget untuk Zoom
          InteractiveViewer(
            panEnabled: true, 
            minScale: 0.5,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "http://192.168.1.37/absensi_karyawan/uploads/$fotoName",
                fit: BoxFit.contain, // Agar foto terlihat utuh
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
          ),
          // Tombol Tutup
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
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
        Uri.parse("http://192.168.1.37/absensi_karyawan/rekaphrharian.php?cabang=${Uri.encodeComponent(widget.cabang)}&tanggal=$formattedDate"),
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
      debugPrint("Error: $e");
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
            flex: 1,
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

  Widget _buildFotoKecil(String? fotoName) {
    return GestureDetector(
      onTap: () => _showZoomableImage(context, fotoName), // Tambahkan fungsi untuk zoom  
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: (fotoName != null && fotoName.isNotEmpty)
              ? Image.network(
                  "http://192.168.1.37/absensi_karyawan/uploads/$fotoName",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.person, size: 20, color: Colors.grey),
                )
              : const Icon(Icons.no_photography, size: 20, color: Colors.grey),
        ),
      )
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
        final fotoMasuk = item["foto_masuk"]; // Pastikan key ini sesuai dari PHP
        final fotoPulang = item["foto_pulang"];

        bool isComplete = (masuk != null && pulang != null);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              // JAM
              Expanded(
                flex: 2, 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      masuk != null ? masuk.toString().substring(0, 5) : "-", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.blue.shade700, 
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    _buildFotoKecil(fotoMasuk),
                  ],
                ),
              ),
              Expanded(
                flex: 2, 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pulang != null ? pulang.toString().substring(0, 5) : "-", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.blue.shade700, 
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    _buildFotoKecil(fotoPulang),
                  ],
                ),
              ),
              Expanded(
              flex: 1,
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