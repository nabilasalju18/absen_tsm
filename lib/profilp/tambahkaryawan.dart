import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TambahKaryawanPage extends StatefulWidget {
  const TambahKaryawanPage({super.key});

  @override
  State<TambahKaryawanPage> createState() => _TambahKaryawanPageState();
}

class _TambahKaryawanPageState extends State<TambahKaryawanPage> {
  final _formKey = GlobalKey<FormState>();

  final String baseUrl =
      "http://192.168.1.51/absensi_karyawan/tambahkaryawan.php";

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedRole;
  String? _selectedStatus;
  String? _selectedCabang;

  bool isLoading = false;

  final List<String> _roles = ['admin', 'hr', 'karyawan','kepala toko', 'asisten'];
  final List<String> _statuses = ['Aktif', 'Tidak Aktif'];
  final List<String> _listCabang = ['DC', 'Tsamaniya 1', 'Tsamaniya 2'];

  @override
  void dispose() {
    _namaController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null ||
        _selectedStatus == null ||
        _selectedCabang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua dropdown wajib dipilih')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'nama': _namaController.text,
          'user_id': _userIdController.text,
          'password': _passwordController.text,
          'role': _selectedRole!,
          'status_karyawan': _selectedStatus!,
          'cabang': _selectedCabang!,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Karyawan berhasil ditambahkan'),
                backgroundColor: Colors.green,
              ),
            );

            _formKey.currentState!.reset();
            _namaController.clear();
            _userIdController.clear();
            _passwordController.clear();

            setState(() {
              _selectedRole = null;
              _selectedStatus = null;
              _selectedCabang = null;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal: ${data['message'] ?? 'Terjadi kesalahan'}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Format respon server salah')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Menangani error koneksi (timeout/rto)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal terhubung ke server'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      appBar: AppBar(
        title: const Text('Tambah Karyawan Baru'),
        backgroundColor: const Color.fromARGB(255, 233, 234, 233),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        // Tambahkan Form agar validator di _simpanData bisa jalan
        child: Form(
          key: _formKey, 
          child: Column(
            // Tambahkan stretch agar tombol Simpan bisa lebar (opsional)
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                  // Tambahkan validator sederhana
                  validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
              ),
              const SizedBox(height: 10), // Jarak antar kontainer

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 222, 250, 223),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'User ID tidak boleh kosong' : null,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Password tidak boleh kosong' : null,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 222, 250, 223),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: _roles
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedRole = val),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 222, 250, 223),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCabang,
                  decoration: const InputDecoration(
                    labelText: 'Cabang',
                    border: OutlineInputBorder(),
                  ),
                  items: _listCabang
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCabang = val),
                ),
              ),
              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: isLoading ? null : _simpanData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
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