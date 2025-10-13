import 'package:buku_tamu_penmad/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() {
  // ✅ inisialisasi database untuk Windows/Linux/Mac
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const BukuTamuApp());
}

class BukuTamuApp extends StatelessWidget {
  const BukuTamuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Buku Tamu",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}
