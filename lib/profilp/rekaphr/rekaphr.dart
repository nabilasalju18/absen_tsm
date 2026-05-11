import 'package:absensi/profilp/rekaphr/hrharian.dart';
import 'package:absensi/profilp/rekaphr/hrbulanan.dart';
import 'package:absensi/profilp/rekaphr/gaji.dart';
import 'package:flutter/material.dart';

class RekapHrPage extends StatefulWidget {
final String cabang;
  const RekapHrPage({super.key, required this.cabang});

  @override
  State<RekapHrPage> createState() => _RekapHrPageState();
}

class _RekapHrPageState extends State<RekapHrPage> {
  // Controller untuk mengatur geseran
  final PageController _pageController = PageController();
  int _currentPage = 0;
late String _selectedCabang; 
final List<String> _cabang = ['DC', 'Tsamaniya 1', 'Tsamaniya 2']; 

@override
void initState() {
  super.initState();

  _selectedCabang = widget.cabang;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      appBar: AppBar(
        title: Text(_getTitle()), // Judul berubah sesuai halaman
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  value: _selectedCabang,
                  icon: const Icon(Icons.keyboard_arrow_down),   
                  items: _cabang                      
                  .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                  ))
                  .toList(),
                  onChanged: (value) {
                    setState(() {
                    _selectedCabang = value!;
                    });
                    },
              ),
            )
          ),  
        ],
      ),
      body: Column(
        children: [
          // Bagian yang bisa digeser
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                RekapHrHarianContent(cabang: _selectedCabang),  
                RekapHrBulananContent(cabang: _selectedCabang), 
                RekapGajiContent(cabang: _selectedCabang), 
              ],
            ),
          ),
          
          // Indikator Titik (Dots) di bawah
          _buildStepIndicator(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Fungsi buat ganti judul AppBar otomatis
  String _getTitle() {
    if (_currentPage == 0) return "Rekap Harian";
    if (_currentPage == 1) return "Rekap Bulanan";
    return "Rekap Gaji";
  }

  // Widget Indikator Titik
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 10,
          width: _currentPage == index ? 25 : 10, 
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.green.shade800 : Colors.grey,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}