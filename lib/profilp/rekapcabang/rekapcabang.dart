import 'package:absensi/profilp/rekapcabang/cabangharian.dart';
import 'package:absensi/profilp/rekapcabang/cabangbulanan.dart';
import 'package:absensi/profilp/rekapcabang/cabangtotal.dart';
import 'package:flutter/material.dart';

class RekapCabangPage extends StatefulWidget {
  final String cabang;
  const RekapCabangPage({super.key, required this.cabang});

  @override
  State<RekapCabangPage> createState() => _RekapCabangPageState();
}

class _RekapCabangPageState extends State<RekapCabangPage> {
  // Controller untuk mengatur geseran
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      appBar: AppBar(
        title: Text(_getTitle()), // Judul berubah sesuai halaman
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
                RekapCabangHarianContent(cabang: widget.cabang),  // Halaman 1
                RekapCabangBulananContent(cabang: widget.cabang), // Halaman 2
                RekapCabangTotalContent(cabang: widget.cabang),    // Halaman 3
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
          width: _currentPage == index ? 25 : 10, // Titik yang aktif lebih panjang
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.green.shade800 : Colors.grey,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}