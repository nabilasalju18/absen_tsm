import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Wajib ada untuk menggunakan DateFormat
import 'package:http/http.dart' as http;
import 'dart:convert';
class RekapGajiContent extends StatefulWidget {
  final String cabang;
  const RekapGajiContent({super.key, required this.cabang});

  @override
  State<RekapGajiContent> createState() => _RekapGajiContentState();
}

class _RekapGajiContentState extends State<RekapGajiContent> {
  List _rekapData = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
@override
  void initState() {
    super.initState();
    _fetchRekap();
  }

  Future<void> _pickMonth() async {
    List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog( // Gunakan dialogContext
        title: const Text("Pilih Bulan", textAlign: TextAlign.center),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          width: double.maxFinite, // Mencegah error layout
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Dialog biasanya tidak scrollable di gridnya
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (ctx, index) {
              final isSelected = _selectedDate.month == (index + 1);
              
              return InkWell(
                onTap: () {
                  setState(() {
                    // Tambahkan hari ke-1 untuk menghindari bug tanggal 31
                    _selectedDate = DateTime(_selectedDate.year, index + 1, 1);
                    _isLoading = true;
                  });
                  Navigator.pop(dialogContext); // Tutup dialog dengan benar
                  _fetchRekap();
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      months[index].substring(0, 3),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.green.shade800,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


 Future<void> _fetchRekap() async {
    try {
      String bulan = _selectedDate.month.toString();
      String tahun = _selectedDate.year.toString();

      final response = await http.get(
        Uri.parse(
          "http://192.168.1.37/absensi_karyawan/rekapgaji.php?bulan=$bulan&tahun=$tahun"
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rekapData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _rekapData = [];
          _isLoading = false;
        });
        debugPrint('Failed to load rekap: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _rekapData = [];
        _isLoading = false;
      });
      debugPrint('Error: $e');
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
      onTap: _pickMonth, // Fungsi untuk buka kalender
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
                DateFormat('MMMM yyyy','id_ID').format(_selectedDate),
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
            flex: 4,
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
            flex: 4,
            child: Text(
              "Gaji",
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
        final gaji = item["gaji"];

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
                flex: 4,
                child: Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              /// JAM
              Expanded(
                flex: 4, 
                child: Text(
                  gaji != null 
                  ? currencyFormatter.format(int.parse(gaji.toString())) : "-", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(
                  color: Colors.blue.shade700, 
                  fontSize: 12,
                  fontWeight: FontWeight.bold
                  ),
                ),
              ),
            
            ],
          ),
        );
      },
    );
  }

}