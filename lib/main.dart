import 'package:flutter/material.dart';
import 'profilp/profil.dart';
import 'homep/home.dart';
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

late List<CameraDescription> availableCamerasList;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  availableCamerasList = await availableCameras();
 
  // ---------------------
  final prefs = await SharedPreferences.getInstance();
  bool isLoginDevice = prefs.getBool("isLoginDevice") ?? false;

  // ---------------------

  runApp(MyApp(isLoginDevice: isLoginDevice)); // Kirim status login ke MyApp
}

/* =========================
   APP ROOT
========================= */
class MyApp extends StatelessWidget {
  final bool isLoginDevice;
  const MyApp({super.key, required this.isLoginDevice});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('id', 'ID'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesia
      ],
      debugShowCheckedModeBanner: false,
      title: 'Absensi Karyawan',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: isLoginDevice ? const MainScreen() : const LoginDevicePage(),
    );
  }
}

/* =========================
   MAIN SCREEN (NO LOGIN)
========================= */
class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});


  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    final pages = [
      HomePageContent(cameras: availableCamerasList), // KIOSK ABSEN
      const ProfilPage(),      // PROFIL SAJA
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 149, 246, 157),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.business, color: Colors.green),
            ),
            const SizedBox(width: 8),
            const Text(
              'Absensi Karyawan',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 79, 3),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}