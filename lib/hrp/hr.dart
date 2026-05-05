import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HRPage extends StatefulWidget {
  const HRPage({super.key});

  @override
  State<HRPage> createState() => _HRPageState();
}

class _HRPageState extends State<HRPage> {
  final String baseUrl = "http://192.168.1.50/absensi_karyawan";

  List izinList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchIzin();
  }

  Future<void> fetchIzin() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/get_izin.php"));
      final data = jsonDecode(res.body);

      setState(() {
        izinList = data['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("ERROR: $e");
    }
  }

  void updateStatus(int index, String status) {
    setState(() {
      izinList[index]['status'] = status;
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),
      appBar: AppBar(
        title: const Text("HR Approval Izin"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : izinList.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada pengajuan izin",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: izinList.length,
                  itemBuilder: (context, index) {
                    final item = izinList[index];

                    return Card(
                      child: ListTile(
                        title: Text(item['nama'] ?? '-'),
                        subtitle: Text("${item['jenis']} - ${item['tanggal']}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['status'] ?? 'pending',
                              style: TextStyle(
                                color: statusColor(item['status'] ?? 'pending'),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    updateStatus(index, "approved");
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    updateStatus(index, "rejected");
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}