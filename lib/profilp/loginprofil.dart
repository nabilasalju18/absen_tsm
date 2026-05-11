import 'package:absensi/main.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginProfilPage extends StatefulWidget {
  const LoginProfilPage({super.key});

  @override
  State<LoginProfilPage> createState() => _LoginProfilPageState();
}

class _LoginProfilPageState extends State<LoginProfilPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    if (userController.text.isEmpty || passController.text.isEmpty) {
      showError("Isi User ID dan Password dulu");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.37/absensi_karyawan/loginprofil.php?action=login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "user_id": userController.text.trim(),
          "password": passController.text.trim(),
        }),
      );

      if (response.statusCode != 200) {
        showError("Server error ${response.statusCode}");
        return;
      }

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        showError("Format response tidak valid");
        return;
      }

      if (data["success"] == true && data["data"] != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool("profileLogin", true);
        await prefs.setString("user_id", data["data"]["user_id"].toString()); 
        await prefs.setString("namaUser", data["data"]["nama"].toString());
        await prefs.setString("role", data["data"]["role"].toString());
        await prefs.setString("cabang", data["data"]["cabang"]??"-");

        if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 1),
        ),
      );
      } else {
        showError(data["message"] ?? "Login gagal");
      }

    } catch (e) {
      showError("Koneksi gagal");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      appBar: AppBar(
        title: const Text("Login Profil"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const MainScreen(),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: userController,
              decoration: const InputDecoration(labelText: "User ID"),
            ),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),

            isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: loginUser,
                child: const Text("Masuk Profil"),
            ),
          ],
        ),
      ),
    );
  }
}