import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'edit_profil_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String nama = "";
  String role = "";

  final String baseUrl =
      "http://192.168.1.45/absensi_karyawan/profil.php";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final res = await http.get(Uri.parse("$baseUrl?action=get"));
    final data = jsonDecode(res.body);

    if (data['success'] == true) {
      setState(() {
        nama = data['data']['nama'] ?? '';
        role = data['data']['role'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      appBar: AppBar(title: const Text("Profil")),

      body: Column(
        children: [
          const SizedBox(height: 30),

          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),

          const SizedBox(height: 20),

          Text("Nama: $nama", style: const TextStyle(fontSize: 18)),
          Text("Role: $role", style: const TextStyle(fontSize: 18)),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilPage(
                    nama: nama,
                    role: role,
                  ),
                ),
              );

              loadProfile();
            },
            child: const Text("Edit Profil"),
          )
        ],
      ),
    );
  }
}