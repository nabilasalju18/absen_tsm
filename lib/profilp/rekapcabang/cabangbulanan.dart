import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class RekapCabangBulananContent extends StatefulWidget {
  final String cabang;
  const RekapCabangBulananContent({super.key, required this.cabang});

  @override
  State<RekapCabangBulananContent> createState() => _RekapCabangBulananContentState();
}

class _RekapCabangBulananContentState extends State<RekapCabangBulananContent> {
  List _rekapData = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

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
  // Pastikan loading aktif sebelum mulai
  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    // Gunakan Uri object agar lebih rapi dan aman
final url = Uri.parse(
  "http://192.168.1.51/absensi_karyawan/rekapcabangbulanan.php"
  "?cabang=${Uri.encodeComponent(widget.cabang)}"
  "&bulan=${_selectedDate.month}"
  "&tahun=${_selectedDate.year}"
);

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    // Cek lagi apakah widget masih ada di layar setelah nunggu response
    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _rekapData = data['data'] ?? [];
        _isLoading = false;
      });
    } else {
      throw "Gagal memuat data (Status: ${response.statusCode})";
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    // Kasih feedback ke user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Terjadi kesalahan: $e")),
    );
    debugPrint("Error Fetch: $e");
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
                  _buildFilterBulan(),
                  _buildHeaderRekap(),
                  _rekapData.isEmpty
                      ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        color: Colors.white,
                        child: const Text("Data tidak ditemukan", textAlign: TextAlign.center),
                      )
                      : _buildListRekap(),
                ],
              ),
          ),
    );
  }

  Widget _buildFilterBulan() {
    return InkWell(
      onTap: _pickMonth,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Icon(
              Icons.calendar_month,
              color: Colors.green.shade800,
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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(10),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text("Nama", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
          Expanded(child: Text("Msk", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
          Expanded(child: Text("Plg", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
          Expanded(child: Text("Cuti", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
          Expanded(child: Text("Sakit", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
          Expanded(child: Text("Izin", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
          Expanded(child: Text("Alpa", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
          Expanded(child: Text("Total", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
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
        final msk = item["msk"]?.toString() ?? "0";
        final plg = item["plg"]?.toString() ?? "0";
        final cuti = item["cuti"]?.toString() ?? "0";
        final sakit = item["sakit"]?.toString() ?? "0";
        final izin = item["izin"]?.toString() ?? "0";
        final alpa = item["alpa"]?.toString() ?? "0";
        final total = item["total"]?.toString() ?? "0";


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
                flex: 2,
                child: Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              /// JAM
              Expanded(
                flex: 1, 
                child: Text(
                  msk, 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.blue.shade700, 
                  fontSize: 12
                  ),
                ),
              ),
              Expanded(
                flex: 1, 
                child: Text(
                  plg, 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.blue.shade700, 
                  fontSize: 12
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  cuti,
                  textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.blue.shade700, 
                    fontSize: 12
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  sakit,
                  textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.blue.shade700, 
                    fontSize: 12
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  izin,
                  textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.blue.shade700, 
                    fontSize: 12
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  alpa,
                  textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.blue.shade700, 
                    fontSize: 12
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  total,
                  textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.blue.shade700, 
                    fontSize: 12
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