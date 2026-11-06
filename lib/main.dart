import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/akademik_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

/// Titik masuk aplikasi AkademikKu
///
/// Struktur:
/// main() → MyApp → MultiProvider(AuthProvider, AkademikProvider)
///        → SplashScreen → LoginScreen → HomeScreen
///        → (Data Mahasiswa • Biodata • Dashboard Input Nilai • Transkrip)
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Paksa orientasi portrait (cocok untuk aplikasi akademik mobile)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Kustomisasi warna status bar agar sinkron dengan tema aplikasi
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Data akademik dimuat dari penyimpanan lokal saat provider dibuat;
        // proses ini selesai jauh sebelum splash screen (2,5 dtk) berakhir.
        ChangeNotifierProvider(create: (_) => AkademikProvider()..muat()),
      ],
      child: MaterialApp(
        title: 'AkademikKu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
