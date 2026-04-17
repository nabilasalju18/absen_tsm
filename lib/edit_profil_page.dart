import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditProfilPage extends StatefulWidget {
  final String nama;
  final String role;

  const EditProfilPage({
    super.key,
    required this.nama,
    required this.role,
  });

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late TextEditingController namaController;
  late TextEditingController passwordController;
  late TextEditingController roleController;

  final String baseUrl =
      "http://192.168.1.45/absensi_karyawan/profil.php";

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.nama);
    roleController = TextEditingController(text: widget.role);
    passwordController = TextEditingController();
  }

  Future<void> save() async {
    final res = await http.post(
      Uri.parse("$baseUrl?action=save"),
      body: {
        "nama": namaController.text,
        "password": passwordController.text,
        "role": roleController.text,
      },
    );

    final data = jsonDecode(res.body);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );

      if (data['success'] == true) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),

      // penting: ini aman untuk navbar nanti
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: "Nama"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: "Role"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: save,
              child: const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}