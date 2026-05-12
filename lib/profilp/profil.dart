import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'loginprofil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'tambahkaryawan.dart';
import 'rekapcabang/rekapcabang.dart';
import 'rekaphr/rekaphr.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> 
  with TickerProviderStateMixin {
  final String baseUrl =
      "http://192.168.1.37/absensi_karyawan/riwayat.php";
  String? userId, namaUser, role, cabang;
  
  bool isLoadingProfil = true;
  bool isLoadingRiwayat = false;
  bool isMoreOpen = false;
  List<Map<String, dynamic>> dataAbsensi = [];
  String errorMessage = "";
  String tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
  String jam = DateFormat('HH:mm').format(DateTime.now());
  Timer? timer;

  String getRoleDisplayName(String? roleId) {
  switch (roleId) {
    case 'R02': return 'Manager';
    case 'R03': return 'HR';
    case 'R04': return 'Admin';
    case 'R05': return 'Kepala Toko';
    case 'R06': return 'Asisten';
    case 'R07': return 'Karyawan';
    default: return 'User';
  }
}

  @override
  void initState() {
    super.initState();
    checkLoginAndLoad();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      setState(() {
        tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
        jam = DateFormat('HH:mm').format(now);
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  
  void updateWaktu() {
    final now = DateTime.now();
    if (!mounted) return;

    setState(() {
      tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
      jam = DateFormat('HH:mm').format(now);
    });
  }
  // Fungsi Cek Login & Ambil Data dari SharedPreferences
  Future<void> checkLoginAndLoad() async {
    final prefs = await SharedPreferences.getInstance();

    bool isLogin = prefs.getBool("profileLogin") ?? false;

    if (!isLogin) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginProfilPage(),
        ),
      );
      return;
    }

    setState(() {
      userId = prefs.getString("user_id")?.trim();
      role = prefs.getString("role")?.toString().trim();
      namaUser = prefs.getString("namaUser");
      cabang = prefs.getString("cabang")??"Tanpa Cabang?";
      isLoadingProfil = false;
    });

  if (userId != null && userId!.isNotEmpty) {
    fetchRiwayat();
  }
  }
  // Fungsi Ambil Data Riwayat dari Database
  Future<void> fetchRiwayat() async {
    if (userId == null || userId!.isEmpty) {
      setState(() {
        errorMessage = "User ID tidak valid";
        isLoadingRiwayat = false;
      });
      return;
    }

    setState(() {
      isLoadingRiwayat = true;
      errorMessage = "";
    });

    try {
      final url = Uri.parse(baseUrl).replace(
        queryParameters: {"user_id": userId},
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        dynamic result;

        try {
          result = jsonDecode(response.body);
        } catch (_) {
          if (!mounted) return;
          setState(() {
            errorMessage = "Format response tidak valid";
          });
          return;
        }

        if (result is Map && result["status"] == "success") {
          if (!mounted) return;
          setState(() {
            dataAbsensi =
                List<Map<String, dynamic>>.from(result["data"] ?? []);
          });
        } else {
          if (!mounted) return;
          setState(() {
            errorMessage = result["message"] ?? "Belum ada data";
            dataAbsensi = [];
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          errorMessage = "Server error ${response.statusCode}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Gagal koneksi ke server";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRiwayat = false;
        });
      }
    }
  }
  // Helper Formatter
  String formatTanggal(String tgl) {
    try {
      final date = DateTime.parse(tgl);
      return DateFormat("dd MMM yyyy").format(date);
    } catch (_) { return tgl; }
  }
  
  String formatJam(String jam) {
    try {
      final time = DateTime.parse(jam);
      return DateFormat("HH:mm").format(time);
    } catch (_) {
      try {
        final time = DateFormat("HH:mm:ss").parse(jam);
        return DateFormat("HH:mm").format(time);
      } catch (_) {
        return jam;
      }
    }
  }
  // Helper Warna
  Color getStatusColor(String status) {
    if (status.contains("Izin")) return Colors.orange;
    if (status == "Masuk") return Colors.green;
    if (status == "Pulang") return Colors.blue;
    return Colors.grey;
  }
  
  void konfirmasiHapus(int id, String status) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Data"),
        content: Text("Yakin mau hapus $status ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              hapusDataKeDatabase(id, status);
            },
            child: const Text(
              "Hapus",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> hapusDataKeDatabase(int id, String status) async {
    final url = Uri.parse(baseUrl).replace(
      queryParameters: {"action": "delete"},
    );

    try {
      final response = await http.post(url, body: {
        "id": id.toString(),
        "type": status.contains("Izin") ? "izin" : "absensi",
      });

      if (response.statusCode == 200) {
        dynamic result;
          try {
            result = jsonDecode(response.body);
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Format response tidak valid")),
            );
            return;
          }

        if (result["status"] == "success") {
          await fetchRiwayat();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result["message"])),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result["message"] ?? "Gagal hapus")),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal koneksi"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Fungsi Logout
  Future<void> logoutProfil() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("profileLogin");
    await prefs.remove("user_id");
    await prefs.remove("role");
    await prefs.remove("namaUser");
    await prefs.remove("cabang");

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginProfilPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Kita hilangkan AppBar di sini karena MainScreen sudah punya AppBar
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      body: isLoadingProfil
          ? const Center(child: CircularProgressIndicator())
          : (userId == null) // Cek apakah sudah login atau belum
              ? const LoginProfilPage() // Jika belum, tampilkan widget Login
              : _buildProfil(), // Jika sudah, tampilkan profil yang tadi kita buat
    );
  }

  Widget _buildProfil() {
    return SafeArea(     
      child: SingleChildScrollView(  
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildDataUser(),
            const SizedBox(height: 20),
            _buildRiwayat(),
            // R03 = hr, R04 = admin, R05 = kepala toko,
            if (role == 'R03' || role == 'R04')...[
              const SizedBox(height: 20),
              _buildTambahKaryawan(),
               const SizedBox(height: 20),
              _buildRekabAbsensiAll(),
            ],
            if (role == 'R04' || role == 'R05')...[
              const SizedBox(height: 20),
              _buildRekabAbsensiCabang(),
            ],
             const SizedBox(height: 20),
            _buildLogoutProfile(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
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
            "Hi, $namaUser",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                jam,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                tanggal,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataUser() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _item(Icons.person, "Nama", namaUser),
          const Divider(height: 20, thickness: 0.5),
          _item(Icons.badge, "User ID", userId),
          const Divider(height: 20, thickness: 0.5),
          _item(Icons.settings, "Role", getRoleDisplayName(role)),
          const Divider(height: 20, thickness: 0.5),
          _item(Icons.location_on, "Cabang", cabang),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 12),

        SizedBox(
          width: 80, 
          child:Text(
            "$label ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),

        const Text(
          ": ",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),

        Expanded(
          child: Text(
            value ?? "-",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis, // Nilainya rata kanan biar rapi
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayat() {
  return Column(
    children: [
      InkWell(
        onTap: () {
          setState(() {
            isMoreOpen = !isMoreOpen;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.green, size: 28),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  "Riwayat Absensi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                isMoreOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),

      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: isMoreOpen
            ? Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildHeaderRiwayat(),
                    const Divider(),
                    /// LOADING
                    if (isLoadingRiwayat)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      )
                    /// ERROR (HARUS DI ATAS)
                    else if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    /// DATA KOSONG
                    else if (dataAbsensi.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("Belum ada data absensi"),
                      )
                    /// DATA ADA
                    else
                      _buildListRiwayat(),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}

  Widget _buildHeaderRiwayat() {
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
            "Tanggal",
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
            "Jam",
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
            "Status",
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

  Widget _buildListRiwayat() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dataAbsensi.length,
      itemBuilder: (context, index) {
        final item = dataAbsensi[index];

        final tanggal = item["tanggal"]?.toString() ?? "-";
        final jam = item["jam"]?.toString() ?? "-";
        final status = item["status"]?.toString() ?? "-";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: index % 2 == 0
                ? Colors.white
                : Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              /// TANGGAL
              Expanded(
                flex: 4,
                child: Text(
                  formatTanggal(tanggal),
                  textAlign: TextAlign.center,
                ),
              ),

              /// JAM
              Expanded(
                flex: 2,
                child: Text(
                  formatJam(jam),
                  textAlign: TextAlign.center,
                ),
              ),

              /// STATUS + DELETE
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        status,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    /// DELETE BUTTON
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        final id = int.tryParse(item["id"].toString());
                        if (id != null) {
                          konfirmasiHapus(id, status);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTambahKaryawan() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TambahKaryawanPage()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_add, color: Colors.green, size: 28),
            const SizedBox(width: 15),
            const Expanded(
              child: Text(
                "Tambah Karyawan Baru",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRekabAbsensiAll() {
    return InkWell(
      onTap: () {
       Navigator.push(context, MaterialPageRoute(builder: (context) => RekapHrPage(cabang: cabang!)));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.table_chart, color: Colors.green, size: 28),
            const SizedBox(width: 15),
            const Expanded(
              child: Text(
                "Rekapitulasi Absensi Seluruh Karyawan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRekabAbsensiCabang() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RekapCabangPage(cabang: cabang!)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment, color: Colors.green, size: 28),
            const SizedBox(width: 15),
            const Expanded(
              child: Text(
                "Rekapitulasi Absensi Cabang",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutProfile() {
    return Center(
      child: ElevatedButton(
        onPressed: logoutProfil,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,

          side: const BorderSide(
            color: Colors.red,
            width: 1,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
        ),
        child: const Text(
          "Logout",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

}