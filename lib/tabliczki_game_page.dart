import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart';
import 'functions.dart';
import 'tabliczki_result_page.dart';

class TabliczkiGamePage extends StatefulWidget {
  final List<String> wybraneTabele;
  final String iloscPytan;

  const TabliczkiGamePage({
    super.key,
    required this.wybraneTabele,
    required this.iloscPytan,
  });

  @override
  State<TabliczkiGamePage> createState() => _TabliczkiGamePageState();
}

class _TabliczkiGamePageState extends State<TabliczkiGamePage> {
  List<Map<String, String>> wszystkiePary = [];
  List<DateTime> listaCzasow = [];
  List<String> historiaPytan = [];
  Map<String, String> aktualnePytanie = {};
  Map<String, String> kolejnePytanie = {};

  bool _isLoading = true;
  bool _trwaZapis = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pobierzPytaniaIZacznij();
    });
  }

  Future<void> _pobierzPytaniaIZacznij() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('wlasne_tabliczki')
          .doc(userId)
          .collection('tabele')
          .get();

      List<Map<String, String>> pobranePary = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String nazwa = data['nazwa'] ?? '';
        if (widget.wybraneTabele.contains(nazwa)) {
          if (data['pary'] != null) {
            List<dynamic> paryList = data['pary'];
            for (var elem in paryList) {
              if (elem is Map) {
                String pyt = elem['pytanie']?.toString() ?? '';
                String odp = elem['odpowiedz']?.toString() ?? '';
                if (pyt.isNotEmpty && odp.isNotEmpty) {
                  pobranePary.add({'pytanie': pyt, 'odpowiedz': odp});
                }
              }
            }
          }
        }
      }

      if (pobranePary.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Brak pytań w wybranych tabelach!')),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        wszystkiePary = pobranePary;
        _isLoading = false;
        _rozpocznijGre();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, String> _losujDzialanieAI(
      Map<String, List<double>> profilTrudnosci, double parametrA) {
    if (wszystkiePary.isEmpty) return {'pytanie': '', 'odpowiedz': ''};

    List<Map<String, dynamic>> wirtualnyWorek = [];
    double sumaWag = 0.0;

    for (var para in wszystkiePary) {
      String dzialanie = para['pytanie']!;
      List<double> czasy = profilTrudnosci[dzialanie] ?? [6.0, 6.0, 6.0];

      double t1 = czasy.isNotEmpty ? czasy[0] : 6.0;
      double t2 = czasy.length > 1 ? czasy[1] : 6.0;
      double t3 = czasy.length > 2 ? czasy[2] : 6.0;

      double tSr = ((2 * t1) + t2 + t3) / 4.0;
      double waga = math.pow((tSr / 1.5), parametrA).toDouble();

      wirtualnyWorek.add({
        'para': para,
        'waga': waga,
      });

      sumaWag += waga;
    }

    final random = math.Random();
    double los = random.nextDouble() * sumaWag;

    double akumulator = 0.0;
    for (var opcja in wirtualnyWorek) {
      akumulator += opcja['waga'];
      if (akumulator >= los) {
        return Map<String, String>.from(opcja['para']);
      }
    }

    return Map<String, String>.from(wirtualnyWorek.last['para']);
  }

  void _rozpocznijGre() {
    final appState = context.read<AppState>();
    listaCzasow = [DateTime.now()];
    historiaPytan = [];

    aktualnePytanie = _losujDzialanieAI(
        appState.profilTrudnosci, appState.parametrA);
    historiaPytan.add(aktualnePytanie['pytanie'] ?? '');

    kolejnePytanie = _losujDzialanieAI(
        appState.profilTrudnosci, appState.parametrA);
  }

  Future<void> _nastepnePytanie() async {
    if (_trwaZapis) return;

    final appState = context.read<AppState>();
    int limitPytan = int.tryParse(widget.iloscPytan) ?? 25;

    DateTime teraz = DateTime.now();
    double czasReakcji = teraz.difference(listaCzasow.last).inMilliseconds / 1000.0;

    appState.aktualizujProfil(aktualnePytanie['pytanie'] ?? '', czasReakcji);
    listaCzasow.add(teraz);

    if (historiaPytan.length >= limitPytan) {
      setState(() => _trwaZapis = true);

      double calkowityCzas = obliczCzasCakowity(listaCzasow);
      appState.ostatniCzas = calkowityCzas;
      appState.ostatniaLiczbaPytan = widget.iloscPytan;

      try {
        String? userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId != null) {
          // 1. Zapis pełnej historii
          await FirebaseFirestore.instance.collection('wyniki').add({
            'uid': userId,
            'kategoria': 'AI_${widget.wybraneTabele.join('_')}',
            'iloscPytan': widget.iloscPytan,
            'czasSekundy': calkowityCzas,
            'dataGry': DateTime.now(),
            'pytania': historiaPytan,
            'czasyReakcji': listaCzasow,
          });

          // 2. Aktualizacja najlepszego wyniku
          String kategoria = 'AI_${widget.wybraneTabele.join('_')}_${widget.iloscPytan}';
          DocumentReference rekordyRef = FirebaseFirestore.instance
              .collection('najlepsze_wyniki')
              .doc(userId);

          DocumentSnapshot docSnap = await rekordyRef.get();
          if (docSnap.exists) {
            Map<String, dynamic> dane = docSnap.data() as Map<String, dynamic>;
            if (!dane.containsKey(kategoria) || calkowityCzas < dane[kategoria]) {
              await rekordyRef.set({kategoria: calkowityCzas}, SetOptions(merge: true));
            }
          } else {
            await rekordyRef.set({kategoria: calkowityCzas});
          }

          // 3. Zapis profilu trudności
          await FirebaseFirestore.instance
              .collection('profile_trudnosci')
              .doc(userId)
              .set({'profil': appState.profilTrudnosci}, SetOptions(merge: true));
        }
      } catch (e) {
        // Ignorowanie błędów zapisu
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TabliczkiResultPage()),
      );
      return;
    }

    setState(() {
      aktualnePytanie = kolejnePytanie;
      historiaPytan.add(aktualnePytanie['pytanie'] ?? '');
      kolejnePytanie = _losujDzialanieAI(
          appState.profilTrudnosci, appState.parametrA);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Odpytywanie (AI)'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odpytywanie (AI)'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${historiaPytan.length} z ${widget.iloscPytan}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            Text(
              aktualnePytanie['pytanie'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              aktualnePytanie['odpowiedz'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _nastepnePytanie,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text('DALEJ', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
