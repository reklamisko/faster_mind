import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'landing_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAhJnzHIkF2twc8pXzb7AWuczldWsGIPIU",
      authDomain: "faster-mind-12a6f.firebaseapp.com",
      projectId: "faster-mind-12a6f",
      storageBucket: "faster-mind-12a6f.firebasestorage.app",
      messagingSenderId: "581343241775",
      appId: "1:581343241775:web:463ab86511994bf7a348da",
      measurementId: "G-P9H90175RD",
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  String zakres = '10';
  String liczbaPytan = '25';

  Map<String, dynamic> najlepszeWyniki = {};
  double ostatniCzas = 0.0;
  String ostatniaLiczbaPytan = '25';

  Map<String, List<double>> profilTrudnosci = {};
  double parametrA = 1.5;

  void ustawZakres(String nowyZakres) {
    zakres = nowyZakres;
    notifyListeners();
  }

  void ustawLiczbePytan(String nowaLiczba) {
    liczbaPytan = nowaLiczba;
    notifyListeners();
  }

  Future<void> pobierzRekordy() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      var docRekordy = await FirebaseFirestore.instance
          .collection('najlepsze_wyniki')
          .doc(userId)
          .get();

      if (docRekordy.exists && docRekordy.data() != null) {
        najlepszeWyniki = docRekordy.data() as Map<String, dynamic>;
      } else {
        najlepszeWyniki = {};
      }

      var docProfil = await FirebaseFirestore.instance
          .collection('profile_trudnosci')
          .doc(userId)
          .get();

      if (docProfil.exists && docProfil.data() != null) {
        var dane = docProfil.data() as Map<String, dynamic>;
        if (dane.containsKey('profil')) {
          Map<String, dynamic> surowyProfil = dane['profil'];
          profilTrudnosci = surowyProfil.map((klucz, wartosc) {
            List<double> czasy =
                (wartosc as List).map((e) => (e as num).toDouble()).toList();
            return MapEntry(klucz, czasy);
          });
        }
      } else {
        profilTrudnosci = {};
      }

      notifyListeners();
    } catch (e) {
      // Błąd
    }
  }

  String sprawdzCzas(String z, String p) {
    String klucz = '${z}_$p';
    if (najlepszeWyniki.containsKey(klucz)) {
      return '${najlepszeWyniki[klucz]}s';
    }
    return '-';
  }

  void aktualizujProfil(String dzialanie, double czas) {
    if (czas < 1.5) return;
    if (czas > 6.0) czas = 6.0;

    if (!profilTrudnosci.containsKey(dzialanie)) {
      profilTrudnosci[dzialanie] = [6.0, 6.0, 6.0];
    }

    profilTrudnosci[dzialanie]!.insert(0, czas);
    if (profilTrudnosci[dzialanie]!.length > 3) {
      profilTrudnosci[dzialanie]!.removeLast();
    }

    notifyListeners();
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const LandingPage();
        }
        return const LoginPage();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faster Mind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
