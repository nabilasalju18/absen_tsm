import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginDevicePage extends StatefulWidget {
  const LoginDevicePage({super.key});

  @override
  State<LoginDevicePage> createState() => _LoginDevicePageState();
}

class _LoginDevicePageState extends State<LoginDevicePage> {
  String loginMode = "absensi";
  
  String? deviceCabang;

  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool isLoading = false;
@override
void initState() {
  super.initState();
  checkLogin();
}

Future<void> loginAbsen() async {
  if (userController.text.isEmpty || passController.text.isEmpty) {
    showError("User ID dan Password wajib diisi");
    return;
  }

  setState(() => isLoading = true);

  try {
    final response = await http.post(
      Uri.parse("http://192.168.1.37/absensi_karyawan/login.php?action=login"),
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
      showError("Server error (${response.statusCode})");
      return;
    }

    final data = jsonDecode(response.body);

    if (data["success"] != true || data["data"] == null) {
      showError(data["message"] ?? "Login gagal");
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    String cabang = data["data"]["cabang"] ?? "-";
    String role = data["data"]["role"].toString();

    // VALIDASI ROLE DULU
    // 3 = admin, 4 = kepala toko, 5 = asisten
    if (!["3", "4", "5"].contains(role)) {
      showError("Kamu tidak punya akses absensi");
      return;
    }

    // SIMPAN DATA
    await prefs.setString("cabangDevice", cabang);
    await prefs.setString("role", role);
    await prefs.setBool("isLogin", true);

    if (!mounted) return;

    // BARU NAVIGATE SEKALI
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );

  } catch (e) {
    showError("Server error / koneksi gagal");
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

Future<void> checkLogin() async {
  final prefs = await SharedPreferences.getInstance();

  bool isLogin = prefs.getBool("isLogin") ?? false;

  if (isLogin) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text(
                "Login Absensi",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

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
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loginAbsen,
                        child: const Text("Login"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}